# Analysis Notebook: DR Sweep, Weber Holds vs Violated

**Model:** Linear Ballistic Accumulator (LBA), simulated via `EMC2`
**Date Created:** 2026-10-06

## 1. Hypotheses
Can higher drift rates (DR) under either Weber scheme reproduce the accuracy and RT pattern seen in `weber_lba_simulation`? The observed (empirical) pattern is judged by the researcher by eye; no numeric match criterion.

- **Holds:** `sv = 0.3 * v` per valence level.
- **Violated:** one constant `sv = 0.3 * mean(scaled match drifts)`, recomputed for each DR factor.

## 2. Variables
* **Manipulated:** DR factor (x1, x1.5, x2, x3) multiplying the match drifts (2/8 = 1.8, 3/7 = 1.2, 4/6 = 0.7); Weber scheme (holds, violated).
* **Fixed (same as `weber_lba_simulation`):** mismatch drift 0.5, `b = 1.7`, `A = 0.5`, `t0 = 0.2`, 70 participants, 20 trials per condition, 15% between-subject SD, valence levels 2, 3, 4, 6, 7, 8.
* **Outcomes:** accuracy and RT per trial.
* 8 datasets in `artifacts/` (`weber_<scheme>_x<factor>.rds/.csv`).

## 3. Findings / Summary
Outputs in `output/`: `04_dr_sweep_tables.html` (accuracy and RT tables), `05_accuracy_by_dr` and `06_rt_by_dr` (PDF + PNG, faceted by DR factor).

* **Accuracy:** raising DR lifts accuracy everywhere. Under Weber holds the near-neutral dip (levels 4, 6) shrinks from about 0.75 at x1 to about 0.95 at x3, so the curve flattens. Under violated the dip stays (about 0.62 at x1, about 0.72 at x1.5, about 0.75 at x2, about 0.80 at x3) while extreme levels stay near ceiling. The gap between schemes at near-neutral valence therefore widens as DR grows.
* **RT:** RT shortens as DR rises (median at valence 4/6 about 2.1s at x1, about 0.85s at x3). Holds and violated medians stay close at every DR; violated has a slightly tighter spread at extreme valence.
* The `rt_by_dr` half-eye for DR x1.5 violated at valence 6 shows a flat-topped density wedge, a plotting artifact of `stat_halfeye` density bounds, not data.

## Confirmed values
* DR factors x1, x1.5, x2, x3, scaling match drifts only (researcher, 2026-10-06).
* Holds `sv = 0.3 v`; violated constant `sv` (researcher, 2026-10-06).

## ASSUMED tags
* Violated constant `sv = 0.3 * mean(scaled match drifts)`, same rule as `weber_lba_simulation`, recomputed per factor.
* Between-subject SD 15% of group means.

## Verification
* Ran end-to-end via `main.R` on 2026-10-06; all 8 datasets, the HTML tables and both figures were produced, and the figures were checked visually. The x1 datasets reproduce the accuracy pattern of `weber_lba_simulation`.
