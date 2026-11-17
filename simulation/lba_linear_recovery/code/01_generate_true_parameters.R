#### GENERATE TRUE PARAMETERS ####
# reads: settings from main.R
# writes: artifacts/true_population_N*.rds, true_parameters_N*.rds, rng_state_N*.rds
# set.seed() is used on purpose: all five recovery studies must see identical agents and data, and must
# reproduce the legacy simulation/emc2_recovery datasets, which were drawn from these seeds.

gen_names <- names(sampled_pars(design_generative(n_subjects_set[1])))

# Population location mu of the generating cell parameters (estimation scale)
mu_gen <- setNames(numeric(length(gen_names)), gen_names)
for (i in 1:3) {
  sides <- list(list(vg = pos_vg[i], track = pos_acc, other = neg_acc),
                list(vg = neg_vg[i], track = neg_acc, other = pos_acc))
  for (side in sides) {
    track_sv <- log(gen$sv0_track) + gen$weber_strength * log(gen$v_track[i] / gen$v_track[1])
    other_sv <- paste0("sv_lR", side$other, ":vg", side$vg)
    mu_gen[paste0("v_lR",  side$track, ":vg", side$vg)] <- gen$v_track[i]
    mu_gen[paste0("v_lR",  side$other, ":vg", side$vg)] <- gen$v_other
    mu_gen[paste0("sv_lR", side$track, ":vg", side$vg)] <- track_sv
    if (other_sv %in% gen_names) mu_gen[other_sv] <- log(gen$sv_other)   # the fixed reference cell has no entry
  }
}
mu_gen[grep("^B_lRemotional", gen_names)] <- log(gen$B_emo)
mu_gen[grep("^B_lRneutral",   gen_names)] <- log(gen$B_neu)
mu_gen["A"]  <- log(gen$A)
mu_gen["t0"] <- log(gen$t0)

# Between-participant covariance: SD per family, constant correlation inside the v, sv and B families
family    <- ifelse(grepl("^v_", gen_names), "v", ifelse(grepl("^sv_", gen_names), "sv",
                    ifelse(grepl("^B_", gen_names), "B", gen_names)))
cor_gen   <- outer(family, family, function(a, b) ifelse(a == b & a %in% c("v", "sv", "B"), gen$within_family_cor, 0))
diag(cor_gen) <- 1
sd_gen    <- unname(gen$sd[family])
Sigma_gen <- diag(sd_gen) %*% cor_gen %*% diag(sd_gen)
dimnames(Sigma_gen) <- list(gen_names, gen_names)

# The fitted model's parameters are affine in the generating ones: f(x) = f(0) + W x, W[, k] = f(e_k) - f(0)
zero_gen    <- setNames(numeric(length(gen_names)), gen_names)
f_zero      <- unlist(map_to_fitted(zero_gen))
W           <- sapply(gen_names, function(k) { e <- zero_gen; e[k] <- 1; unlist(map_to_fitted(e)) - f_zero })
fitted_pars <- names(sampled_pars(design_fitted(n_subjects_set[1])))
W           <- W[fitted_pars, , drop = FALSE]
mu_fitted   <- unlist(map_to_fitted(mu_gen))[fitted_pars]
sigma_fitted <- sqrt(diag(W %*% Sigma_gen %*% t(W)))

for (N in n_subjects_set) {
  seed <- base_seed + 1e6 * scenario_index + 1e3 * N + replicate_index
  set.seed(seed)
  alpha <- make_random_effects(design_generative(N), mu_gen, n_subj = N, covariances = Sigma_gen)
  saveRDS(get(".Random.seed", envir = globalenv()), artifact_path("rng_state", N))

  true_population <- list(
    N = N, seed = seed,
    generating = list(mu = mu_gen, sigma = setNames(sd_gen, gen_names), cov = Sigma_gen),
    fitted     = list(mu = mu_fitted, sigma = setNames(sigma_fitted, fitted_pars), W = W))
  saveRDS(true_population,        artifact_path("true_population", N))
  saveRDS(as.data.frame(alpha),   artifact_path("true_parameters", N))
}
