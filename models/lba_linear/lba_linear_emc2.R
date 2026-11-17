#### MODEL: lba_linear (EMC2 fitting side) ####
# ASSUMED[EMC2 stands in for .stan]: this file is the fitting direction of the model (design, blocks, priors) written
# for EMC2 instead of Stan. Assumes library(EMC2) is loaded by main.R.
# Agreements with lba_linear.R:
#  - scale: v and slopes real; sv intercepts, B, A, t0 on the log scale (EMC2 LBA); sv slopes in log-sv units.
#  - population form: EMC2 draws subject parameters as multivariate normal around mu on that scale, blocked by family.
#  - the data carry direction (pos/neg) and intensity (0,1,2) from prep_data_lba_linear().
# v and sv: accumulator x direction intercept (weakest intensity) + accumulator x direction x intensity slope.
# Scale reference: sv of the neutral accumulator, positive direction, intercept, fixed to 1 (log 0).

fixed_sv_lba_linear <- "sv_lRneutral:directionpos"

design_lba_linear <- function(n_subjects) {
  design(factors = list(subjects = seq_len(n_subjects), direction = c("pos", "neg")),
         covariates = "intensity", Rlevels = c("emotional", "neutral"),
         formula = list(v  ~ 0 + lR:direction + lR:direction:intensity,
                        sv ~ 0 + lR:direction + lR:direction:intensity,
                        B ~ 0 + lR, A ~ 1, t0 ~ 1),
         constants = setNames(0, fixed_sv_lba_linear), model = LBA, report_p_vector = FALSE)
}

family_lba_linear <- function(par_names) {
  ifelse(grepl("^v_", par_names), "v", ifelse(grepl("^sv_", par_names), "sv", ifelse(grepl("^B_", par_names), "B", par_names)))
}

# One covariance block per family: v, sv, B, A, t0
par_groups_lba_linear <- function(design) {
  match(family_lba_linear(names(sampled_pars(design))), c("v", "sv", "B", "A", "t0"))
}

# Prior on mu (estimation scale): c(mean, sd). Slopes centred on 0 (skeptical about increases).
prior_lba_linear <- function(design) {
  par_names <- names(sampled_pars(design))
  is_slope  <- grepl(":intensity$", par_names)
  family    <- family_lba_linear(par_names)
  key       <- ifelse(family %in% c("v", "sv"), paste0(family, ifelse(is_slope, "_slope", "_int")), family)

  mu_by_key <- list(v_int = c(1, 1),      v_slope = c(0, 0.5),
                    sv_int = c(0, 0.3),   sv_slope = c(0, 0.3),
                    B = c(log(1.2), 0.5), A = c(log(0.4), 0.5), t0 = c(log(0.3), 0.4))

  prior(design, type = "blocked", par_groups = par_groups_lba_linear(design),
        mu_mean = setNames(sapply(key, function(k) mu_by_key[[k]][1]), par_names),
        mu_sd   = setNames(sapply(key, function(k) mu_by_key[[k]][2]), par_names))
}
