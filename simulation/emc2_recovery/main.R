#### main.R -- run the whole recovery pipeline for one tier ####
# Run from simulation/emc2_recovery/ :
#   Rscript main.R pilot            # 1 dataset, 20 participants, short chains (pipeline test)
#   Rscript main.R tier1 [workers]  # N = 100, 20 reps x {perception, action}
#   Rscript main.R tier2 | tier3    # other sample sizes / half-size Weber effect
# Every stage skips work that is already on disk, so an interrupted run can simply be restarted.
args <- commandArgs(TRUE)
tier_name <- if (length(args) >= 1) args[1] else "pilot"
workers   <- if (length(args) >= 2) as.integer(args[2]) else NULL

source("01_config.R")
source("02_simulate.R")   # defines simulate_dataset(); its command-line block is skipped when sourced
source("03_fit.R")        # defines fit_one(), run_fits()
source("04_evaluate.R")   # defines evaluate_tier()

tier <- get_tier(tier_name)

# 1. simulate (+ preregistered exclusions)
for (i in seq_len(nrow(tier$jobs))) {
  j <- tier$jobs[i, ]; f <- file.path(tier$out, "data", paste0(j$id, ".rds"))
  if (!file.exists(f)) { simulate_dataset(j$scenario, j$N, j$rep, f); cat("simulated", j$id, "\n") }
}
# 2. fit (parallel across datasets, resumable)
run_fits(tier_name, workers)
# 3. evaluate
evaluate_tier(tier_name)
