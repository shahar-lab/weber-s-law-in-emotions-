# Analysis Notebook: Weber's Law in Emotions — LBA Simulation

**Model:** Linear Ballistic Accumulator (LBA), simulated via `EMC2`
**Date Created:** 2026-09-13

## 1. Hypotheses
Testing whether accuracy and RT distributions for emotional-valence judgments differ
depending on whether Weber's Law holds for the drift-rate process:

- **Dataset A (`weber_holds`):** between-trial drift SD (`sv`) scales proportionally
  with the mean drift rate of the condition (constant coefficient of variation).
- **Dataset B (`weber_violated`):** `sv` is constant across all conditions regardless
  of drift rate magnitude.

## 2. Variables
* **Design:** 6 valence levels (2, 3, 4, 6, 7, 8; level 5/neutral absent). Drift rate
  depends on extremity (distance from neutral), U-shaped: levels 2/8 (most extreme) →
  high drift; levels 4/6 (near-neutral) → low drift; levels 3/7 → intermediate.
* **Fixed across all conditions and both datasets:** threshold (`b`), start-point
  variability (`A`), non-decision time (`t0`), incorrect-accumulator drift (`v_mismatch`).
* **Varies by condition/dataset:** mean drift rate (`v`), between-trial drift SD (`sv`).
* **Hierarchical structure:** 70 simulated participants per dataset, with
  participant-level parameters varying around group-level means (random effects).
* **Trials:** ~20 trials per condition per participant (~120/participant, ~8,400/dataset).
* **Outcome variables:** accuracy/choice and RT per trial.

## 3. Findings / Summary
Five standalone figures in `output/` (PDF+PNG each), comparing `weber_holds` vs
`weber_violated`:
* `rt_pooled_violin` / `rt_pooled_halfeye` — RT distribution by valence, pooled across
  correct/incorrect (violin+boxplot and ggdist half-eye versions).
* `rt_split_violin` / `rt_split_halfeye` — RT distribution by valence, split into
  Correct/Incorrect facets (violin+boxplot and half-eye versions).
* `accuracy_by_valence` — proportion correct by valence.

Plus `output/summary_report.html` — a plain, self-contained HTML file (no
pandoc/rmarkdown dependency, built directly via `knitr::kable()` + `writeLines()`)
with two tables: (1) accuracy by valence level x dataset, (2) RT statistics (median,
mean, 10th percentile, 90th percentile, in seconds, pooled across correct/incorrect)
by valence level x dataset.

Both datasets show faster, tighter RTs at extreme valence (2, 8) than near-neutral
valence (4, 6), consistent with the extremity-driven drift design. Accuracy tells the
core Weber's-law story clearly: `weber_holds` ranges ~73-95% with a mild extremity
effect, while `weber_violated` ranges ~63-99%, dipping sharply at near-neutral levels
(4, 6) — holding `sv` constant regardless of drift magnitude hurts accuracy far more
when drift is already weak, whereas scaling `sv` down with drift (Weber's law)
dampens that effect. The divergence between the two datasets is large and clearly
visible at near-neutral valence (roughly a 10-point accuracy gap).

The `sv/v` ratio (the literal Weber's-law relationship) was checked directly and is
unaffected by any of the `v_mismatch` tuning below: in `weber_holds`, `sv/v = 0.3`
(= `weber_k`) at every valence level exactly, as designed; in `weber_violated`, `sv/v`
correctly varies by level (since `sv` is held constant while `v` changes) — `v_mismatch`
only ever affects the *incorrect* accumulator's drift (an accuracy lever), never `sv`
or the correct accumulator's `v`, so it does not touch Weber's-law adherence in either
dataset.

**Revision history:**
* 2026-09-13 (v1): drift means 3.0/2.1/1.25, mismatch drift -1 → accuracy too high
  (~94-100%) across all conditions, not diagnostic of the Weber's-law effect.
* 2026-09-13 (v2): drift means lowered to 1.8/1.2/0.7 (researcher-directed, ~40%
  proportional reduction) and mismatch drift raised from -1 to 0 (the negative mismatch
  value kept the correct accumulator winning almost every trial regardless of drift
  magnitude, so lowering drift alone didn't move accuracy) — accuracy still too high
  (~85-100%).
* 2026-09-13 (v3): mismatch drift raised further from 0 to 0.4 (researcher-directed;
  0.6 was considered but rejected as too aggressive since it would meet/exceed the
  near-neutral match drift of 0.7 and collapse those levels toward chance) — accuracy
  realistic and diagnostic: `weber_holds` ~81-96%, `weber_violated` ~68-99%.
* 2026-09-14 (v4, current): mismatch drift raised to 0.5, briefly reverted to 0.4,
  then raised back to 0.5 at researcher request — 0.5 is the current value. Accuracy:
  `weber_holds` ~73-95%, `weber_violated` ~63-99%.
* 2026-09-13: figures reworked from one 3-panel composite into 5 separate standalone
  PNG/PDF files per researcher request, adding ggdist half-eye versions alongside the
  original violin plots.
* 2026-09-14: `rt_split_violin` and `rt_split_halfeye`'s y-axis changed from per-facet
  free scaling to a shared fixed window, tightened per researcher request from 10s to
  7s, for a more consistent and readable axis across the Correct/Incorrect facets.

## Confirmed values
* Numeric drift-rate means per level (current): 2/8 → 1.8, 4/6 → 0.7, 3/7 → 1.2
  (confirmed by researcher 2026-09-13, ~40% proportional reduction from the original
  3.0/1.25/2.1 after accuracy was found too high across all conditions).
* Mismatching accumulator's `v` (current): 0.5 (confirmed by researcher 2026-09-14,
  after a brief revert to 0.4 in between).
* `rt_split_violin`/`rt_split_halfeye` y-axis: shared fixed window, 0-7s (confirmed by
  researcher 2026-09-14, tightened from an initial 10s).

## Model structure notes
* EMC2's LBA requires a stimulus factor `S` (correct-response identity, sharing levels
  with the response options) separate from the `valence` factor; drift (`v`) is
  formulated as `v ~ 0 + valence:lM`, where `lM` (match) comes from `matchfun` comparing
  `S` to the latent response. The matching accumulator's drift uses each level's
  extremity-based mean; the mismatching accumulator uses the shared `v_mismatch`
  constant (`define_design.R`, currently 0.5 — see Confirmed values above for why).
  `v_mismatch` is independent of the `sv`/`v` relationship that defines Weber's-law
  adherence (see Findings/Summary above) — it only ever adjusts overall accuracy.
* `A`, `B` (with threshold `b = A + B`), `t0`, and `sv` are estimated on the **log
  scale** in EMC2's LBA (see `?EMC2::LBA`); natural-scale target values are set in
  `define_design.R` (`b = 1.5`, `A = 0.5`, `t0 = 0.2`) and log-transformed before being
  passed to `make_data()`.

## ASSUMED tags (open for researcher confirmation)
* `weber_k = 0.3` as the proportionality coefficient for Dataset A's `sv = k * v`.
* Dataset B's constant `sv` set to `weber_k * mean(mean_v)` (mid-range, so overall noise
  is comparable to Dataset A).
* Fixed natural-scale values: `b = 1.5`, `A = 0.5`, `t0 = 0.2`.
* Between-subject SDs for hierarchical variability: 15% of each group-level mean.
* Standard 2-accumulator (binary choice) LBA setup.

## Verification
* Ran end-to-end via `main.R` on 2026-09-14 with the current (v_mismatch=0.5) values.
  Both datasets generate without error; accuracy by valence level: `weber_holds`
  2→0.95, 3→0.90, 4→0.73, 6→0.74, 7→0.91, 8→0.93; `weber_violated` 2→0.99, 3→0.89,
  4→0.63, 6→0.63, 7→0.89, 8→0.99 — realistic and strongly diagnostic of the
  Weber's-law effect, with a clear ~10-point accuracy gap between datasets at
  near-neutral valence. Faster RTs at extreme valence than near-neutral, consistent
  with the extremity-driven drift-rate design. `sv/v` ratio verified directly:
  constant at 0.3 across all valence levels in `weber_holds`, varying (0.206-0.529)
  in `weber_violated` — Weber's law adherence is unaffected by the v_mismatch tuning.
  All 5 figures (10 files) regenerated and visually confirmed readable (fixed 0-7s
  y-axis on the split RT plots; 99.5th percentile zoom on the pooled RT plots).
