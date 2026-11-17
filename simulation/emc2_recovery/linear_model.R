#### linear_model.R -- LINEAR-IN-INTENSITY version of the model (NOT the preregistered cell-means model) ####
# v  ~ accumulator x direction (intercepts, at intensity 1) + accumulator x direction x intensity (slopes)
# log sv: same structure; B ~ accumulator; A, t0 single.   intensity coded 0,1,2 (= intensity 1,2,3 minus 1),
# so the intercept is the weakest level and the slope is the average step per intensity level (comparable to the Weber / v steps).
# direction: pos = valence 6,7,8 (intensity 1,2,3);  neg = valence 4,3,2 (intensity 1,2,3).
# Reference for the scale: sv of the neutral accumulator, positive direction, intercept, fixed to 1 (log 0).
# Used by 03_fit.R when a tier has model = "linear". It reuses data simulated from the cell-means generator
# (same datasets as the cell-means fits), so the two model forms are compared on identical data.

lin_fixed_sv <- "sv_lRneutral:directionpos"
lin_int <- c("2" = 2, "3" = 1, "4" = 0, "6" = 0, "7" = 1, "8" = 2)      # intensity - 1, by valence group

lin_prep_data <- function(dat) {
  dat$direction <- factor(ifelse(dat$vg %in% pos_vg, "pos", "neg"), levels = c("pos", "neg"))
  dat$intensity <- unname(lin_int[as.character(dat$vg)])
  dat
}

make_design_lin <- function(n_subj) {
  design(factors = list(subjects = seq_len(n_subj), direction = c("pos", "neg")),
         covariates = "intensity", Rlevels = acc_levels,
         formula = list(v ~ 0 + lR:direction + lR:direction:intensity,
                        sv ~ 0 + lR:direction + lR:direction:intensity,
                        B ~ 0 + lR, A ~ 1, t0 ~ 1),
         constants = setNames(0, lin_fixed_sv), model = LBA, report_p_vector = FALSE)
}

lin_family <- function(nm) ifelse(grepl("^v_", nm), "v", ifelse(grepl("^sv_", nm), "sv", ifelse(grepl("^B_", nm), "B", nm)))
par_groups_lin <- function(design) match(lin_family(names(sampled_pars(design))), c("v", "sv", "B", "A", "t0"))

# Priors (MINE): centred on 0 for slopes => skeptical about the hypothesised increases.
prior_cfg_lin <- list(v_int = c(1, 1), v_slope = c(0, 0.5), sv_int = c(0, 0.3), sv_slope = c(0, 0.3),
                      B = prior_cfg$B, A = prior_cfg$A, t0 = prior_cfg$t0)
make_prior_lin <- function(design) {
  nm <- names(sampled_pars(design)); slope <- grepl(":intensity$", nm); fam <- lin_family(nm)
  key <- ifelse(fam %in% c("v", "sv"), paste0(fam, ifelse(slope, "_slope", "_int")), fam)
  prior(design, type = "blocked", par_groups = par_groups_lin(design),
        mu_mean = setNames(sapply(key, function(k) prior_cfg_lin[[k]][1]), nm),
        mu_sd   = setNames(sapply(key, function(k) prior_cfg_lin[[k]][2]), nm))
}

# Truth for the linear parameters = least-squares line through the 3 true cell values (identity for B, A, t0).
# Returns weights W (linear pars x cell pars) so truth = W %*% cell values (group means, or per-subject rows).
lin_weights <- function(lin_names, cell_names) {
  W <- matrix(0, length(lin_names), length(cell_names), dimnames = list(lin_names, cell_names))
  vgs <- list(pos = c("6", "7", "8"), neg = c("4", "3", "2"))               # intensity 0,1,2
  for (p in lin_names) {
    m <- regmatches(p, regexec("^(v|sv)_lR(emotional|neutral):direction(pos|neg)(:intensity)?$", p))[[1]]
    if (length(m) == 0) { W[p, p] <- 1; next }
    cells <- paste0(m[2], "_lR", m[3], ":vg", vgs[[m[4]]])
    w <- if (nzchar(m[5])) c(-1/2, 0, 1/2) else c(5/6, 1/3, -1/6)           # slope / intercept of the OLS line, x = 0,1,2
    for (k in 1:3) if (cells[k] %in% cell_names) W[p, cells[k]] <- w[k]      # the fixed cell (sv = 1 -> log 0) contributes 0
  }
  W
}
