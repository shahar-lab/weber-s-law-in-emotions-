#### RENDER COMPARISON TABLES TO HTML (no pandoc/rmarkdown dependency) ####

accuracy_table_html <- kable(
  df_accuracy, digits = 3, format = "html",
  caption = "Table 1. Proportion correct (R == S) by valence level -- each candidate v_mismatch value (weber_holds sv scheme) vs the reference weber_violated dataset."
)

# Wide layout: one row per valence, each dataset's 4 RT statistics grouped under its
# own header (kableExtra::add_header_above), per researcher request to keep the
# datasets in separate columns rather than stacked rows.
n_datasets <- length(levels(df_all$dataset))
rt_table_html <- kable(
  df_rt_wide, digits = 3, format = "html",
  col.names = c("Valence", rep(c("Median RT (s)", "Mean RT (s)", "10th pct RT (s)", "90th pct RT (s)"), n_datasets)),
  caption = "Table 2. RT statistics (seconds), pooled across correct and incorrect trials -- each candidate v_mismatch value vs the reference weber_violated dataset, in separate column groups."
) |>
  add_header_above(setNames(c(1, rep(4, n_datasets)), c(" ", levels(df_all$dataset))))

report_html <- c(
  "<!DOCTYPE html>",
  "<html>",
  "<head>",
  '<meta charset="utf-8">',
  "<title>Weber-Holds Mimicry of Weber-Violated -- Comparison</title>",
  "<style>",
  "body { font-family: sans-serif; margin: 2em; }",
  "table { border-collapse: collapse; margin-bottom: 2em; }",
  "th, td { border: 1px solid #ccc; padding: 6px 12px; text-align: right; }",
  "th { background-color: #f0f0f0; }",
  "caption { font-weight: bold; text-align: left; margin-bottom: 0.5em; }",
  "</style>",
  "</head>",
  "<body>",
  "<h1>Can a Weber's-Law-Holds LBA Mimic weber_violated via Higher v_mismatch?</h1>",
  "<p>Candidate datasets share weber_holds' sv = weber_k * mean_v scheme (weber_k = 0.3, unchanged); only v_mismatch is raised above the sibling project's current 0.5.</p>",
  as.character(accuracy_table_html),
  as.character(rt_table_html),
  "</body>",
  "</html>"
)

writeLines(report_html, file.path(output_dir, "mimicry_comparison.html"))
