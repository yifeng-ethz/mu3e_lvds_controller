# ❓ DV Report — mu3e_lvds_controller SystemVerilog rebuild

**DUT:** `mu3e_lvds_controller` &nbsp; **Date:** `2026-04-29` &nbsp; **RTL variant:** `sv_rebuild` &nbsp; **Seed:** `default`

This page is the chief-architect dashboard for the active LVDS controller
rebuild worktree. Per-case evidence lives under `tb/uvm/log/` until the
`REPORT/` generator is added.

## Legend

✅ pass / closed &middot; ⚠️ partial / below target / known limitation &middot; ❌ failed / missing evidence &middot; ❓ pending &middot; ℹ️ informational

## Health

| status | field | value |
|:---:|---|---|
| ✅ | failed_cases | `0 in checked B001-B020 QuestaOne batch` |
| ✅ | signoff_runs_with_failures | `0 in promoted checked batch` |
| ⚠️ | catalog_backlog_cases | `198 remaining after B001-B020` |
| ⚠️ | unimplemented_cases | `scoreboard/reference model still partial` |
| ✅ | stale_artifacts | `0` |
| ❓ | structural_coverage_closure | `pending` |

## Signoff Scope

| field | claimed value |
|---|---|
| DUT_IMPL | `SystemVerilog rebuild` |
| N_LANE | `12 default; 1/4/32 compile smoke covered` |
| N_ENGINE | `1 default; N_ENGINE=N_LANE compile smoke covered` |
| ROUTING_TOPOLOGY | `partitioned default; full topology semantics still under RTL bring-up` |
| SCORE_WINDOW_W | `10 default` |
| simulator | `QuestaOne 2026.1_1 at /data1/questaone_sim/questasim` |

## Non-Claims

- This dashboard is not a signoff claim. It tracks bring-up progress while RTL
  and UVM checks are still being implemented.
- Coverage values remain pending until per-case UCDB collection and merge
  automation are added.
- B001-B020 are fully evidenced runtime cases at this checkpoint.

## Bucket Summary

| status | bucket | catalog_planned | promoted | evidenced | backlog | merged | promoted functional |
|:---:|---|---:|---:|---:|---:|---|---|
| ⚠️ | [`BASIC`](doc/DV_BASIC.md) | 78 | 20 | 20 | 58 | pending | 25.64% (20/78) |
| ❓ | [`EDGE`](doc/DV_EDGE.md) | 50 | 0 | 0 | 50 | pending | 0.00% (0/50) |
| ❓ | [`PROF`](doc/DV_PROF.md) | 40 | 0 | 0 | 40 | pending | 0.00% (0/40) |
| ❓ | [`ERROR`](doc/DV_ERROR.md) | 50 | 0 | 0 | 50 | pending | 0.00% (0/50) |

## Totals

| status | metric | pct | target |
|:---:|---|---|---|
| ❓ | stmt | pending | 95.0 |
| ❓ | branch | pending | 90.0 |
| ❓ | cond | pending | - |
| ❓ | expr | pending | - |
| ❓ | fsm_state | pending | 95.0 |
| ❓ | fsm_trans | pending | 90.0 |
| ❓ | toggle | pending | 80.0 |

- catalog_planned_cases: `218`
- promoted_signoff_cases: `20`
- evidenced_promoted_cases: `20`
- promoted functional coverage: `9.17% (20/218)`
- structural coverage closure: `pending`

## Signoff Runs

| status | run_id | kind | build | seq | txns | cross_pct |
|:---:|---|---|---|---|---:|---:|
| ✅ | `B001_questaone_smoke` | isolated | primary | `lvds_b001_read_uid_after_cold_reset_test` | 1 | 0.00 |
| ✅ | `B001_B020_identity_control` | isolated batch | primary | `lvds_base_test +LVDS_CASE_ID` | 20 | 0.00 |
| ❓ | `basic_bucket_frame` | bucket_frame | primary | `lvds_bucket_frame_basic_test` | 78 | 0.00 |

## Index

- [`BUG_HISTORY.md`](BUG_HISTORY.md) — bug ledger and fix evidence
- [`doc/DV_COV.md`](doc/DV_COV.md) — coverage ledger
- [`doc/DV_BASIC.md`](doc/DV_BASIC.md) — BASIC bucket plan
- [`uvm/`](uvm/) — active UVM harness and logs

_This dashboard is currently hand-maintained during bring-up. Replace it with a generator before signoff._
