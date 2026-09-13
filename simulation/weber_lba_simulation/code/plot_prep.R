#### LOAD SIMULATED DATASETS ####

df_holds    <- readRDS(file.path(artifacts_dir, "weber_holds.rds"))
df_violated <- readRDS(file.path(artifacts_dir, "weber_violated.rds"))

df_all <- bind_rows(df_holds, df_violated) |>
  mutate(
    valence = factor(valence, levels = sort(unique(valence))),
    correct = if_else(R == S, "Correct", "Incorrect")
  )

# Shared 2-color mapping (Paul Tol bright, colorblind-safe), reused across all plots.
dataset_colors <- c(weber_holds = "#4477AA", weber_violated = "#EE6677")

# Pooled RT (correct+incorrect) legitimately includes the same rare long-RT incorrect
# trials as the split plots' "Incorrect" facet, which stretches the auto-computed
# y-axis and compresses the bulk of the distribution near zero. coord_cartesian()
# zooms to the 99.5th percentile without dropping/altering the underlying data (unlike
# xlim()/ylim(), which would discard rows before the violin/boxplot are computed) --
# the same pooled data still feeds the plot, only the visible window changes.
rt_zoom_limit <- quantile(df_all$rt, 0.995)

#### EXPORT HELPER ####

save_plot <- function(plot, plot_name) {
  ggsave(file.path(output_dir, paste0(plot_name, ".pdf")), plot = plot, width = 10, height = 8, bg = "white")
  ggsave(file.path(output_dir, paste0(plot_name, ".png")), plot = plot, width = 10, height = 8, dpi = 300, bg = "white")
}
