#### MODEL: lba_linear ####
# Generating code for the linear-in-intensity LBA (two accumulators: emotional, neutral).
# Lives in models/lba_linear/ alongside lba_linear_emc2.R (stands in for the .stan file).
# Fitting and evaluation happen in simulation/ or analyses/ folders, never here.
# Assumes library(EMC2) is loaded by main.R and lba_linear_emc2.R is sourced (design_lba_linear).
#
# Agreements with lba_linear_emc2.R (scale and population form):
#  - params arrive on the ESTIMATION scale EMC2 samples: v and all slopes real; sv intercepts, B, A, t0 on the
#    log scale; sv slopes in log-sv units. They are passed to make_data() untransformed.
#  - one row per agent, drawn by the calling study (nothing is drawn here).

# ASSUMED[valence levels]: the six valence groups, in this order, are the levels of vg.
vg_levels_lba_linear  <- c("2", "3", "4", "6", "7", "8")
acc_levels_lba_linear <- c("emotional", "neutral")

# Adds direction (pos = valence 6,7,8; neg = valence 4,3,2) and intensity (numeric 0,1,2 = intensity 1,2,3 minus 1).
prep_data_lba_linear <- function(df) {
  intensity_by_vg <- c("2" = 2, "3" = 1, "4" = 0, "6" = 0, "7" = 1, "8" = 2)
  df$direction <- factor(ifelse(as.character(df$vg) %in% c("6", "7", "8"), "pos", "neg"), levels = c("pos", "neg"))
  df$intensity <- unname(intensity_by_vg[as.character(df$vg)])
  df
}

# n_trials: named integer vector over valence "2","3","4","6","7","8"; params: n_subjects x 19 data frame
generate_lba_linear <- function(n_subjects, n_trials, params) {
  design <- design_lba_linear(n_subjects)
  par_names <- names(sampled_pars(design))
  stopifnot(nrow(params) == n_subjects, setequal(names(params), par_names), setequal(names(n_trials), vg_levels_lba_linear))

  alpha <- as.matrix(params[, par_names])
  rownames(alpha) <- as.character(seq_len(n_subjects))

  df <- do.call(rbind, lapply(seq_len(n_subjects), function(s) {
    data.frame(subjects = s, vg = rep(vg_levels_lba_linear, n_trials[vg_levels_lba_linear]))
  }))
  df$subjects <- factor(df$subjects, levels = seq_len(n_subjects))
  df$vg       <- factor(df$vg, levels = vg_levels_lba_linear)
  df$R        <- factor(acc_levels_lba_linear[1], levels = acc_levels_lba_linear)
  df$rt       <- NA_real_
  df <- prep_data_lba_linear(df)

  df <- make_data(alpha, design, data = df)
  df[, c("subjects", "vg", "R", "rt")]
}

# Cell-means generating parameters (columns v_lR{acc}:vg{g}, sv_lR{acc}:vg{g}, B_lR{acc}, A, t0; rows = agents,
# or one named vector of group means) -> this model's 19 parameters: the least-squares line through the three
# cells of each accumulator x direction, x = 0,1,2.  slope = (high - low) / 2; intercept = 5/6 low + 1/3 mid - 1/6 high.
# The fixed cell sv_lRneutral:vg6 is absent from the table and counts as log 0.
map_generator_to_lba_linear <- function(params) {
  cells <- as.data.frame(if (is.null(dim(params))) t(params) else params, check.names = FALSE)
  vgs_by_direction <- list(pos = c("6", "7", "8"), neg = c("4", "3", "2"))   # intensity 0, 1, 2
  cell_value <- function(name) if (name %in% names(cells)) cells[[name]] else rep(0, nrow(cells))

  out <- data.frame(row.names = seq_len(nrow(cells)))
  for (family in c("v", "sv")) for (acc in acc_levels_lba_linear) for (direction in c("pos", "neg")) {
    cell_names <- paste0(family, "_lR", acc, ":vg", vgs_by_direction[[direction]])
    low <- cell_value(cell_names[1]); mid <- cell_value(cell_names[2]); high <- cell_value(cell_names[3])
    stem <- paste0(family, "_lR", acc, ":direction", direction)
    if (stem != "sv_lRneutral:directionpos") out[[stem]] <- low * 5/6 + mid / 3 - high / 6
    out[[paste0(stem, ":intensity")]] <- (high - low) / 2
  }
  for (name in c("B_lRemotional", "B_lRneutral", "A", "t0")) out[[name]] <- cell_value(name)
  out
}
