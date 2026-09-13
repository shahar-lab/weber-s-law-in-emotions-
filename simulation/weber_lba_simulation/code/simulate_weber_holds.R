#### DATASET A: WEBER'S LAW HOLDS (sv SCALES WITH MEAN DRIFT) ####

# sv proportional to each condition's mean drift rate (constant CV).
design_holds <- design_df |>
  mutate(sv = weber_k * mean_v)

# S must share Rlevels' level set (it encodes which accumulator is objectively
# correct, per EMC2's race-model convention: matchfun compares d$S to d$lR). Valence
# level is therefore a *separate* factor ("valence") entered into the formula
# alongside lM, not S itself -- S only carries correct-response identity.
# `0 + valence:lM` gives one v/sv parameter per (valence level x match) cell directly
# (EMC2's no-intercept idiom), so the matching accumulator's drift is driven by that
# level's extremity and the mismatching accumulator gets its own free cell.
# S is fully crossed with valence in this design (as `factors` requires), so
# make_data() below is given n_trials_per_cell (not n_trials_per_condition) to realize
# the spec's target 20 trials/condition/participant once S's 2 levels are multiplied
# back in, rather than doubling to 40/condition/participant.
emc_design_holds <- EMC2::design(
  factors     = list(subjects = 1:n_participants, valence = valence_levels, S = accumulators),
  Rlevels     = accumulators,
  matchfun    = function(d) d$S == d$lR,
  formula     = list(v ~ 0 + valence:lM, sv ~ 0 + valence:lM, B ~ 1, A ~ 1, t0 ~ 1),
  model       = EMC2::LBA
)

# Parameter names read off the live design object (EMC2's actual valence:lM cell
# naming), never guessed/pasted, so they line up exactly with what make_data() expects.
sampled_names   <- names(EMC2::sampled_pars(emc_design_holds))
v_names         <- grep("^v_",  sampled_names, value = TRUE)
sv_names        <- grep("^sv_", sampled_names, value = TRUE)

level_of  <- function(nm) valence_levels[vapply(valence_levels, \(l) grepl(paste0("valence", l, "(:|$)"), nm), logical(1))]
is_match  <- function(nm) grepl("lMTRUE", nm)

v_levels  <- vapply(v_names,  level_of, numeric(1))
v_match   <- vapply(v_names,  is_match, logical(1))
sv_levels <- vapply(sv_names, level_of, numeric(1))

# Matching accumulator's v/sv is driven by that level's extremity-based mean_v/sv;
# mismatching accumulator's v uses the shared v_mismatch constant (define_design.R),
# while sv is shared across match states within a level so noise still scales with
# that level's drift magnitude regardless of which accumulator it is attached to. v is
# on the natural (real-line) scale per ?EMC2::LBA; sv is log-scale, so each condition's
# natural-scale sv (design_holds$sv) is log-transformed here.
v_values  <- ifelse(v_match, design_holds$mean_v[match(v_levels, design_holds$level)], v_mismatch)
sv_values <- log(design_holds$sv[match(sv_levels, design_holds$level)])

# Group-level means: v, sv vary by level x match cell per design_holds; B, A, t0 fixed
# (already log-scale from define_design.R, per EMC2::LBA's parameterization).
group_means_holds <- c(
  setNames(v_values,  v_names),
  setNames(sv_values, sv_names),
  B  = B_fixed,
  A  = A_fixed,
  t0 = t0_fixed
)

# ASSUMED[no between-subject SD given]: 15% of each group-level mean, giving
# hierarchical participant-level variability consistent with EMC2's typical
# data-generating approach.
group_sds_holds <- abs(group_means_holds) * 0.15

data_holds <- EMC2::make_data(
  parameters = group_means_holds,
  design     = emc_design_holds,
  n_trials   = n_trials_per_cell,
  n_subjects = n_participants,
  sd         = group_sds_holds
)

df_weber_holds <- data_holds |>
  as_tibble() |>
  rename(participant = subjects) |>
  mutate(dataset = "weber_holds")

saveRDS(df_weber_holds, file.path(artifacts_dir, "weber_holds.rds"))
write_csv(df_weber_holds, file.path(artifacts_dir, "weber_holds.csv"))
