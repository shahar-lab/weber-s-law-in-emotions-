#### 05_report_pdf.R -- diagnostic PDF per fitted dataset: scatter plot for EVERY parameter, group recovery, traces, trade-offs ####
# Usage (from simulation/emc2_recovery/):  Rscript 05_report_pdf.R <tier> [id]     e.g. con_test | lin_test | blr_test | conA_test
# Output: output/<tier>/figures/diagnostic_<id>.pdf
# Pages: 1 summary | 2 group-level recovery (true vs 90% HDI, + per-chain means) | 3.. participant-level scatter (true vs
#        estimated, one panel per parameter) | traces of the group means per chain | posterior correlations of the group means.
# Truth: the generating cell parameters mapped to the model's own parameters (identity for the cell-means model).
source("01_config.R")
hdi <- function(x, prob = hdi_prob) { x <- sort(x); n <- length(x); k <- max(1, floor(prob * n)); w <- x[(k + 1):n] - x[1:(n - k)]; i <- which.min(w); c(x[i], x[i + k]) }
chain_cols <- c("#1b6ca8", "#d95f02", "#2a9d5c")

report_one <- function(tier_name, id) {
  tier <- get_tier(tier_name); spec <- model_spec(tier$model)
  r   <- readRDS(file.path(tier$out, "results", paste0(id, ".rds")))
  sim <- readRDS(file.path(tier$out, "data", paste0(id, ".rds")))
  pn  <- rownames(r$mu_draws)
  W <- if (is.null(spec$weights)) { m <- diag(length(pn)); dimnames(m) <- list(pn, pn); m } else spec$weights(pn, names(sim$true_mu))
  tr  <- as.vector(W %*% sim$true_mu[colnames(W)]); names(tr) <- pn
  ta  <- sim$true_alpha[, intersect(colnames(sim$true_alpha), colnames(W)), drop = FALSE]
  TA  <- ta %*% t(W[, colnames(ta), drop = FALSE]); est <- r$alpha_mean[, pn, drop = FALSE]
  H   <- t(apply(r$mu_draws, 1, hdi)); gm <- rowMeans(r$mu_draws); cov <- H[, 1] <= tr & tr <= H[, 2]
  # per-chain traces from the raw fit (optional; large file)
  f_raw <- file.path(tier$out, "fits_raw", paste0(id, ".RData")); th <- NULL
  if (file.exists(f_raw)) th <- tryCatch({ e <- get(load(f_raw)); lapply(e, function(ch) ch$samples$theta_mu[pn, ]) }, error = function(e) NULL)
  if (Sys.getenv("REPORT_PNG") == "") pdf(file.path(tier$out, "figures", paste0("diagnostic_", id, ".pdf")), width = 11, height = 8.5) else
    png(file.path(Sys.getenv("REPORT_PNG"), paste0(id, "_%02d.png")), width = 2200, height = 1700, res = 200)

  # ---- page 1: summary ----
  plot.new(); par(mar = c(1, 1, 3, 1))
  fam <- lin_family(pn)
  rp <- sapply(pn, function(k) suppressWarnings(cor(est[, k], TA[, k])))
  txt <- c(sprintf("Diagnostic report: %s   (model form: %s, N = %d, scenario: %s)", id, tier$model %||% "cell", r$N, r$scenario), "",
    sprintf("Convergence: max R-hat mu = %.2f, alpha = %.2f;  min ESS mu = %.0f, alpha = %.0f;  %d draws/chain-merged, %.0f min",
            r$max_rhat$mu, r$max_rhat$alpha, r$min_ess$mu, r$min_ess$alpha, r$n_draws, r$minutes),
    "   (targets: R-hat < 1.1, ESS > 200)",
    sprintf("Group means with the true value inside the 90%% HDI: %d of %d", sum(cov), length(cov)), "",
    "By parameter family:  group coverage | mean |bias| | mean participant-level r",
    sapply(unique(fam), function(f) sprintf("   %-3s  %d/%d covered | %.2f | r = %.2f", f, sum(cov[fam == f]), sum(fam == f),
            mean(abs(gm - tr)[fam == f]), mean(rp[fam == f], na.rm = TRUE))), "",
    "How to read: chains that sit at different levels (trace pages) or an R-hat far above 1.1 mean the parameter is not",
    "identified by these data; estimates and HDIs of such parameters should not be interpreted.")
  text(0, seq(1, 0.05, length.out = length(txt)), txt, adj = c(0, 1), family = "mono", cex = 0.85, xpd = NA)

  # ---- page 2: group-level recovery ----
  par(mar = c(4, 12, 3, 2)); k <- length(pn); y <- rev(seq_len(k))
  xr <- range(c(H, tr, if (!is.null(th)) sapply(th, rowMeans)))
  plot(NA, xlim = xr, ylim = c(0.5, k + 0.5), yaxt = "n", xlab = "group mean (estimation scale: log for sv, B, A, t0)", ylab = "",
       main = "Group-level recovery: truth (diamond) vs posterior mean and 90% HDI")
  axis(2, y, pn, las = 1, cex.axis = 0.6); abline(h = y, col = "grey92")
  segments(H[, 1], y, H[, 2], y, lwd = 3, col = ifelse(cov, "grey45", "red")); points(gm, y, pch = 16)
  if (!is.null(th)) for (i in seq_along(th)) points(rowMeans(th[[i]]), y - 0.18 + 0.18 * (i - 1), pch = 20, cex = 0.7, col = chain_cols[i])
  points(tr, y, pch = 18, cex = 1.6)
  legend("bottomright", c("truth", "posterior mean", "90% HDI covers truth", "90% HDI misses truth", "chain 1/2/3 means"),
         pch = c(18, 16, NA, NA, 20), lwd = c(NA, NA, 3, 3, NA), col = c("black", "black", "grey45", "red", "#d95f02"), bty = "n", cex = 0.7)

  # ---- participant-level scatter: one panel per parameter ----
  per <- 9
  for (pg in seq(1, k, by = per)) {
    par(mfrow = c(3, 3), mar = c(4, 4, 3.2, 1), oma = c(0, 0, 2, 0))
    for (j in pg:min(k, pg + per - 1)) {
      p <- pn[j]; x <- TA[, p]; yv <- est[, p]; lim <- range(x, yv)
      plot(x, yv, pch = 16, col = adjustcolor("black", 0.55), xlim = lim, ylim = lim, xlab = "true (participant)", ylab = "estimated (posterior mean)",
           main = p, cex.main = 0.85)
      abline(0, 1, lty = 2); if (sd(x) > 0 && sd(yv) > 0) abline(lm(yv ~ x), col = "red", lwd = 2)
      abline(v = tr[p], col = "grey70", lty = 3); abline(h = gm[p], col = "#1b6ca8", lty = 3)
      rr <- suppressWarnings(cor(x, yv)); b <- mean(yv - x); rm <- sqrt(mean((yv - x)^2))
      legend("topleft", sprintf("r = %.2f\nbias = %.2f\nRMSE = %.2f", rr, b, rm), bty = "n", cex = 0.8)
    }
    mtext(sprintf("Participant-level recovery (dashed = identity, red = fitted line, grey = true group mean, blue = estimated group mean)   [%s]", id),
          outer = TRUE, cex = 0.8)
  }

  # ---- traces of the group means ----
  if (!is.null(th)) for (pg in seq(1, k, by = per)) {
    par(mfrow = c(3, 3), mar = c(4, 4, 3, 1), oma = c(0, 0, 2, 0))
    for (j in pg:min(k, pg + per - 1)) {
      p <- pn[j]; yy <- sapply(th, function(x) x[p, ])
      matplot(yy, type = "l", lty = 1, col = adjustcolor(chain_cols, 0.75), ylim = range(yy, tr[p]), xlab = "iteration", ylab = "group mean", main = p, cex.main = 0.85)
      abline(h = tr[p], lty = 2, lwd = 2)
    }
    mtext("Trace plots of the group means, one line per chain (dashed = true value). Separated chains = not converged.", outer = TRUE, cex = 0.8)
  }

  # ---- posterior correlations of group means (trade-offs) ----
  C <- cor(t(r$mu_draws)); par(mfrow = c(1, 1), mar = c(9, 9, 3, 2), oma = c(0, 0, 0, 0))
  image(seq_len(k), seq_len(k), C[, k:1], zlim = c(-1, 1), col = hcl.colors(41, "Blue-Red 3"), axes = FALSE, xlab = "", ylab = "",
        main = "Posterior correlations of the group means (strong off-diagonal = trade-off)")
  axis(1, seq_len(k), pn, las = 2, cex.axis = 0.55); axis(2, seq_len(k), rev(pn), las = 1, cex.axis = 0.55); box()
  dev.off()
  invisible(file.path(tier$out, "figures", paste0("diagnostic_", id, ".pdf")))
}

`%||%` <- function(a, b) if (is.null(a)) b else a
if (sys.nframe() == 0L) {
  a <- commandArgs(TRUE); tier <- get_tier(a[1])
  ids <- if (length(a) > 1) a[2] else sub("[.]rds$", "", list.files(file.path(tier$out, "results"), "[.]rds$"))
  for (id in ids) cat("wrote", report_one(a[1], id), "\n")
}
