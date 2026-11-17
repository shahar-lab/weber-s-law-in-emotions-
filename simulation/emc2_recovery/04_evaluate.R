#### 04_evaluate.R -- recovery evaluation from the slim fit results ####
# Usage (from simulation/emc2_recovery/):  Rscript 04_evaluate.R <tier>
# Writes CSV tables to output/<tier>/tables/ and figures to output/<tier>/figures/.
source("01_config.R")
suppressPackageStartupMessages({ library(coda); library(ggplot2) })

family_of <- function(nm) ifelse(grepl("^v_", nm), "v", ifelse(grepl("^sv_", nm), "log(sv)", ifelse(grepl("^B_", nm), "log(B)", ifelse(nm == "A", "log(A)", "log(t0)"))))
hdi <- function(x, prob = hdi_prob) as.numeric(HPDinterval(as.mcmc(x), prob = prob))
hdi_rows <- function(m, prob = hdi_prob) t(apply(m, 1, hdi, prob = prob))   # rows = quantities, cols = lo/hi
rmse <- function(x) sqrt(mean(x^2))

load_tier <- function(tier) {
  ids <- tier$jobs$id[file.exists(file.path(tier$out, "results", paste0(tier$jobs$id, ".rds")))]
  lapply(setNames(ids, ids), function(id) {
    r <- readRDS(file.path(tier$out, "results", paste0(id, ".rds")))
    s <- readRDS(file.path(tier$out, "data", paste0(id, ".rds")))
    r$true_mu <- s$true_mu; r$true_alpha <- s$true_alpha; r$n_excluded <- s$n_excluded; r
  })
}

# ---- 1. convergence -------------------------------------------------------------
eval_convergence <- function(R) do.call(rbind, lapply(R, function(r) data.frame(
  id = r$id, scenario = r$scenario, N = r$N, rep = r$rep,
  max_rhat_mu = as.numeric(unlist(r$max_rhat$mu))[1], max_rhat_alpha = as.numeric(unlist(r$max_rhat$alpha))[1],
  min_ess_mu = as.numeric(unlist(r$min_ess$mu))[1], min_ess_alpha = as.numeric(unlist(r$min_ess$alpha))[1],
  minutes = r$minutes, pct_excluded = 100 * (1 - r$n_excluded["kept"] / r$n_excluded["total"]))))

# ---- 2. group level --------------------------------------------------------------
eval_group <- function(R) do.call(rbind, lapply(R, function(r) {
  est <- rowMeans(r$mu_draws); ci <- hdi_rows(r$mu_draws); tru <- r$true_mu[rownames(r$mu_draws)]
  data.frame(id = r$id, scenario = r$scenario, N = r$N, rep = r$rep, param = rownames(r$mu_draws),
             family = family_of(rownames(r$mu_draws)), true = tru, est = est, lo = ci[, 1], hi = ci[, 2],
             covered = tru >= ci[, 1] & tru <= ci[, 2], row.names = NULL)
}))

# ---- 3. participant level --------------------------------------------------------
eval_subject <- function(R) do.call(rbind, lapply(R, function(r) {
  tr <- r$true_alpha; es <- r$alpha_mean; es <- es[rownames(tr), colnames(tr), drop = FALSE]
  data.frame(id = r$id, scenario = r$scenario, N = r$N, rep = r$rep, param = colnames(tr), family = family_of(colnames(tr)),
             cor = sapply(colnames(tr), function(p) cor(tr[, p], es[, p])),
             bias = colMeans(es - tr), rmse = apply(es - tr, 2, rmse), row.names = NULL)
}))

# ---- 4. parameter trade-offs ------------------------------------------------------
cells <- function(nm) { x <- sub("^(v|sv|B)_", "", nm); x[grepl("^(v|sv|B)_", nm)] }
tradeoff_pairs <- function(nm) {
  cl <- unique(cells(nm)[grepl(":vg", cells(nm))]); out <- NULL
  Bname <- function(c_) if (paste0("B_", c_) %in% nm) paste0("B_", c_) else paste0("B_", sub(":vg.*", "", c_))  # B per cell or per accumulator
  for (c_ in cl) for (pr in list(c("sv", "B"), c("sv", "v"), c("v", "B"))) {
    nmf <- function(p) if (p == "B") Bname(c_) else paste0(p, "_", c_)
    a <- nmf(pr[1]); b <- nmf(pr[2])
    if (all(c(a, b) %in% nm)) out <- rbind(out, data.frame(cell = c_, pair = paste(pr, collapse = "-"), a = a, b = b))
  }
  out
}
eval_tradeoffs <- function(R) {
  grp <- list(); subj <- list(); mats <- list()
  for (r in R) {
    nm <- rownames(r$mu_draws); pp <- tradeoff_pairs(nm); cm <- cor(t(r$mu_draws)); mats[[r$id]] <- cm
    grp[[r$id]] <- data.frame(id = r$id, scenario = r$scenario, N = r$N, level = "group", pp[, c("cell", "pair")],
                              cor = mapply(function(a, b) cm[a, b], pp$a, pp$b))
    ad <- r$alpha_draws   # par x subj x draw
    sc <- sapply(seq_len(nrow(pp)), function(i) mean(sapply(seq_len(dim(ad)[2]), function(s) cor(ad[pp$a[i], s, ], ad[pp$b[i], s, ]))))
    subj[[r$id]] <- data.frame(id = r$id, scenario = r$scenario, N = r$N, level = "subject (mean within-subject)", pp[, c("cell", "pair")], cor = sc)
  }
  list(pairs = do.call(rbind, c(grp, subj)), mats = mats)
}

# ---- 5. hypothesis quantities & decision rules -------------------------------------
hyp_contrasts <- function(nm) {
  C <- step_contrasts(nm)
  rbind(C, H1_mean4 = colMeans(C[grepl("^H1_", rownames(C)), ]), H2_mean4 = colMeans(C[grepl("^H2_", rownames(C)), ]))
}
decision_table <- function(q, tru, meta) {   # q: quantity x draw; tru: named truth
  ci <- hdi_rows(q)
  do.call(rbind, lapply(rope_grid, function(rp) data.frame(meta, quantity = rownames(q), rope = rp, true = tru[rownames(q)],
         est = rowMeans(q), lo = ci[, 1], hi = ci[, 2], covered = tru[rownames(q)] >= ci[, 1] & tru[rownames(q)] <= ci[, 2],
         detected = ci[, 1] > rp, truth_above = tru[rownames(q)] > rp, row.names = NULL)))
}
eval_hypotheses <- function(R) {
  out <- lapply(R, function(r) { C <- hyp_contrasts(rownames(r$mu_draws))
    decision_table(C %*% r$mu_draws, drop(C %*% r$true_mu[colnames(C)]), data.frame(id = r$id, scenario = r$scenario, N = r$N, rep = r$rep)) })
  do.call(rbind, out)
}
# conjunction ("all four steps") and disjunction ("any step") rules on top of per-step decisions
add_composite_rules <- function(H) {
  stp <- H[grepl("^H[12]_(pos|neg)", H$quantity), ]; stp$hyp <- substr(stp$quantity, 1, 2)
  key <- c("id", "scenario", "N", "rep", "rope", "hyp")
  agg <- aggregate(cbind(detected, truth_above) ~ id + scenario + N + rep + rope + hyp, stp,
                   function(x) c(all = all(x), any = any(x)))
  data.frame(agg[, key], rule = rep(c("all_4_steps", "any_step"), each = nrow(agg)),
             detected = c(agg$detected[, "all"], agg$detected[, "any"]),
             truth_above = c(agg$truth_above[, "all"], agg$truth_above[, "any"]))
}
# H3: perception minus action (independent datasets -> elementwise draw differences are valid).
eval_h3 <- function(R) {
  out <- list(); sc <- sapply(R, `[[`, "scenario"); Ns <- sapply(R, `[[`, "N"); rp <- sapply(R, `[[`, "rep")
  pairs <- list(c("perception", "action"), c("perception_half", "action"), c("action", "action"))
  for (pr in pairs) for (n in unique(Ns)) {
    A <- R[sc == pr[1] & Ns == n]; B <- R[sc == pr[2] & Ns == n]
    for (a in A) {
      if (pr[1] == pr[2]) { b <- B[sapply(B, `[[`, "rep") == (a$rep %% max(sapply(B, `[[`, "rep"))) + 1]; if (!length(b)) next; b <- b[[1]]
      } else { b <- B[sapply(B, `[[`, "rep") == a$rep]; if (!length(b)) next; b <- b[[1]] }
      C <- hyp_contrasts(rownames(a$mu_draws)); k <- min(ncol(a$mu_draws), ncol(b$mu_draws))
      q <- C %*% (a$mu_draws[, 1:k] - b$mu_draws[, 1:k]); tru <- drop(C %*% (a$true_mu - b$true_mu)[colnames(C)])
      out[[length(out) + 1]] <- decision_table(q, tru, data.frame(contrast = paste(pr, collapse = " - "), N = n, rep = a$rep))
    }
  }
  do.call(rbind, out)
}

summ_decisions <- function(D, by) {
  D$correct <- D$detected == D$truth_above
  aggregate(cbind(detected, correct) ~ ., D[, c(by, "detected", "correct")], mean)
}

# ---- plots -------------------------------------------------------------------------
plot_group <- function(G, file) {
  p <- ggplot(G, aes(true, est, colour = covered)) + geom_abline(slope = 1, intercept = 0, linetype = 2) +
    geom_linerange(aes(ymin = lo, ymax = hi), alpha = .25) + geom_point(size = 1, alpha = .6) +
    facet_grid(scenario ~ family + N, scales = "free", labeller = label_both) + scale_colour_manual(values = c(`TRUE` = "grey30", `FALSE` = "red3")) +
    labs(x = "generating group mean", y = "posterior mean (90% HDI)", colour = "HDI covers truth") + theme_bw(9)
  ggsave(file, p, width = 16, height = 3 + 2 * length(unique(G$scenario)))
}
plot_subject <- function(R, file) {
  d <- do.call(rbind, lapply(R, function(r) { if (r$rep != 1) return(NULL)
    tr <- r$true_alpha; es <- r$alpha_mean[rownames(tr), colnames(tr)]
    data.frame(scenario = r$scenario, N = r$N, param = rep(colnames(tr), each = nrow(tr)), family = rep(family_of(colnames(tr)), each = nrow(tr)),
               true = as.vector(tr), est = as.vector(es)) }))
  p <- ggplot(d, aes(true, est)) + geom_abline(slope = 1, intercept = 0, linetype = 2) + geom_point(alpha = .15, size = .6) +
    facet_wrap(scenario + N ~ family, scales = "free", ncol = 5, labeller = label_wrap_gen(multi_line = FALSE)) +
    labs(x = "generating participant parameter", y = "posterior mean") + theme_bw(9)
  ggsave(file, p, width = 16, height = 3 * length(unique(paste(d$scenario, d$N))) + 1, limitsize = FALSE)
}
plot_tradeoffs <- function(mats, file) {
  m <- Reduce(`+`, mats) / length(mats); d <- as.data.frame(as.table(m)); names(d) <- c("a", "b", "cor")
  p <- ggplot(d, aes(a, b, fill = cor)) + geom_tile() + scale_fill_gradient2(limits = c(-1, 1)) + theme_bw(7) +
    theme(axis.text.x = element_text(angle = 90, hjust = 1)) + labs(x = NULL, y = NULL, title = "Mean posterior correlation of group-level means")
  ggsave(file, p, width = 11, height = 10)
}
plot_hyp <- function(H, file) {
  d <- H[H$rope == rope_main & grepl("^H[12]_mean4", H$quantity), ]
  p <- ggplot(d, aes(factor(N), est)) + geom_hline(aes(yintercept = true), linetype = 2) + geom_pointrange(aes(ymin = lo, ymax = hi), alpha = .4, position = position_jitter(.15)) +
    facet_grid(quantity ~ scenario, scales = "free_y") + labs(x = "N participants", y = "posterior mean + 90% HDI (dashed = truth)") + theme_bw(9)
  ggsave(file, p, width = 9, height = 6)
}

# ---- driver ------------------------------------------------------------------------
evaluate_tier <- function(tier_name) {
  tier <- get_tier(tier_name); dir.create(file.path(tier$out, "tables"), showWarnings = FALSE)
  tab <- function(x, nm) { write.csv(x, file.path(tier$out, "tables", paste0(nm, ".csv")), row.names = FALSE); x }
  R <- load_tier(tier); cat(length(R), "of", nrow(tier$jobs), "fits available\n"); if (!length(R)) stop("no results")
  conv <- tab(eval_convergence(R), "convergence")
  cat("\n== Convergence (max R-hat, min ESS; mu = group means) ==\n")
  print(aggregate(cbind(max_rhat_mu, min_ess_mu, max_rhat_alpha, min_ess_alpha, minutes, pct_excluded) ~ scenario + N, conv, median), digits = 3)
  cat("fits with mu R-hat < 1.1 and ESS > 200:", sum(conv$max_rhat_mu < 1.1 & conv$min_ess_mu > 200, na.rm = TRUE), "of", nrow(conv), "\n")

  G <- tab(eval_group(R), "group_level_by_fit")
  Gs <- tab(aggregate(cbind(bias = est - true, abs_err = abs(est - true), coverage = covered) ~ scenario + N + family, G, mean), "group_level_summary_by_family")
  tab(aggregate(cbind(true, est, coverage = covered) ~ scenario + N + param, G, mean), "group_level_summary_by_param")
  Gs$rmse <- aggregate(I(est - true) ~ scenario + N + family, G, rmse)[[4]]
  cat("\n== Group level: bias, mean |error|, 90% HDI coverage ==\n"); print(Gs, digits = 3)
  plot_group(G, file.path(tier$out, "figures", "group_level_recovery.pdf"))

  S <- tab(eval_subject(R), "participant_level_by_fit")
  Ss <- tab(aggregate(cbind(cor, bias, rmse) ~ scenario + N + family, S, mean), "participant_level_summary_by_family")
  cat("\n== Participant level: correlation, bias, RMSE ==\n"); print(Ss, digits = 3)
  plot_subject(R, file.path(tier$out, "figures", "participant_level_scatter.pdf"))

  T_ <- eval_tradeoffs(R)
  Ts <- tab(aggregate(cor ~ scenario + N + level + pair, T_$pairs, mean), "tradeoffs_summary")
  cat("\n== Trade-offs: mean posterior correlation within cell ==\n"); print(Ts, digits = 2)
  tab(T_$pairs, "tradeoffs_by_fit"); plot_tradeoffs(T_$mats, file.path(tier$out, "figures", "tradeoff_correlations.pdf"))

  H <- tab(eval_hypotheses(R), "hypothesis_quantities_by_fit")
  cat("\n== Hypothesis quantities: bias and coverage (ROPE-independent) ==\n")
  print(aggregate(cbind(true, est, coverage = covered) ~ scenario + N + quantity, H[H$rope == rope_main, ], mean), digits = 3)
  cat("\n== Decision rules per step: detection rate (truth_above = TRUE -> power; FALSE -> false-positive rate) ==\n")
  Dstep <- tab(aggregate(cbind(detected, correct = (detected == truth_above)) ~ scenario + N + quantity + rope + truth_above, H, mean), "decisions_per_step")
  print(Dstep[Dstep$rope %in% c(0, rope_main), ], digits = 2)
  Dc <- add_composite_rules(H)
  Dcs <- tab(aggregate(cbind(detected, correct = (detected == truth_above)) ~ scenario + N + hyp + rule + rope + truth_above, Dc, mean), "decisions_composite")
  cat("\n== Composite rules (all 4 steps / any step) ==\n"); print(Dcs[Dcs$rope %in% c(0, rope_main), ], digits = 2)
  plot_hyp(H, file.path(tier$out, "figures", "hypothesis_steps.pdf"))

  H3 <- eval_h3(R)
  if (!is.null(H3) && nrow(H3)) {
    tab(H3, "h3_by_pair")
    h3s <- tab(aggregate(cbind(detected, correct = (detected == truth_above)) ~ contrast + N + quantity + rope + truth_above, H3, mean), "h3_decisions")
    cat("\n== H3 (first contrast = perception - action; 'action - action' = null pairs; n pairs per row varies) ==\n")
    print(h3s[h3s$rope %in% c(0, rope_main) & grepl("mean4", h3s$quantity), ], digits = 2)
  }
  invisible(list(conv = conv, G = G, S = S, H = H))
}

if (sys.nframe() == 0L) evaluate_tier(commandArgs(TRUE)[1])
