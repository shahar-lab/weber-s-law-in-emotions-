#### MODEL: lba_constrained_fixA (fitting direction, EMC2) ####
# ASSUMED[EMC2 file stands in for .stan]: EMC2 fits the LBA, so this file replaces lba_constrained_fixA.stan.
# Assumes library(EMC2) is loaded by the study's main.R.
# Model: constrained non-tracking accumulator, A fixed at its true value (not a preregistered model).
#   Tracking accumulator (emotional for valence 6,7,8; neutral for 4,3,2): own v and log sv per valence cell (6 + 6).
#   Non-tracking accumulator: one v per direction (npos, nneg); sv fixed at 1 (log sv = 0) in every cell.
#   B per accumulator, t0 single, A a constant at log(0.4). 17 free parameters.
# Agreement with lba_constrained_fixA.R: same parameter names and scale (v on the real line;
# sv, B, t0 on the log scale; threshold b = A + B; A constant on the log scale).

design_lba_constrained_fixA <- function(n_subjects) {
  # factor is called vg because EMC2 forbids underscores in factor names
  vg_levels <- c("2", "3", "4", "6", "7", "8")

  # cell label per row: tracking cells keep their valence (t2..t8), the other accumulator is pooled by direction
  cellv_fun <- function(d) {
    tracking <- (d$vg %in% c("6", "7", "8") & d$lR == "emotional") |
                (d$vg %in% c("2", "3", "4") & d$lR == "neutral")
    label    <- ifelse(tracking, paste0("t", d$vg), ifelse(d$vg %in% c("6", "7", "8"), "npos", "nneg"))
    factor(label, levels = c("t2", "t3", "t4", "t6", "t7", "t8", "npos", "nneg"))
  }

  design(factors   = list(subjects = seq_len(n_subjects), vg = vg_levels),
         Rlevels   = c("emotional", "neutral"),
         functions = list(cellv = cellv_fun),
         formula   = list(v ~ 0 + cellv, sv ~ 0 + cellv, B ~ 0 + lR, A ~ 1, t0 ~ 1),
         # log sv = 0 fixes the scale; A fixed at its true value 0.4 (log scale)
         constants = c(sv_cellvnpos = 0, sv_cellvnneg = 0, A = log(0.4)),
         model = LBA, report_p_vector = FALSE)
}

# Blocked covariance: one block per family v, sv, B, t0 (parameters of a family may correlate)
family_lba_constrained_fixA <- function(design) {
  par_names <- names(sampled_pars(design))
  ifelse(grepl("^v_", par_names), "v",
         ifelse(grepl("^sv_", par_names), "sv",
                ifelse(grepl("^B_", par_names), "B", par_names)))
}

par_groups_lba_constrained_fixA <- function(design) {
  match(family_lba_constrained_fixA(design), c("v", "sv", "B", "t0"))
}

# Priors on the population means, estimation scale (no prior for A: it is a constant):
#   v ~ N(1, 1); log sv ~ N(0, 0.3); log B ~ N(log 1.2, 0.5); log t0 ~ N(log 0.3, 0.4)
prior_lba_constrained_fixA <- function(design) {
  par_names  <- names(sampled_pars(design))
  family     <- family_lba_constrained_fixA(design)
  prior_mean <- c(v = 1, sv = 0, B = log(1.2), t0 = log(0.3))
  prior_sd   <- c(v = 1, sv = 0.3, B = 0.5, t0 = 0.4)

  prior(design, type = "blocked", par_groups = par_groups_lba_constrained_fixA(design),
        mu_mean = setNames(unname(prior_mean[family]), par_names),
        mu_sd   = setNames(unname(prior_sd[family]),   par_names))
}
