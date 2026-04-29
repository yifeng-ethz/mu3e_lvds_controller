# BUG_HISTORY.md - mu3e_lvds_controller DV bug ledger

Class legend:
- `R` = RTL / DUT bug
- `H` = harness / testcase / reporting bug

Severity legend:
- `soft error` = the lane produces a corrupted decoded byte that flushes
  through the AVST stream and the next frame deassembler can drop the
  affected packet without wedging
- `hard stuck error` = the bug poisons the engine pool, the routing
  fabric, the steering queue, the training FSM, or a counter aperture
  in a way that needs a soft-reset on a lane (or a full DUT reset) to
  recover
- `non-datapath-refactor` = observability, reporting, harness, or
  identity / version metadata work with no direct decoded-byte effect

Encounterability legend:
- practical severity is `severity x encounterability`, so the index
  must say how likely a reader is to hit the bug in normal use rather
  than only when it first appeared in one simulation log
- nominal datapath operation = legal traffic with about `50%` per-lane
  glitch occupancy across the planned random soaks (e.g. P002 / P004 /
  P005 / P031 / P040), and no forced error injection or artificially
  pathological stalls beyond what the planned random spec already
  programs
- nominal control-path operation = routine bring-up / CSR program /
  readback / clear-counter sequences (B-bucket cases B001 .. B028 plus
  per-lane control writes from B011 .. B020)
- `common (...)` = readily hit in nominal operation
- `occasional (...)` = hit in nominal operation without heroic setup,
  but not in every short run
- `rare (...)` = legal in nominal operation, but usually needs long
  runtime or unlucky alignment
- `corner-only (...)` = requires a legal but non-nominal stress or
  corner profile (E-bucket / P-bucket sweeps)
- `directed-only (...)` = requires targeted error injection,
  formal/probe flow, reporting-only flow, or another non-operational
  stimulus (X-bucket / SVA probes)
- detailed `min / p50 / max` first-hit sim-time studies may still
  appear inside individual bug sections; current measured mixed-soak
  encounter data is not yet collected on this IP — the encounterability
  band is the index column, not raw first-hit sim-time

Fix status detail contract for active entries and future updates:
- `state` = fixed / open / partial plus the current verification gate
- `mechanism` = how the implemented repair changes the RTL or harness
  behavior
- `before_fix_outcome` and `after_fix_outcome` = concise evidence
  showing what changed
- `potential_hazard` = whether the fix looks permanent or is still
  provisional / profile-limited
- `Claude Opus 4.7 xhigh review decision` = explicit review state; use
  `pending / not run` until that review has actually happened

Historical formal note:
- this ledger starts on `2026-04-29` against the SystemVerilog rebuild
  worktree at `/home/yifeng/packages/mu3e_ip_dev/worktrees/mu3e_lvds_controller_sv_rebuild_20260429`
- the legacy VHDL/terp `lvds_rx_controller_pro` 25.1.0631 is a
  reference image only and bugs found in it are NOT logged here
- the current supported formal tool is `qverify` (primary) and
  `znformal` / `jaspergold` (cross-check) per the `dv-workflow` skill
- the current supported simulator runtime is `Questa FSE 2022.4` at
  `/data1/intelFPGA_pro/23.1/questa_fse/`

## Index

| bug_id | class | severity | encounterability | status | first seen | commit | summary |
|---|---|---|---|---|---|---|---|
| [BUG-000-H](#bug-000-h-dv-plan-freeze-marker-no-rtl-bugs-reported-yet) | H | non-datapath-refactor | `directed-only (plan freeze)` | open (RTL not yet authored) | DV plan freeze on `2026-04-29` | `pending` | DV plan freeze marker; first real bug entry will follow once codex begins RTL/UVM authoring. |

## 2026-04-29

### BUG-000-H: DV plan freeze marker; no RTL bugs reported yet
- First seen in:
  - `tb/doc/DV_PLAN.md` plan freeze on `2026-04-29` (the worktree at
    `/home/yifeng/packages/mu3e_ip_dev/worktrees/mu3e_lvds_controller_sv_rebuild_20260429`
    contains DV plan + harness plan + bucket files only; `rtl/`,
    `tb/uvm/`, `tb/formal/` are placeholder directories until codex
    begins authoring).
- Symptom:
  - none (this is a placeholder entry that satisfies the
    `bug_history_format_check.py` requirement of at least one indexed
    row and one dated section while the ledger is empty of real bugs).
- Root cause:
  - the lint's contract assumes the ledger is created at first bug
    discovery rather than at plan freeze.
- Fix status:
  - state:
    - open until the first real R-class or H-class bug is recorded
      against the SV rebuild
  - mechanism:
    - delete this row when the first real bug entry lands; renumber
      from BUG-001-X onward
  - before_fix_outcome:
    - lint failed with "BUG_HISTORY index must contain at least one
      bug row" and "BUG_HISTORY must contain at least one dated
      '## YYYY-MM-DD' section"
  - after_fix_outcome:
    - lint passes; the ledger is structurally valid even before any
      simulation has been run
  - potential_hazard:
    - a real first bug must replace this marker; leaving it
      indefinitely hides whether the SV rebuild has been exercised at
      all
  - Claude Opus 4.7 xhigh review decision:
    - pending / not run
