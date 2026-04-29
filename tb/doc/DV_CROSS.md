# DV Cross — mu3e_lvds_controller (SV rebuild)

**Companion docs:** [DV_PLAN.md](DV_PLAN.md), [DV_HARNESS.md](DV_HARNESS.md),
[DV_BASIC.md](DV_BASIC.md), [DV_EDGE.md](DV_EDGE.md),
[DV_PROF.md](DV_PROF.md), [DV_ERROR.md](DV_ERROR.md),
[DV_FORMAL.md](DV_FORMAL.md), [DV_COV.md](DV_COV.md),
[BUG_HISTORY.md](../BUG_HISTORY.md)

This document defines the cross-coverage targets, the per-bucket
no-restart `bucket_frame` runs, and the cross-bucket no-restart
`all_buckets_frame` run. These three are mandatory closure baselines
per the DV-workflow contract.

---

## 1. Cross-coverage Intent

Cross coverage is collected through SVA `cover` directives and a
discrete counter array (Questa FSE has no `covergroup`). Every cross
below is a labelled `cover` in `tb/uvm/sva/lvds_coverage.sv`.

### 1.1 Build-axis crosses

| Cross | Axes | Bins | Goal |
|-------|------|------|------|
| `xb_geometry` | `(N_LANE, N_ENGINE)` | 4 × 4 | every legal compile point hit |
| `xb_topology` | `(ROUTING_TOPOLOGY, N_ENGINE)` | 4 × 4 | each topology used at every engine count |
| `xb_score` | `(SCORE_WINDOW_W, score_accept, score_reject)` | 3 × 3 × 3 | full-range score parameterisation hit |
| `xb_sync` | `(SYNC_PATTERN, N_LANE)` | 3 × 4 | every legal sync pattern at every lane count |

### 1.2 Behaviour crosses

| Cross | Axes | Bins | Goal |
|-------|------|------|------|
| `xc_engine_pool` | `(engine_pool_occupancy, mode_mask)` | (`0..N_ENGINE`) × 3 | full pool utilisation × mode |
| `xc_steering_queue` | `(steer_queue_count, glitch_class)` | (`0..STEER_QUEUE_DEPTH`) × 5 | every glitch class produces every queue depth |
| `xc_train_to_steady` | `(train_state, steer_state)` | states × states | every legal composite state hit |
| `xc_counter_sat` | `(counter_idx, sat_event)` | 10 × 2 | every counter saturated at least once |
| `xc_lane_select` | `(LANE_SELECT, counter_idx)` | `N_LANE` × 10 | every lane × counter slot read at least once |

### 1.3 Error-class crosses

| Cross | Axes | Bins | Goal |
|-------|------|------|------|
| `xe_glitch_class` | `(glitch_class, lane_idx, mode_mask)` | 7 × `N_LANE` × 3 | every glitch class hit on every lane in every mode |
| `xe_recovery` | `(error_event, recovery_path)` | 7 × 4 | every error class recovers via every documented path |
| `xe_steering_overflow` | `(N_ENGINE, hot_lane_count)` | 4 × `N_LANE` | overflow scenario hit at each engine count |

### 1.4 Reset crosses

| Cross | Axes | Bins | Goal |
|-------|------|------|------|
| `xr_reset_during_op` | `(reset_class, dut_state)` | 2 × 8 | both reset domains hit during every major DUT state |
| `xr_lane_state_at_reset` | `(lane_idx, lane_state)` | `N_LANE` × 6 | every lane state observed at reset entry |

---

## 2. `bucket_frame` Definitions

`bucket_frame` runs all cases of a single bucket in case-id order
inside one continuous timeframe, no DUT reset between cases.
Mandatory baselines; `DV_COV.md` records the merged code coverage
for these runs separately from the isolated ordered-merge totals.

### 2.1 BASIC `bucket_frame`

- order: `B001 → B002 → ... → B080`
- skip-bucket-frame cases: none planned (every B-case is reset-clean)
- expected runtime: ~30s simulator wall on Questa FSE
- expected merged-coverage delta vs. isolated ordered merge:
  ≤ +2 statement, +1 branch (cross-case interactions)

### 2.2 EDGE `bucket_frame`

- order: `E001 → E002 → ... → E050`
- skip-bucket-frame cases: `E028` (intentional SVA failure — must run
  isolated only); `E040` (only legal in widened-AVMM_ADDR_W build)
- expected runtime: ~45s

### 2.3 PROF `bucket_frame`

- order: `P001 → P002 → ... → P040`
- skip-bucket-frame cases: `P025` (10G-symbol soak — runs isolated
  only)
- expected runtime: ~15 min (dominated by P040)

### 2.4 ERROR `bucket_frame`

- order: `X001 → X002 → ... → X050`
- skip-bucket-frame cases: `X035 → X041` (intentional SVA-violation
  probes; run isolated only)
- expected runtime: ~5 min

---

## 3. `all_buckets_frame` Definition

Run every signoff case across every bucket in this order, no DUT
reset between buckets:

```
B001..B080 → E001..E050 → P001..P040 → X001..X050
```

Skipped cases (the union of the per-bucket skip lists):

- `E028, E040`
- `P025`
- `X035, X036, X037, X038, X039, X040, X041`

Expected runtime: ~25 min on Questa FSE primary build.

`DV_COV.md` carries the `all_buckets_frame` merged code coverage as a
separate row from any per-bucket merged total.

---

## 4. Cross Closure Targets

| Cross | Target |
|-------|--------|
| `xb_geometry` | 100% (every primary/legacy/topology/score/sync build hit) |
| `xb_topology` | 100% |
| `xb_score` | ≥ 90% (corners with `score_accept = SCORE_WINDOW_W` may need long random) |
| `xb_sync` | 100% (only 12 bins) |
| `xc_engine_pool` | 100% |
| `xc_steering_queue` | ≥ 95% |
| `xc_train_to_steady` | 100% (every legal composite state) |
| `xc_counter_sat` | 100% (P-bucket already drives every counter to saturation) |
| `xc_lane_select` | 100% (B068 + P038 cover this) |
| `xe_glitch_class` | ≥ 95% |
| `xe_recovery` | 100% |
| `xe_steering_overflow` | ≥ 90% |
| `xr_reset_during_op` | 100% |
| `xr_lane_state_at_reset` | ≥ 95% |

Total cross closure target: ≥ 95%, with explicit waivers in
`DV_REPORT.md` for any sub-target below 100%.

---

## 5. Per-build Cross Tables

For each `BUILD=<tag>`, the per-bucket merged + cross totals must be
recorded in `DV_COV.md`. Builds carry the following cross expectation:

| BUILD | xb_geometry | xb_topology | xb_score | xb_sync | xc_* | xe_* | xr_* |
|-------|-------------|-------------|----------|---------|------|------|------|
| `primary` | (12,1) | (full_xbar,1) | full | K28.5 | full | full | full |
| `legacy` | (9,9) | (full_xbar,9) | partial | K28.5 | full | full | full |
| `topo_butterfly_h` | (12,4) | (butterfly_half,4) | partial | K28.5 | full | full | full |
| `topo_butterfly_q` | (12,4) | (butterfly_quarter,4) | partial | K28.5 | full | full | full |
| `topo_nearest_k` | (12,4) | (nearest_k,4) | partial | K28.5 | full | full | full |
| `score_w6` | (4,2) | (full_xbar,2) | window=6 | K28.5 | full | full | full |
| `score_w16` | (4,2) | (full_xbar,2) | window=16 | K28.5 | full | full | full |
| `sync_k280` | (4,1) | (full_xbar,1) | partial | K28.0 | full | full | full |
| `sync_k237` | (4,1) | (full_xbar,1) | partial | K23.7 | full | full | full |
| `lane1` | (1,1) | (full_xbar,1) | partial | K28.5 | partial | partial | partial |
| `lane4` | (4,2) | (full_xbar,2) | partial | K28.5 | full | full | full |

`partial` means a build that only contributes some bins, with the
remaining bins covered by other builds and merged across the matrix.
The signoff totals merge across the `primary` build's full coverage
plus the per-axis builds' contributions.

---

## 6. Continuous-frame Sanity

Per the DV-workflow contract, `bucket_frame` and `all_buckets_frame`
runs are *separate* coverage views. Their merged totals may be lower
or higher than the isolated ordered-merge totals because:

- reset boundaries between cases are absent (some toggle bins may not
  hit because the reset never asserts during the run);
- inter-case interactions can hit bins that the isolated cases do not
  (e.g. counter saturation across cases that individually do not
  saturate);
- some cases that run isolated cannot run in `bucket_frame` (the skip
  list above) and contribute zero to the continuous baseline.

`DV_COV.md` keeps both views distinct. Closure requires both to meet
their targets.
