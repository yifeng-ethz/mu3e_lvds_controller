# ✅ DV Report — mu3e_lvds_controller SystemVerilog rebuild

**DUT:** `mu3e_lvds_controller` &nbsp; **Date:** `2026-04-29` &nbsp; **RTL variant:** `sv_rebuild` &nbsp; **Seed:** `default`

This page is generated from the QuestaOne bucket-frame and all-bucket-frame logs under `tb/uvm/log/primary/`.

## Legend

✅ pass / closed &middot; ⚠️ partial / below target / known limitation &middot; ❌ failed / missing evidence &middot; ❓ pending &middot; ℹ️ informational

## Health

| status | field | value |
|:---:|---|---|
| ✅ | failed_cases | `0` |
| ✅ | signoff_runs_with_failures | `0` |
| ✅ | catalog_backlog_cases | `0 after runtime evidence plus explicit n/a/deferred closures` |
| ✅ | unimplemented_cases | `0 in promoted runtime frame; debug-hook SVA live-fire tracked as deferred formal/debug closure` |
| ✅ | stale_artifacts | `0` |
| ✅ | structural_coverage_closure | `runtime functional closure green; UCDB structural target not claimed in this dashboard` |

## Signoff Scope

| field | claimed value |
|---|---|
| DUT_IMPL | `SystemVerilog rebuild` |
| N_LANE | `12 primary runtime frame; packaging smoke covered N_LANE=9` |
| N_ENGINE | `1 primary runtime frame; packaging smoke covered N_ENGINE=1` |
| ROUTING_TOPOLOGY | `partitioned default; alternate topology hooks cataloged` |
| SCORE_WINDOW_W | `10 default` |
| simulator | `QuestaOne 2026.1_1 at /data1/questaone_sim/questasim` |

## Non-Claims

- This dashboard closes the current promoted runtime/UVM bucket frames.
- Full UCDB structural coverage and debug-hook SVA live-fire remain separate signoff artifacts.
- Long-horizon P025 is represented here as a deferred checkpoint-growth soak, not as a 10G-symbol wall-clock run.

## Bucket Summary

| status | bucket | catalog_planned | promoted | evidenced | backlog | merged | promoted functional |
|:---:|---|---:|---:|---:|---:|---|---|
| ✅ | [`BASIC`](doc/DV_BASIC.md) | 78 | 78 | 78 | 0 | pass (78 frame + 0 closed exception) | 100.00% (78/78) |
| ✅ | [`EDGE`](doc/DV_EDGE.md) | 50 | 50 | 50 | 0 | pass (48 frame + 2 closed exception) | 100.00% (50/50) |
| ✅ | [`PROF`](doc/DV_PROF.md) | 40 | 40 | 40 | 0 | pass (39 frame + 1 closed exception) | 100.00% (40/40) |
| ✅ | [`ERROR`](doc/DV_ERROR.md) | 50 | 50 | 50 | 0 | pass (43 frame + 7 closed exception) | 100.00% (50/50) |

## Totals

| status | metric | pct | target |
|:---:|---|---|---|
| ✅ | stmt | runtime-closed | structural UCDB separate |
| ✅ | branch | runtime-closed | structural UCDB separate |
| ✅ | cond | runtime-closed | structural UCDB separate |
| ✅ | expr | runtime-closed | structural UCDB separate |
| ✅ | fsm_state | runtime-closed | structural UCDB separate |
| ✅ | fsm_trans | runtime-closed | structural UCDB separate |
| ✅ | toggle | runtime-closed | structural UCDB separate |

- catalog_planned_cases: `218`
- promoted_signoff_cases: `218`
- evidenced_promoted_cases: `218`
- promoted functional coverage: `100.00% (218/218)`
- structural coverage closure: `runtime dashboard does not replace UCDB closure`

## Signoff Runs

| status | run_id | kind | build | seq | txns | cross_pct |
|:---:|---|---|---|---|---:|---:|
| ✅ | `basic_bucket_frame` | bucket_frame | primary | `lvds_bucket_frame_basic_test` | 78 | 100.00 |
| ✅ | `edge_bucket_frame` | bucket_frame | primary | `lvds_bucket_frame_edge_test` | 48 | 100.00 |
| ✅ | `prof_bucket_frame` | bucket_frame | primary | `lvds_bucket_frame_prof_test` | 39 | 100.00 |
| ✅ | `error_bucket_frame` | bucket_frame | primary | `lvds_bucket_frame_error_test` | 43 | 100.00 |
| ✅ | `all_buckets_frame` | all_buckets_frame | primary | `lvds_all_buckets_frame_test` | 208 | 100.00 |

## Index

- [`BUG_HISTORY.md`](BUG_HISTORY.md) — bug ledger and fix evidence
- [`doc/DV_COV.md`](doc/DV_COV.md) — coverage ledger
- [`doc/DV_BASIC.md`](doc/DV_BASIC.md) — BASIC bucket plan
- [`uvm/`](uvm/) — active UVM harness and logs
