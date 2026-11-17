#### WRITE WORD REPORT ####
# reads: artifacts/recovery_table, exclusion_counts, fig1/fig2/fig3 (_N*.rds), output/07-09 PNG files
# writes: output/12_recovery_report.docx (both N). Reporting only: no verdict is written.

make_ft <- function(df) {
  df |> mutate(across(where(is.numeric), ~ round(.x, 2))) |> flextable() |>
    fontsize(size = 8, part = "all") |> autofit()
}
tables       <- lapply(setNames(n_subjects_set, n_subjects_set), function(N) readRDS(artifact_path("recovery_table", N)))
stop_rule    <- stop_criteria$sample
hdi_percent  <- round(hdi_width * 100)
trial_text   <- paste(names(n_trials), n_trials, sep = ": ", collapse = ", ")
population_table <- data.frame(
  Quantity = c("Tracking drift rate v, intensity 1-3", "Non-tracking drift rate v", "Non-tracking sv", "Tracking sv at intensity 1",
               "Weber strength", "Threshold distance B (emotional, neutral)", "Start-point A", "Non-decision time t0",
               "Between-participant SD (estimation scale)", "Within-family correlation (v, sv, B)"),
  Value = c(paste(gen$v_track, collapse = ", "), gen$v_other, gen$sv_other, gen$sv0_track, gen$weber_strength,
            paste(gen$B_emo, gen$B_neu, sep = ", "), gen$A, gen$t0,
            paste(names(gen$sd), gen$sd, sep = " = ", collapse = "; "), gen$within_family_cor))

doc <- read_docx() |>
  body_add_par(paste("Parameter recovery:", fitted_model, "(EMC2 LBA)"), style = "heading 1") |>
  body_add_par("Design", style = "heading 2") |>
  body_add_par(sprintf(paste("Data were generated from %s and fitted with %s. Sample sizes: N = %s participants, %d session(s);",
                             "trials per valence group %s (%d per participant). No unit-interval transform is used in this model:",
                             "v is on the real line and sv, B, A, t0 are drawn and estimated on the log scale."),
                       generative_model, fitted_model, paste(n_subjects_set, collapse = " and "), n_sessions,
                       trial_text, sum(n_trials)), style = "Normal") |>
  body_add_flextable(make_ft(population_table)) |>
  body_add_par(sprintf(paste("Estimation used EMC2 %s: %d chains, blocked covariance by parameter family, sampling in blocks of %d",
                             "iterations until R-hat < %.1f and ESS > %d for mu and alpha (at most %d blocks). Priors on the population",
                             "means are those defined in models/%s/%s_emc2.R."),
                       as.character(packageVersion("EMC2")), n_chains, stop_rule$iter, stop_rule$max_gd, stop_rule$min_es,
                       max_tries, fitted_model, fitted_model), style = "Normal") |>
  body_add_par("Exclusions", style = "heading 2") |>
  body_add_flextable(make_ft(bind_rows(lapply(n_subjects_set, function(N) readRDS(artifact_path("exclusion_counts", N)))))) |>
  body_add_par("Convergence", style = "heading 2") |>
  body_add_flextable(make_ft(bind_rows(lapply(tables, function(t) t$convergence), .id = "N")))

for (N in n_subjects_set) {
  tbl <- tables[[as.character(N)]]
  captions <- c(
    sprintf("Posterior density of each population location parameter (mu) for N = %d simulated participants. The point and bar mark the posterior median and the %d%% highest-density interval; the blue dotted line marks the true generating value.", N, hdi_percent),
    sprintf("Posterior density of each population scale parameter (sigma) for N = %d simulated participants. The point and bar mark the posterior median and the %d%% highest-density interval; the blue dotted line marks the true generating value.", N, hdi_percent),
    sprintf("True versus recovered parameter values for N = %d simulated participants, one panel per parameter. Each point is one participant (recovered = posterior median); the solid line is the OLS fit, the dashed line is the identity, and r is Pearson's correlation.", N))
  figure_files <- c("07_population_location", "08_population_scale", "09_individual_recovery")
  figure_names <- c("fig1_population_location", "fig2_population_scale", "fig3_individual_recovery")

  doc <- doc |>
    body_add_break() |>
    body_add_par(sprintf("N = %d", N), style = "heading 1") |>
    body_add_par("Participant level, by parameter family (r = Pearson correlation; bias = mean of recovered - true; slope = OLS slope of recovered on true; shrinkage = recovered SD / true SD)", style = "Normal") |>
    body_add_flextable(make_ft(tbl$participant_by_family)) |>
    body_add_par(sprintf("Population level, by family: number of true values inside the %d%% HDI", hdi_percent), style = "Normal") |>
    body_add_flextable(make_ft(tbl$population_by_family)) |>
    body_add_par(sprintf("Trade-offs: parameter pairs whose recovery errors correlate with |r| >= %.1f (%d of %d pairs)", tradeoff_report_r, nrow(tbl$tradeoffs), tbl$n_pairs), style = "Normal") |>
    body_add_flextable(make_ft(tbl$tradeoffs))

  for (i in 1:3) {
    height_in <- attr(readRDS(artifact_path(figure_names[i], N)), "height_in")
    shrink    <- min(6.5 / fig_width, 8.5 / height_in)
    doc <- doc |>
      body_add_break() |>
      body_add_img(output_path(figure_files[i], N, "png"), width = fig_width * shrink, height = height_in * shrink) |>
      body_add_fpar(fpar(ftext(sprintf("Figure %d.", i), fp_text(italic = TRUE)), ftext(paste0(" ", captions[i]))))
  }
}
print(doc, target = file.path(output_dir, "12_recovery_report.docx"))
