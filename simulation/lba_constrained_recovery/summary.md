# Recovery Notebook: lba_constrained (EMC2 LBA, perception scenario)

**Generative model:** `models/lba_cellmeans/` (cell-means LBA, B per accumulator, A free)
**Fitted model:** `models/lba_constrained/` (tracking accumulator: v and log sv per valence cell (6 + 6); non-tracking accumulator: one v per direction and sv fixed to 1 in all cells; B per accumulator, A and t0 single; 18 free parameters. Not the preregistered model)
**Job-folder:** `simulation/lba_constrained_recovery/`
**Date Created:** 2026-11-16

## 1. Design (set in `main.R`)

* **n_subjects:** N = 50 and N = 100 (one study each, both inside this folder)
* **n_trials:** 138 per participant (22, 24, 23, 24, 23, 22 for valence 2, 3, 4, 6, 7, 8)
* **n_sessions:** 1
* **Population location (`mu_*`) of the generating model:** tracking v 1.5 / 2.1 / 2.7 (valence 6, 7, 8 on the emotional accumulator; 4, 3, 2 on the neutral accumulator); non-tracking v 0.8; non-tracking sv 1.0; tracking sv 0.8 at the lowest intensity with log sv rising by log(v_i / v_1) (Weber strength 1); B 1.5 (emotional) and 1.7 (neutral); A 0.4; t0 0.30 s
* **Population scale (`sigma_*`):** SDs on the estimation scale: v 0.25, log sv 0.15, log B 0.20, log A 0.25, log t0 0.15; within-family correlation 0.3 (v, sv, B), none across families
* **Unit-interval transforms:** none (v on the real line; sv, B, A, t0 on the log scale; threshold b = A + B)
* **Sampler:** EMC2 3.5.0, 3 chains, blocked covariance by parameter family; sampling continues in blocks of 1000 draws until R-hat < 1.1 and ESS > 200 on the group means and participant parameters, at most 20 blocks
* **Priors (researcher to review; mine, not preregistered):** v ~ N(1, 1); log sv ~ N(0, 0.3); log B ~ N(log 1.2, 0.5); log A ~ N(log 0.4, 0.5); log t0 ~ N(log 0.3, 0.4)
* **Exclusions applied to the generated data (preregistered):** no response or RT > 10 s; RT < 0.15 s; per participant |RT - median| > 3 scaled MAD (two-sided)
* **Recovery criteria:** none set by the researcher; the report lists R-hat, ESS, Pearson r, bias, precision, 90% HDI coverage and trade-offs without a verdict

## 2. Generating true parameters

* Agent parameters are drawn with EMC2 `make_random_effects()` from the population values above, seeded per N (seed = 20261106 + 1e6 + 1e3 * N + 1) so that all five recovery folders fit identical datasets.
* Artifacts: `true_population_N*.rds`, `true_parameters_N*.rds`, `rng_state_N*.rds`
* Output: `02_true_parameters_dots_N*` (dot histograms of the true agent values with the population density)

## 3. Generating data

* Generating definition loaded from `models/lba_cellmeans/`; the preregistered exclusions are applied after generation.
* Artifacts: `simulated_data_N*.rds`, `exclusion_counts_N*.rds`
* Re-running regenerates exactly the datasets used by the earlier `simulation/emc2_recovery` pipeline (checked identical for N = 50 and N = 100).

## 4. Recovering parameters

* Fitting definition: `models/lba_constrained/lba_constrained_emc2.R` (EMC2 design, blocked covariance, priors); tracking accumulator: v and log sv per valence cell (6 + 6); non-tracking accumulator: one v per direction and sv fixed to 1 in all cells; B per accumulator, A and t0 single; 18 free parameters. Not the preregistered model
* Fit reuse: the existing fits of the identical datasets (earlier tier con_test) were copied into artifacts and marked done; nothing was refitted
* Artifacts: `emc_fit_N*.RData`, `fit_done_N*.rds`, `draws_pop_N*.rds`, `draws_sbj_N*.rds`, `chains_mu_N*.rds`, `convergence_N*.rds`, `recovered_parameters_N*.rds`, `recovery_table_N*.rds`

## 5. Findings / Summary

* (Leave this section blank until the model is fitted and the Word/PDF report has been inspected.)
* Required deliverables in `output/`: `12_recovery_report.docx` (narrative, embedded figures, APA captions) and `11_recovery_figures_N*.pdf` (multi-page vector PDF: Figure 1 population locations, Figure 2 population scales, Figure 3 true vs recovered per parameter, trace plots, posterior correlations); each figure is also saved as PDF and PNG (`07_`, `08_`, `09_`, `10_`).

## 6. Manuscript excerpt: example 1

[Placeholder. After the researcher inspects the results, a short paragraph describing the recovery design: sample sizes, generating population distributions, and the fitted model.]

## 7. Manuscript excerpt: example 2

[Placeholder. After the researcher inspects the results, a short paragraph reporting the recovery result: population coverage and participant-level Pearson r, bias and precision.]
