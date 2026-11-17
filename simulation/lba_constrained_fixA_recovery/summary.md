# Recovery Notebook: lba_constrained_fixA (EMC2 LBA, perception scenario)

**Generative model:** `models/lba_cellmeans/` (cell-means LBA, B per accumulator, A free)
**Fitted model:** `models/lba_constrained_fixA/` (as lba_constrained, with A fixed at its true value 0.4 (log A = -0.916); 17 free parameters. A fixed at its generating value is a best case, not a realistic analysis. Not the preregistered model)
**Job-folder:** `simulation/lba_constrained_fixA_recovery/`
**Date Created:** 2026-11-16

## 1. Design (set in `main.R`)

* **n_subjects:** N = 50 and N = 100 (one study each, both inside this folder)
* **n_trials:** 138 per participant (22, 24, 23, 24, 23, 22 for valence 2, 3, 4, 6, 7, 8)
* **n_sessions:** 1
* **Population location (`mu_*`) of the generating model:** tracking v 1.5 / 2.1 / 2.7 (valence 6, 7, 8 on the emotional accumulator; 4, 3, 2 on the neutral accumulator); non-tracking v 0.8; non-tracking sv 1.0; tracking sv 0.8 at the lowest intensity with log sv rising by log(v_i / v_1) (Weber strength 1); B 1.5 (emotional) and 1.7 (neutral); A 0.4; t0 0.30 s
* **Population scale (`sigma_*`):** SDs on the estimation scale: v 0.25, log sv 0.15, log B 0.20, log A 0.25, log t0 0.15; within-family correlation 0.3 (v, sv, B), none across families
* **Unit-interval transforms:** none (v on the real line; sv, B, A, t0 on the log scale; threshold b = A + B)
* **Sampler:** EMC2 3.5.0, 3 chains, blocked covariance by parameter family; sampling continues in blocks of 1000 draws until R-hat < 1.1 and ESS > 200 on the group means and participant parameters, at most 20 blocks
* **Priors (researcher to review; mine, not preregistered):** v ~ N(1, 1); log sv ~ N(0, 0.3); log B ~ N(log 1.2, 0.5); log A ~ N(log 0.4, 0.5); log t0 ~ N(log 0.3, 0.4); A is a constant, so it has no prior
* **Exclusions applied to the generated data (preregistered):** no response or RT > 10 s; RT < 0.15 s; per participant |RT - median| > 3 scaled MAD (two-sided)
* **Recovery criteria:** none set by the researcher; the report lists R-hat, ESS, Pearson r, bias, precision, 90% HDI coverage and trade-offs without a verdict

### Estimated parameters of the fitted model (17 free)

The tracking accumulator is the neutral accumulator for negative images (valence 2, 3, 4) and the emotional accumulator for positive images (valence 6, 7, 8). Only v is on the real line; every other parameter is estimated on the log scale. "True value" is the generating group mean.

| # | Name | What it is | Scale | True value (estimation scale) | After exp() |
|---|---|---|---|---|---|
| 1 | `v_cellvt2` | Drift rate of the tracking accumulator on valence-2 images | real line | 2.7 | n/a |
| 2 | `v_cellvt3` | Same, valence 3 | real line | 2.1 | n/a |
| 3 | `v_cellvt4` | Same, valence 4 | real line | 1.5 | n/a |
| 4 | `v_cellvt6` | Drift rate of the tracking accumulator on valence-6 images | real line | 1.5 | n/a |
| 5 | `v_cellvt7` | Same, valence 7 | real line | 2.1 | n/a |
| 6 | `v_cellvt8` | Same, valence 8 | real line | 2.7 | n/a |
| 7 | `v_cellvnpos` | Drift rate of the non-tracking (neutral) accumulator on positive images, one value for valence 6, 7, 8 | real line | 0.8 | n/a |
| 8 | `v_cellvnneg` | Drift rate of the non-tracking (emotional) accumulator on negative images, one value for valence 2, 3, 4 | real line | 0.8 | n/a |
| 9 | `sv_cellvt2` | Drift-rate variability (SD) of the tracking accumulator on valence 2 (H1, Weber, is about its change across cells) | log | 0.365 | 1.44 |
| 10 | `sv_cellvt3` | Same, valence 3 | log | 0.113 | 1.12 |
| 11 | `sv_cellvt4` | Same, valence 4 | log | -0.223 | 0.80 |
| 12 | `sv_cellvt6` | Same, valence 6 | log | -0.223 | 0.80 |
| 13 | `sv_cellvt7` | Same, valence 7 | log | 0.113 | 1.12 |
| 14 | `sv_cellvt8` | Same, valence 8 | log | 0.365 | 1.44 |
| 15 | `B_lRemotional` | Threshold distance of the emotional accumulator (threshold = A + B) | log | 0.405 | 1.5 |
| 16 | `B_lRneutral` | Threshold distance of the neutral accumulator | log | 0.531 | 1.7 |
| 17 | `t0` | Non-decision time (encoding and motor time) | log | -1.204 | 0.30 s |

### Fixed parameters of the fitted model

| Name | Fixed at (estimation scale) | After exp() | What it is and why |
|---|---|---|---|
| `sv_cellvnpos`, `sv_cellvnneg` | 0 | 1 | Drift-rate variability of the non-tracking accumulator in every valence cell. It fixes the scale of the model. |
| `A` | -0.916 | 0.4 | Range of the start point. Fixed at its true generating value, which is a best case (a real analysis would not know it). |

## 2. Generating true parameters

* Agent parameters are drawn with EMC2 `make_random_effects()` from the population values above, seeded per N (seed = 20261106 + 1e6 + 1e3 * N + 1) so that all five recovery folders fit identical datasets.
* Artifacts: `true_population_N*.rds`, `true_parameters_N*.rds`, `rng_state_N*.rds`
* Output: `02_true_parameters_dots_N*` (dot histograms of the true agent values with the population density)

## 3. Generating data

* Generating definition loaded from `models/lba_cellmeans/`; the preregistered exclusions are applied after generation.
* Artifacts: `simulated_data_N*.rds` (+ `.csv` copy), `exclusion_counts_N*.rds`
* Re-running regenerates exactly the datasets used by the earlier `simulation/emc2_recovery` pipeline (checked identical for N = 50 and N = 100).

## 4. Recovering parameters

* Fitting definition: `models/lba_constrained_fixA/lba_constrained_fixA_emc2.R` (EMC2 design, blocked covariance, priors); as lba_constrained, with A fixed at its true value 0.4 (log A = -0.916); 17 free parameters. A fixed at its generating value is a best case, not a realistic analysis. Not the preregistered model
* Fit reuse: the existing fits of the identical datasets (earlier tier conA_test) were copied into artifacts and marked done; nothing was refitted
* Artifacts: `emc_fit_N*.RData`, `fit_done_N*.rds`, `draws_pop_N*.rds`, `draws_sbj_N*.rds`, `chains_mu_N*.rds`, `convergence_N*.rds`, `recovered_parameters_N*.rds`, `recovery_table_N*.rds`

## 5. Findings / Summary

* (Leave this section blank until the model is fitted and the Word/PDF report has been inspected.)
* Required deliverables in `output/`: `12_recovery_report.docx` (narrative, embedded figures, APA captions) and `11_recovery_figures_N*.pdf` (multi-page vector PDF: Figure 1 population locations, Figure 2 population scales, Figure 3 true vs recovered per parameter, trace plots, posterior correlations); each figure is also saved as PDF and PNG (`07_`, `08_`, `09_`, `10_`).

## 6. Manuscript excerpt: example 1

[Placeholder. After the researcher inspects the results, a short paragraph describing the recovery design: sample sizes, generating population distributions, and the fitted model.]

## 7. Manuscript excerpt: example 2

[Placeholder. After the researcher inspects the results, a short paragraph reporting the recovery result: population coverage and participant-level Pearson r, bias and precision.]
