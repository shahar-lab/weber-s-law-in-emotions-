rm(list = ls())

#### SETUP ####

library(here)
library(tidyverse)
library(EMC2)
library(ggdist)
library(knitr)
library(kableExtra)

project_root  <- here::here()
code_dir      <- file.path(project_root, "simulation", "dr_sweep", "code")
artifacts_dir <- file.path(project_root, "simulation", "dr_sweep", "artifacts")
output_dir    <- file.path(project_root, "simulation", "dr_sweep", "output")

# Pure simulation - no data/ is read here.

#### EXECUTE PIPELINE ####

# 1. Valence levels, base drifts, DR factor grid, fixed LBA parameters
source(file.path(code_dir, "01_define_design.R"))

# 2. Simulate one dataset per (Weber scheme x DR factor)
source(file.path(code_dir, "02_simulate_sweep.R"))

# 3. Accuracy and RT summaries across all datasets
source(file.path(code_dir, "03_build_summaries.R"))

# 4. Static HTML report (accuracy + RT tables)
source(file.path(code_dir, "04_render_report.R"))

# 5. Accuracy by valence, faceted by DR factor
source(file.path(code_dir, "05_plot_accuracy.R"))

# 6. RT distribution by valence, faceted by DR factor
source(file.path(code_dir, "06_plot_rt.R"))

