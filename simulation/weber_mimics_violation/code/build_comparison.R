#### LOAD CANDIDATE DATASETS + READ-ONLY weber_violated REFERENCE ####

df_candidates <- candidate_names |>
  map(\(nm) readRDS(file.path(artifacts_dir, paste0(nm, ".rds")))) |>
  list_rbind()

# Read-only reference dataset from the sibling project (never regenerated, never
# copied into this folder's artifacts/), per the ENVIRONMENT contract.
df_violated <- readRDS(weber_violated_path)

df_all <- bind_rows(df_candidates, df_violated) |>
  mutate(
    valence = factor(valence, levels = sort(unique(valence))),
    correct = R == S,
    dataset = factor(dataset, levels = c(candidate_names, "weber_violated"))
  )

# Shared 2+ color mapping (Paul Tol bright, colorblind-safe), one color per candidate
# plus the reference dataset -- reused across both comparison plots.
dataset_colors <- setNames(
  c("#4477AA", "#EE6677", "#228833", "#CCBB44")[seq_along(levels(df_all$dataset))],
  levels(df_all$dataset)
)

#### ACCURACY-BY-VALENCE COMPARISON ####

df_accuracy <- df_all |>
  summarise(accuracy = mean(correct), .by = c(valence, dataset)) |>
  pivot_wider(names_from = dataset, values_from = accuracy) |>
  arrange(valence)

#### RT STATISTICS COMPARISON (pooled across correct/incorrect) ####

# Long form (one row per valence x dataset) kept for the RT half-eye/violin plots,
# which need one row per trial-level summary to facet/dodge by dataset.
df_rt <- df_all |>
  summarise(
    median_rt = median(rt),
    mean_rt   = mean(rt),
    p10_rt    = quantile(rt, 0.10),
    p90_rt    = quantile(rt, 0.90),
    .by = c(valence, dataset)
  ) |>
  arrange(valence, dataset)

# Wide form for the HTML report table: one row per valence, with each dataset's 4
# statistics (median/mean/p10/p90) as its own column group -- mirrors df_accuracy's
# wide-by-dataset layout in Table 1, per researcher request to separate datasets
# into distinct columns rather than stacking them as rows.
# pivot_wider(values_from = <multiple columns>) orders the result statistic-major
# (all datasets' median_rt, then all datasets' mean_rt, ...) rather than
# dataset-major -- select() reorders to dataset-major (each dataset's 4 stats kept
# together) to match the header grouping built in render_comparison_report.R.
df_rt_wide <- df_rt |>
  pivot_wider(
    names_from  = dataset,
    values_from = c(median_rt, mean_rt, p10_rt, p90_rt),
    names_glue  = "{dataset}_{.value}"
  ) |>
  arrange(valence) |>
  select(valence, starts_with(paste0(levels(df_all$dataset), "_")))
