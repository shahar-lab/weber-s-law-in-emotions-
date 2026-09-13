#### DATASET B: WEBER'S LAW VIOLATED (sv CONSTANT ACROSS CONDITIONS) ####

# sv fixed at the same absolute value in every condition, regardless of mean drift.
design_violated <- design_df |>
  mutate(sv = sv_constant)

# S must share Rlevels' level set (correct-response identity, per EMC2's race-model
# convention). Valence level is a *separate* factor ("valence") entered into the
# formula alongside lM. `0 + valence:lM` gives one v parameter per (valence level x
# match) cell (EMC2's no-intercept idiom); sv stays `~ 1` (single constant parameter,
# no valence dependence) so noise does not scale with drift magnitude, per the spec.
# S is fully crossed with valence in this design (as `factors` requires), so
# make_data() below is given n_trials_per_cell (not n_trials_per_condition) to realize
# the spec's target 20 trials/condition/participant once S's 2 levels are multiplied
# back in, rather than doubling to 40/condition/participant.
emc_design_violated <- EMC2::design(
  factors     = list(subjects = 1:n_participants, valence = valence_levels, S = accumulators),
  Rlevels     = accumulators,
  matchfun    = function(d) d$S == d$lR,
  formula     = list(v ~ 0 + valence:lM, sv ~ 1, B ~ 1, A ~ 1, t0 ~ 1),
  model       = EMC2::LBA
)

# Parameter names read off the live design object (EMC2's actual valence:lM cell
# naming), never guessed/pasted, so they line up exactly with what make_data() expects.
sampled_names <- names(EMC2::sampled_pars(emc_design_violated))
v_names       <- grep("^v_", sampled_names, value = TRUE)

level_of <- function(nm) valence_levels[vapply(valence_levels, \(l) grepl(paste0("valence", l, "(:|$)"), nm), logical(1))]
is_match <- function(nm) grepl("lMTRUE", nm)

v_levels <- vapply(v_names, level_of, numeric(1))
v_match  <- vapply(v_names, is_match, logical(1))

# Matching accumulator's v is driven by that level's extremity-based mean_v;
# mismatching accumulator's v uses the shared v_mismatch constant (define_design.R),
# same convention as Dataset A, for comparability between the two datasets. v is on
# the natural (real-line) scale per ?EMC2::LBA.
v_values <- ifelse(v_match, design_violated$mean_v[match(v_levels, design_violated$level)], v_mismatch)

# Group-level means: v varies by level x match cell; sv, B, A, t0 fixed (identical to
# Dataset A for b, A, t0; sv held constant here instead of scaling with drift). sv, B,
# A, t0 are log-scale per ?EMC2::LBA -- sv_constant is natural-scale (from
# define_design.R) and log-transformed here; B/A/t0 come pre-transformed.
group_means_violated <- c(
  setNames(v_values, v_names),
  sv = log(sv_constant),
  B  = B_fixed,
  A  = A_fixed,
  t0 = t0_fixed
)

# ASSUMED[no between-subject SD given]: same 15%-of-mean convention as Dataset A,
# for consistency across the two simulated datasets.
group_sds_violated <- abs(group_means_violated) * 0.15

data_violated <- EMC2::make_data(
  parameters = group_means_violated,
  design     = emc_design_violated,
  n_trials   = n_trials_per_cell,
  n_subjects = n_participants,
  sd         = group_sds_violated
)

df_weber_violated <- data_violated |>
  as_tibble() |>
  rename(participant = subjects) |>
  mutate(dataset = "weber_violated")

saveRDS(df_weber_violated, file.path(artifacts_dir, "weber_violated.rds"))
write_csv(df_weber_violated, file.path(artifacts_dir, "weber_violated.csv"))
