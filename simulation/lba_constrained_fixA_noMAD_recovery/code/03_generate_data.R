#### GENERATE DATA ####
# reads: artifacts/true_parameters_N*.rds, rng_state_N*.rds
# writes: artifacts/simulated_data_N*.rds (+ .csv copy), exclusion_counts_N*.rds
# The saved RNG state is restored (not re-seeded) so that make_data() inside the generator continues the
# stream that drew the agents. This reproduces the legacy datasets and gives all five studies identical data.

for (N in n_subjects_set) {
  true_parameters <- readRDS(artifact_path("true_parameters", N))
  assign(".Random.seed", readRDS(artifact_path("rng_state", N)), envir = globalenv())

  df_raw <- generate_data(N, n_trials, true_parameters)

  # Basic trimming, in order: (a) no response or rt > max_rt, (b) rt < min_rt. No MAD cutoff.
  no_response <- !is.finite(df_raw$rt) | df_raw$rt > excl$max_rt
  df_a        <- df_raw[!no_response, ]
  too_fast    <- df_a$rt < excl$min_rt
  df          <- df_a[!too_fast, ]
  df$subjects <- droplevels(df$subjects)

  exclusion_counts <- data.frame(N = N, total = nrow(df_raw), no_response = sum(no_response),
                                 too_fast = sum(too_fast), kept = nrow(df))
  print(exclusion_counts)

  saveRDS(df,               artifact_path("simulated_data", N))
  write.csv(df,             artifact_path("simulated_data", N, "csv"), row.names = FALSE)
  saveRDS(exclusion_counts, artifact_path("exclusion_counts", N))
}
