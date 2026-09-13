#### RT DISTRIBUTION BY VALENCE, SPLIT BY ACCURACY (VIOLIN) ####

# Capped at 7s per researcher request (2026-09-13, matching the half-eye version below)
# -- coord_cartesian() zooms the visible window without dropping/altering the
# underlying data fed to geom_violin()/geom_boxplot(). A shared 0-7s window (rather
# than free_y per facet, used in an earlier round) is what was asked for here, trading
# independent per-facet scaling for one consistent, predictable axis across Correct
# and Incorrect.
p_rt_split_violin <- ggplot(df_all, aes(x = valence, y = rt, fill = dataset)) +
  geom_violin(position = position_dodge(width = 0.8), colour = NA, alpha = 0.7) +
  geom_boxplot(position = position_dodge(width = 0.8), width = 0.1, outlier.shape = NA, colour = "black") +
  scale_fill_manual(values = dataset_colors) +
  coord_cartesian(ylim = c(0, 7)) +
  facet_wrap(~correct, ncol = 1) +
  labs(x = "Valence level", y = "Response time (s)", fill = "Dataset") +
  theme_minimal(base_size = 12)

save_plot(p_rt_split_violin, "rt_split_violin")

#### RT DISTRIBUTION BY VALENCE, SPLIT BY ACCURACY (HALF-EYE) ####

# Capped at 7s per researcher request (2026-09-13, tightened from an initial 10s) --
# coord_cartesian() zooms the visible window without dropping/altering the underlying
# data fed to stat_halfeye(), same approach as the pooled plots' rt_zoom_limit. A
# shared 0-7s window (rather than free_y per facet) is what was asked for here,
# trading independent per-facet scaling for one consistent, predictable axis across
# Correct and Incorrect.
p_rt_split_halfeye <- ggplot(df_all, aes(x = valence, y = rt, fill = dataset)) +
  stat_halfeye(
    data = ~ filter(.x, dataset == "weber_holds"),
    side = "left", justification = 1.1, .width = c(0.66, 0.95), point_interval = "median_qi"
  ) +
  stat_halfeye(
    data = ~ filter(.x, dataset == "weber_violated"),
    side = "right", justification = -0.1, .width = c(0.66, 0.95), point_interval = "median_qi"
  ) +
  scale_fill_manual(values = dataset_colors) +
  coord_cartesian(ylim = c(0, 7)) +
  facet_wrap(~correct, ncol = 1) +
  labs(x = "Valence level", y = "Response time (s)", fill = "Dataset") +
  theme_minimal(base_size = 12)

save_plot(p_rt_split_halfeye, "rt_split_halfeye")
