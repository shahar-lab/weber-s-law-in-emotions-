# Parameter recovery: hierarchical LBA (EMC2 3.5.0) for "Weber's Law in emotions"

## Run
From this folder (`simulation/emc2_recovery/`), with R 4.4 and EMC2 >= 3.5:

```
Rscript main.R pilot            # 1 dataset, 20 participants, short chains (pipeline test only)
Rscript main.R tier1 6          # N = 100, 20 reps x {perception, action}; 6 parallel fits
Rscript main.R tier2            # N = 50 and 150
Rscript main.R tier3            # half-size Weber effect, N = 50/100/150
```

Everything is resumable: finished datasets/fits are skipped, interrupted fits continue from their
autosave in `output/<tier>/fits_raw/`. Individual stages: `02_simulate.R <tier>`, `03_fit.R <tier> [workers]`,
`04_evaluate.R <tier>`. `Rscript 02_simulate.R calibrate` prints accuracy/RT implied by the generating values.

## Files
| file | role |
|---|---|
| `01_config.R` | **all** editable settings: generating values, scenarios, trial counts, exclusions, priors, ROPE grid, tiers |
| `02_simulate.R` | simulate participant parameters + data, apply preregistered exclusions (a: no response in 10 s, b: RT < 150 ms, c: per-participant |RT - median| > 3 MAD, two-sided) |
| `03_fit.R` | fit with EMC2 (`make_emc` -> `fit`), save slim posterior summaries (`results/*.rds`) |
| `04_evaluate.R` | convergence, group/participant recovery, trade-offs, Weber/v steps, decision rules, H3 |
| `main.R` | runs 02 -> 03 -> 04 for one tier |

Outputs per tier in `output/<tier>/`: `data/`, `fits_raw/` (large; can be deleted after `results/` exists), `results/`, `tables/` (CSV), `figures/` (PDF).

## Model as implemented
- Accumulators `emotional`/`neutral` (EMC2's `lR`); factor `valence_group` is called `vg` internally (EMC2 forbids underscores).
- `v ~ 0 + lR:vg`, `sv ~ 0 + lR:vg`, `B ~ 0 + lR:vg`, `A ~ 1`, `t0 ~ 1`; 37 free parameters.
- sv reference cell fixed to 1: **`sv_lRneutral:vg6`** (non-tracking accumulator, weakest positive cell). It is not part of any Weber step, so the step estimates keep their uncertainty.
- Intensity-tracking accumulator: `emotional` for positive images (6<7<8), `neutral` for negative images (4<3<2).
- Trials per participant: 22/24/23/24/23/22 for valence 2/3/4/6/7/8 = 138 (preregistered table).

## Choices that are mine, not preregistered (change in `01_config.R`)
1. **Priors.** Group means: v ~ N(1, 1), log sv ~ N(0, 0.3), log B ~ N(log 1.2, 0.5), log A ~ N(log 0.4, 0.5), log t0 ~ N(log 0.3, 0.4); EMC2 default for the variance prior. Same mean for every cell of a parameter, so nothing favours the hypothesised ordering. Limitation: with cell-means coding the prior is on cells, not on the differences between them; a prior that shrinks the *steps* toward 0 would require contrast coding.
2. **ROPE.** Not preregistered; results are reported for half-widths 0, 0.05, 0.10, 0.20 (`rope_grid`), `rope_main = 0.10` for figures.
3. **Between-participant covariance.** "Blocked": parameters of the same type (all v, all sv, all B) may correlate with each other (generated with r = 0.3); v, sv, B, A and t0 are independent of each other. A full 37 x 37 covariance would be far slower and is not needed for this question.
4. **Decision rule.** Per step: lower bound of the 90% HDI > 0 (or > ROPE). Also reported: all four steps ("all_4_steps"), any step, and the mean of the four steps (`*_mean4`).

## Generating values (natural scale)
Tracking v 1.5/2.1/2.7, non-tracking v 0.8; non-tracking sv 1.0; tracking sv starts at 0.8 and grows as `v^strength`
(perception strength 1 -> log-sv steps 0.34 and 0.25; action 0 -> no steps; `perception_half` 0.5);
B 1.5 (emotional) / 1.7 (neutral); A 0.4; t0 0.30 s. Between-subject SDs: v 0.25, log sv 0.15, log B 0.20, log A 0.25, log t0 0.15.
Implied (calibration, many trials): P(tracked option) 60-95% across cells, median RT 0.9-1.3 s, ~6% of trials removed by the MAD rule, almost none by rules (a)/(b).
The action scenario doubles as the null case for H1 and, paired with perception, for H3 (the `action - action` pairs estimate the H3 false-positive rate).

## Status / honest caveats
- Pipeline tested end to end on the pilot (simulate -> fit -> extract -> evaluate -> figures). The H3 branch was only checked with a synthetic pair, not on real fits.
- **The pilot did not converge** (max R-hat about 11, ESS about 9; 20 participants, deliberately short chains, 17.7 min). Its recovery numbers are meaningless; it only proves the code runs.
- **Run times for the real tiers are still unmeasured.** Before launching tier1, time one converged N = 100 fit and use it to budget the tier (the stop rule is R-hat < 1.1, ESS > 200 on group means and participant parameters; `max_tries` caps effort). Fits that hit the cap are flagged by the convergence table, and should be reported, not silently dropped.
- Expect weak participant-level recovery of sv (about 20 trials per cell); the study is meant to quantify exactly that.
- Windows: EMC2 parallelises only across chains, so each fit uses 3 cores and tiers parallelise across datasets (`workers` in `01_config.R`).
