rm(list = ls())

#### SETUP ####

library(here)
library(tidyverse)
library(EMC2)

# ggdist powers the half-eye RT distribution plots; install once if missing.
if (!requireNamespace("ggdist", quietly = TRUE)) {
  install.packages("ggdist", repos = "https://cloud.r-project.org")
}
library(ggdist)

# here::here() anchors to the .Rproj root regardless of the working directory,
# so paths resolve identically on any machine without setwd() gymnastics.
project_root  <- here::here()
code_dir      <- file.path(project_root, "simulation", "weber_lba_simulation", "code")
artifacts_dir <- file.path(project_root, "simulation", "weber_lba_simulation", "artifacts")
output_dir    <- file.path(project_root, "simulation", "weber_lba_simulation", "output")

# Pure simulation - no data/ is read here, per the Artifacts Rule.



#### EXECUTE PIPELINE ####

# 1. Shared LBA design (valence levels, drift mapping, fixed parameters)
source(file.path(code_dir, "define_design.R"))

# 2. Simulate Dataset A: Weber's law holds (sv scales with mean drift rate)
source(file.path(code_dir, "simulate_weber_holds.R"))

# 3. Simulate Dataset B: Weber's law violated (sv constant across conditions)
source(file.path(code_dir, "simulate_weber_violated.R"))

# 4. Load simulated data, shared color mapping, and export helper for the plot scripts
source(file.path(code_dir, "plot_prep.R"))

# 5. RT distribution by valence, pooled across correct/incorrect (violin + half-eye)
source(file.path(code_dir, "plot_rt_pooled.R"))

# 6. RT distribution by valence, split by correct/incorrect (violin + half-eye)
source(file.path(code_dir, "plot_rt_split.R"))

# 7. Accuracy by valence, holds vs violated
source(file.path(code_dir, "plot_accuracy.R"))
