#### diag_single.R -- sanity check: non-hierarchical fit of ONE participant with lots of data ####
# Rscript diag_single.R <exclusions 0|1> [trials_per_cell]. Checks code/bias before trusting hierarchical fits.
source("01_config.R")
a <- commandArgs(TRUE); use_excl <- as.integer(a[1]); ntc <- if (length(a) > 1) as.integer(a[2]) else 1000
set.seed(42)
des <- make_design(1); gm <- true_group_means("perception", des)
skel <- data.frame(subjects = factor(1), vg = factor(rep(vg_levels, each = ntc), levels = vg_levels),
                   R = factor(acc_levels[1], levels = acc_levels), rt = NA_real_)
dat <- make_data(gm, des, data = skel)[, c("subjects", "vg", "R", "rt")]
n0 <- nrow(dat)
if (use_excl) dat <- apply_exclusions(dat)$data else dat <- dat[is.finite(dat$rt) & dat$rt <= max_rt, ]
cat("rows", n0, "->", nrow(dat), "\n")
nm <- names(sampled_pars(des)); fam <- sapply(nm, function(n) if (grepl("^v_", n)) "v" else if (grepl("^sv_", n)) "sv" else if (grepl("^B_", n)) "B" else n)
pr <- prior(des, type = "single", pmean = setNames(sapply(fam, function(f) prior_cfg[[f]]["mean"]), nm),
            psd = setNames(sapply(fam, function(f) prior_cfg[[f]]["sd"]), nm))
emc <- make_emc(dat, des, type = "single", prior_list = pr, n_chains = 3, compress = FALSE)
t0 <- Sys.time()
emc <- fit(emc, cores_for_chains = 3, verbose = FALSE, max_tries = 10,
           stop_criteria = list(sample = list(iter = 1000, max_gd = 1.1, selection = "alpha", omit_mpsrf = TRUE)))
cat("minutes", round(as.numeric(difftime(Sys.time(), t0, units = "mins")), 1), "\n")
al <- get_pars(emc, selection = "alpha", merge_chains = TRUE, return_mcmc = FALSE)[, 1, ]
est <- rowMeans(al); ci <- t(apply(al, 1, quantile, c(.05, .95)))
tab <- data.frame(par = nm, true = round(gm[nm], 2), est = round(est, 2), lo = round(ci[, 1], 2), hi = round(ci[, 2], 2))
tab$ok <- tab$true >= tab$lo & tab$true <= tab$hi
print(tab, row.names = FALSE); cat("covered:", sum(tab$ok), "of", nrow(tab), "\n")
cat("max R-hat:", unlist(gd_summary(emc, selection = "alpha", stat_only = TRUE)), " min ESS:", unlist(ess_summary(emc, selection = "alpha", stat_only = TRUE)), "\n")
