#### ACCURACY BY VALENCE ####

df_accuracy <- df_all |>
  summarise(accuracy = mean(correct == "Correct"), .by = c(dataset, valence))

p_accuracy <- ggplot(df_accuracy, aes(x = valence, y = accuracy, colour = dataset, group = dataset)) +
  geom_line(linewidth = 0.8) +
  geom_point(size = 2.5) +
  scale_colour_manual(values = dataset_colors) +
  labs(x = "Valence level", y = "Proportion correct", colour = "Dataset") +
  theme_minimal(base_size = 12)

save_plot(p_accuracy, "accuracy_by_valence")
