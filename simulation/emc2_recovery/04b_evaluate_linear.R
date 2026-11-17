#### 04b_evaluate_linear.R -- recovery summary for the ALTERNATIVE model forms (tiers lin_test, con_test) ####
# Usage (from simulation/emc2_recovery/):  Rscript 04b_evaluate_linear.R <tier>      e.g. lin_test | con_test
# Truth for the alternative parameters = linear map W of the true cell values (see linear_model.R / constrained_model.R).
source("01_config.R")

hdi <- function(x, prob = hdi_prob) {
  x <- sort(x); n <- length(x); k <- max(1, floor(prob * n)); w <- x[(k + 1):n] - x[1:(n - k)]
  i <- which.min(w); c(lo = x[i], hi = x[i + k])
}

evaluate_lin <- function(tier_name = "lin_test") {
  tier <- get_tier(tier_name); spec <- model_spec(tier$model); dir.create(file.path(tier$out, "tables"), showWarnings = FALSE)
  files <- list.files(file.path(tier$out, "results"), "[.]rds$", full.names = TRUE)
  conv <- grp <- ppl <- hyp <- NULL
  for (f in files) {
    r <- readRDS(f); sim <- readRDS(file.path(tier$out, "data", basename(f)))
    pn <- rownames(r$mu_draws)
    W  <- spec$weights(pn, names(sim$true_mu))
    tr <- as.vector(W %*% sim$true_mu[colnames(W)]); names(tr) <- pn
    conv <- rbind(conv, data.frame(id = r$id, N = r$N, max_rhat_mu = r$max_rhat$mu, max_rhat_alpha = r$max_rhat$alpha,
                                   min_ess_mu = r$min_ess$mu, min_ess_alpha = r$min_ess$alpha, n_draws = r$n_draws, minutes = r$minutes))
    H <- t(apply(r$mu_draws, 1, hdi))                                       # group level
    g <- data.frame(id = r$id, N = r$N, par = pn, true = tr, est = rowMeans(r$mu_draws), lo90 = H[, 1], hi90 = H[, 2])
    g$bias <- g$est - g$true; g$covered <- g$lo90 <= g$true & g$true <= g$hi90; grp <- rbind(grp, g)
    ta <- sim$true_alpha; ta <- ta[, intersect(colnames(ta), colnames(W)), drop = FALSE]      # participant level
    TA <- ta %*% t(W[, colnames(ta), drop = FALSE])
    ppl <- rbind(ppl, do.call(rbind, lapply(pn, function(k) data.frame(id = r$id, N = r$N, par = k,
          r = suppressWarnings(cor(r$alpha_mean[, k], TA[, k])), bias = mean(r$alpha_mean[, k] - TA[, k]),
          rmse = sqrt(mean((r$alpha_mean[, k] - TA[, k])^2))))))
    hq <- spec$hyp()                                                         # hypothesis quantities (contrasts on mu)
    hyp <- rbind(hyp, do.call(rbind, lapply(names(hq), function(n) { w <- hq[[n]]
      d <- colSums(w * r$mu_draws[names(w), , drop = FALSE]); h <- hdi(d)
      data.frame(id = r$id, N = r$N, quantity = n, true = sum(w * tr[names(w)]), est = mean(d), lo90 = h[1], hi90 = h[2],
                 p_gt0 = mean(d > 0), detected_lo_gt0 = h[1] > 0) })))
  }
  rownames(hyp) <- NULL
  pre <- if (tier$model == "linear") "lin_" else "con_"
  for (nm in c("conv", "grp", "ppl", "hyp")) write.csv(get(nm), file.path(tier$out, "tables", paste0(pre, nm, ".csv")), row.names = FALSE)
  pdf(file.path(tier$out, "figures", paste0(pre, "group_recovery.pdf")), width = 9, height = 5)
  for (id in unique(grp$id)) { g <- grp[grp$id == id, ]
    plot(g$true, g$est, ylim = range(g$lo90, g$hi90), xlim = range(g$true), pch = 16, xlab = "true group mean", ylab = "posterior mean (90% HDI)", main = id)
    segments(g$true, g$lo90, g$true, g$hi90, col = ifelse(g$covered, "grey40", "red")); abline(0, 1, lty = 2)
    text(g$true, g$est, g$par, cex = .45, pos = 4) }
  dev.off()
  options(width = 200)
  cat("\n== convergence ==\n"); print(conv, digits = 3, row.names = FALSE)
  cat("\n== group level: coverage of 90% HDI and mean |bias| by family ==\n")
  grp$family <- lin_family(grp$par); print(aggregate(cbind(covered, abs_bias = abs(bias)) ~ id + family, grp, mean), digits = 2)
  cat("\n== group level, every parameter ==\n"); print(format(grp[, c("id", "par", "true", "est", "lo90", "hi90", "covered")], digits = 2), row.names = FALSE)
  cat("\n== participant level ==\n"); print(format(ppl, digits = 2), row.names = FALSE)
  cat("\n== hypothesis quantities ==\n"); print(format(hyp, digits = 2), row.names = FALSE)
  invisible(list(conv = conv, grp = grp, ppl = ppl, hyp = hyp))
}

if (sys.nframe() == 0L) { a <- commandArgs(TRUE); evaluate_lin(if (length(a)) a[1] else "lin_test") }
