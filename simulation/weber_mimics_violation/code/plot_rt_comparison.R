#### RT DISTRIBUTION COMPARISON, POOLED ACROSS ACCURACY (HALF-EYE) ####

# dataset_colors is defined in build_comparison.R (shared across both comparison plots).

# Zoom to the 99.5th percentile without discarding data, same convention as
# weber_lba_simulation's pooled RT plots.
rt_zoom_limit <- quantile(df_all$rt, 0.995)

# 4 datasets (3 candidates + weber_violated reference) dodged side-by-side per valence
# level via position_dodge on a single stat_halfeye() layer (unlike the sibling
# project's 2-dataset half-eye plots, which use two separate side="left"/"right"
# layers -- with 4 groups, dodging one layer keeps this from needing 4 manually
# offset layers).
p_rt_comparison <- ggplot(df_all, aes(x = valence, y = rt, fill = dataset)) +
  stat_halfeye(
    position = position_dodge(width = 0.9),
    .width = c(0.66, 0.95), point_interval = "median_qi"
  ) +
  scale_fill_manual(values = dataset_colors) +
  coord_cartesian(ylim = c(0, rt_zoom_limit)) +
  labs(x = "Valence level", y = "Response time (s)", fill = "Dataset") +
  theme_minimal(base_size = 12)

ggsave(file.path(output_dir, "rt_comparison_halfeye.pdf"), plot = p_rt_comparison, width = 10, height = 8, bg = "white")
ggsave(file.path(output_dir, "rt_comparison_halfeye.png"), plot = p_rt_comparison, width = 10, height = 8, dpi = 300, bg = "white")
