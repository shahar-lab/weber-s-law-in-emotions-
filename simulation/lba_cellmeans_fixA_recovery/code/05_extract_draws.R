#### EXTRACT DRAWS ####
# reads: artifacts/emc_fit_N*.RData, true_population_N*.rds, true_parameters_N*.rds
# writes: artifacts/draws_pop, draws_sbj, chains_mu, chains_stage, convergence, recovered_parameters (_N*.rds)

thin_idx <- function(n, k) unique(round(seq(1, n, length.out = min(n, k))))

for (N in n_subjects_set) {
  stopifnot(file.exists(artifact_path("fit_done", N)))
  true_population <- readRDS(artifact_path("true_population", N))
  true_fitted     <- map_to_fitted(readRDS(artifact_path("true_parameters", N)))
  fitted_pars     <- names(true_population$fitted$mu)

  fit_env <- new.env()
  load(artifact_path("emc_fit", N, "RData"), envir = fit_env)
  emc <- Find(function(object) inherits(object, "emc"), mget(ls(fit_env), envir = fit_env))

  mu     <- get_pars(emc, selection = "mu",     merge_chains = TRUE, return_mcmc = FALSE)   # parameters x draws
  alpha  <- get_pars(emc, selection = "alpha",  merge_chains = TRUE, return_mcmc = FALSE)   # parameters x subjects x draws
  sigma2 <- get_pars(emc, selection = "sigma2", merge_chains = TRUE, return_mcmc = FALSE)   # population variances, parameters x draws
  if (!all(fitted_pars %in% rownames(sigma2))) rownames(sigma2) <- rownames(mu)

  # Population draws (long): mu and sigma = sqrt(variance), up to n_draws_pop thinned draws
  pop_idx <- thin_idx(ncol(mu), n_draws_pop)
  pop_matrices <- list(mu = mu[fitted_pars, pop_idx], sigma = sqrt(sigma2[fitted_pars, pop_idx]))
  draws_pop <- imap(pop_matrices, function(m, type) {
    tibble(.draw = rep(pop_idx, each = nrow(m)), type = type,
           parameter = rep(rownames(m), times = ncol(m)), value = as.vector(m))
  }) |> list_rbind() |> mutate(variable = paste0(type, "_", parameter))

  # Agent-level draws: array parameters x subjects x draws, thinned to n_draws_sbj
  draws_sbj <- alpha[fitted_pars, , thin_idx(dim(alpha)[3], n_draws_sbj), drop = FALSE]

  # Convergence of the raw fit
  convergence <- tibble(
    selection = c("mu", "alpha"),
    rhat_max  = vapply(selection, function(s) max(as.numeric(unlist(
      gd_summary(emc, selection = s, stat = "max", stat_only = TRUE))), na.rm = TRUE), numeric(1), USE.NAMES = FALSE),
    ess_min   = vapply(selection, function(s) min(as.numeric(unlist(
      ess_summary(emc, selection = s, stat = "min", stat_only = TRUE))), na.rm = TRUE), numeric(1), USE.NAMES = FALSE))

  # Recovered parameters per agent (posterior median and SD over all draws) beside the truth
  subject_ids <- as.integer(dimnames(alpha)[[2]])
  post_median <- apply(alpha[fitted_pars, , , drop = FALSE], c(1, 2), median)
  post_sd     <- apply(alpha[fitted_pars, , , drop = FALSE], c(1, 2), sd)
  recovered_parameters <- tibble(
    subject      = rep(subject_ids, each = length(fitted_pars)),
    parameter    = rep(fitted_pars, times = length(subject_ids)),
    true         = as.vector(t(as.matrix(true_fitted[subject_ids, fitted_pars]))),
    recovered    = as.vector(post_median),
    posterior_sd = as.vector(post_sd))

  saveRDS(draws_pop,            artifact_path("draws_pop", N))
  saveRDS(draws_sbj,            artifact_path("draws_sbj", N))
  saveRDS(lapply(emc, function(ch) ch$samples$theta_mu), artifact_path("chains_mu", N))
  saveRDS(lapply(emc, function(ch) ch$samples$stage),    artifact_path("chains_stage", N))
  saveRDS(convergence,          artifact_path("convergence", N))
  saveRDS(recovered_parameters, artifact_path("recovered_parameters", N))
  rm(emc, alpha, mu, sigma2); gc()
}
