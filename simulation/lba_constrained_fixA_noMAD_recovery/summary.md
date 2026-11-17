# Recovery Notebook: lba_constrained_fixA without the MAD cutoff (EMC2 LBA, perception scenario, N = 100)

**Generative model:** `models/lba_cellmeans/` (cell-means LBA, B per accumulator, A free)
**Fitted model:** `models/lba_constrained_fixA/` (constrained non-tracking accumulator, A fixed at 0.4; 17 free parameters. Not the preregistered model)
**Job-folder:** `simulation/lba_constrained_fixA_noMAD_recovery/`
**Cloned from:** `simulation/lba_constrained_fixA_recovery/` (left untouched)
**Date Created:** 2026-11-17

**Why this study:** the source study's fit was biased at the population level (all v about +1.0 to +1.3, B about 1.8 times too high, t0 about 0.12 s instead of 0.30 s). The per-participant 3-MAD rule removed 6.3% of trials, all of them slow, and the fitted model treats the trimmed data as complete. This study refits the same agents and the same raw data with only the basic trimming, to see how much of that bias the MAD cutoff causes.

## 1. Design (set in `main.R`)

* **What differs from the source study:** N = 100 only; exclusions are (a) no response or RT > 10 s and (b) RT < 0.15 s, with no MAD cutoff; no reuse of earlier fits (the model is fitted fresh)
* **n_subjects:** N = 100
* **n_trials:** 138 per participant (22, 24, 23, 24, 23, 22 for valence 2, 3, 4, 6, 7, 8)
* **n_sessions:** 1
* **Population location (`mu_*`) of the generating model:** tracking v 1.5 / 2.1 / 2.7 (valence 6, 7, 8 on the emotional accumulator; 4, 3, 2 on the neutral accumulator); non-tracking v 0.8; non-tracking sv 1.0; tracking sv 0.8 at the lowest intensity with log sv rising by log(v_i / v_1) (Weber strength 1); B 1.5 (emotional) and 1.7 (neutral); A 0.4; t0 0.30 s
* **Population scale (`sigma_*`):** SDs on the estimation scale: v 0.25, log sv 0.15, log B 0.20, log A 0.25, log t0 0.15; within-family correlation 0.3 (v, sv, B), none across families
* **Unit-interval transforms:** none (v on the real line; sv, B, A, t0 on the log scale; threshold b = A + B)
* **Sampler:** EMC2 3.5.0, 3 chains, blocked covariance by parameter family; sampling continues in blocks of 1000 draws until R-hat < 1.1 and ESS > 200 on the group means and participant parameters, at most 20 blocks
* **Priors (researcher to review; not preregistered):** v ~ N(1, 1); log sv ~ N(0, 0.3); log B ~ N(log 1.2, 0.5); log t0 ~ N(log 0.3, 0.4). A is a constant (log 0.4), so it has no prior
* **Exclusions applied to the generated data:** no response or RT > 10 s; RT < 0.15 s. No MAD cutoff
* **Recovery criteria:** none set by the researcher; the report lists R-hat, ESS, Pearson r, bias, precision, 90% HDI coverage and trade-offs without a verdict

### Fixed parameters of the fitted model

| Name | Fixed at (estimation scale) | After exp() | What it is |
|---|---|---|---|
| `sv_cellvnpos`, `sv_cellvnneg` | 0 | 1 | Drift-rate variability of the non-tracking accumulator; fixes the scale of the model |
| `A` | -0.916 | 0.4 | Range of the start point. Equals the population mean of the generating A; individual generating A values vary (SD 0.25 on the log scale), so it is not each participant's true value |

## 2. Generating true parameters

* Agent parameters are drawn with EMC2 `make_random_effects()` from the population values above, with seed = 20261106 + 1e6 + 1e3 * 100 + 1. The seed depends on N only, so these 100 agents are the same as the source study's N = 100 agents.
* Artifacts: `true_population_N100.rds`, `true_parameters_N100.rds`, `rng_state_N100.rds`
* Output: `02_true_parameters_dots_N100` (dot histograms of the true agent values with the population density)

## 3. Generating data

* Generating definition loaded from `models/lba_cellmeans/`; the raw trials are identical to the source study's N = 100 raw trials. Only the exclusions differ.
* Artifacts: `simulated_data_N100.rds` (+ `.csv` copy), `exclusion_counts_N100.rds`

## 4. Recovering parameters

* Fitting definition: `models/lba_constrained_fixA/lba_constrained_fixA_emc2.R` (EMC2 design, blocked covariance, priors)
* Fitted fresh; no earlier fit is reused
* Artifacts: `emc_fit_N100.RData`, `fit_done_N100.rds`, `draws_pop_N100.rds`, `draws_sbj_N100.rds`, `chains_mu_N100.rds`, `convergence_N100.rds`, `recovered_parameters_N100.rds`, `recovery_table_N100.rds`

## 5. Findings / Summary

* (Leave this section blank until the model is fitted and the Word/PDF report has been inspected.)
* Required deliverables in `output/`: `12_recovery_report.docx` (narrative, embedded figures, APA captions) and `11_recovery_figures_N100.pdf` (multi-page vector PDF: Figure 1 population locations, Figure 2 population scales, Figure 3 true vs recovered per parameter, trace plots, posterior correlations); each figure is also saved as PDF and PNG (`07_`, `08_`, `09_`, `10_`).

## 6. Manuscript excerpt: example 1

[Placeholder. After the researcher inspects the results, a short paragraph describing the recovery design: sample size, generating population distributions, exclusions, and the fitted model.]

## 7. Manuscript excerpt: example 2

[Placeholder. After the researcher inspects the results, a short paragraph reporting the recovery result: population coverage and participant-level Pearson r, bias and precision.]
