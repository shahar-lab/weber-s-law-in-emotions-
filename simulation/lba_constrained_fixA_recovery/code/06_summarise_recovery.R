#### SUMMARISE RECOVERY ####
# reads: artifacts/true_population, recovered_parameters, draws_pop, convergence (_N*.rds)
# writes: artifacts/recovery_table_N*.rds
# Numbers only: no pass/fail threshold is applied (the researcher set no recovery criteria).

for (N in n_subjects_set) {
  true_population <- readRDS(artifact_path("true_population", N))
  recovered       <- readRDS(artifact_path("recovered_parameters", N))
  draws_pop       <- readRDS(artifact_path("draws_pop", N))
  convergence     <- readRDS(artifact_path("convergence", N))
  fitted_pars     <- names(true_population$fitted$mu)

  # 1. Convergence first, 2-4. participant level: Pearson r, bias, precision, shrinkage
  participant <- recovered |>
    group_by(parameter) |>
    summarise(r = cor(true, recovered), bias_mean = mean(recovered - true),
              ols_slope = cov(true, recovered) / var(true),
              median_posterior_sd = median(posterior_sd),
              true_sd = sd(true), recovered_sd = sd(recovered),
              shrinkage_ratio = recovered_sd / true_sd, .groups = "drop") |>
    mutate(family = sub("_.*$", "", parameter), .before = 1) |>
    arrange(match(parameter, fitted_pars))

  participant_by_family <- participant |>
    group_by(family) |>
    summarise(n_parameters = n(), median_r = median(r), mean_bias = mean(bias_mean),
              median_ols_slope = median(ols_slope),
              median_posterior_sd = median(median_posterior_sd),
              median_shrinkage_ratio = median(shrinkage_ratio), .groups = "drop") |>
    arrange(match(family, participant$family))

  # 5. Population level: posterior median, 90% HDI and whether the true value lies inside it
  truth <- bind_rows(
    tibble(type = "mu",    parameter = fitted_pars, true = unname(true_population$fitted$mu[fitted_pars])),
    tibble(type = "sigma", parameter = fitted_pars, true = unname(true_population$fitted$sigma[fitted_pars])))
  population <- draws_pop |>
    group_by(type, parameter) |>
    median_hdci(value, .width = hdi_width) |>
    ungroup() |>
    left_join(truth, by = c("type", "parameter")) |>
    mutate(family = sub("_.*$", "", parameter), covered = true >= .lower & true <= .upper) |>
    select(type, family, parameter, median = value, hdi_lower = .lower, hdi_upper = .upper, true, covered) |>
    arrange(type, match(parameter, fitted_pars))

  population_by_family <- population |>
    group_by(type, family) |>
    summarise(n_parameters = n(), n_true_inside_hdi = sum(covered), .groups = "drop")

  # 6. Trade-offs: Pearson correlation of the recovery errors of every parameter pair
  errors <- recovered |>
    mutate(error = recovered - true) |>
    pivot_wider(id_cols = subject, names_from = parameter, values_from = error) |>
    select(-subject)
  cor_errors <- cor(errors)
  pair_index <- which(upper.tri(cor_errors), arr.ind = TRUE)
  tradeoffs  <- tibble(parameter_1 = rownames(cor_errors)[pair_index[, 1]],
                       parameter_2 = colnames(cor_errors)[pair_index[, 2]],
                       r = cor_errors[pair_index]) |>
    filter(abs(r) >= tradeoff_report_r) |>
    arrange(desc(abs(r)))

  recovery_table <- list(N = N, convergence = convergence, participant = participant,
                         participant_by_family = participant_by_family, population = population,
                         population_by_family = population_by_family, tradeoffs = tradeoffs,
                         n_pairs = nrow(pair_index))
  print(convergence)
  saveRDS(recovery_table, artifact_path("recovery_table", N))
}
