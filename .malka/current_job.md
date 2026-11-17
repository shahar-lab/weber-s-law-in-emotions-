# Approved Job Card (confirmed by the researcher, 2026-11-17)

Job Card
JOB
Rerun the lba_constrained_fixA recovery for N = 100 only, with basic trimming (no response or RT > 10 s; RT < 0.15 s) and no MAD cutoff
FOLDER
simulation/lba_constrained_fixA_noMAD_recovery/ (new; clone of simulation/lba_constrained_fixA_recovery/)
ROUTED READS
- 02-analysis/smart_clone.md
- parameter_recovery/context.md
- parameter_recovery/template_summary.md
- 04-simulations/references/how-to-build-a-recovery-pipeline.md
- 04-simulations/references/how-to-read-recovery.md
CHECKS
- Source job-folder
- What changes in the clone
- Which `models/` definition generates and which is fitted
- Population location and scale per parameter (set in `main.R`)
- `n_subjects`, `n_trials`, `n_sessions`
- Sampler (Stan, brms, or other)
- Logistic transform onto the unit interval, or none
- Success criteria: correlation, bias, precision
SPECIFICATION
- Source job-folder: simulation/lba_constrained_fixA_recovery/ (left untouched). Copy code/ and main.R; empty artifacts/ and output/.
- Changes in the clone: n_subjects_set = 100 only; exclusions = (a) no response or RT > 10 s, (b) RT < 0.15 s; MAD step removed; legacy fit reuse switched off (legacy_run_dir = NULL) so the model is fitted fresh.
- Generating model: lba_cellmeans; fitted model: lba_constrained_fixA (A fixed at 0.4, 17 free).
- Population: unchanged from the source main.R (tracking v 1.5/2.1/2.7; non-tracking v 0.8, sv 1.0; tracking sv0 0.8, Weber strength 1; B 1.5/1.7; A 0.4; t0 0.30; SDs v 0.25, sv 0.15, B 0.20, A 0.25, t0 0.15; within-family cor 0.3).
- Seed: unchanged (base_seed 20261106, scenario 1, replicate 1), so agents and raw data are identical to the source run.
- n_trials 22/24/23/24/23/22 (valence 2/3/4/6/7/8), n_sessions 1.
- Sampler: EMC2, 3 chains, blocks of 1000, R-hat < 1.1, ESS > 200 on mu and alpha, max 20 blocks; priors from models/lba_constrained_fixA/lba_constrained_fixA_emc2.R.
- No unit-interval transform.
- Recovery criteria: none; report without a verdict (as in the source).
- After the fit: report population-level bias next to the MAD-trimmed run.
