#### FIGURE 3: INDIVIDUAL RECOVERY ####
# reads: artifacts/recovered_parameters_N*.rds
# writes: artifacts/fig3_individual_recovery_N*.rds, output/09_individual_recovery_N*.{pdf,png}
# True vs recovered posterior median, one panel per estimated parameter, each with its own same-range axes.

for (N in n_subjects_set) {
  df <- readRDS(artifact_path("recovered_parameters", N)) |>
    filter(complete.cases(true, recovered)) |>
    mutate(parameter = factor(parameter, levels = unique(parameter)))

  # Per-panel limits: a blank layer carrying both ends of the range on x and y
  panel_limits <- df |>
    group_by(parameter) |>
    summarise(lower = min(true, recovered), upper = max(true, recovered), .groups = "drop") |>
    pivot_longer(c(lower, upper), values_to = "limit")
  panel_correlation <- df |>
    group_by(parameter) |>
    summarise(r = cor(true, recovered), .groups = "drop") |>
    mutate(label = sprintf("[Pearson r = %.2f]", r))

  p <- ggplot(df, aes(x = true, y = recovered)) +
    geom_blank(data = panel_limits, aes(x = limit, y = limit)) +
    geom_point(colour = "#4477AA", alpha = 0.75, size = 2) +
    geom_smooth(method = "lm", formula = y ~ x, se = FALSE, colour = "#EE6677", linewidth = 0.8) +
    geom_abline(slope = 1, intercept = 0, linetype = "dashed", colour = "grey60", linewidth = 0.6) +
    geom_text(data = panel_correlation, aes(label = label), x = Inf, y = Inf, hjust = 1.05, vjust = 1.4,
              size = 3, colour = "grey30", inherit.aes = FALSE) +
    facet_wrap(~ parameter, scales = "free", ncol = facet_ncol) +
    scale_x_continuous(n.breaks = 4) +
    scale_y_continuous(n.breaks = 4) +
    theme_minimal(base_size = 13) +
    theme(panel.grid.minor = element_blank(), aspect.ratio = 1, strip.text = element_text(size = 8),
          axis.text = element_text(size = 8)) +
    labs(x = "True parameter value", y = "Recovered parameter value (posterior median)")

  height_in <- height_per_row_scatter * ceiling(nlevels(df$parameter) / facet_ncol)
  attr(p, "height_in") <- height_in
  saveRDS(p, artifact_path("fig3_individual_recovery", N))
  ggsave(output_path("09_individual_recovery", N, "pdf"), p, width = fig_width, height = height_in, bg = "white")
  ggsave(output_path("09_individual_recovery", N, "png"), p, width = fig_width, height = height_in, dpi = 300, bg = "white")
}
