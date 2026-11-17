#### constrained_model.R -- cell-means model with a CONSTRAINED non-tracking accumulator (NOT the preregistered model) ####
# Tracking accumulator (emotional for pos images 6,7,8; neutral for neg images 4,3,2): v and log sv free per valence cell (6 + 6).
# Non-tracking accumulator: ONE v per direction (npos, nneg), sv fixed to 1 (log 0) in every cell (sets the scale).
# B per accumulator, A and t0 single. 18 free parameters. Factor cellv is built by EMC2 from lR and vg.

con_cell_fun <- function(d) {
  trk <- (d$vg %in% c("6", "7", "8") & d$lR == "emotional") | (d$vg %in% c("2", "3", "4") & d$lR == "neutral")
  factor(ifelse(trk, paste0("t", d$vg), ifelse(d$vg %in% c("6", "7", "8"), "npos", "nneg")),
         levels = c("t2", "t3", "t4", "t6", "t7", "t8", "npos", "nneg"))
}

make_design_con <- function(n_subj) {
  design(factors = list(subjects = seq_len(n_subj), vg = vg_levels), Rlevels = acc_levels,
         functions = list(cellv = con_cell_fun),
         formula = list(v ~ 0 + cellv, sv ~ 0 + cellv, B ~ 0 + lR, A ~ 1, t0 ~ 1),
         constants = c(sv_cellvnpos = 0, sv_cellvnneg = 0, if (fix_A) c(A = log(gen$A))), model = LBA, report_p_vector = FALSE)
}

# truth of the constrained parameters from the true cell parameters (cell-means generator): W x cell values
con_weights <- function(con_names, cell_names) {
  W <- matrix(0, length(con_names), length(cell_names), dimnames = list(con_names, cell_names))
  for (p in con_names) {
    m <- regmatches(p, regexec("^(v|sv)_cellv(t([2-8])|npos|nneg)$", p))[[1]]
    if (length(m) == 0) { W[p, p] <- 1; next }                                # B, A, t0
    if (nzchar(m[4])) { acc <- if (m[4] %in% pos_vg) pos_acc else neg_acc; W[p, paste0(m[2], "_lR", acc, ":vg", m[4])] <- 1 }
    else { vgs <- if (m[3] == "npos") pos_vg else neg_vg; acc <- if (m[3] == "npos") neg_acc else pos_acc   # non-tracking: mean of 3 cells
           for (g in vgs) if (paste0(m[2], "_lR", acc, ":vg", g) %in% cell_names) W[p, paste0(m[2], "_lR", acc, ":vg", g)] <- 1 / 3 }
  }
  W
}

# ---- registry: how fit / evaluate treat each model form ----
step_defs_con <- function() {          # H1 (sv) and H2 (v) steps of the tracking accumulator as contrasts on mu
  st <- list(pos_7m6 = c("t7", "t6"), pos_8m7 = c("t8", "t7"), neg_3m4 = c("t3", "t4"), neg_2m3 = c("t2", "t3"))
  out <- list()
  for (par in c("sv", "v")) for (n in names(st)) out[[paste0(if (par == "sv") "H1_" else "H2_", n)]] <-
    setNames(c(1, -1), paste0(par, "_cellv", st[[n]]))
  out
}
step_defs_lin <- function() list(
  H1_pos_sv_slope = c("sv_lRemotional:directionpos:intensity" = 1), H1_neg_sv_slope = c("sv_lRneutral:directionneg:intensity" = 1),
  H2_pos_v_slope  = c("v_lRemotional:directionpos:intensity" = 1),  H2_neg_v_slope  = c("v_lRneutral:directionneg:intensity" = 1))

model_spec <- function(model = "cell") switch(model %||% "cell",
  cell = list(design = make_design, prep = identity, prior = make_prior, groups = par_groups_for, weights = NULL, hyp = NULL),
  linear = list(design = make_design_lin, prep = lin_prep_data, prior = make_prior_lin, groups = par_groups_lin,
                weights = lin_weights, hyp = step_defs_lin, family = lin_family),
  constrained = list(design = make_design_con, prep = identity, prior = make_prior, groups = par_groups_for,
                     weights = con_weights, hyp = step_defs_con, family = lin_family),
  stop("unknown model form: ", model))
`%||%` <- function(a, b) if (is.null(a)) b else a
