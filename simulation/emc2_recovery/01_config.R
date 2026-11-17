#### 01_config.R -- ALL settings for the EMC2 parameter-recovery study ####
# Sourced by 02_simulate.R, 03_fit.R and 04_evaluate.R. Edit values ONLY here.
# Scale note: EMC2's LBA samples v on the real line and sv, B, A, t0 on the LOG
# scale (see ?EMC2::LBA; b = B + A). Everything "(nat)" below is natural scale and
# is log-transformed in true_group_means().

suppressPackageStartupMessages(library(EMC2))

# ---- paths -------------------------------------------------------------------
root_dir <- tryCatch(dirname(sys.frame(1)$ofile), error = function(e) NULL)
if (is.null(root_dir)) root_dir <- getwd()   # run scripts from simulation/emc2_recovery/

# ---- task design ---------------------------------------------------------------
vg_levels  <- c("2", "3", "4", "6", "7", "8")      # valence_group (EMC2 forbids "_" in factor names -> "vg")
trials_vg  <- c(22, 24, 23, 24, 23, 22)             # trials per valence group (prereg table); total 138
names(trials_vg) <- vg_levels
acc_levels <- c("emotional", "neutral")             # accumulators = response options
max_rt     <- 10                                    # response window (s)

# Intensity-tracking accumulator: emotional for positive images, neutral for negative.
# Intensity order 1 -> 3 (weakest -> strongest):
pos_vg <- c("6", "7", "8"); pos_acc <- "emotional"
neg_vg <- c("4", "3", "2"); neg_acc <- "neutral"

# ---- generating values (group level, natural scale) ----------------------------
gen <- list(
  v_track   = c(1.5, 2.1, 2.7),   # v of tracking accumulator, intensity 1..3
  v_other   = 0.8,                # v of non-tracking accumulator (flat)
  sv_other  = 1.0,                # sv of non-tracking accumulator (flat); the fixed ref cell lives here
  sv0_track = 0.8,                # sv of tracking accumulator at intensity 1
  B_emo     = 1.5,                # B (threshold distance) emotional accumulator
  B_neu     = 1.7,                # B neutral accumulator (small bias towards "neutral")
  A         = 0.4,
  t0        = 0.30,
  # between-subject SDs on the ESTIMATION scale (v: raw; sv/B/A/t0: log)
  sd = c(v = 0.25, sv = 0.15, B = 0.20, A = 0.25, t0 = 0.15),
  within_family_cor = 0.3         # correlation among cells of the same parameter family
)

# Scenarios. weber_strength scales how much log(sv) of the tracking accumulator grows with intensity:
#   log sv_i = log(sv0_track) + weber_strength * log(v_i / v_1)
#   1 = proportional to v (Weber's law; log-sv steps 0.34, 0.25), 0 = constant sv (null).
scenarios <- list(
  perception      = list(weber_strength = 1),
  action          = list(weber_strength = 0),     # also the null case for H1/H3
  perception_half = list(weber_strength = 0.5)    # half-size effect (power curve)
)

# Reference cell for identifiability: sv = 1 (log sv = 0) here. Non-tracking accumulator, weakest positive cell.
sv_fixed_cell <- "sv_lRneutral:vg6"

# ---- exclusions (prereg order: a, b, c) -----------------------------------------
excl <- list(min_rt = 0.15, mad_k = 3, mad_constant = 1.4826)  # (c) two-sided, per participant

# ---- model / fitting -------------------------------------------------------------
# Structure of B (threshold distance). Diagnosis (see README): the preregistered "cell" version
# (B ~ accumulator:valence_group) is not recoverable -- B, v and sv trade off within cells.
#   "lR"   : B per accumulator only (valence groups are intermixed, so no per-valence threshold)  [default]
#   "cell" : preregistered B ~ lR:vg.   Override from the shell: B_MODEL=cell Rscript ...
B_model <- Sys.getenv("B_MODEL", "lR")
stopifnot(B_model %in% c("lR", "cell"))
# FIX_A=1: A fixed at its generating value (diagnostic only; NOT preregistered). Use with tier fixA_test.
fix_A <- Sys.getenv("FIX_A", "0") == "1"

# Participant-level covariance: parameters of the same family (v, sv, B) may correlate;
# A and t0 are each their own block. ("blocked" in EMC2 = par_groups)
par_groups_for <- function(design) {
  nm <- names(sampled_pars(design))
  match(ifelse(grepl("^v_", nm), "v", ifelse(grepl("^sv_", nm), "sv", ifelse(grepl("^B_", nm), "B", nm))), c("v", "sv", "B", "A", "t0"))
}

# Priors (MY DEFAULTS -- preregistration only says weak/informative/skeptical).
# Same prior mean for every cell => no a-priori ordering, i.e. skeptical about the hypothesised steps.
prior_cfg <- list(
  v  = c(mean = 1.0,      sd = 1.0),
  sv = c(mean = 0,        sd = 0.3),   # log scale
  B  = c(mean = log(1.2), sd = 0.5),
  A  = c(mean = log(0.4), sd = 0.5),
  t0 = c(mean = log(0.30), sd = 0.4)
)

n_chains <- 3
compress <- FALSE        # no RT binning (avoids binning bias)
fit_iter <- 1000         # sampling-stage iterations per chain
stop_crit <- list(max_gd = 1.1, min_es = 200, selection = c("mu", "alpha"), omit_mpsrf = TRUE)
max_tries <- 20
n_post_alpha <- 200      # thinned subject-level draws stored (trade-off analysis)
n_post_mu    <- 1000     # thinned group-level draws stored

# ---- decision rules ---------------------------------------------------------------
hdi_prob  <- 0.90
rope_grid <- c(0, 0.05, 0.10, 0.20)   # ROPE half-widths evaluated (preregistered value undefined; pick later)
rope_main <- 0.10

# ---- study tiers ---------------------------------------------------------------
tiers <- list(
  pilot = list(scenarios = "perception", N = 20, reps = 1,
               stop = list(preburn = list(iter = 100), burn = list(mean_gd = 1.3),
                           adapt = list(min_unique = 100),
                           sample = list(iter = 200, max_gd = 1.3, selection = "mu", omit_mpsrf = TRUE)),
               max_tries = 3, workers = 1),
  # same dataset as pilot (same seed) but the full stopping rule: tests whether/when a real fit converges
  pilot_full = list(scenarios = "perception", N = 20, reps = 1, stop = NULL, max_tries = max_tries, workers = 1),
  # B per accumulator only, A free, 138 trials/participant: can the parameters be recovered at all?
  blr_test = list(scenarios = "perception", N = c(50, 100), reps = 1, stop = NULL, max_tries = max_tries, workers = 2),
  fixA_test = list(scenarios = "perception", N = 50, reps = 1, stop = NULL, max_tries = max_tries, workers = 1),
  lin_test = list(scenarios = "perception", N = c(50, 100), reps = 1, stop = NULL, max_tries = max_tries, workers = 2, model = "linear"),
  con_test = list(scenarios = "perception", N = c(50, 100), reps = 1, stop = NULL, max_tries = max_tries, workers = 2, model = "constrained"),
  conA_test = list(scenarios = "perception", N = c(50, 100), reps = 1, stop = NULL, max_tries = max_tries, workers = 2, model = "constrained"),   # run with FIX_A=1
  tier1 = list(scenarios = c("perception", "action"), N = 100, reps = 1:20, stop = NULL, max_tries = max_tries, workers = 6),
  tier2 = list(scenarios = c("perception", "action"), N = c(50, 150), reps = 1:20, stop = NULL, max_tries = max_tries, workers = 6),
  tier3 = list(scenarios = "perception_half", N = c(50, 100, 150), reps = 1:20, stop = NULL, max_tries = max_tries, workers = 6)
)
base_seed <- 20261106

# ================================ helpers ==========================================
get_tier <- function(name) {
  stopifnot(name %in% names(tiers))
  t <- tiers[[name]]; t$name <- name
  t$out <- file.path(root_dir, "output", name)
  for (s in c("data", "fits_raw", "results", "figures")) dir.create(file.path(t$out, s), recursive = TRUE, showWarnings = FALSE)
  t$jobs <- expand.grid(scenario = t$scenarios, N = t$N, rep = t$reps, stringsAsFactors = FALSE)
  t$jobs$id <- sprintf("%s_N%03d_r%02d", t$jobs$scenario, t$jobs$N, t$jobs$rep)
  t
}

seed_for <- function(scenario, N, rep) base_seed + 1e6 * match(scenario, names(scenarios)) + 1e3 * N + rep

make_design <- function(n_subj) {
  design(factors = list(subjects = seq_len(n_subj), vg = vg_levels),
         Rlevels = acc_levels,
         formula = list(v ~ 0 + lR:vg, sv ~ 0 + lR:vg, if (B_model == "lR") B ~ 0 + lR else B ~ 0 + lR:vg, A ~ 1, t0 ~ 1),
         constants = c(setNames(0, sv_fixed_cell), if (fix_A) c(A = log(gen$A))),
         model = LBA, report_p_vector = FALSE)
}

# Named vector of group-level means on the estimation scale, in sampled_pars() order.
true_group_means <- function(scenario, design) {
  s <- scenarios[[scenario]]$weber_strength
  p <- sampled_pars(design); p[] <- 0
  set <- function(prefix, acc, vgs, val) p[paste0(prefix, "_lR", acc, ":vg", vgs)] <<- val
  for (i in 1:3) {
    for (side in list(list(vg = pos_vg[i], trk = pos_acc, oth = neg_acc),
                      list(vg = neg_vg[i], trk = neg_acc, oth = pos_acc))) {
      set("v",  side$trk, side$vg, gen$v_track[i])
      set("v",  side$oth, side$vg, gen$v_other)
      set("sv", side$trk, side$vg, log(gen$sv0_track) + s * log(gen$v_track[i] / gen$v_track[1]))
      if (paste0("sv_lR", side$oth, ":vg", side$vg) != sv_fixed_cell)
        set("sv", side$oth, side$vg, log(gen$sv_other))
    }
  }
  p[grep("^B_lRemotional", names(p))] <- log(gen$B_emo)
  p[grep("^B_lRneutral",   names(p))] <- log(gen$B_neu)
  if ("A" %in% names(p)) p["A"] <- log(gen$A)
  p["t0"] <- log(gen$t0)
  p
}

# Between-subject covariance: SDs per family, constant correlation within v / sv / B.
true_group_cov <- function(design) {
  nm <- names(sampled_pars(design))
  fam <- ifelse(grepl("^v_", nm), "v", ifelse(grepl("^sv_", nm), "sv", ifelse(grepl("^B_", nm), "B", nm)))
  sds <- gen$sd[fam]
  R <- outer(fam, fam, function(a, b) ifelse(a == b & a %in% c("v", "sv", "B"), gen$within_family_cor, 0)); diag(R) <- 1
  S <- diag(sds) %*% R %*% diag(sds); dimnames(S) <- list(nm, nm); S
}

make_prior <- function(design) {
  nm <- names(sampled_pars(design))
  fam <- ifelse(grepl("^v_", nm), "v", ifelse(grepl("^sv_", nm), "sv", ifelse(grepl("^B_", nm), "B", nm)))
  prior(design, type = "blocked", par_groups = par_groups_for(design),
        mu_mean = setNames(sapply(fam, function(f) prior_cfg[[f]]["mean"]), nm),
        mu_sd   = setNames(sapply(fam, function(f) prior_cfg[[f]]["sd"]),   nm))
}

# Hypothesis-relevant contrasts as named linear combinations of mu (rows = quantities, cols = parameters).
# H1 (Weber steps, log sv) and H2 (v steps) for the intensity-tracking accumulator.
step_contrasts <- function(par_names) {
  steps <- list(
    pos_7m6 = list(acc = pos_acc, hi = "7", lo = "6"), pos_8m7 = list(acc = pos_acc, hi = "8", lo = "7"),
    neg_3m4 = list(acc = neg_acc, hi = "3", lo = "4"), neg_2m3 = list(acc = neg_acc, hi = "2", lo = "3"))
  out <- NULL
  for (par in c("sv", "v")) for (n in names(steps)) {
    s <- steps[[n]]; w <- setNames(numeric(length(par_names)), par_names)
    w[paste0(par, "_lR", s$acc, ":vg", s$hi)] <- 1; w[paste0(par, "_lR", s$acc, ":vg", s$lo)] <- -1
    out <- rbind(out, w); rownames(out)[nrow(out)] <- paste0(if (par == "sv") "H1_" else "H2_", n)
  }
  out
}

# Preregistered exclusions, in order (a) no response in window, (b) RT < 150 ms,
# (c) per participant |RT - median| > k * MAD (two-sided). Returns kept data + counts.
apply_exclusions <- function(dat) {
  n0 <- nrow(dat)
  a <- !is.finite(dat$rt) | dat$rt > max_rt;       dat <- dat[!a, ]
  b <- dat$rt < excl$min_rt;                       dat <- dat[!b, ]
  keep <- unlist(lapply(split(seq_len(nrow(dat)), dat$subjects), function(ix) {
    r <- dat$rt[ix]; m <- median(r); d <- excl$mad_constant * median(abs(r - m))
    ix[abs(r - m) <= excl$mad_k * d]
  }))
  c_ <- nrow(dat) - length(keep); dat <- dat[sort(keep), ]
  dat$subjects <- droplevels(dat$subjects)
  list(data = dat, counts = c(total = n0, no_response = sum(a), too_fast = sum(b), mad = c_, kept = nrow(dat)))
}

# linear-in-intensity model (diagnostic alternative, not preregistered); needs prior_cfg defined above
source("linear_model.R")
source("constrained_model.R")
