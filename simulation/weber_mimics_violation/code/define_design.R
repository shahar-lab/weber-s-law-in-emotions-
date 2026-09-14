#### DEFINE VALENCE LEVELS AND DRIFT MAPPING (IDENTICAL TO weber_holds) ####

# Identical extremity-based drift means to weber_lba_simulation's weber_holds dataset,
# per the spec (only v_mismatch is varied here).
valence_levels <- c(2, 3, 4, 6, 7, 8)

design_df <- tibble(
  level     = valence_levels,
  extremity = abs(level - 5),
  mean_v    = case_when(
    level %in% c(2, 8) ~ 1.8,
    level %in% c(4, 6) ~ 0.7,
    level %in% c(3, 7) ~ 1.2
  )
)

# weber_k must NOT change from weber_holds -- sv = weber_k * mean_v stays the literal
# Weber's-law relationship throughout; only v_mismatch is being tuned.
weber_k <- 0.3

design_holds <- design_df |>
  mutate(sv = weber_k * mean_v)

# FIXED, identical to weber_lba_simulation (natural scale; log-transformed below for
# EMC2::LBA, which estimates A, B, t0, sv on the log scale -- see ?EMC2::LBA).
# b updated from 1.5 to 1.7 (2026-09-14) to match weber_lba_simulation's sibling
# project, which raised b from 1.5 to slow RT at extreme valence (after an
# intermediate 2.0 was judged too slow, settling on 1.7 as a gentle nudge).
b_natural  <- 1.7
A_natural  <- 0.5
B_natural  <- b_natural - A_natural
t0_natural <- 0.2

A_fixed  <- log(A_natural)
B_fixed  <- log(B_natural)
t0_fixed <- log(t0_natural)

n_participants <- 70
accumulators   <- c("left", "right")

# ASSUMED[no v_mismatch grid given]: candidate values above weber_lba_simulation's
# current 0.5, spaced by 0.1, stopping short of the near-neutral match drift (0.7) to
# avoid collapsing those levels to chance outright -- chosen to bracket the range where
# weber_violated's ~63-99% accuracy-by-valence pattern (sharp near-neutral dip) might be
# reproducible under the Weber's-law-holds sv scheme.
v_mismatch_grid <- c(0.6, 0.7, 0.8)

# ASSUMED[no naming convention given]: candidate datasets/artifacts are named
# "weber_holds_vmismatch_<value>" (e.g. weber_holds_vmismatch_0.6), read back by value
# from v_mismatch_grid throughout the pipeline.
candidate_names <- paste0("weber_holds_vmismatch_", v_mismatch_grid)

# Target trials per valence condition per participant, identical to weber_lba_simulation.
n_trials_per_condition <- 20
n_trials_per_cell      <- n_trials_per_condition / length(accumulators)
