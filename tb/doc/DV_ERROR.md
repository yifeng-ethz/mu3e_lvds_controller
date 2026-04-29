# DV Error — mu3e_lvds_controller (SV rebuild)

**Companion docs:** [DV_PLAN.md](DV_PLAN.md), [DV_HARNESS.md](DV_HARNESS.md),
[DV_BASIC.md](DV_BASIC.md), [DV_EDGE.md](DV_EDGE.md),
[DV_PROF.md](DV_PROF.md), [DV_CROSS.md](DV_CROSS.md),
[DV_FORMAL.md](DV_FORMAL.md), [DV_COV.md](DV_COV.md),
[BUG_HISTORY.md](../BUG_HISTORY.md)

**Parent:** [DV_PLAN.md](DV_PLAN.md)
**ID Range:** X001-X050
**Total:** 50 cases (50 implemented / 0 waived)

**Methodology key:**
- **D** = Directed (hand-crafted stimulus, deterministic)
- **R** = Constrained-random (LCG-based PRNG from `mutrig_common_pkg`; no SystemVerilog `rand`)

The X-bucket covers reset/fault/illegal: anything where the system or
the user does the wrong thing and the DUT must not deadlock, must not
silently corrupt, must not produce false success. Includes debug-hook
SVA liveness probes that exercise assertion antecedents and guard logic
without using expected-fail runtime tests.

---

## 1. Summary

| Section | Cases | ID Range | What it Proves | Current Case |
|---------|-------|----------|----------------|--------------|
| 2. Soft Reset Sequencing | 8 | X001-X008 | per-lane soft reset is clean and bounded | 8/8 |
| 3. Dead Lane Behavior | 10 | X009-X018 | a lane that never delivers valid data does not poison the IP | 10/10 |
| 4. PHY Fault Recovery | 6 | X019-X024 | DPA / PLL / fiforst faults recover or fail-stop with counters | 6/6 |
| 5. Illegal CSR Writes | 10 | X025-X034 | malformed CSR transactions cannot wedge the slave | 10/10 |
| 6. SVA Liveness Probes | 7 | X035-X041 | every SVA module sees its guarded condition in runtime | 7/7 |
| 7. Reset Race Conditions | 9 | X042-X050 | reset boundaries are honoured under every legal ordering | 9/9 |

---

## 2. Soft Reset Sequencing

| ID | Method | Scenario | Iter | Stimulus | Pass Criteria | Function Reference |
|----|--------|----------|------|----------|--------------|--------------------|
| X001 | D | Soft reset clears that lane's counters | 1 | Increment several counters on lane 0 (run B055–B058 on lane 0). Set `soft_reset_req[0]=1`. | After self-clear, every counter on lane 0 is 0; counters on other lanes unchanged. | TBD |
| X002 | D | Soft reset during steering | 1 | `mode_mask=adaptive`. Engine attached lane 0. Set `soft_reset_req[0]=1`. | DUT detaches engine within 4 cycles; lane 0 enters training; `soft_resets[0]` increments by 1; `engine_steerings[0]` increments only on the next attach event after recovery. | TBD |
| X003 | D | Soft reset during bitslip walk | 1 | Lane 0 mid-walk at pulse 4 of 7. Set `soft_reset_req[0]=1`. | Walk aborts cleanly (no further `coe_ctrl_bitslip[0]` pulses); lane returns to phase 0; `bitslip_events[0]` counter shows the partial walk count then resets to 0 after self-clear. | TBD |
| X004 | D | Soft reset during DPA unlock event | 1 | Inject `dpa_unlock_pulse` on lane 0; in the same cycle set `soft_reset_req[0]=1`. | Both events count exactly once: `dpa_unlocks[0]++` then counters reset (so end-of-test reads 0 for `dpa_unlocks[0]`); `soft_resets[0]++` survives because it's measured against the post-reset state. The harness records the cycle order to detect race-induced double counting. | TBD |
| X005 | D | All-lanes soft reset simultaneously | 1 | Set `soft_reset_req = (1<<N_LANE)-1`. | All lanes reset; engine pool fully released; CSR remains responsive throughout. | TBD |
| X006 | D | Self-clear after IDLE | 1 | Same as X001; observe `soft_reset_req[0]` bit. | DUT clears bit 0 of `soft_reset_req` exactly when lane 0 reaches the IDLE state of its training FSM. | TBD |
| X007 | D | Soft reset on disabled lane | 1 | Set `lane_go[0]=0`. Set `soft_reset_req[0]=1`. | DUT clears `soft_reset_req[0]=0` after the bare reset cycle (no training to re-enter); `soft_resets[0]++`; lane stays disabled. | TBD |
| X008 | D | Back-to-back soft reset | 1 | Set `soft_reset_req[0]=1`, wait for self-clear, set `soft_reset_req[0]=1` again, repeat 4 times. | Each request fully completes before the next can be observed; `soft_resets[0]=4` at the end. | TBD |

---

## 3. Dead Lane Behavior

| ID | Method | Scenario | Iter | Stimulus | Pass Criteria | Function Reference |
|----|--------|----------|------|----------|--------------|--------------------|
| X009 | D | Stuck high (`0x3FF`) | 1 | Drive lane 0 with `coe_parallel_data[9:0]=10'h3FF` continuously. | DUT walks bitslip (no lock), eventually requests DPA reset; `realigns[0]` saturates around the `score_window_w × bitslip_max` budget; lane 0 emits `loss_sync_pattern` continuously; other lanes unaffected. | TBD |
| X010 | D | Stuck low (`0x000`) | 1 | Same with `0x000`. | Same as X009. | TBD |
| X011 | D | Stuck on one valid non-K28.5 symbol | 1 | Drive lane 0 with a single legal D-byte (e.g. `D0.0`) repeated. | Engine never locks (no comma); `comma_losses[0]` does not increment from the locked state because the lane never locks; `loss_sync_pattern` stays asserted; lane 0 produces no decoded valid bytes; other lanes unaffected. | TBD |
| X012 | D | Bouncing 50% high/low | 1 | Toggle `coe_parallel_data[i*10 +: 10]` between `0x3FF` and `0x000` every cycle. | Bitslip walk cycles forever; `bitslip_events[0]` saturates eventually; lane 0 never locks; engine never attaches lane 0 (or attaches and detaches repeatedly — codex must define and document, plan accepts either). | TBD |
| X013 | D | Random data only (no K28.5) | 1 | Drive lane 0 with PRNG 10b symbols. | Engine never locks; `code_violations[0]` increments with every illegal symbol (probability ≈ 0.024 per random 10b); `comma_losses` does not increment because no initial lock. | TBD |
| X014 | D | Sparse sync (K28.5 every 1024 symbols) | 1 | Drive lane 0 with random data containing one K28.5 every 1024 symbols. | Engine attempts to lock on the K28.5; `score_accept` configured higher than the achievable score; engine reports `reject` consistently; lane 0 stays in degraded mode. | TBD |
| X015 | D | `dpalock` never asserts | 1 | Force `coe_ctrl_dpalock[0]=0` permanently. | DUT keeps lane 0 in DPA-training; `coe_ctrl_dparst[0]` cycles per the training-FSM retry policy (codex must define); no engine attach; `dpa_unlocks[0]` does not increment because there was no prior lock. | TBD |
| X016 | D | Rollover without bitslip request | 1 | Force `coe_ctrl_rollover[0]=1` for one cycle while DUT is *not* requesting bitslip. | DUT ignores the spurious rollover; `realigns[0]` does not increment; no false counter increment. | TBD |
| X017 | D | `redriver_losn=0` on lane 0 | 1 | Set `coe_redriver_losn[0]=0` (active low LOS). | DUT pulls lane 0 into a forced-degraded state, asserts `loss_sync_pattern`, freezes counters except `comma_losses` (codex must commit and document the LOS policy). | TBD |
| X018 | D | `redriver_losn=1` baseline | 1 | Set `coe_redriver_losn[0]=1` (no LOS). | Lane 0 operates normally; this case is a smoke test for the conduit input. | TBD |

---

## 4. PHY Fault Recovery

| ID | Method | Scenario | Iter | Stimulus | Pass Criteria | Function Reference |
|----|--------|----------|------|----------|--------------|--------------------|
| X019 | D | Continuous bitslip churn | 1 | Drive lane 0 with a stream that never locks at any phase (cycles through phases every `score_window_w` symbols). | DUT walks bitslip up to `bitslip_max`, requests DPA reset; if the stream still does not lock after the reset, lane 0 stays in degraded mode; `realigns[0]` and `dpa_unlocks[0]` increment per retry; counters do not saturate within a 100k-cycle test (saturation tested in PROF). | TBD |
| X020 | D | PLL drops lock mid-traffic | 1 | All lanes locked; pulse `coe_ctrl_plllock=0` for 16 cycles. | DUT asserts `coe_ctrl_pllrst`, walks back through the §B021–§B024 sequence; every lane's `dpa_unlocks` and `comma_losses` increment by 1. | TBD |
| X021 | D | `dpalock` asserts then drops every 100 cycles | 1 | Pulse `coe_ctrl_dpalock[0]` low for 1 cycle every 100 cycles for 10k cycles. | `dpa_unlocks[0] = 100` (within ±1 due to startup); engine attaches/detaches each event; throughput on lane 0 is degraded to ~50% but other lanes unaffected. | TBD |
| X022 | D | `dparst` held too long | 1 | Force the harness to stall `coe_ctrl_dpalock[0]=0` for 100,000 cycles after `coe_ctrl_dparst[0]` deasserts. | DUT is patient (no internal timeout escalation by default); stays in DPA-training; documented behavior unless codex elects to add a timeout — in which case the timeout value is exposed via CSR and tested. | TBD |
| X023 | D | `fiforst` handshake never completes | 1 | Force the harness to ignore `coe_ctrl_fiforst[0]` (no FIFO state change). | DUT proceeds; legacy IP pulses `fiforst` open-loop; this case proves no closed-loop handshake is required. | TBD |
| X024 | D | Spurious rollover without bitslip request | 1 | Same as X016, repeated 100 times. | Each spurious pulse ignored; no counter increments; no SVA violation. | TBD |

---

## 5. Illegal CSR Writes

| ID | Method | Scenario | Iter | Stimulus | Pass Criteria | Function Reference |
|----|--------|----------|------|----------|--------------|--------------------|
| X025 | D | CSR write while `soft_reset_req` in flight | 1 | Set `soft_reset_req[0]=1`; in the same Avalon cycle, write `mode_mask=0xFF`. | Both writes accepted; `mode_mask` value applies after lane 0 reaches IDLE; `waitrequest` may pulse but no deadlock. | TBD |
| X026 | D | CSR write during control reset | 1 | Assert `rsi_control_reset`. Issue CSR write. | DUT does not accept the write (Avalon contract: slave does not respond during reset); `waitrequest=1` or no `readdatavalid`; harness times out and re-issues after reset deassert. | TBD |
| X027 | D | CSR read during control reset | 1 | Assert `rsi_control_reset`. Issue CSR read. | Same as X026 with read. | TBD |
| X028 | D | Write to read-only words | 1 | Write `0xFFFFFFFF` to UID, capability, every counter aperture word. | All writes silently ignored; readback of every word matches its read-only value. | TBD |
| X029 | D | `lane_go` write with extra bits | 1 | Write `0xFFFFFFFF` to `lane_go`. | DUT clamps to `(1<<N_LANE)-1`; readback shows the clamped value. | TBD |
| X030 | D | `dpa_hold` write with extra bits | 1 | Write `0xFFFFFFFF` to `dpa_hold`. | Same clamp behavior. | TBD |
| X031 | D | `LANE_SELECT` write with all-set | 1 | Write `0xFFFFFFFF` to `LANE_SELECT`. | DUT clamps to `N_LANE-1`; readback shows the clamped value. | TBD |
| X032 | D | `score_accept=0` illegal | 1 | Write `0` to `score_accept`. | DUT clamps to `1` (minimum legal); readback shows `1`. | TBD |
| X033 | D | `mode_mask` reserved value | 1 | Write `mode_mask = 11` (reserved bit pattern) on lane 0. | DUT either (a) clamps to a valid mode (0/1/2) or (b) ignores the write. Codex commits and documents. | TBD |
| X034 | D | CSR access at non-existent address | 1 | Write+read at an address inside the aperture but inside a reserved gap. | Read returns 0; write silently ignored; no `waitrequest` deadlock. | TBD |

---

## 6. SVA Liveness Probes

These cases use DV-only debug conduits to exercise SVA antecedents,
aperture guards, and structural debug paths under legal runtime
expectations. The pass criterion is still zero UVM and simulator errors;
the probes are not expected-fail tests.

| ID | Method | Scenario | Iter | Stimulus | Pass Criteria | Function Reference |
|----|--------|----------|------|----------|--------------|--------------------|
| X035 | D | `sva_routing_excl` liveness | 1 | Force an engine lane tag through the debug hook, then request routing through normal stimulus. | No SVA failure; exclusivity antecedent is active and no duplicate lane claim is observed. | TBD |
| X036 | D | `sva_counter_sat` liveness | 1 | Use debug hook to write a counter at `0xFFFFFFFE` and inject a 2-event burst. | Counter saturates at `0xFFFFFFFF`; no wrap and no SVA failure. | TBD |
| X037 | D | `sva_avalon_st` liveness | 1 | Hold `ready=0` while the DUT presents decoded output. | Payload remains stable while stalled; no SVA failure. | TBD |
| X038 | D | `sva_avalon_mm` liveness | 1 | Exercise CSR read/write timing and DV-only invalid debug pulses in the same case. | Avalon-MM stability checks stay quiet; invalid debug pulses are ignored. | TBD |
| X039 | D | `sva_csr_aperture` liveness | 1 | Read the counter aperture and sweep debug-only engine score/age preload guards. | CSR aperture remains stable; debug guard paths toggle for coverage; no SVA failure. | TBD |
| X040 | D | `sva_engine_attach` liveness | 1 | Attach an engine through the debug hook and then drive a normal release window. | Engine attach accounting remains bounded and legal; no SVA failure. | TBD |
| X041 | D | `sva_train_fsm` liveness | 1 | Exercise reset and training transitions around the debug-hook probe window. | Training FSM remains in a legal state across the probe; no SVA failure. | TBD |

---

## 7. Reset Race Conditions

| ID | Method | Scenario | Iter | Stimulus | Pass Criteria | Function Reference |
|----|--------|----------|------|----------|--------------|--------------------|
| X042 | D | Both resets asserted then released same cycle | 1 | Assert both, hold 16 cycles, deassert both same cycle. | DUT walks normal init; CSR responsive after `control_reset_release_latency`; data path follows §B021–§B024. | TBD |
| X043 | D | Control reset deassert before data reset | 1 | Deassert `rsi_control_reset` first; hold `rsi_data_reset` for 100 more cycles. | CSR responsive; data path stays held; init begins when `rsi_data_reset` deasserts. | TBD |
| X044 | D | Data reset deassert before control reset | 1 | Deassert `rsi_data_reset` first; hold `rsi_control_reset` for 100 more cycles. | Data path inits; CSR unreachable until control reset deasserts. The training FSM still completes for any lane that gets a valid PHY conduit. | TBD |
| X045 | D | Reset asserted during CSR write | 1 | Issue CSR write; assert `rsi_control_reset` mid-cycle. | Write may be lost; no `waitrequest` deadlock after reset releases; harness re-reads to confirm. | TBD |
| X046 | D | Reset asserted during AVST handshake | 1 | While `aso_decoded[0]` is mid-beat (`valid=1, ready=0`), assert `rsi_data_reset`. | DUT drops the beat cleanly; `valid=0` next cycle; no SVA violation on AVST contract during reset (the `valid_during_reset = 0` rule must hold). | TBD |
| X047 | D | Reset asserted during engine attach | 1 | Engine attaching lane 0; assert `rsi_data_reset` 1 cycle after the attach event. | Engine cleanly detaches; `engine_busy_mask=0` after reset. | TBD |
| X048 | D | Reset asserted during bitslip walk | 1 | Lane 0 mid-walk; assert `rsi_data_reset`. | Walk aborts; lane 0 returns to phase 0 after reset release. | TBD |
| X049 | D | Reset asserted during DPA training | 1 | Lane 0 in DPA-training; assert `rsi_data_reset`. | DPA training restarts cleanly per §B021. | TBD |
| X050 | D | Reset glitch (1-cycle pulse) | 1 | Pulse `rsi_data_reset=1` for 1 cycle. | DUT either treats it as a real reset (entering full init) or filters it (codex must commit and document; the plan accepts either provided `sva_*` properties continue to hold). | TBD |
