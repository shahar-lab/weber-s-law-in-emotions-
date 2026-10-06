#### DEFINE VALENCE LEVELS, BASE DRIFTS AND DR FACTOR GRID ####

valence_levels <- c(2, 3, 4, 6, 7, 8)

# Base match drifts, identical to weber_lba_simulation
design_base <- tibble(
  level  = valence_levels,
  mean_v = case_when(
    level %in% c(2, 8) ~ 1.8,
    level %in% c(4, 6) ~ 0.7,
    level %in% c(3, 7) ~ 1.2
  )
)

# Researcher-confirmed grid: match drifts are multiplied by these factors;
# x1 reproduces the current weber_lba_simulation.
dr_factors <- c(1, 1.5, 2, 3)
weber_k    <- 0.3

# Fixed across all datasets (natural scale; EMC2::LBA takes A, B, t0, sv on the log scale)
v_mismatch <- 0.5
b_natural  <- 1.7
A_natural  <- 0.5
B_natural  <- b_natural - A_natural
t0_natural <- 0.2

A_fixed  <- log(A_natural)
B_fixed  <- log(B_natural)
t0_fixed <- log(t0_natural)

n_participants         <- 70
accumulators           <- c("left", "right")
n_trials_per_condition <- 20
n_trials_per_cell      <- n_trials_per_condition / length(accumulators)

# One row per dataset to simulate
df_grid <- expand_grid(scheme = c("holds", "violated"), dr_factor = dr_factors) |>
  mutate(dataset = paste0("weber_", scheme, "_x", dr_factor))
