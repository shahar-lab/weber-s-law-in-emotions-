#### GENERATE DATA ####
# reads: artifacts/true_parameters_N*.rds, rng_state_N*.rds
# writes: artifacts/simulated_data_N*.rds, exclusion_counts_N*.rds
# The saved RNG state is restored (not re-seeded) so that make_data() inside the generator continues the
# stream that drew the agents. This reproduces the legacy datasets and gives all five studies identical data.

for (N in n_subjects_set) {
  true_parameters <- readRDS(artifact_path("true_parameters", N))
  assign(".Random.seed", readRDS(artifact_path("rng_state", N)), envir = globalenv())

  df_raw <- generate_data(N, n_trials, true_parameters)

  # Preregistered exclusions, in order: (a) no response or rt > max_rt, (b) rt < min_rt, (c) per participant MAD
  no_response <- !is.finite(df_raw$rt) | df_raw$rt > excl$max_rt
  df_a        <- df_raw[!no_response, ]
  too_fast    <- df_a$rt < excl$min_rt
  df_b        <- df_a[!too_fast, ]
  df <- df_b |>
    group_by(subjects) |>
    filter(abs(rt - median(rt)) <= excl$mad_k * excl$mad_constant * median(abs(rt - median(rt)))) |>
    ungroup() |>
    as.data.frame()
  df$subjects <- droplevels(df$subjects)

  exclusion_counts <- data.frame(N = N, total = nrow(df_raw), no_response = sum(no_response),
                                 too_fast = sum(too_fast), mad = nrow(df_b) - nrow(df), kept = nrow(df))
  print(exclusion_counts)

  saveRDS(df,               artifact_path("simulated_data", N))
  saveRDS(exclusion_counts, artifact_path("exclusion_counts", N))
}
