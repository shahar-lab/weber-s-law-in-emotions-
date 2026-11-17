#### FIGURE 1: POPULATION LOCATION ####
# reads: artifacts/draws_pop_N*.rds, true_population_N*.rds
# writes: artifacts/fig1_population_location_N*.rds, output/07_population_location_N*.{pdf,png}
# Posterior density of every population location mu, with the true value as a dotted blue line.

for (N in n_subjects_set) {
  true_population <- readRDS(artifact_path("true_population", N))
  fitted_pars     <- names(true_population$fitted$mu)
  strip_labels    <- paste0('mu["', fitted_pars, '"]')

  draws <- readRDS(artifact_path("draws_pop", N)) |>
    filter(type == "mu") |>
    mutate(label = factor(paste0('mu["', parameter, '"]'), levels = strip_labels))
  truth <- tibble(label = factor(strip_labels, levels = strip_labels),
                  true_value = unname(true_population$fitted$mu))

  p <- ggplot(draws, aes(x = value, y = 0)) +
    stat_slab(fill = "gray80") +
    stat_pointinterval(.width = hdi_width, point_interval = median_hdci, point_size = 2.5) +
    geom_vline(data = truth, aes(xintercept = true_value), linetype = "dotted", colour = "blue", linewidth = 0.8) +
    geom_blank(data = truth, aes(x = true_value, y = 0)) +   # keeps the true value inside every panel's x range
    facet_wrap(~ label, scales = "free_x", ncol = facet_ncol, labeller = label_parsed) +
    coord_cartesian(ylim = c(0, 1.3), clip = "off") +
    theme_minimal(base_size = 13) +
    theme(panel.grid = element_blank(), axis.title.y = element_blank(), axis.text.y = element_blank(),
          axis.ticks.y = element_blank(), axis.line.y = element_blank(),
          axis.line.x = element_line(colour = "grey30"), axis.text.x = element_text(size = 8)) +
    labs(x = "Posterior value")

  height_in <- height_per_row_density * ceiling(length(fitted_pars) / facet_ncol)
  attr(p, "height_in") <- height_in
  saveRDS(p, artifact_path("fig1_population_location", N))
  ggsave(output_path("07_population_location", N, "pdf"), p, width = fig_width, height = height_in, bg = "white")
  ggsave(output_path("07_population_location", N, "png"), p, width = fig_width, height = height_in, dpi = 300, bg = "white")
}
