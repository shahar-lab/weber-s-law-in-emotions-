#### RENDER TABLES TO HTML ####

accuracy_table_html <- kable(
  df_accuracy_wide, digits = 3, format = "html",
  caption = "Table 1. Proportion correct by valence level, per DR factor and Weber scheme."
)

rt_table_html <- kable(
  df_rt_wide, digits = 3, format = "html",
  col.names = c("Valence", rep(c("Median", "Mean", "P10", "P90"), length(dataset_labels))),
  caption = "Table 2. RT statistics (seconds), pooled across correct and incorrect trials."
) |>
  add_header_above(setNames(c(1, rep(4, length(dataset_labels))), c(" ", dataset_labels)))

report_html <- c(
  "<!DOCTYPE html>", "<html>", "<head>", '<meta charset="utf-8">',
  "<title>DR Sweep: Weber Holds vs Violated</title>",
  "<style>",
  "body { font-family: sans-serif; margin: 2em; }",
  "table { border-collapse: collapse; margin-bottom: 2em; }",
  "th, td { border: 1px solid #ccc; padding: 6px 12px; text-align: right; }",
  "th { background-color: #f0f0f0; }",
  "caption { font-weight: bold; text-align: left; margin-bottom: 0.5em; }",
  "</style>", "</head>", "<body>",
  "<h1>Scaling Match Drift Rates Under Weber Holds vs Violated</h1>",
  "<p>Match drifts (1.8 / 1.2 / 0.7) are multiplied by the DR factor; mismatch drift 0.5, b = 1.7, A = 0.5, t0 = 0.2. Holds: sv = 0.3 v. Violated: constant sv = 0.3 x mean scaled v.</p>",
  as.character(accuracy_table_html),
  as.character(rt_table_html),
  "</body>", "</html>"
)

writeLines(report_html, file.path(output_dir, "04_dr_sweep_tables.html"))
