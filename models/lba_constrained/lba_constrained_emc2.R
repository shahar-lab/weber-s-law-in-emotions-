#### MODEL: lba_constrained (fitting side, EMC2) ####
# ASSUMED[stands in for lba_constrained.stan: the model is fitted with EMC2, so the fitting definition is an R file]
# Same model as lba_constrained.R. Assumes library(EMC2) is loaded by the study's main.R.
# Tracking accumulator (emotional for valence 6,7,8; neutral for valence 4,3,2): own v and log sv per valence cell.
# Non-tracking accumulator: one v per direction (npos, nneg); sv fixed to 1 (log sv = 0), which sets the scale.
# Scale (agreement 2): v is real; sv, B, A, t0 are sampled on the log scale (EMC2 LBA), same as lba_constrained.R.

design_lba_constrained <- function(n_subjects) {
  vg_levels  <- c("2", "3", "4", "6", "7", "8")
  acc_levels <- c("emotional", "neutral")

  # cellv: tracking cells t<valence>; the other accumulator is npos (positive images) or nneg (negative images)
  cellv_function <- function(d) {
    tracking <- (d$vg %in% c("6", "7", "8") & d$lR == "emotional") | (d$vg %in% c("2", "3", "4") & d$lR == "neutral")
    factor(ifelse(tracking, paste0("t", d$vg), ifelse(d$vg %in% c("6", "7", "8"), "npos", "nneg")),
           levels = c("t2", "t3", "t4", "t6", "t7", "t8", "npos", "nneg"))
  }

  design(factors   = list(subjects = seq_len(n_subjects), vg = vg_levels),
         Rlevels   = acc_levels,
         functions = list(cellv = cellv_function),
         formula   = list(v ~ 0 + cellv, sv ~ 0 + cellv, B ~ 0 + lR, A ~ 1, t0 ~ 1),
         constants = c(sv_cellvnpos = 0, sv_cellvnneg = 0),
         model     = LBA, report_p_vector = FALSE)
}

# Covariance blocks by parameter family; A and t0 are each their own block (match order v, sv, B, A, t0)
par_groups_lba_constrained <- function(design) {
  par_names <- names(sampled_pars(design))
  family    <- ifelse(grepl("^v_", par_names), "v",
                      ifelse(grepl("^sv_", par_names), "sv",
                             ifelse(grepl("^B_", par_names), "B", par_names)))
  match(family, c("v", "sv", "B", "A", "t0"))
}

# Population-mean priors on the estimation scale (agreement 1: same scale as the generated parameters)
# ASSUMED[priors as given in the Job Card; one prior sd per family, same mean for every cell of a family]
prior_lba_constrained <- function(design) {
  par_names <- names(sampled_pars(design))
  family    <- ifelse(grepl("^v_", par_names), "v",
                      ifelse(grepl("^sv_", par_names), "sv",
                             ifelse(grepl("^B_", par_names), "B", par_names)))
  prior_mean <- c(v = 1, sv = 0,   B = log(1.2), A = log(0.4), t0 = log(0.3))
  prior_sd   <- c(v = 1, sv = 0.3, B = 0.5,      A = 0.5,      t0 = 0.4)

  prior(design, type = "blocked", par_groups = par_groups_lba_constrained(design),
        mu_mean = setNames(unname(prior_mean[family]), par_names),
        mu_sd   = setNames(unname(prior_sd[family]),   par_names))
}
