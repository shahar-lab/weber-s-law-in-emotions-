#### MODEL: lba_constrained_fixA ####
# Generating code for the lba_constrained_fixA model (EMC2 LBA, constrained non-tracking accumulator, A fixed).
# Lives in models/lba_constrained_fixA/ alongside lba_constrained_fixA_emc2.R (project-rules.md §1).
# Assumes library(EMC2) is loaded and lba_constrained_fixA_emc2.R is sourced first (it holds the design).
# Fitting and evaluation happen in simulation/ or analyses/ folders, never here.

# params: data frame, one row per agent, 17 columns, on the ESTIMATION scale
#   (the same scale the fitting model samples, so no transform is applied here):
#   v_cellvt2..t8, v_cellvnpos, v_cellvnneg   real line   drift rates (tracking cells; non-tracking per direction)
#   sv_cellvt2..t8                            log scale    drift-rate SD of the tracking accumulator
#   B_lRemotional, B_lRneutral                log scale    threshold distance per accumulator; EMC2 b = A + B
#   t0                                        log scale    non-decision time
# sv of the non-tracking cells (log sv = 0) and A (log 0.4) are design constants and have no column.
# n_trials: named integer vector of trials per valence group, names "2","3","4","6","7","8".
# Returns a long data frame, one row per trial: subjects, vg, R, rt. No exclusions applied.
generate_lba_constrained_fixA <- function(n_subjects, n_trials, params) {
  vg_levels  <- names(n_trials)
  acc_levels <- c("emotional", "neutral")

  design_lba <- design_lba_constrained_fixA(n_subjects)
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

# From the generating cell-means table (columns v_lR{acc}:vg{g}, sv_lR..., B_lR..., A, t0; rows = agents,
# or one named vector of group means) to the 17 parameters of this model.
#   tracking cells copied (emotional for vg 6,7,8; neutral for vg 4,3,2); non-tracking v = mean of its
#   three cells per direction (npos: neutral at vg 6,7,8; nneg: emotional at vg 2,3,4); B, t0 copied; A dropped.
map_generator_to_lba_constrained_fixA <- function(params) {
  params <- as.data.frame(if (is.null(dim(params))) t(params) else params, check.names = FALSE)

  pos_vg <- c("6", "7", "8")
  neg_vg <- c("2", "3", "4")
  out    <- data.frame(row.names = seq_len(nrow(params)))

  for (g in pos_vg) {
    out[[paste0("v_cellvt",  g)]] <- params[[paste0("v_lRemotional:vg",  g)]]
    out[[paste0("sv_cellvt", g)]] <- params[[paste0("sv_lRemotional:vg", g)]]
  }
  for (g in neg_vg) {
    out[[paste0("v_cellvt",  g)]] <- params[[paste0("v_lRneutral:vg",  g)]]
    out[[paste0("sv_cellvt", g)]] <- params[[paste0("sv_lRneutral:vg", g)]]
  }
  out$v_cellvnpos <- rowMeans(params[, paste0("v_lRneutral:vg",   pos_vg), drop = FALSE])
  out$v_cellvnneg <- rowMeans(params[, paste0("v_lRemotional:vg", neg_vg), drop = FALSE])
  out$B_lRemotional <- params[["B_lRemotional"]]
  out$B_lRneutral   <- params[["B_lRneutral"]]
  out$t0            <- params[["t0"]]

  # reorder to EMC2's sampled_pars() order: v (t2..t8, npos, nneg), sv (t2..t8), B, t0
  v_order  <- paste0("v_cellv",  c("t2", "t3", "t4", "t6", "t7", "t8", "npos", "nneg"))
  sv_order <- paste0("sv_cellv", c("t2", "t3", "t4", "t6", "t7", "t8"))
  out[, c(v_order, sv_order, "B_lRemotional", "B_lRneutral", "t0")]
}
