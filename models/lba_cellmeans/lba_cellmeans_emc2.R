#### MODEL: lba_cellmeans (fitting direction, EMC2) ####
# ASSUMED[EMC2 file stands in for .stan]: EMC2 fits the LBA, so this file replaces lba_cellmeans.stan.
# Assumes library(EMC2) is loaded by the study's main.R.
# Agreement with lba_cellmeans.R: same parameter names and the same scale (v on the real line;
# sv, B, A, t0 on the log scale; threshold b = A + B). Population values, sampler settings and
# trial counts are set in the simulation folder's main.R, not here.

design_lba_cellmeans <- function(n_subjects) {
  # factor is called vg because EMC2 forbids underscores in factor names
  vg_levels <- c("2", "3", "4", "6", "7", "8")
  design(factors  = list(subjects = seq_len(n_subjects), vg = vg_levels),
         Rlevels  = c("emotional", "neutral"),
         formula  = list(v ~ 0 + lR:vg, sv ~ 0 + lR:vg, B ~ 0 + lR, A ~ 1, t0 ~ 1),
         constants = c("sv_lRneutral:vg6" = 0),   # log sv = 0 fixes the scale (identifiability)
         model = LBA, report_p_vector = FALSE)
}

# Blocked covariance: one block per family v, sv, B, A, t0 (parameters of a family may correlate)
family_lba_cellmeans <- function(design) {
  par_names <- names(sampled_pars(design))
  ifelse(grepl("^v_", par_names), "v",
         ifelse(grepl("^sv_", par_names), "sv",
                ifelse(grepl("^B_", par_names), "B", par_names)))
}

par_groups_lba_cellmeans <- function(design) {
  match(family_lba_cellmeans(design), c("v", "sv", "B", "A", "t0"))
}

# Priors on the population means, estimation scale:
#   v ~ N(1, 1); log sv ~ N(0, 0.3); log B ~ N(log 1.2, 0.5); log A ~ N(log 0.4, 0.5); log t0 ~ N(log 0.3, 0.4)
prior_lba_cellmeans <- function(design) {
  par_names <- names(sampled_pars(design))
  family    <- family_lba_cellmeans(design)
  prior_mean <- c(v = 1, sv = 0, B = log(1.2), A = log(0.4), t0 = log(0.3))
  prior_sd   <- c(v = 1, sv = 0.3, B = 0.5, A = 0.5, t0 = 0.4)

  prior(design, type = "blocked", par_groups = par_groups_lba_cellmeans(design),
        mu_mean = setNames(unname(prior_mean[family]), par_names),
        mu_sd   = setNames(unname(prior_sd[family]),   par_names))
}
