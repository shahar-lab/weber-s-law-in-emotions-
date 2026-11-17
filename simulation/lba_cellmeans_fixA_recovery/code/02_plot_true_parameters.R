#### PLOT TRUE PARAMETERS ####
# reads: artifacts/true_population_N*.rds, true_parameters_N*.rds
# writes: output/02_true_parameters_dots_N*.{pdf,png}
# One dot histogram per fitted-model parameter (true agent values) with the population normal density overlaid.
# The density is rescaled so its peak equals the tallest dot stack (dots are drawn in normalised panel units).

for (N in n_subjects_set) {
  true_population <- readRDS(artifact_path("true_population", N))
  true_fitted     <- map_to_fitted(readRDS(artifact_path("true_parameters", N)))
  fitted_pars     <- names(true_population$fitted$mu)

  dot_plots <- list()
  for (par in fitted_pars) {
    df     <- data.frame(x = true_fitted[[par]])
    mu_par <- true_population$fitted$mu[[par]]
    sd_par <- true_population$fitted$sigma[[par]]

    # x range: the data and the population mean +/- 3 SD, widened 10%; ticks in multiples of 0.05, 5-10 marks
    r          <- range(c(df$x, mu_par + c(-3, 3) * sd_par))
    full_range <- c(r[1] - 0.10 * diff(r), r[2] + 0.10 * diff(r))
    steps      <- c(0.05, 0.10, 0.20, 0.25, 0.50, 1, 2, 5, 10)
    n_ticks    <- diff(full_range) / steps + 1
    hit        <- steps[n_ticks >= 5 & n_ticks <= 10]
    tick_step  <- if (length(hit)) hit[1] else steps[which.min(abs(n_ticks - 7))]
    axis_breaks <- seq(ceiling(full_range[1] / tick_step) * tick_step,
                       floor(full_range[2] / tick_step) * tick_step, by = tick_step)
    axis_breaks <- round(axis_breaks / 0.05) * 0.05
    if (full_range[1] <= 0 && full_range[2] >= 0) axis_breaks <- sort(unique(c(0, axis_breaks)))

    p <- ggplot(df, aes(x = x)) +
      geom_dots(layout = "bin", binwidth = NA, fill = "gray50", colour = "gray30") +
      scale_x_continuous(breaks = axis_breaks) +
      coord_cartesian(xlim = full_range, clip = "off") +
      theme_minimal(base_size = 13) +
      theme(panel.grid.minor = element_blank(), axis.text = element_text(size = 8),
            axis.title = element_text(size = 8)) +
      labs(x = par)

    # Count axis and density overlay, both read from the built dots layer
    built       <- ggplot_build(p)$data[[1]]
    max_count   <- max(table(round(built$x, 8)))   # one row per dot; dots of a stack share x
    curve       <- data.frame(x = seq(full_range[1], full_range[2], length.out = 200))
    curve$y     <- dnorm(curve$x, mu_par, sd_par) / dnorm(mu_par, mu_par, sd_par) * max(built$y)
    dot_plots[[par]] <- p +
      geom_line(data = curve, aes(x = x, y = y), colour = "#EE6677", linewidth = 0.7) +
      scale_y_continuous(name = "Count", breaks = seq(0, max(built$y), length.out = 4),
                         labels = round(seq(0, max_count, length.out = 4)))
  }

  p_final <- wrap_plots(dot_plots, ncol = facet_ncol)
  height  <- 2.5 * ceiling(length(fitted_pars) / facet_ncol)
  ggsave(output_path("02_true_parameters_dots", N, "pdf"), p_final, width = fig_width, height = height, bg = "white")
  ggsave(output_path("02_true_parameters_dots", N, "png"), p_final, width = fig_width, height = height, dpi = 300, bg = "white")
}
