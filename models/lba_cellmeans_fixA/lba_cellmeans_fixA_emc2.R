#### MODEL: lba_cellmeans_fixA (EMC2 fitting definition) ####
# Fitting code for the lba_cellmeans_fixA model; stands in for lba_cellmeans_fixA.stan
# (EMC2 is the sampler, no Stan). ASSUMED[EMC2 file replaces the .stan file, per Job Card 2].
# Lives in models/lba_cellmeans_fixA/ alongside lba_cellmeans_fixA.R (project-rules.md section 1).
# Assumes library(EMC2) is loaded by the study's main.R. Nothing is fitted here.
#
# Cell-means LBA, 2 accumulators (lR = emotional, neutral) x 6 valence groups (vg = 2,3,4,6,7,8):
#   v  ~ 0 + lR:vg   (12, real scale)
#   sv ~ 0 + lR:vg   (11 free, log scale; sv_lRneutral:vg6 constant 0 = sv of 1)
#   B  ~ 0 + lR      (2, log scale)
#   A  fixed at log(0.4) (constant, not sampled)
#   t0 ~ 1           (1, log scale)
# 26 free parameters. The population form and scales match the generating file:
# subject parameters are multivariate normal on this estimation scale (EMC2 LBA: v real; sv, B, A, t0 log).

vg_levels_fixA  <- c("2", "3", "4", "6", "7", "8")   # "vg", not "valence_group": EMC2 forbids "_" in factor names
acc_levels_fixA <- c("emotional", "neutral")
log_A_fixed     <- log(0.4)

design_lba_cellmeans_fixA <- function(n_subjects) {
  design(factors   = list(subjects = seq_len(n_subjects), vg = vg_levels_fixA),
         Rlevels   = acc_levels_fixA,
         formula   = list(v ~ 0 + lR:vg, sv ~ 0 + lR:vg, B ~ 0 + lR, A ~ 1, t0 ~ 1),
         constants = c("sv_lRneutral:vg6" = 0, A = log_A_fixed),
         model     = LBA,
         report_p_vector = FALSE)
}

# Covariance blocks by family (v, sv, B, t0); A is not sampled, so it has no block.
par_groups_lba_cellmeans_fixA <- function(design) {
  par_names <- names(sampled_pars(design))
  family    <- ifelse(grepl("^v_", par_names), "v",
               ifelse(grepl("^sv_", par_names), "sv",
               ifelse(grepl("^B_", par_names), "B", par_names)))
  match(family, c("v", "sv", "B", "t0"))
}

# Priors on the estimation scale; same prior mean for every cell of a family (no ordering assumed).
prior_lba_cellmeans_fixA <- function(design) {
  par_names <- names(sampled_pars(design))
  family    <- ifelse(grepl("^v_", par_names), "v",
               ifelse(grepl("^sv_", par_names), "sv",
               ifelse(grepl("^B_", par_names), "B", par_names)))

  prior_mean <- c(v = 1,  sv = 0,   B = log(1.2), t0 = log(0.3))
  prior_sd   <- c(v = 1,  sv = 0.3, B = 0.5,      t0 = 0.4)

  prior(design,
        type       = "blocked",
        par_groups = par_groups_lba_cellmeans_fixA(design),
        mu_mean    = setNames(unname(prior_mean[family]), par_names),
        mu_sd      = setNames(unname(prior_sd[family]),   par_names))
}
