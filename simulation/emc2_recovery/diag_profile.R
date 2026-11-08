source("01_config.R")
set.seed(42)   # same data as diag_single.R 0
des <- make_design(1); gm <- true_group_means("perception", des)
skel <- data.frame(subjects = factor(1), vg = factor(rep(vg_levels, each = 1000), levels = vg_levels),
                   R = factor(acc_levels[1], levels = acc_levels), rt = NA_real_)
dat <- make_data(gm, des, data = skel)[, c("subjects", "vg", "R", "rt")]
dat <- dat[is.finite(dat$rt) & dat$rt <= max_rt, ]
print(args(profile_plot))
pdf("output/diag/profile.pdf", width = 12, height = 8)
res <- profile_plot(dat, des, gm, use_par = c("A", "t0", "B_lRemotional:vg2", "v_lRemotional:vg7", "sv_lRemotional:vg7", "v_lRneutral:vg2"), n_point = 41, range = 0.5, layout = c(2, 3))
dev.off()
str(res)
