#### SIMULATE ONE DATASET PER WEBER SCHEME x DR FACTOR ####

# Same design and parameter-building as weber_lba_simulation: holds uses
# sv ~ 0 + valence:lM (sv = weber_k * v per level), violated uses sv ~ 1 (one constant sv).
simulate_one_dataset <- function(scheme, dr_factor, dataset) {

  design_scaled <- design_base |>
    mutate(mean_v = mean_v * dr_factor, sv = weber_k * mean_v)

  sv_formula <- if (scheme == "holds") sv ~ 0 + valence:lM else sv ~ 1

  emc_design <- EMC2::design(
    factors  = list(subjects = 1:n_participants, valence = valence_levels, S = accumulators),
    Rlevels  = accumulators,
    matchfun = function(d) d$S == d$lR,
    formula  = list(v ~ 0 + valence:lM, sv_formula, B ~ 1, A ~ 1, t0 ~ 1),
    model    = EMC2::LBA
  )

  sampled_names <- names(EMC2::sampled_pars(emc_design))
  v_names       <- grep("^v_", sampled_names, value = TRUE)

  level_of <- function(nm) valence_levels[vapply(valence_levels, \(l) grepl(paste0("valence", l, "(:|$)"), nm), logical(1))]
  v_levels <- vapply(v_names, level_of, numeric(1))
  v_match  <- grepl("lMTRUE", v_names)
  v_values <- ifelse(v_match, design_scaled$mean_v[match(v_levels, design_scaled$level)], v_mismatch)

  if (scheme == "holds") {
    sv_names  <- grep("^sv_", sampled_names, value = TRUE)
    sv_levels <- vapply(sv_names, level_of, numeric(1))
    sv_means  <- setNames(log(design_scaled$sv[match(sv_levels, design_scaled$level)]), sv_names)
  } else {
    # ASSUMED[rule carried over from weber_lba_simulation]: constant sv = weber_k * mean scaled drift
    sv_means <- c(sv = log(weber_k * mean(design_scaled$mean_v)))
  }

  group_means <- c(setNames(v_values, v_names), sv_means, B = B_fixed, A = A_fixed, t0 = t0_fixed)
  group_sds   <- abs(group_means) * 0.15

  df_out <- EMC2::make_data(
    parameters = group_means,
    design     = emc_design,
    n_trials   = n_trials_per_cell,
    n_subjects = n_participants,
    sd         = group_sds
  ) |>
    as_tibble() |>
    rename(participant = subjects) |>
    mutate(dataset = dataset, scheme = scheme, dr_factor = dr_factor)

  saveRDS(df_out, file.path(artifacts_dir, paste0(dataset, ".rds")))
  write_csv(df_out, file.path(artifacts_dir, paste0(dataset, ".csv")))
}

pwalk(df_grid, simulate_one_dataset)
