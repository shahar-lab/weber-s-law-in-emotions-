#### ACCURACY-BY-VALENCE COMPARISON (LINE + POINT) ####

# Reuses df_accuracy (built once in build_comparison.R) rather than re-deriving the
# same mean(correct) summary from df_all -- pivoted back to long form since ggplot
# needs one row per (valence, dataset) to map colour = dataset.
p_accuracy_comparison <- df_accuracy |>
  pivot_longer(-valence, names_to = "dataset", values_to = "accuracy") |>
  mutate(dataset = factor(dataset, levels = levels(df_all$dataset))) |>
  ggplot(aes(x = valence, y = accuracy, colour = dataset, group = dataset)) +
  geom_line(linewidth = 0.8) +
  geom_point(size = 2.5) +
  scale_colour_manual(values = dataset_colors) +
  labs(x = "Valence level", y = "Proportion correct", colour = "Dataset") +
  theme_minimal(base_size = 12)

ggsave(file.path(output_dir, "accuracy_comparison.pdf"), plot = p_accuracy_comparison, width = 10, height = 8, bg = "white")
ggsave(file.path(output_dir, "accuracy_comparison.png"), plot = p_accuracy_comparison, width = 10, height = 8, dpi = 300, bg = "white")
