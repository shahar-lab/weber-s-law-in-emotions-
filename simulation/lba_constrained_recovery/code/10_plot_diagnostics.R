#### DIAGNOSTIC FIGURES ####
# reads: artifacts/chains_mu, chains_stage, draws_pop, true_population (_N*.rds)
# writes: artifacts/diag_trace_N*.rds, diag_correlation_N*.rds, output/10_trace_N*.{pdf,png}, 10_correlation_N*.{pdf,png}
# Trace of every mu per chain (sampling stage), and the posterior correlation of the mu draws.

for (N in n_subjects_set) {
  true_population <- readRDS(artifact_path("true_population", N))
  chains_mu       <- readRDS(artifact_path("chains_mu", N))
  chains_stage    <- readRDS(artifact_path("chains_stage", N))
  fitted_pars     <- names(true_population$fitted$mu)

  # Trace: one line per chain, dashed line at the true value
  trace_df <- do.call(rbind, lapply(seq_along(chains_mu), function(chain) {
    draws_chain <- chains_mu[[chain]]
    keep        <- if (is.null(chains_stage[[chain]])) rep(TRUE, ncol(draws_chain)) else chains_stage[[chain]] == "sample"
    draws_chain <- draws_chain[fitted_pars, keep, drop = FALSE]
    data.frame(chain = factor(chain), parameter = rep(fitted_pars, times = ncol(draws_chain)),
               iteration = rep(seq_len(ncol(draws_chain)), each = nrow(draws_chain)), value = as.vector(draws_chain))
  }))
  trace_df$parameter <- factor(trace_df$parameter, levels = fitted_pars)
  truth <- tibble(parameter = factor(fitted_pars, levels = fitted_pars), true_value = unname(true_population$fitted$mu))

  trace_plot <- ggplot(trace_df, aes(x = iteration, y = value, colour = chain)) +
    geom_line(linewidth = 0.25, alpha = 0.8) +
    geom_hline(data = truth, aes(yintercept = true_value), linetype = "dashed", colour = "grey20", inherit.aes = FALSE) +
    facet_wrap(~ parameter, scales = "free_y", ncol = facet_ncol) +
    scale_colour_manual(values = c("#4477AA", "#EE6677", "#228833")) +
    theme_minimal(base_size = 13) +
    theme(panel.grid.minor = element_blank(), strip.text = element_text(size = 8), axis.text = element_text(size = 8),
          legend.position = "bottom") +
    labs(x = "Sampling iteration", y = "mu", colour = "Chain")
  attr(trace_plot, "height_in") <- height_per_row_density * ceiling(length(fitted_pars) / facet_ncol)

  # Posterior correlation of the mu draws
  mu_wide <- readRDS(artifact_path("draws_pop", N)) |>
    filter(type == "mu") |>
    select(.draw, parameter, value) |>
    pivot_wider(names_from = parameter, values_from = value) |>
    select(-.draw)
  correlation <- as.data.frame(as.table(cor(mu_wide[, fitted_pars]))) |>
    rename(parameter_x = Var1, parameter_y = Var2, r = Freq)

  correlation_plot <- ggplot(correlation, aes(x = parameter_x, y = parameter_y, fill = r)) +
    geom_tile() +
    scale_fill_viridis_c(option = "mako", limits = c(-1, 1)) +
    scale_y_discrete(limits = rev) +
    coord_fixed() +
    theme_minimal(base_size = 13) +
    theme(axis.text.x = element_text(angle = 90, hjust = 1, size = 7), axis.text.y = element_text(size = 7)) +
    labs(x = NULL, y = NULL, fill = "Posterior\ncorrelation")
  attr(correlation_plot, "height_in") <- 8

  for (item in list(list(plot = trace_plot, stem = "trace"), list(plot = correlation_plot, stem = "correlation"))) {
    saveRDS(item$plot, artifact_path(paste0("diag_", item$stem), N))
    height_in <- attr(item$plot, "height_in")
    ggsave(output_path(paste0("10_", item$stem), N, "pdf"), item$plot, width = fig_width, height = height_in, bg = "white")
    ggsave(output_path(paste0("10_", item$stem), N, "png"), item$plot, width = fig_width, height = height_in, dpi = 300, bg = "white")
  }
}
