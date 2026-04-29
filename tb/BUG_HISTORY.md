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
- the current supported simulator runtime is `QuestaOne 2026.1_1` at
  `/data1/questaone_sim/questasim/` with the ETH floating license at
  `8161@lic-mentor.ethz.ch`

## Index

| bug_id | class | severity | encounterability | status | first seen | commit | summary |
|---|---|---|---|---|---|---|---|
| [BUG-001-H](#bug-001-h-uvm-csr-read-sampled-registered-read-data-before-nba-update) | H | non-datapath-refactor | `common (first CSR readback smoke)` | fixed (B001 clean on QuestaOne) | B001 on `2026-04-29` at 355 ns | `pending` | CSR agent sampled registered read data before the DUT NBA update, so the UID read saw stale zero. |

## 2026-04-29

### BUG-001-H: UVM CSR read sampled registered read data before NBA update
- First seen in:
  - `make -C tb/uvm TEST=lvds_b001_read_uid_after_cold_reset_test
    SYMBOL_CAP=64 run` under `QuestaOne 2026.1_1` on `2026-04-29`.
  - B001 reported `word 0 expected 0x4c564453 got 0x00000000` at
    355 ns.
- Symptom:
  - the first CSR UID read returned stale reset data even though the
    RTL compiled and the UID decode path was present.
- Root cause:
  - the UVM CSR agent asserted `avs_csr_read` after a clock edge and
    sampled `avs_csr_readdata` at the next clock edge in the active
    region. The DUT updates registered read data with a nonblocking
    assignment on that same edge, so the agent sampled before the NBA
    update.
- Fix status:
  - state:
    - fixed and verified with B001 under QuestaOne
  - mechanism:
    - add a 1 ps post-clock sample skew in `csr_read` so the agent
      observes the registered read-data update for the accepted read
    - initialize sparse associative-array scoreboard/coverage counters
      before first increment so QuestaOne regressions do not carry
      avoidable simulator warnings
  - before_fix_outcome:
    - B001 produced one `UVM_ERROR` and later two simulator warnings
      from first-hit sparse associative-array increments
  - after_fix_outcome:
    - `make -C tb/uvm TEST=lvds_b001_read_uid_after_cold_reset_test
      SYMBOL_CAP=64 run` completes under QuestaOne with compile
      `Errors: 0, Warnings: 0`, simulation `Errors: 0, Warnings: 0`,
      and UVM summary `UVM_ERROR : 0`
  - potential_hazard:
    - permanent for the current registered-read CSR contract; if the
      CSR agent is later replaced by UVM RAL, the same post-edge
      sampling rule must be preserved
  - Claude Opus 4.7 xhigh review decision:
    - pending / not run
