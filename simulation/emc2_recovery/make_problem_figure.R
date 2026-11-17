# Diagnostic figure for the identifiability problem (blr_test, N = 100, B per accumulator, A free).
suppressMessages(library(EMC2)); source("01_config.R")
e  <- get(load("output/blr_test/fits_raw/perception_N100_r01.RData"))
th <- lapply(e, function(ch) ch$samples$theta_mu)            # par x iter, per chain
pn <- rownames(th[[1]]); tr <- true_group_means("perception", make_design(100))[pn]
cols <- c("#1b6ca8", "#d95f02", "#2a9d5c")
dir.create("output/diag", showWarnings = FALSE)
png("output/diag/problem_figure.png", width = 2400, height = 1700, res = 200)
layout(matrix(c(1,2,3, 4,4,5), 2, byrow = TRUE)); par(mar = c(4.2, 4.2, 3, 1), cex.main = 1)
trace <- function(p, main) {
  y <- sapply(th, function(x) x[p, ]); matplot(y, type = "l", lty = 1, ylim = range(c(y, tr[p])), col = adjustcolor(cols, .7), xlab = "iteration (sampling stage)",
         ylab = "group mean (estimation scale)", main = main); abline(h = tr[p], lwd = 2, lty = 2)
}
trace("A", "A (log): true value (dashed) is far below all chains"); legend("topright", c("chain 1","chain 2","chain 3","true value"), col = c(cols,"black"), lty = c(1,1,1,2), lwd = c(1,1,1,2), bty = "n", cex = .8)
trace("B_lRemotional", "B, emotional accumulator (log)")
trace("v_lRneutral:vg2", "v, neutral accumulator, valence 2")
# ridge: A vs B_emotional vs chain
plot(NA, xlim = range(c(sapply(th, function(x) x["A",]), tr["A"])), ylim = range(c(sapply(th, function(x) x["B_lRemotional",]), tr["B_lRemotional"])),
     xlab = "A (log)", ylab = "B emotional (log)", main = "Joint posterior of A and B: chains disagree, truth (x) is far away")
for (i in 1:3) points(th[[i]]["A",], th[[i]]["B_lRemotional",], pch = 16, cex = .4, col = adjustcolor(cols[i], .35))
points(tr["A"], tr["B_lRemotional"], pch = 4, cex = 2.5, lwd = 3)
legend("topright", "x = true value", bty = "n", cex = .8)
# chain means vs truth for all params
fam <- ifelse(grepl("^v_", pn), "v", ifelse(grepl("^sv_", pn), "sv", ifelse(grepl("^B_", pn), "B", pn)))
cm <- sapply(th, function(x) rowMeans(x))                      # par x chain
plot(tr, rowMeans(cm), type = "n", xlim = range(c(tr, cm)), ylim = range(c(tr, cm)), xlab = "true group mean", ylab = "posterior mean per chain",
     main = "All 27 group means: estimates vs truth")
abline(0, 1, lwd = 2, lty = 2)
for (i in 1:3) points(tr, cm[, i], pch = 16, col = adjustcolor(cols[i], .7), cex = 1)
text(tr[c("A")], cm["A", 1], "A", pos = 4, cex = .8)
dev.off()
