# Analysis Notebook: Weber-Holds Mimicry of Weber-Violated

**Model:** Linear Ballistic Accumulator (LBA), simulated via `EMC2`
**Date Created:** 2026-09-14

## 1. Hypotheses
The sibling project `simulation/weber_lba_simulation/` showed that `weber_holds` and
`weber_violated` produce similar RT central tendency, and that `weber_violated`'s
accuracy pattern (sharper dip at near-neutral valence) looked more consistent with
observed data. This raised a concern: is accuracy alone (or accuracy + RT central
tendency) enough to behaviorally distinguish "Weber's law holds" from "Weber's law
violated" — or can a Weber's-law-adherent model be tuned (via a different
mismatch-accumulator drift, `v_mismatch`) to mimic the violated model's accuracy
pattern, making the two indistinguishable from this kind of summary data?

This simulation tests that directly: keep the Weber's-law relationship
(`sv = weber_k * mean_v`, `weber_k = 0.3`) fully intact, and vary only `v_mismatch`
across a small grid of values above the sibling project's current 0.5, to see whether
any candidate reproduces `weber_violated`'s accuracy-by-valence curve — and if so,
whether the resulting RT distributions also converge.

## 2. Variables
* **Design:** identical to `weber_lba_simulation`'s `weber_holds` dataset in every
  respect except `v_mismatch`: 6 valence levels (2,3,4,6,7,8), extremity-based drift
  means (2/8 → 1.8, 4/6 → 0.7, 3/7 → 1.2), `sv = weber_k * mean_v` with
  `weber_k = 0.3` (unchanged — this must stay adherent to Weber's law), fixed
  `b = 1.7`, `A = 0.5`, `t0 = 0.2`, 70 participants, 20 trials/condition/participant,
  15%-of-mean between-subject SD.
* **Manipulated:** `v_mismatch` across a grid of candidate values: 0.6, 0.7, 0.8
  (ASSUMED — spaced 0.1 above the sibling project's current 0.5, stopping short of
  0.7 itself as a match-drift value to avoid collapsing near-neutral levels to
  chance outright; see `code/define_design.R`).
* **Reference:** `weber_violated.rds`, read read-only from
  `../weber_lba_simulation/artifacts/` (not regenerated).
* **Outcome variables:** accuracy/choice and RT per trial, per candidate dataset.

## 3. Findings / Summary
Output in `output/`: `mimicry_comparison.html` (accuracy + RT tables, all 3
candidates vs. `weber_violated`), `accuracy_comparison.{pdf,png}`,
`rt_comparison_halfeye.{pdf,png}`. `mimicry_comparison.html`'s Table 2 (RT
statistics) is laid out with each dataset (3 candidates + `weber_violated`) in its
own grouped column block (median/mean/10th pct/90th pct RT), mirroring Table 1's
wide-by-dataset accuracy layout, per researcher request (2026-09-14) to keep
datasets visually separated rather than stacked as rows.

**Accuracy:** no single `v_mismatch` value in the tested grid (0.6/0.7/0.8) reproduces
`weber_violated`'s accuracy-by-valence shape. `v_mismatch = 0.6` comes closest at the
near-neutral levels (4,6: 0.629/0.614 vs. `weber_violated`'s 0.641/0.639) but
undershoots at the extreme levels (2,8: 0.924/0.935 vs. 0.991/0.989). Raising
`v_mismatch` further (0.7, 0.8) overshoots the near-neutral dip *past*
`weber_violated` (down to 0.364-0.383 at 0.8) while extreme-level accuracy keeps
falling too — a single flat `v_mismatch` shift can't reproduce `weber_violated`'s
sharper, more localized near-neutral dip while keeping extreme-valence accuracy high;
that dip's shape is a genuine, structural difference between the two `sv` schemes,
not just an intensity difference `v_mismatch` alone can equalize. This pattern held
both before and after the `b: 1.5 → 1.7` sync with the sibling project — the
threshold change shifted every dataset's RT later but did not change this
qualitative conclusion.

**RT:** all three candidates' RT distributions (median, mean, 10th/90th percentile,
and the full distribution shape, shown as half-eyes in `rt_comparison_halfeye`) are
nearly indistinguishable from `weber_violated`'s at
every valence level, regardless of accuracy differences. This confirms the
researcher's original concern: RT central tendency and distribution shape give
almost no leverage to distinguish the Weber's-law-holds vs. violated hypotheses in
this design — the fine shape of the accuracy-by-valence curve (specifically, how
sharp/localized the near-neutral dip is) is the primary distinguishing signal
available from behavior, not RT.

## Confirmed values
* (None yet — this is an exploratory sweep, not a final model choice; the researcher
  has not adopted any of the tested `v_mismatch` values as a replacement for
  `weber_lba_simulation`'s own parameters.)

## ASSUMED tags (open for researcher confirmation)
* `v_mismatch_grid <- c(0.6, 0.7, 0.8)` — candidate values to test.
* Candidate dataset/artifact naming: `weber_holds_vmismatch_<value>` (e.g.
  `weber_holds_vmismatch_0.6`), saved as `.rds` + `.csv` in `artifacts/`.
* Between-subject SD: 15% of each group-level mean (carried over from
  `weber_lba_simulation`'s convention).
* Fixed natural-scale `b = 1.7`, `A = 0.5`, `t0 = 0.2`, kept in sync with
  `weber_lba_simulation` (originally 1.5, updated 2026-09-14 when the sibling
  project's `b` changed).

## Verification
* Ran end-to-end via `main.R` on 2026-09-14. All three candidate datasets generate
  without error (8,400 rows each), read-only `weber_violated` reference loads
  correctly from the sibling project's artifacts/, both HTML tables and both
  comparison plots (RT half-eye, accuracy line+point) render with real computed
  numbers matching each other and the sibling project's previously-verified figures.
