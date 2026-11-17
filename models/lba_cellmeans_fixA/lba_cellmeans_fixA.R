#### MODEL: lba_cellmeans_fixA ####
# Generating code for the lba_cellmeans_fixA model.
# Lives in models/lba_cellmeans_fixA/ alongside lba_cellmeans_fixA_emc2.R (project-rules.md section 1).
# Fitting and evaluation happen in simulation/ or analyses/ folders, never here.
# Requires library(EMC2) (loaded by main.R) and lba_cellmeans_fixA_emc2.R sourced first,
# because the design (including the constant A = log 0.4) is defined there once for both directions.

# params: data frame, one row per subject, 26 columns named as EMC2 names them
#   (v_lRemotional:vg2, ..., sv_lRneutral:vg8, B_lRemotional, B_lRneutral, t0), on the
#   ESTIMATION scale: v real; sv, B, t0 log. There is no A column: A comes from the design constant.
#   Subject rows come from the same multivariate normal the fitting prior assumes.
# n_trials: trials per valence group, a vector named by vg ("2","3","4","6","7","8"),
#   or one number repeated for every group. ASSUMED[vector form so the unbalanced
#   22,24,23,24,23,22 table can be passed; exclusions are the study's job, not applied here].
# Returns a long data frame: subjects, vg, R, rt (one row per trial; R = chosen accumulator).
generate_lba_cellmeans_fixA <- function(n_subjects, n_trials, params) {
  design_fixA <- design_lba_cellmeans_fixA(n_subjects)
  par_names   <- names(sampled_pars(design_fixA))
  stopifnot(nrow(params) == n_subjects, setequal(names(params), par_names))

  trials_per_vg <- if (length(n_trials) == 1) rep(n_trials, length(vg_levels_fixA)) else n_trials[vg_levels_fixA]

  alpha <- as.matrix(params[, par_names])
  rownames(alpha) <- seq_len(n_subjects)

  df_skeleton <- do.call(rbind, lapply(seq_len(n_subjects), function(s) {
    data.frame(subjects = s, vg = rep(vg_levels_fixA, trials_per_vg))
  }))
  df_skeleton$subjects <- factor(df_skeleton$subjects)
  df_skeleton$vg       <- factor(df_skeleton$vg, levels = vg_levels_fixA)
  df_skeleton$R        <- factor(acc_levels_fixA[1], levels = acc_levels_fixA)
  df_skeleton$rt       <- NA_real_

  df <- make_data(alpha, design_fixA, data = df_skeleton)
  df[, c("subjects", "vg", "R", "rt")]
}

# Map the generating cell-means parameter table (27 columns incl. A) to this model's
# parameters: drop A. The truth for the fixed A is the constant log(0.4) itself.
map_generator_to_lba_cellmeans_fixA <- function(params) {
  if (is.null(dim(params))) return(params[names(params) != "A"])   # single named vector of group means
  params[, names(params) != "A", drop = FALSE]
}
