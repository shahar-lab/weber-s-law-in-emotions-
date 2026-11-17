rm(list = ls())

#### SETUP ####

library(EMC2)
library(here)
library(tidyverse)
library(posterior)
library(ggplot2)
library(ggdist)
library(patchwork)
library(tidybayes)
library(officer)
library(flextable)

# Directories (to clone this study, change fitted_model and folder_name only)
folder_name   <- "lba_cellmeans_fixA_recovery"
project_root  <- here()
code_dir      <- file.path(project_root, "simulation", folder_name, "code")
artifacts_dir <- file.path(project_root, "simulation", folder_name, "artifacts")
output_dir    <- file.path(project_root, "simulation", folder_name, "output")
models_dir    <- file.path(project_root, "models")

# Models
generative_model <- "lba_cellmeans"
fitted_model     <- "lba_cellmeans_fixA"

# The EMC2 file (design, blocks, priors) is sourced before the generating file, for both models
for (model_name in unique(c(generative_model, fitted_model))) {
  source(file.path(models_dir, model_name, paste0(model_name, "_emc2.R")))
  source(file.path(models_dir, model_name, paste0(model_name, ".R")))
}

# Generic interface of the two models (every script uses these names, never a model name)
design_generative <- get(paste0("design_", generative_model))
generate_data     <- get(paste0("generate_", generative_model))
design_fitted     <- get(paste0("design_", fitted_model))
prior_fitted      <- get(paste0("prior_", fitted_model))
par_groups_fitted <- get(paste0("par_groups_", fitted_model))
map_fitted        <- get(paste0("map_generator_to_", fitted_model))
prep_data_fitted  <- if (exists(paste0("prep_data_", fitted_model))) get(paste0("prep_data_", fitted_model)) else identity

# Figure layout shared by every plotting script
fig_width  <- 10   # inches
facet_ncol <- 4    # facet / panel columns

# File names: <stem>_N050.<ext>; artifacts are read back by every script, output files carry the script's NN
artifact_path <- function(stem, N, ext = "rds") file.path(artifacts_dir, sprintf("%s_N%03d.%s", stem, N, ext))
output_path   <- function(stem, N, ext) file.path(output_dir, sprintf("%s_N%03d.%s", stem, N, ext))

# Generating cell-means parameters (data frame, or one named vector) -> data frame of the fitted model's parameters
map_to_fitted <- function(params) {
  mapped <- map_fitted(params)
  as.data.frame(if (is.null(dim(mapped))) t(mapped) else mapped, check.names = FALSE)
}


#### GENERATING TRUE PARAMETERS ####
# No unit-interval transform in this model: v is on the real line; sv, B, A, t0 are drawn on the log scale.

n_subjects_set <- c(50)   # only N = 50 has an existing fit

# Population values on the natural scale; code/01 turns them into mu (estimation scale)
gen <- list(
  v_track           = c(1.5, 2.1, 2.7),  # tracking accumulator, intensity 1..3
  v_other           = 0.8,               # non-tracking accumulator
  sv_other          = 1.0,               # non-tracking accumulator
  sv0_track         = 0.8,               # tracking sv at the lowest intensity
  weber_strength    = 1,                 # log sv_i = log sv0 + weber_strength * log(v_i / v_1)
  B_emo             = 1.5,               # threshold distance, emotional accumulator
  B_neu             = 1.7,               # threshold distance, neutral accumulator
  A                 = 0.4,
  t0                = 0.30,
  sd                = c(v = 0.25, sv = 0.15, B = 0.20, A = 0.25, t0 = 0.15),  # between-participant SD, estimation scale
  within_family_cor = 0.3                # v, sv and B families; no correlation across families
)

# Tracking accumulator: emotional for positive images (valence 6, 7, 8), neutral for negative (4, 3, 2)
pos_vg  <- c("6", "7", "8");  pos_acc <- "emotional"
neg_vg  <- c("4", "3", "2");  neg_acc <- "neutral"

# Seed per N (legacy formula, 'perception' scenario = index 1, replication 1). Needed so that all five
# studies see identical data and reproduce the legacy simulation/emc2_recovery datasets.
base_seed       <- 20261106
scenario_index  <- 1
replicate_index <- 1

source(file.path(code_dir, "01_generate_true_parameters.R"))
source(file.path(code_dir, "02_plot_true_parameters.R"))


#### GENERATING DATA ####

n_trials   <- c("2" = 22, "3" = 24, "4" = 23, "6" = 24, "7" = 23, "8" = 22)   # per valence group
n_sessions <- 1

# Preregistered exclusions (a) rt missing or > max_rt, (b) rt < min_rt, (c) per participant |rt - median| > mad_k scaled MAD
excl <- list(max_rt = 10, min_rt = 0.15, mad_k = 3, mad_constant = 1.4826)

source(file.path(code_dir, "03_generate_data.R"))


#### RECOVERING PARAMETERS ####

n_chains      <- 3
compress_rt   <- FALSE
stop_criteria <- list(sample = list(iter = 1000, max_gd = 1.1, min_es = 200,
                                    selection = c("mu", "alpha"), omit_mpsrf = TRUE))
max_tries     <- 20

# Existing fits of the identical datasets are reused (NULL when the model has none)
legacy_run_dir  <- file.path(project_root, "simulation", "emc2_recovery", "output", "fixA_test")
legacy_fit_name <- "perception_N%03d_r01"

n_draws_pop        <- 2000   # thinned population draws kept
n_draws_sbj        <- 500    # thinned agent-level draws kept
hdi_width          <- 0.90
tradeoff_report_r  <- 0.5    # trade-off pairs with |r| >= this are reported

source(file.path(code_dir, "04_fit_model.R"))
source(file.path(code_dir, "05_extract_draws.R"))
source(file.path(code_dir, "06_summarise_recovery.R"))


#### VISUALIZATION AND OUTPUT ####

height_per_row_density <- 2.2  # Figures 1-2, per facet row
height_per_row_scatter <- 3    # Figure 3, per facet row

source(file.path(code_dir, "07_plot_population_location.R"))
source(file.path(code_dir, "08_plot_population_scale.R"))
source(file.path(code_dir, "09_plot_individual_recovery.R"))
source(file.path(code_dir, "10_plot_diagnostics.R"))
source(file.path(code_dir, "11_compile_recovery_pdf.R"))
source(file.path(code_dir, "12_write_recovery_docx.R"))
