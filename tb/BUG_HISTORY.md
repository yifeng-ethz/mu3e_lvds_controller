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
| [BUG-001-H](#bug-001-h-uvm-csr-read-sampled-registered-read-data-before-nba-update) | H | non-datapath-refactor | `common (first CSR readback smoke)` | fixed (B001 clean on QuestaOne) | B001 on `2026-04-29` at 355 ns | `41bc171` | CSR agent sampled registered read data before the DUT NBA update, so the UID read saw stale zero. |
| [BUG-002-R](#bug-002-r-reset-default-mode-attached-a-super-engine-before-software-selected-legacy-bit-slip-mode) | R | hard stuck error | `common (routine control mode programming)` | fixed (B001-B020 clean on QuestaOne) | B016 on `2026-04-29` at 1405001 ps | `faf9ff0` | Reset defaulted MODE_MASK to auto mode, so a super engine was attached before software selected legacy bit-slip mode. |
| [BUG-003-H](#bug-003-h-continuous-frame-harness-held-reset-and-carried-control-state-across-cases) | H | non-datapath-refactor | `common (mandatory bucket_frame / all_buckets_frame runs)` | fixed (bucket frames and all_buckets_frame clean on QuestaOne) | all_buckets_frame on `2026-04-29` at B001 / X046 | `ab0d5eb` | Continuous-frame harness held reset into B001, leaked lane control state across cases, and did not fail Make on simulator assertion errors. |
| [BUG-004-H](#bug-004-h-prof-saturation-cases-inherited-threshold-state-in-continuous-frames) | H | non-datapath-refactor | `common (mandatory PROF/all-buckets no-restart frames)` | fixed (218-case all_buckets_frame clean on QuestaOne) | all_buckets_frame on `2026-04-29` at P023/P024 | `fe639d8` | PROF saturation cases preloaded counters but did not fully establish the score/training prerequisites needed for the next event in a no-restart frame. |
| [BUG-005-H](#bug-005-h-structural-toggle-closure-had-no-legal-stimulus-for-engine-age-storage) | H | non-datapath-refactor | `directed-only (coverage closure debug hook)` | fixed (primary+max32 UCDB toggle above 80%) | signoff coverage merge on `2026-04-29` | `fe639d8` | Normal runtime thresholds left `engine_age` high bits structurally untoggled, so the suite missed the toggle target until a DV-only preload swept the storage. |
| [BUG-006-R](#bug-006-r-standalone-timing-exposed-unpipelined-shared-engine-and-csr-cones) | R | non-datapath-refactor | `corner-only (standalone 1.1x Quartus timing signoff)` | fixed (Quartus 1.1x timing and QuestaOne frame regressions clean) | standalone compile on `2026-04-29` | pending | Shared-engine score/release logic, dynamic CSR counter reads, and dynamic score-change counter writes were too deep for 1.1x standalone timing. |

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

### BUG-003-H: Continuous-frame harness held reset and carried control state across cases
- First seen in:
  - `make -C tb/uvm TEST=lvds_all_buckets_frame_test SYMBOL_CAP=256
    RUN_LOG=log/primary/all_buckets_frame.log run` under
    `QuestaOne 2026.1_1` on `2026-04-29`.
  - B001 reported UID readback `0x00000000` because the continuous-frame
    driver never released reset before the first case.
  - After that reset-release fix, B014-B018 exposed stale `lane_go=0` /
    `dpa_hold` state carried forward from earlier control cases.
  - X046 also produced a simulator assertion error because the reset-race
    stimulus asserted reset in the same sampling edge as the AVST assertion.
- Symptom:
  - mandatory no-restart frame modes failed even though the same cases passed
    as isolated reset-per-case runs.
  - the Makefile only rejected nonzero `UVM_ERROR` / `UVM_FATAL` counts, so a
    simulator assertion error could escape as a shell success when the UVM
    summary stayed clean.
- Root cause:
  - `continuous_frame` skipped `drive_reset()` for every case, including the
    first case in the frame.
  - control-case stimulus assumed reset-per-case defaults instead of
    explicitly programming prerequisites before each no-restart case.
  - X046 used nonblocking reset assignment immediately after a data-clock
    posedge, so the SVA sampled the pre-reset value and the case tested a
    scheduler artifact.
  - the Makefile post-run check ignored simulator `** Error` / `Errors: N`
    lines.
- Fix status:
  - state:
    - fixed and verified with all bucket-frame baselines plus the
      all-buckets-frame baseline under QuestaOne
  - mechanism:
    - release reset once at the start of a continuous frame while still
      preserving no-reset operation between later cases
    - make B012-B018 explicitly program `lane_go` / `dpa_hold` prerequisites
      before checking their local behavior
    - align X046 reset assertion to the data-clock negative edge so the next
      sampled edge sees reset asserted
    - make the UVM Makefile fail on simulator assertion errors unless a future
      expected-fail SVA probe flow deliberately opts out
    - generate `DV_REPORT.md` from the Questa logs instead of hand-editing the
      dashboard
  - before_fix_outcome:
    - `all_buckets_frame` produced UVM failures in B001/B014-B018 and one
      simulator assertion error in X046
  - after_fix_outcome:
    - `make -C tb/uvm bucket_frame SYMBOL_CAP=256` completes with BASIC
      `78/78`, EDGE `48/48` runtime-frame cases, PROF `39/39`
      runtime-frame cases, and ERROR `43/43` runtime-frame cases passing
    - `make -C tb/uvm TEST=lvds_all_buckets_frame_test SYMBOL_CAP=256
      RUN_LOG=log/primary/all_buckets_frame.log run` completes with
      `UVM_ERROR : 0`, `UVM_FATAL : 0`, simulator `Errors: 0`, and `208`
      runtime-frame transactions
  - potential_hazard:
    - permanent for the current no-restart frame machinery. The debug-hook SVA
      live-fire cases remain outside the runtime frame until the planned debug
      hooks exist.
  - Claude Opus 4.7 xhigh review decision:
    - pending / not run

### BUG-002-R: Reset default mode attached a super engine before software selected legacy bit-slip mode
- First seen in:
  - `make -C tb/uvm TEST=lvds_base_test
    EXTRA_ARGS="+LVDS_CASE_ID=B016" SYMBOL_CAP=256
    RUN_LOG=log/primary/B016.log run` under `QuestaOne 2026.1_1` on
    `2026-04-29`.
  - B016 reported `lane 0 counter 7 expected 0 got 1` at 1405001 ps.
- Symptom:
  - the `engine_steerings` counter incremented even though B016 had
    programmed legacy bit-slip mode (`MODE_MASK=0`) and expected the shared
    super decoder-aligner pool to remain unused.
- Root cause:
  - the data-domain reset default for `mode_mask` was `2`, matching auto mode.
    A locked lane could therefore request the shared engine during the reset
    release window before the control-path CSR write to legacy mode arrived.
- Fix status:
  - state:
    - fixed and verified with the checked B001-B020 batch under QuestaOne
  - mechanism:
    - reset `mode_mask` and its data-clock synchronizer defaults to legacy
      bit-slip mode (`0`)
    - keep adaptive and auto super-engine steering opt-in through explicit CSR
      writes
    - add checked B016/B017/B018 expectations so bit-slip, adaptive, and auto
      mode now observe different steering-counter behavior
  - before_fix_outcome:
    - B016 produced one `UVM_ERROR` because lane 0 had already consumed an
      engine steering event before the testcase wrote `MODE_MASK=0`
  - after_fix_outcome:
    - the checked B001-B020 batch completes under QuestaOne with all 20 cases
      passing and UVM summary `UVM_ERROR : 0`
  - potential_hazard:
    - the global two-bit `MODE_MASK` encoding is provisional. The next CSR
      freeze must decide whether this remains global or becomes a per-lane
      two-bit field before firmware depends on it.
  - Claude Opus 4.7 xhigh review decision:
    - pending / not run

### BUG-004-H: PROF saturation cases inherited threshold state in continuous frames
- First seen in:
  - `make -C tb/uvm TEST=lvds_all_buckets_frame_test SYMBOL_CAP=256
    RUN_LOG=log/primary/all_buckets_frame.log run` under
    `QuestaOne 2026.1_1` on `2026-04-29`.
  - P023 previously expected `bitslip_events[0] == 0xffffffff` but read
    `0xfffffffe` in the continuous all-buckets frame.
  - After P023 was made self-contained, P024 exposed the same class by
    expecting `uptime_since_lock[0] == 0xffffffff` but reading `0xfffffffe`.
- Symptom:
  - isolated saturation cases passed, but no-restart frames missed the
    final increment after the DV preload.
- Root cause:
  - the saturation cases preloaded the target counter to `0xfffffffe`
    and then assumed the next stimulus would generate the matching event.
    In continuous frames, inherited CSR state could keep the lane out of
    the required mode or out of `TRAIN_HOLDING_LOCK`, so the event did not
    occur before readback.
- Fix status:
  - state:
    - fixed and verified with bucket-frame and all-buckets-frame
      regressions under QuestaOne
  - mechanism:
    - program `sync_pattern`, `lane_go`, `dpa_hold`, `mode_mask`,
      `score_accept=1`, and `score_reject=0` inside the saturation
      sequence before preloading the target counter
    - keep the final event after preload specific to the counter under
      test, so saturation still checks the real DUT increment path
  - before_fix_outcome:
    - all-buckets-frame produced one `UVM_ERROR` in P024:
      `expected 0xffffffff got 0xfffffffe`
  - after_fix_outcome:
    - `make -C tb/uvm TEST=lvds_all_buckets_frame_test SYMBOL_CAP=256
      RUN_LOG=log/primary/all_buckets_frame.log run` completes with
      `218` observed transactions, `UVM_ERROR : 0`, `UVM_FATAL : 0`,
      and simulator `Errors: 0`
    - `make -C tb/uvm bucket_frame SYMBOL_CAP=256` completes with
      BASIC `78/78`, EDGE `50/50`, PROF `40/40`, and ERROR `50/50`
      runtime-frame cases passing
  - potential_hazard:
    - permanent for the current debug-preload saturation pattern. Any new
      saturating counter case must establish its own post-preload event
      prerequisites instead of relying on previous cases.
  - Claude Opus 4.7 xhigh review decision:
    - pending / not run

### BUG-005-H: Structural toggle closure had no legal stimulus for engine age storage
- First seen in:
  - merged `cov_primary` plus `max32` UCDB coverage review under
    `QuestaOne 2026.1_1` on `2026-04-29`.
  - the merged toggle score was `73.75%`, below the DV-workflow
    structural target of at least `80%`.
- Symptom:
  - statement, branch, condition, and expression coverage were at or above
    target, but toggle coverage stayed below target.
  - `vcover report -details` showed the largest avoidable hole in
    `engine_age` storage.
- Root cause:
  - legal runtime traffic releases engines before the high `engine_age`
    bits can toggle. Those bits are real storage and not dead code, but
    normal training thresholds intentionally bound their runtime range.
- Fix status:
  - state:
    - fixed and verified with full primary and max32 isolated coverage
      sweeps under QuestaOne
  - mechanism:
    - add `LVDS_DV_DEBUG`-guarded engine-age preload ports in the DUT and
      UVM interface
    - extend X039 to sweep `engine_age` through `16'hffff` and `16'h0000`
      for every configured engine while keeping the production port list
      unchanged when `LVDS_DV_DEBUG` is absent
    - qualify UCDB test names by build so primary and max32 coverage can
      merge without duplicate testcase names
  - before_fix_outcome:
    - merged primary+max32 toggle coverage was `73.75%`
  - after_fix_outcome:
    - merged primary+max32 structural coverage reports branch `100.00%`,
      condition `94.52%`, expression `90.00%`, statement `99.09%`,
      toggle `80.98%`, and total `92.92%`
  - potential_hazard:
    - permanent for DV coverage closure. The hook is compiled only under
      `LVDS_DV_DEBUG`; production builds do not expose this preload path.
  - Claude Opus 4.7 xhigh review decision:
    - pending / not run

### BUG-006-R: Standalone timing exposed unpipelined shared-engine and CSR cones
- First seen in:
  - `quartus_sh --flow compile lvds_controller_syn -c lvds_controller_syn`
    under Quartus 18.1 Standard on `2026-04-29`.
  - the first standalone fit missed setup with data WNS `-22.059 ns` and
    control WNS `-0.766 ns` at the 1.1x signoff clocks.
- Symptom:
  - the RTL passed QuestaOne UVM but failed standalone timing closure for
    the default `N_LANE=12`, `N_ENGINE=1` resource-saving configuration.
- Root cause:
  - the shared super-engine path combined selected-lane symbol routing,
    10-phase decode/score bookkeeping, best-score selection, and release
    decisions in the same data-clock cycle.
  - the CSR read mux subtracted the counter base address and dynamically
    indexed the per-lane counter aperture in the control-clock readback path.
  - the score-change statistic increment used `engine_attach_lane` as a
    dynamic write index directly into `lane_counter[*][SCORE_CHANGES]`.
- Fix status:
  - state:
    - fixed and verified with Quartus standalone timing, bucket-frame
      regression, all-buckets-frame regression, and generated-netlist smoke
  - mechanism:
    - scan the 10 score phases with registered `engine_score_scan_phase`
      and `engine_best_score` instead of reducing all phases into the
      release path in one cycle
    - register selected engine score symbols and per-lane engine requests
      before updating shared engine state
    - replace CSR counter-aperture subtract/index decode with direct
      address cases
    - convert score-change counter updates into one-cycle per-lane
      one-hot events before incrementing `lane_counter`
  - before_fix_outcome:
    - initial standalone compile: data setup WNS `-22.059 ns`, control setup
      WNS `-0.766 ns`
    - intermediate compile after partial pipelines: data setup WNS
      `-0.485 ns`, control setup WNS `+0.291 ns`
  - after_fix_outcome:
    - final standalone compile: slow 85 C setup slack `+0.202 ns`
      on `control_clk`, `+0.427 ns` on `data_clk`; hold slack `+0.260 ns`
      on `control_clk`, `+0.283 ns` on `data_clk`
    - `make -C tb/uvm bucket_frame SYMBOL_CAP=256` passes BASIC `78`,
      EDGE `50`, PROF `40`, and ERROR `50` frame cases with zero UVM
      errors/fatals
    - `make -C tb/uvm TEST=lvds_all_buckets_frame_test SYMBOL_CAP=256
      RUN_LOG=log/primary/all_buckets_frame_after_timing_close.log run`
      passes `218` transactions with zero UVM errors/fatals
    - Quartus-generated functional netlist smoke compiles and runs under
      QuestaOne with `Errors: 0, Warnings: 0`
  - potential_hazard:
    - permanent for the default standalone signoff geometry. Larger
      `N_ENGINE` / `N_LANE` matrix builds still need their own timing
      compiles because the routing network changes placement and fanout.
  - Claude Opus 4.7 xhigh review decision:
    - pending / not run
