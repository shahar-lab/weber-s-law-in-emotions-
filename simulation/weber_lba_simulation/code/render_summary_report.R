#### BUILD SUMMARY REPORT DATA ####

df_holds    <- readRDS(file.path(artifacts_dir, "weber_holds.rds"))
df_violated <- readRDS(file.path(artifacts_dir, "weber_violated.rds"))

df_all <- bind_rows(df_holds, df_violated) |>
  mutate(
    valence = factor(valence, levels = sort(unique(valence))),
    correct = R == S
  )

df_accuracy <- df_all |>
  summarise(accuracy = mean(correct), .by = c(valence, dataset)) |>
  pivot_wider(names_from = dataset, values_from = accuracy) |>
  arrange(valence)

df_rt <- df_all |>
  summarise(
    median_rt = median(rt),
    mean_rt   = mean(rt),
    p10_rt    = quantile(rt, 0.10),
    p90_rt    = quantile(rt, 0.90),
    .by = c(valence, dataset)
  ) |>
  arrange(valence, dataset)

#### RENDER TABLES TO HTML (no pandoc/rmarkdown dependency) ####

accuracy_table_html <- kable(
  df_accuracy, digits = 3, format = "html",
  caption = "Table 1. Proportion correct (R == S) by valence level and dataset."
)

rt_table_html <- kable(
  df_rt, digits = 3, format = "html",
  col.names = c("Valence", "Dataset", "Median RT (s)", "Mean RT (s)", "10th pct RT (s)", "90th pct RT (s)"),
  caption = "Table 2. RT statistics (seconds), pooled across correct and incorrect trials, by valence level and dataset."
)

report_html <- c(
  "<!DOCTYPE html>",
  "<html>",
  "<head>",
  '<meta charset="utf-8">',
  "<title>Weber's Law LBA Simulation -- Summary Statistics</title>",
  "<style>",
  "body { font-family: sans-serif; margin: 2em; }",
  "table { border-collapse: collapse; margin-bottom: 2em; }",
  "th, td { border: 1px solid #ccc; padding: 6px 12px; text-align: right; }",
  "th { background-color: #f0f0f0; }",
  "caption { font-weight: bold; text-align: left; margin-bottom: 0.5em; }",
  "</style>",
  "</head>",
  "<body>",
  "<h1>Weber's Law LBA Simulation -- Summary Statistics</h1>",
  as.character(accuracy_table_html),
  as.character(rt_table_html),
  "</body>",
  "</html>"
)

writeLines(report_html, file.path(output_dir, "summary_report.html"))
