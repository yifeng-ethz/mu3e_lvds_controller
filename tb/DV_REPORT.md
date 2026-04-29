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
| ✅ | catalog_backlog_cases | `0; all 218 cataloged cases execute in promoted runtime frames` |
| ✅ | unimplemented_cases | `0` |
| ✅ | stale_artifacts | `0` |
| ✅ | structural_coverage_closure | `92.92% total; stmt/branch/cond/expr/toggle targets checked below` |

## Signoff Scope

| field | claimed value |
|---|---|
| DUT_IMPL | `SystemVerilog rebuild` |
| N_LANE | `12 primary runtime frame; 32-lane max32 structural coverage companion` |
| N_ENGINE | `1 primary runtime frame; 32-engine max32 structural coverage companion` |
| ROUTING_TOPOLOGY | `partitioned default; alternate topology hooks cataloged` |
| SCORE_WINDOW_W | `10 default` |
| simulator | `QuestaOne 2026.1_1 at /data1/questaone_sim/questasim` |

## Non-Claims

- This dashboard closes the current promoted runtime/UVM bucket frames.
- P025 is implemented as a bounded checkpoint-growth soak under the regression `SYMBOL_CAP`; no physical 10G-symbol wall-clock simulation is claimed.

## Bucket Summary

| status | bucket | catalog_planned | promoted | evidenced | backlog | merged | promoted functional |
|:---:|---|---:|---:|---:|---:|---|---|
| ✅ | [`BASIC`](doc/DV_BASIC.md) | 78 | 78 | 78 | 0 | pass (78 frame + 0 closed exception) | 100.00% (78/78) |
| ✅ | [`EDGE`](doc/DV_EDGE.md) | 50 | 50 | 50 | 0 | pass (50 frame + 0 closed exception) | 100.00% (50/50) |
| ✅ | [`PROF`](doc/DV_PROF.md) | 40 | 40 | 40 | 0 | pass (40 frame + 0 closed exception) | 100.00% (40/40) |
| ✅ | [`ERROR`](doc/DV_ERROR.md) | 50 | 50 | 50 | 0 | pass (50 frame + 0 closed exception) | 100.00% (50/50) |

## Totals

| status | metric | pct | target |
|:---:|---|---|---|
| ✅ | stmt | 99.09% | >= 95% |
| ✅ | branch | 100.00% | >= 90% |
| ✅ | cond | 94.52% | >= 85% |
| ✅ | expr | 90.00% | >= 85% |
| ✅ | fsm_state | n/a | no DUT FSM coverage class emitted by Questa for this design |
| ✅ | fsm_trans | n/a | no DUT FSM coverage class emitted by Questa for this design |
| ✅ | toggle | 80.98% | >= 80% |

- catalog_planned_cases: `218`
- promoted_signoff_cases: `218`
- evidenced_promoted_cases: `218`
- promoted functional coverage: `100.00% (218/218)`
- structural coverage closure: `92.92% total merged primary+max32 UCDB`
- structural coverage artifact: `REPORT/coverage/signoff_primary_max32_summary.txt`

## Signoff Runs

| status | run_id | kind | build | seq | txns | cross_pct |
|:---:|---|---|---|---|---:|---:|
| ✅ | `basic_bucket_frame` | bucket_frame | primary | `lvds_bucket_frame_basic_test` | 78 | 100.00 |
| ✅ | `edge_bucket_frame` | bucket_frame | primary | `lvds_bucket_frame_edge_test` | 50 | 100.00 |
| ✅ | `prof_bucket_frame` | bucket_frame | primary | `lvds_bucket_frame_prof_test` | 40 | 100.00 |
| ✅ | `error_bucket_frame` | bucket_frame | primary | `lvds_bucket_frame_error_test` | 50 | 100.00 |
| ✅ | `all_buckets_frame` | all_buckets_frame | primary | `lvds_all_buckets_frame_test` | 218 | 100.00 |

## Index

- [`BUG_HISTORY.md`](BUG_HISTORY.md) — bug ledger and fix evidence
- [`doc/DV_COV.md`](doc/DV_COV.md) — coverage ledger
- [`DV_REPORT.json`](DV_REPORT.json) — machine-readable scoreboard summary
- [`doc/DV_BASIC.md`](doc/DV_BASIC.md) — BASIC bucket plan
- [`uvm/`](uvm/) — active UVM harness and logs

_Regenerate with `python3 tb/uvm/script/generate_dv_report.py` after refreshing bucket-frame logs and coverage summary._
