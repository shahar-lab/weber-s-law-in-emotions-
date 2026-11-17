#### COMPILE RECOVERY PDF ####
# reads: artifacts/fig1_population_location, fig2_population_scale, fig3_individual_recovery, diag_trace, diag_correlation (_N*.rds)
# writes: output/11_recovery_figures_N*.pdf (multi-page vector PDF, one figure per page)
# Page size = 10 in wide and as tall as the tallest figure, so no figure is squeezed.

for (N in n_subjects_set) {
  figures <- list(readRDS(artifact_path("fig1_population_location", N)),
                  readRDS(artifact_path("fig2_population_scale", N)),
                  readRDS(artifact_path("fig3_individual_recovery", N)),
                  readRDS(artifact_path("diag_trace", N)),
                  readRDS(artifact_path("diag_correlation", N)))
  page_height <- max(vapply(figures, function(figure) attr(figure, "height_in"), numeric(1)))

  pdf(output_path("11_recovery_figures", N, "pdf"), onefile = TRUE, width = fig_width, height = page_height)
  for (figure in figures) print(figure)
  dev.off()
}
