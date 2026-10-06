#### BUILD ACCURACY AND RT SUMMARIES ####

df_all <- df_grid$dataset |>
  map(\(nm) readRDS(file.path(artifacts_dir, paste0(nm, ".rds")))) |>
  list_rbind() |>
  mutate(
    valence   = factor(valence, levels = sort(unique(valence))),
    correct   = R == S,
    scheme    = factor(scheme, levels = c("holds", "violated")),
    dr_factor = factor(dr_factor, levels = dr_factors, labels = paste0("DR x", dr_factors))
  )

df_accuracy <- df_all |>
  summarise(accuracy = mean(correct), .by = c(dr_factor, scheme, valence)) |>
  arrange(dr_factor, scheme, valence)

df_rt <- df_all |>
  summarise(
    median_rt = median(rt),
    mean_rt   = mean(rt),
    p10_rt    = quantile(rt, 0.10),
    p90_rt    = quantile(rt, 0.90),
    .by = c(dr_factor, scheme, valence)
  ) |>
  arrange(dr_factor, scheme, valence)

# Wide: one row per valence, one column group per dataset (factor x scheme)
dataset_labels <- df_grid |>
  mutate(label = paste0("DR x", dr_factor, " ", scheme)) |>
  pull(label)

df_accuracy_wide <- df_accuracy |>
  unite("dataset", dr_factor, scheme, sep = " ") |>
  pivot_wider(names_from = dataset, values_from = accuracy) |>
  select(valence, all_of(dataset_labels))

df_rt_wide <- df_rt |>
  unite("dataset", dr_factor, scheme, sep = " ") |>
  pivot_wider(
    names_from = dataset, values_from = c(median_rt, mean_rt, p10_rt, p90_rt),
    names_glue = "{dataset}_{.value}"
  ) |>
  select(valence, all_of(paste0(rep(dataset_labels, each = 4), "_", c("median_rt", "mean_rt", "p10_rt", "p90_rt"))))

# Colours for the two Weber schemes (Paul Tol bright, colorblind-safe)
scheme_colors <- c(holds = "#4477AA", violated = "#EE6677")

saveRDS(df_all, file.path(artifacts_dir, "df_all.rds"))
