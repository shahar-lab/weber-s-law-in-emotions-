#### ACCURACY BY VALENCE, FACETED BY DR FACTOR ####

p_accuracy <- df_accuracy |>
  ggplot(aes(x = valence, y = accuracy, colour = scheme, group = scheme)) +
  geom_line(linewidth = 0.8) +
  geom_point(size = 2.5) +
  facet_wrap(~ dr_factor, nrow = 1) +
  scale_colour_manual(values = scheme_colors) +
  labs(x = "Valence level", y = "Proportion correct", colour = "Weber's law") +
  theme_minimal(base_size = 12)

ggsave(file.path(output_dir, "05_accuracy_by_dr.pdf"), plot = p_accuracy, width = 14, height = 5, bg = "white")
ggsave(file.path(output_dir, "05_accuracy_by_dr.png"), plot = p_accuracy, width = 14, height = 5, dpi = 300, bg = "white")
