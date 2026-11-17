#### 03_fit.R -- fit the hierarchical LBA to each simulated dataset (resumable, parallel) ####
# Usage (from simulation/emc2_recovery/):  Rscript 03_fit.R <tier> [workers]
# Each job: output/<tier>/data/<id>.rds -> output/<tier>/results/<id>.rds (slim posterior summary).
# Full emc objects are autosaved to output/<tier>/fits_raw/<id>.RData while sampling; if a run is
# interrupted, re-running resumes from that file. Finished jobs (results file exists) are skipped.
source("01_config.R")

thin_idx <- function(n, k) unique(round(seq(1, n, length.out = min(n, k))))

fit_one <- function(id, tier_name) {
  tier <- get_tier(tier_name)
  f_res <- file.path(tier$out, "results", paste0(id, ".rds"))
  if (file.exists(f_res)) return(invisible("skipped"))
  sim   <- readRDS(file.path(tier$out, "data", paste0(id, ".rds")))
  f_raw <- file.path(tier$out, "fits_raw", paste0(id, ".RData"))
  t_start <- Sys.time()

  spec <- model_spec(tier$model)                  # "cell" (default, preregistered) | "linear" | "constrained"
  des <- spec$design(sim$N)
  if (file.exists(f_raw)) {
    emc <- f_raw                                   # fit() accepts a path and resumes
  } else {
    emc <- make_emc(spec$prep(sim$data), des, type = "blocked", par_groups = spec$groups(des),
                    prior_list = spec$prior(des), n_chains = n_chains, compress = compress)
  }
  sc <- if (is.null(tier$stop)) list(sample = c(list(iter = fit_iter), stop_crit)) else tier$stop
  emc <- fit(emc, fileName = f_raw, cores_for_chains = n_chains, verbose = FALSE,
             stop_criteria = sc, max_tries = tier$max_tries)

  # ---- slim extraction ----
  mu    <- get_pars(emc, selection = "mu",     merge_chains = TRUE, return_mcmc = FALSE)   # par x draw
  alpha <- get_pars(emc, selection = "alpha",  merge_chains = TRUE, return_mcmc = FALSE)   # par x subj x draw
  sig2  <- get_pars(emc, selection = "sigma2", merge_chains = TRUE, return_mcmc = FALSE)   # variances (par x draw)
  im <- thin_idx(ncol(mu), n_post_mu); ia <- thin_idx(dim(alpha)[3], n_post_alpha)
  gd  <- lapply(c(mu = "mu", alpha = "alpha"), function(s) tryCatch(gd_summary(emc, selection = s, stat = "max", stat_only = TRUE), error = function(e) NA))
  ess <- lapply(c(mu = "mu", alpha = "alpha"), function(s) tryCatch(ess_summary(emc, selection = s, stat = "min", stat_only = TRUE), error = function(e) NA))
  res <- list(id = id, scenario = sim$scenario, N = sim$N, rep = sim$rep,
              mu_draws = mu[, im, drop = FALSE],
              alpha_mean = apply(alpha, c(2, 1), mean),                  # subj x par
              alpha_sd   = apply(alpha, c(2, 1), sd),
              alpha_draws = alpha[, , ia, drop = FALSE],
              sigma2_mean = rowMeans(sig2),
              max_rhat = gd, min_ess = ess,
              n_draws = ncol(mu), minutes = as.numeric(difftime(Sys.time(), t_start, units = "mins")))
  saveRDS(res, f_res)
  invisible("done")
}

run_fits <- function(tier_name, workers = NULL) {
  tier <- get_tier(tier_name); workers <- workers %||% tier$workers
  todo <- tier$jobs$id[!file.exists(file.path(tier$out, "results", paste0(tier$jobs$id, ".rds")))]
  cat(sprintf("[%s] %d jobs, %d to do, %d worker(s) x %d chains\n", tier_name, nrow(tier$jobs), length(todo), workers, n_chains))
  if (!length(todo)) return(invisible())
  if (workers <= 1) { for (id in todo) { fit_one(id, tier_name); cat("finished", id, "\n") }; return(invisible()) }
  cl <- parallel::makeCluster(workers, outfile = file.path(tier$out, "worker_log.txt"))
  on.exit(parallel::stopCluster(cl))
  parallel::clusterExport(cl, c("tier_name"), envir = environment())
  parallel::clusterEvalQ(cl, source("01_config.R"))
  parallel::clusterExport(cl, c("fit_one", "thin_idx"))
  invisible(parallel::clusterApplyLB(cl, todo, function(id) { fit_one(id, tier_name); id }))
}
`%||%` <- function(a, b) if (is.null(a)) b else a

if (sys.nframe() == 0L) {
  a <- commandArgs(TRUE)
  run_fits(a[1], if (length(a) > 1) as.integer(a[2]) else NULL)
}
