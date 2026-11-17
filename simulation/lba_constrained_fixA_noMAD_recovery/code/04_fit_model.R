#### FIT MODEL ####
# reads: artifacts/simulated_data_N*.rds
# writes: artifacts/emc_fit_N*.RData (EMC2 autosave), fit_done_N*.rds (marker)
# An N whose marker exists is never refitted. If only the autosave exists, fit() resumes from it.
# An existing fit of the identical dataset (legacy_run_dir) is copied in once and resumed the same way.

for (N in n_subjects_set) {
  fit_file    <- artifact_path("emc_fit", N, "RData")
  marker_file <- artifact_path("fit_done", N)
  if (file.exists(marker_file)) {
    message("N = ", N, ": fit_done marker exists, fit skipped")
    next
  }

  # A finished legacy fit of the identical dataset is reused as it stands: copied in and marked done, never resumed
  if (!is.null(legacy_run_dir) && !file.exists(fit_file)) {
    legacy_fit <- file.path(legacy_run_dir, "fits_raw", paste0(sprintf(legacy_fit_name, N), ".RData"))
    legacy_res <- file.path(legacy_run_dir, "results", paste0(sprintf(legacy_fit_name, N), ".rds"))
    if (file.exists(legacy_fit) && file.exists(legacy_res)) {
      file.copy(legacy_fit, fit_file)
      legacy <- readRDS(legacy_res)
      saveRDS(list(N = N, minutes = legacy$minutes, draws = legacy$n_draws, reused_legacy_fit = TRUE), marker_file)
      message("N = ", N, ": legacy fit copied and marked done")
      next
    }
  }

  df         <- prep_data_fitted(readRDS(artifact_path("simulated_data", N)))
  design_fit <- design_fitted(N)
  emc <- if (file.exists(fit_file)) {
    fit_file
  } else {
    make_emc(df, design_fit, type = "blocked", par_groups = par_groups_fitted(design_fit),
             prior_list = prior_fitted(design_fit), n_chains = n_chains, compress = compress_rt)
  }

  start_time <- Sys.time()
  emc <- fit(emc, fileName = fit_file, cores_for_chains = n_chains, verbose = FALSE,
             stop_criteria = stop_criteria, max_tries = max_tries)
  minutes <- as.numeric(difftime(Sys.time(), start_time, units = "mins"))

  n_draws <- ncol(get_pars(emc, selection = "mu", merge_chains = TRUE, return_mcmc = FALSE))
  saveRDS(list(N = N, minutes = minutes, draws = n_draws), marker_file)
}
