#### 02_simulate.R -- simulate hierarchical datasets (+ preregistered exclusions) ####
# Usage (from simulation/emc2_recovery/):
#   Rscript 02_simulate.R <tier>          # simulate all datasets of a tier (skips existing files)
#   Rscript 02_simulate.R calibrate       # accuracy / RT table for the generating values (no fitting)
source("01_config.R")

simulate_dataset <- function(scenario, N, rep, out_file = NULL, seed = seed_for(scenario, N, rep)) {
  if (!is.null(out_file) && file.exists(out_file)) return(invisible(readRDS(out_file)))
  set.seed(seed)
  des <- make_design(N)
  gm  <- true_group_means(scenario, des)
  Sig <- true_group_cov(des)
  alpha <- make_random_effects(des, gm, n_subj = N, covariances = Sig)       # N x n_par true subject parameters
  # skeleton with the preregistered (unbalanced) trial counts per valence group
  skel <- do.call(rbind, lapply(seq_len(N), function(s) data.frame(subjects = s, vg = rep(vg_levels, trials_vg))))
  skel$subjects <- factor(skel$subjects); skel$vg <- factor(skel$vg, levels = vg_levels)
  skel$R <- factor(acc_levels[1], levels = acc_levels); skel$rt <- NA_real_
  raw <- make_data(alpha, des, data = skel)
  raw <- raw[, c("subjects", "vg", "R", "rt")]
  ex  <- apply_exclusions(raw)
  res <- list(scenario = scenario, N = N, rep = rep, seed = seed, true_mu = gm, true_sigma = Sig,
              true_alpha = alpha, data = ex$data, n_excluded = ex$counts)
  if (!is.null(out_file)) saveRDS(res, out_file)
  invisible(res)
}

# Quick look at what the generating values imply (many trials, one "average" subject per scenario).
calibrate <- function(n_trials = 2000) {
  des <- make_design(1)
  for (sc in names(scenarios)) {
    set.seed(1)
    gm <- true_group_means(sc, des)
    skel <- data.frame(subjects = factor(1), vg = factor(rep(vg_levels, each = n_trials), levels = vg_levels),
                       R = factor(acc_levels[1], levels = acc_levels), rt = NA_real_)
    d <- make_data(gm, des, data = skel)
    trk <- (d$vg %in% pos_vg & d$R == pos_acc) | (d$vg %in% neg_vg & d$R == neg_acc)
    ex <- apply_exclusions(transform(d, subjects = factor(1)))
    cat("\n== scenario:", sc, "==\n")
    print(round(cbind(p_tracked = tapply(trk, d$vg, mean), median_RT = tapply(d$rt, d$vg, median),
                      q10_RT = tapply(d$rt, d$vg, quantile, .1), q90_RT = tapply(d$rt, d$vg, quantile, .9)), 3))
    cat("excluded:", paste(names(ex$counts), ex$counts, collapse = ", "), "\n")
  }
}

if (sys.nframe() == 0L) {
  arg <- commandArgs(TRUE)[1]
  if (identical(arg, "calibrate")) calibrate() else {
    tier <- get_tier(arg)
    for (i in seq_len(nrow(tier$jobs))) {
      j <- tier$jobs[i, ]
      f <- file.path(tier$out, "data", paste0(j$id, ".rds"))
      if (!file.exists(f)) { simulate_dataset(j$scenario, j$N, j$rep, f); cat("simulated", j$id, "\n") }
    }
  }
}
