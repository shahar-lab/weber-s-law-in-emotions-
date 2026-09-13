#### RT DISTRIBUTION BY VALENCE, POOLED ACROSS ACCURACY (VIOLIN) ####

p_rt_pooled_violin <- ggplot(df_all, aes(x = valence, y = rt, fill = dataset)) +
  geom_violin(position = position_dodge(width = 0.8), colour = NA, alpha = 0.7) +
  geom_boxplot(position = position_dodge(width = 0.8), width = 0.1, outlier.shape = NA, colour = "black") +
  scale_fill_manual(values = dataset_colors) +
  coord_cartesian(ylim = c(0, rt_zoom_limit)) +
  labs(x = "Valence level", y = "Response time (s)", fill = "Dataset") +
  theme_minimal(base_size = 12)

save_plot(p_rt_pooled_violin, "rt_pooled_violin")

#### RT DISTRIBUTION BY VALENCE, POOLED ACROSS ACCURACY (HALF-EYE) ####

# side/justification dodge the two datasets' half-eyes so they don't overlap at each
# valence level: weber_holds slabs open leftward (side = "left"), weber_violated open
# rightward (side = "right"), each nudged away from the shared x position.
p_rt_pooled_halfeye <- ggplot(df_all, aes(x = valence, y = rt, fill = dataset)) +
  stat_halfeye(
    data = ~ filter(.x, dataset == "weber_holds"),
    side = "left", justification = 1.1, .width = c(0.66, 0.95), point_interval = "median_qi"
  ) +
  stat_halfeye(
    data = ~ filter(.x, dataset == "weber_violated"),
    side = "right", justification = -0.1, .width = c(0.66, 0.95), point_interval = "median_qi"
  ) +
  scale_fill_manual(values = dataset_colors) +
  coord_cartesian(ylim = c(0, rt_zoom_limit)) +
  labs(x = "Valence level", y = "Response time (s)", fill = "Dataset") +
  theme_minimal(base_size = 12)

save_plot(p_rt_pooled_halfeye, "rt_pooled_halfeye")
