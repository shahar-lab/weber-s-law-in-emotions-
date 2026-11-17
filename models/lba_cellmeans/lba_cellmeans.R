#### MODEL: lba_cellmeans ####
# Generating code for the lba_cellmeans model (EMC2 LBA, one parameter per cell).
# Lives in models/lba_cellmeans/ alongside lba_cellmeans_emc2.R (project-rules.md §1).
# Assumes library(EMC2) is loaded and lba_cellmeans_emc2.R is sourced first (it holds the design).
# Fitting and evaluation happen in simulation/ or analyses/ folders, never here.

# params: data frame, one row per agent, one column per parameter, on the ESTIMATION scale
#   (the same scale the fitting model samples, so no transform is applied here):
#   v_lR*:vg*   real line     drift rate of each accumulator (emotional / neutral) per valence group
#   sv_lR*:vg*  log scale     drift-rate SD; sv_lRneutral:vg6 is the constant fixed at 0 (= log 1) and has no column
#   B_lR*       log scale     threshold distance per accumulator; EMC2 threshold b = A + B
#   A           log scale     start-point upper bound
#   t0          log scale     non-decision time
# n_trials: named integer vector of trials per valence group, names "2","3","4","6","7","8".
# Returns a long data frame, one row per trial: subjects, vg, R, rt. No exclusions applied.
generate_lba_cellmeans <- function(n_subjects, n_trials, params) {
  vg_levels  <- names(n_trials)
  acc_levels <- c("emotional", "neutral")

  design_lba <- design_lba_cellmeans(n_subjects)
  par_names  <- names(sampled_pars(design_lba))
  stopifnot(nrow(params) == n_subjects, all(par_names %in% names(params)))

  # EMC2 expects a matrix, one row per subject, columns in sampled_pars() order
  alpha <- as.matrix(params[, par_names])
  rownames(alpha) <- seq_len(n_subjects)

  # skeleton with the given (unbalanced) trial counts per valence group
  skel <- do.call(rbind, lapply(seq_len(n_subjects), function(s) {
    data.frame(subjects = s, vg = rep(vg_levels, n_trials))
  }))
  skel$subjects <- factor(skel$subjects)
  skel$vg       <- factor(skel$vg, levels = vg_levels)
  skel$R        <- factor(acc_levels[1], levels = acc_levels)
  skel$rt       <- NA_real_

  df <- make_data(alpha, design_lba, data = skel)
  df[, c("subjects", "vg", "R", "rt")]
}

# Identity: generator and fitted parameters share one scale and one set of names
# (kept for a uniform interface with the other models).
map_generator_to_lba_cellmeans <- function(params) params
