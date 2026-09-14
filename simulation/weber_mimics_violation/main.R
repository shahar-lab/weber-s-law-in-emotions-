rm(list = ls())

#### SETUP ####

library(here)
library(tidyverse)
library(EMC2)

if (!requireNamespace("ggdist", quietly = TRUE)) {
  install.packages("ggdist", repos = "https://cloud.r-project.org")
}
library(ggdist)

# knitr::kable() renders the static HTML comparison report's tables directly (no
# rmarkdown/pandoc dependency); install once if missing.
if (!requireNamespace("knitr", quietly = TRUE)) {
  install.packages("knitr", repos = "https://cloud.r-project.org")
}
library(knitr)

# kableExtra::add_header_above() groups Table 2's per-dataset RT columns under a
# shared header, so each candidate's median/mean/p10/p90 stay visually separated
# (researcher request); install once if missing.
if (!requireNamespace("kableExtra", quietly = TRUE)) {
  install.packages("kableExtra", repos = "https://cloud.r-project.org")
}
library(kableExtra)

# here::here() anchors to the .Rproj root regardless of the working directory,
# so paths resolve identically on any machine without setwd() gymnastics.
project_root  <- here::here()
code_dir      <- file.path(project_root, "simulation", "weber_mimics_violation", "code")
artifacts_dir <- file.path(project_root, "simulation", "weber_mimics_violation", "artifacts")
output_dir    <- file.path(project_root, "simulation", "weber_mimics_violation", "output")

# Read-only reference dataset from the sibling project, per the Artifacts Rule --
# never copied into this folder's own artifacts/, read directly each run.
weber_violated_path <- file.path(project_root, "simulation", "weber_lba_simulation", "artifacts", "weber_violated.rds")

# Pure simulation - no data/ is read here, per the Artifacts Rule.



#### EXECUTE PIPELINE ####

# 1. Shared LBA design (valence levels, drift mapping, fixed parameters, v_mismatch grid)
source(file.path(code_dir, "define_design.R"))

# 2. Simulate one weber_holds-style dataset per candidate v_mismatch value
source(file.path(code_dir, "simulate_candidates.R"))

# 3. Load candidate datasets + read-only weber_violated reference, build comparison tables
source(file.path(code_dir, "build_comparison.R"))

# 4. Static HTML report (accuracy + RT comparison tables, candidates vs weber_violated)
source(file.path(code_dir, "render_comparison_report.R"))

# 5. Optional RT distribution comparison plot (nice-to-have)
source(file.path(code_dir, "plot_rt_comparison.R"))

# 6. Accuracy-by-valence comparison plot (candidates vs weber_violated)
source(file.path(code_dir, "plot_accuracy_comparison.R"))
