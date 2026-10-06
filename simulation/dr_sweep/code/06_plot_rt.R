#### RT DISTRIBUTION BY VALENCE, FACETED BY DR FACTOR (HALF-EYE) ####

# Zoom to the 99.5th percentile without discarding data
rt_zoom_limit <- quantile(df_all$rt, 0.995)

p_rt <- ggplot(df_all, aes(x = valence, y = rt, fill = scheme)) +
  stat_halfeye(
    position = position_dodge(width = 0.9),
    .width = c(0.66, 0.95), point_interval = "median_qi"
  ) +
  facet_wrap(~ dr_factor, nrow = 1) +
  scale_fill_manual(values = scheme_colors) +
  coord_cartesian(ylim = c(0, rt_zoom_limit)) +
  labs(x = "Valence level", y = "Response time (s)", fill = "Weber's law") +
  theme_minimal(base_size = 12)

ggsave(file.path(output_dir, "06_rt_by_dr.pdf"), plot = p_rt, width = 16, height = 6, bg = "white")
ggsave(file.path(output_dir, "06_rt_by_dr.png"), plot = p_rt, width = 16, height = 6, dpi = 300, bg = "white")
