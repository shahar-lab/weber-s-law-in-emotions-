#### SIMULATE ONE WEBER-HOLDS DATASET PER CANDIDATE v_mismatch ####

# Design formula/structure identical to weber_lba_simulation's weber_holds dataset --
# only v_mismatch changes across candidates, sv = weber_k * mean_v (Weber's law) is
# untouched. Looped with purrr::walk2 (grid value + matching name) rather than a
# hand-written for-loop, per lab style.
simulate_one_candidate <- function(v_mismatch_value, candidate_name) {

  emc_design <- EMC2::design(
    factors     = list(subjects = 1:n_participants, valence = valence_levels, S = accumulators),
    Rlevels     = accumulators,
    matchfun    = function(d) d$S == d$lR,
    formula     = list(v ~ 0 + valence:lM, sv ~ 0 + valence:lM, B ~ 1, A ~ 1, t0 ~ 1),
    model       = EMC2::LBA
  )

  sampled_names <- names(EMC2::sampled_pars(emc_design))
  v_names       <- grep("^v_",  sampled_names, value = TRUE)
  sv_names      <- grep("^sv_", sampled_names, value = TRUE)

  level_of <- function(nm) valence_levels[vapply(valence_levels, \(l) grepl(paste0("valence", l, "(:|$)"), nm), logical(1))]
  is_match <- function(nm) grepl("lMTRUE", nm)

  v_levels  <- vapply(v_names,  level_of, numeric(1))
  v_match   <- vapply(v_names,  is_match, logical(1))
  sv_levels <- vapply(sv_names, level_of, numeric(1))

  v_values  <- ifelse(v_match, design_holds$mean_v[match(v_levels, design_holds$level)], v_mismatch_value)
  sv_values <- log(design_holds$sv[match(sv_levels, design_holds$level)])

  group_means <- c(
    setNames(v_values,  v_names),
    setNames(sv_values, sv_names),
    B  = B_fixed,
    A  = A_fixed,
    t0 = t0_fixed
  )

  # ASSUMED[no between-subject SD given]: same 15%-of-mean convention as weber_lba_simulation.
  group_sds <- abs(group_means) * 0.15

  data_out <- EMC2::make_data(
    parameters = group_means,
    design     = emc_design,
    n_trials   = n_trials_per_cell,
    n_subjects = n_participants,
    sd         = group_sds
  )

  df_out <- data_out |>
    as_tibble() |>
    rename(participant = subjects) |>
    mutate(dataset = candidate_name)

  saveRDS(df_out, file.path(artifacts_dir, paste0(candidate_name, ".rds")))
  write_csv(df_out, file.path(artifacts_dir, paste0(candidate_name, ".csv")))
}

purrr::walk2(v_mismatch_grid, candidate_names, simulate_one_candidate)
