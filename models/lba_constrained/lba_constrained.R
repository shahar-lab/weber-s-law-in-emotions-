#### MODEL: lba_constrained ####
# Generating code for the lba_constrained model (constrained non-tracking accumulator LBA).
# Lives in models/lba_constrained/ alongside lba_constrained_emc2.R (fitting side).
# ASSUMED[generate_lba_constrained calls design_lba_constrained() from lba_constrained_emc2.R, so main.R sources both files and loads library(EMC2)]
# Fitting and evaluation happen in simulation/ or analyses/ folders, never here.

# 18 parameter names, on the estimation scale: v real; sv, B, A, t0 on the log scale (agreement 2)
lba_constrained_par_names <- c(paste0("v_cellv",  c("t2", "t3", "t4", "t6", "t7", "t8", "npos", "nneg")),
                               paste0("sv_cellv", c("t2", "t3", "t4", "t6", "t7", "t8")),
                               "B_lRemotional", "B_lRneutral", "A", "t0")

# params: data frame, one row per agent, one column per name in lba_constrained_par_names (EMC2 applies exp() to log-scale ones)
# n_trials: named integer vector, trials per valence group "2","3","4","6","7","8"
# returns a long data frame: one row per trial, columns subjects, vg, R, rt
generate_lba_constrained <- function(n_subjects, n_trials, params) {
  stopifnot(nrow(params) == n_subjects, all(lba_constrained_par_names %in% colnames(params)))
  vg_levels  <- c("2", "3", "4", "6", "7", "8")
  acc_levels <- c("emotional", "neutral")

  design <- design_lba_constrained(n_subjects)
  alpha  <- as.matrix(params[, names(sampled_pars(design))])
  rownames(alpha) <- seq_len(n_subjects)

  # skeleton: one row per trial, with the requested number of trials per valence group
  skeleton <- do.call(rbind, lapply(seq_len(n_subjects), function(s)
    data.frame(subjects = s, vg = rep(vg_levels, n_trials[vg_levels]))))
  skeleton$subjects <- factor(skeleton$subjects)
  skeleton$vg       <- factor(skeleton$vg, levels = vg_levels)
  skeleton$R        <- factor(acc_levels[1], levels = acc_levels)
  skeleton$rt       <- NA_real_

  df <- make_data(alpha, design, data = skeleton)
  df[, c("subjects", "vg", "R", "rt")]
}

# Map the cell-means generating parameters (columns v_lR<acc>:vg<g>, sv_lR<acc>:vg<g>, B_lR<acc>, A, t0;
# a data frame with one row per agent, or one named vector of group means) onto the 18 parameters above.
map_generator_to_lba_constrained <- function(params) {
  gen <- if (is.null(dim(params))) as.data.frame(as.list(params), check.names = FALSE)
         else as.data.frame(params, check.names = FALSE)

  positive_vg <- c("6", "7", "8"); negative_vg <- c("4", "3", "2")
  mapped <- list()

  # tracking cells: copied from the matching generating cell
  for (g in positive_vg) for (p in c("v", "sv")) mapped[[paste0(p, "_cellvt", g)]] <- gen[[paste0(p, "_lRemotional:vg", g)]]
  for (g in negative_vg) for (p in c("v", "sv")) mapped[[paste0(p, "_cellvt", g)]] <- gen[[paste0(p, "_lRneutral:vg", g)]]

  # non-tracking v: mean of the three generating cells of that direction
  mapped[["v_cellvnpos"]] <- rowMeans(gen[, paste0("v_lRneutral:vg", positive_vg), drop = FALSE])
  mapped[["v_cellvnneg"]] <- rowMeans(gen[, paste0("v_lRemotional:vg", negative_vg), drop = FALSE])

  for (p in c("B_lRemotional", "B_lRneutral", "A", "t0")) mapped[[p]] <- gen[[p]]

  as.data.frame(mapped, check.names = FALSE)[, lba_constrained_par_names]
}
