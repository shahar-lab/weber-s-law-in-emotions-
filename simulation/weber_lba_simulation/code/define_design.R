#### DEFINE VALENCE LEVELS AND DRIFT MAPPING ####

# Monotonic-in-extremity drift means. Lowered from the initial 3.0/1.25/2.1 (researcher
# confirmed 2026-09-13) because accuracy was too close to ceiling (~94-100%) across all
# valence levels with the original values; scaled down proportionally (~40% reduction)
# to bring accuracy into a more realistic range while preserving the extremity
# ordering and relative spacing between levels.
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

# ASSUMED[no coefficient given for Dataset A]: k = 0.3 sets sv proportional to
# mean drift rate (constant coefficient of variation) for the Weber-holds dataset.
weber_k <- 0.3

# ASSUMED[no constant sv given for Dataset B]: fixed at the mid-range sv implied
# by weber_k applied to the grand mean drift rate, so the two datasets are
# comparable in overall noise level.
sv_constant <- weber_k * mean(design_df$mean_v)

# FIXED across both datasets and all conditions, expressed on the natural scale.
# ASSUMED[no values given]: reasonable single LBA parameter values (b = A + B is the
# natural-scale response threshold; t0 in seconds).
b_natural  <- 1.5
A_natural  <- 0.5
B_natural  <- b_natural - A_natural
t0_natural <- 0.2

# EMC2's LBA estimates A, B, t0, sv on the LOG scale (see ?EMC2::LBA -- "Transform"
# column), and parameterizes the threshold as b = B + A rather than b directly. The
# natural-scale values above are converted here so make_data() receives what EMC2
# actually expects; only v is passed on its natural (real-line) scale.
A_fixed  <- log(A_natural)
B_fixed  <- log(B_natural)
t0_fixed <- log(t0_natural)

n_participants <- 70

# ASSUMED[EMC2 standard]: 2-accumulator (binary choice) LBA, as implied by a
# valence-judgment task with no explicit response-option count in the spec.
accumulators <- c("left", "right")

# ASSUMED[no mismatch-drift value given]: incorrect accumulator's v, shared across all
# valence levels and both datasets. History: -1 (below-baseline) kept accuracy pinned
# near ceiling (~96-100%) regardless of drift magnitude; raised to 0 (researcher
# feedback 2026-09-13) still left accuracy too high (~85-100%); raised to 0.4 still
# too high (~68-100%); raised to 0.5 (2026-09-14) brought accuracy down further
# (~63-99%); reverted to 0.4 (2026-09-14) at researcher request; then raised back to
# 0.5 (2026-09-14) -- current value.
v_mismatch <- 0.5

# Target trials per valence condition per participant, per the spec.
n_trials_per_condition <- 20

# n_trials passed to make_data() is per (valence x S) cell -- S (correct-response
# identity) is fully crossed with valence in the design, so this is divided by the
# number of S levels to realize the target count once S's levels are multiplied back
# in (n_trials_per_cell x length(accumulators) = n_trials_per_condition), rather than
# double-counting to 2x the target.
n_trials_per_cell <- n_trials_per_condition / length(accumulators)
