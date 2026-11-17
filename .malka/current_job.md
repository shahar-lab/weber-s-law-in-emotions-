# Approved Job Cards (confirmed by the researcher)

Shared specification (applies to all ten cards)
- Generating model for every study: `lba_cellmeans` (cell-means LBA, B per accumulator, A free). Perception scenario only.
- Fitted model: the study's own model. Estimator: EMC2 3.5.0 (no Stan; EMC2 is the sampler).
- Task: 2 accumulators (emotional, neutral); valence groups 2,3,4 (negative) and 6,7,8 (positive); 138 trials per participant (22,24,23,24,23,22 for valence 2,3,4,6,7,8); max RT 10 s.
- Tracking accumulator: emotional for positive images (6<7<8), neutral for negative images (4<3<2).
- Exclusions (preregistered): (a) no response or RT > 10 s; (b) RT < 0.15 s; (c) per participant |RT - median| > 3 scaled MAD (constant 1.4826), two-sided.
- Sample sizes: N = 50 and N = 100, both inside each study (files carry _N050 / _N100). All five studies use the same seed per N so they fit identical datasets (seed = 20261106 + 1e6*scenario_index + 1e3*N + rep, as in the legacy code).
- Population (set in main.R): tracking v 1.5/2.1/2.7; non-tracking v 0.8; non-tracking sv 1.0; tracking sv starts 0.8, log sv_i = log 0.8 + log(v_i / v_1) (Weber strength 1); B 1.5 (emotional), 1.7 (neutral); A 0.4; t0 0.30 s. Between-participant SDs (log scale for sv,B,A,t0): v 0.25, sv 0.15, B 0.20, A 0.25, t0 0.15; within-family correlation 0.3 (v, sv, B families); no correlation across families.
- Fitting: 3 chains; blocked covariance by family (v, sv, B, A, t0); stop rule R-hat < 1.1, ESS > 200 on mu and alpha; blocks of 1000 sampling draws; at most 20 blocks. Existing fits are reused: the fit stage skips a fit whose artifact exists.
- Priors: v ~ N(1,1); log sv ~ N(0,0.3); log B ~ N(log 1.2, 0.5); log A ~ N(log 0.4, 0.5); log t0 ~ N(log 0.3, 0.4). Linear model only: v slope ~ N(0,0.5), log sv slope ~ N(0,0.3); intercepts as above.
- Recovery criteria: none set by the researcher. Report R-hat, ESS, Pearson r, bias (mean error and OLS slope), precision (median posterior SD, shrinkage), 90% HDI coverage at the population level, and trade-off correlations; no pass/fail verdict.
- Figures (each PDF + PNG, canvas 10 x 8 in unless a plot-type file says otherwise): Figure 1 population location (mu) posteriors; Figure 2 population scale (sigma) posteriors; Figure 3 true vs recovered scatter, one panel per estimated parameter, y = posterior median. Plus extra pages (trace per chain, posterior-correlation heatmap) in the multi-page PDF, and a Word report.

## Models (5 cards, parallel)
Job Card 1: JOB Write the generating cell-means LBA definition and its EMC2 fitting definition. FOLDER models/lba_cellmeans/ (new). Parameters: v and log sv per accumulator x valence cell (sv_lRneutral:vg6 fixed to log 0), log B per accumulator, log A, log t0.
Job Card 2: FOLDER models/lba_cellmeans_fixA/ (new). As card 1 with log A fixed at log 0.4 (constant).
Job Card 3: FOLDER models/lba_constrained/ (new). Tracking v and log sv per valence cell (6+6); non-tracking v one per direction (2); non-tracking sv fixed 1 in all cells; B per accumulator; A; t0 (18 free). Includes the map from generating cell parameters to this model's parameters (non-tracking v = mean of the three cells).
Job Card 4: FOLDER models/lba_constrained_fixA/ (new). As card 3 with log A fixed at log 0.4 (17 free).
Job Card 5: FOLDER models/lba_linear/ (new). v and log sv = accumulator x direction intercept (intensity 1) + accumulator x direction x intensity slope (intensity coded 0-2; direction pos = 6,7,8; neg = 4,3,2); sv_lRneutral:directionpos intercept fixed log 0; B per accumulator; A; t0 (19 free). Includes the map from generating cell parameters (least-squares line through the three cells).

## Simulation (5 cards; after the models)
Job Card 6: FOLDER simulation/lba_cellmeans_recovery/ (new)   fitted model lba_cellmeans   existing results from blr_test (N 50, 100)
Job Card 7: FOLDER simulation/lba_cellmeans_fixA_recovery/ (new)   lba_cellmeans_fixA   existing from fixA_test (N 50 only)
Job Card 8: FOLDER simulation/lba_constrained_recovery/ (new)   lba_constrained   existing from con_test (N 50, 100)
Job Card 9: FOLDER simulation/lba_constrained_fixA_recovery/ (new)   lba_constrained_fixA   waits for the running conA_test fits (N 50, 100)
Job Card 10: FOLDER simulation/lba_linear_recovery/ (new)   lba_linear   existing from lin_test (N 50, 100)
Each: main.R with the five-header parameter-recovery layout; code/ numbered scripts; artifacts/ (true_population.rds, true_parameters.rds, simulated_data.rds, fit, draws_sbj.rds, draws_pop.rds, recovered_parameters.rds, recovery_table.rds with N suffix); output/ (figures, multi-page PDF, Word report); summary.md written by Malka. The old simulation/emc2_recovery stays untouched.
