# DV Basic — mu3e_lvds_controller (SV rebuild)

**Companion docs:** [DV_PLAN.md](DV_PLAN.md), [DV_HARNESS.md](DV_HARNESS.md),
[DV_EDGE.md](DV_EDGE.md), [DV_PROF.md](DV_PROF.md),
[DV_ERROR.md](DV_ERROR.md), [DV_CROSS.md](DV_CROSS.md),
[DV_FORMAL.md](DV_FORMAL.md), [DV_COV.md](DV_COV.md),
[BUG_HISTORY.md](../BUG_HISTORY.md)

**Parent:** [DV_PLAN.md](DV_PLAN.md)
**ID Range:** B001-B080
**Total:** 78 cases (0 implemented / 0 waived)

**Methodology key:**
- **D** = Directed (hand-crafted stimulus, deterministic)
- **R** = Constrained-random (LCG-based PRNG from `mutrig_common_pkg`; no SystemVerilog `rand`)

The B-bucket exists to prove the IP boots, the identity surface matches
the `ip-packaging` skill, the per-lane control bits work, the
`altlvds_rx`-conduit handshake matches Intel doc 683062, the mini-decoder
walks the byte boundary correctly, the training→steady transition
behaves under all `mode_mask` values, the counter aperture is atomic, and
the 10-counter set increments deterministically. Failure of any B-case
invalidates every downstream bucket.

---

## 1. Summary

| Section | Cases | ID Range | What it Proves | Current Case |
|---------|-------|----------|----------------|--------------|
| 2. CSR Identity and Header | 10 | B001-B010 | identity contract per ip-packaging skill | 0/10 |
| 3. Per-lane Control Words | 10 | B011-B020 | runtime control bits at the lane granularity | 0/10 |
| 4. PHY Power-up and DPA Sequence | 8 | B021-B028 | reset / DPA / FIFO sequencing per Intel doc 683062 | 0/8 |
| 5. Mini-Decoder Bitslip Walk | 12 | B029-B040 | byte-boundary lock through bitslip rotation | 0/12 |
| 6. Training to Steady Transition | 10 | B041-B050 | engine attach / release per mode_mask | 0/10 |
| 7. Counter Aperture | 4 | B051-B054 | LANE_SELECT atomicity and out-of-range behavior | 0/4 |
| 8. Per-lane Counter Set | 14 | B055-B068 | every counter increments per defined event | 0/14 |
| 9. Engine Pool Steering | 10 | B071-B080 | shared engine pool attach / release; legacy parity | 0/10 |

---

## 2. CSR Identity and Header

| ID | Method | Scenario | Iter | Stimulus | Pass Criteria | Function Reference |
|----|--------|----------|------|----------|--------------|--------------------|
| B001 | D | Read UID after cold reset | 1 | Hold both resets 16 cycles, release. Read CSR word 0. | Returns `0x4C564453` (ASCII `LVDS`). | TBD |
| B002 | D | Write to UID is silently ignored | 1 | Read UID, write `0xDEADBEEF` to word 0, read again. | Both reads equal `0x4C564453`; no `waitrequest` deadlock. | TBD |
| B003 | D | META page 0 returns VERSION | 1 | Write `0` to word 1, read word 1. | Returns `{MAJOR=26, MINOR=0, PATCH=0, BUILD=0x429}` packed `[31:24],[23:16],[15:12],[11:0]`. | TBD |
| B004 | D | META page 1 returns DATE | 1 | Write `1` to word 1, read word 1. | Returns `0x20260429`. | TBD |
| B005 | D | META page 2 returns GIT | 1 | Write `2` to word 1, read word 1. | Returns the build-time `VERSION_GIT` constant; the harness shadows the value. | TBD |
| B006 | D | META page 3 returns INSTANCE_ID | 1 | Write `3` to word 1, read word 1. | Returns the integration-time `INSTANCE_ID` constant. | TBD |
| B007 | D | META invalid page selector holds last valid value | 1 | Write `0`, read; write `4`, read. | Second read still returns the page-0 (VERSION) value. | TBD |
| B008 | D | Capability word reports compile-time geometry | 1 | Read CSR `capability` word. | Reports `N_LANE`, `N_ENGINE`, `ROUTING_TOPOLOGY` enum, `SCORE_WINDOW_W`. Bit-fields per `_hw.tcl`. | TBD |
| B009 | D | Sync-pattern reset value is K28.5 | 1 | Read CSR `sync_pattern` after reset. | Returns `0011111010` (`0xFA`). | TBD |
| B010 | D | Sync-pattern runtime overwrite | 1 | Write K28.0 (`0xF4`) to `sync_pattern`, read back, observe DUT switching mini-decoder anchor. | Readback equals the written value; mini-decoder loses K28.5 lock and acquires K28.0 lock within `score_window_w + dpa_lock_delay_cycles_p` cycles. | TBD |

---

## 3. Per-lane Control Words

| ID | Method | Scenario | Iter | Stimulus | Pass Criteria | Function Reference |
|----|--------|----------|------|----------|--------------|--------------------|
| B011 | D | `lane_go` reset value all-on | 1 | Read `lane_go` after reset. | Lower `N_LANE` bits = 1; upper bits = 0. | TBD |
| B012 | D | `lane_go` clear stops one lane | 1 | Write `lane_go` clearing bit 0 only. Inject K28.5 idle. | Lane 0 produces no AVST output, all other lanes still decode K28.5. | TBD |
| B013 | D | `lane_go` all-clear stops every lane | 1 | Write `lane_go=0`. Inject K28.5 on every lane. | No AVST output on any lane; counters remain frozen. | TBD |
| B014 | D | `dpa_hold` per-lane | 1 | Set `dpa_hold[0]=1`. Reset and bring-up. | Lane 0 stays in DPA-held state; `coe_ctrl_dpahold[0]` asserted; other lanes lock normally. | TBD |
| B015 | D | `soft_reset_req` per-lane self-clear | 1 | Set `soft_reset_req[0]=1`. Wait for the lane to reach IDLE. | DUT clears bit 0 of `soft_reset_req` automatically; counters for lane 0 reset to zero; lane re-enters training. | TBD |
| B016 | D | `mode_mask` = `bit_slip` (legacy) | 1 | Set `mode_mask[0]=00`. Inject K28.5 on lane 0. | Lane 0 walks bitslip until lock; engine pool never attaches lane 0; `engine_steerings[0]` stays zero. | TBD |
| B017 | D | `mode_mask` = `adaptive` (eager) | 1 | Set `mode_mask[0]=01`. Inject K28.5 on lane 0. | Engine pool attaches lane 0 within `dpa_lock_delay_cycles_p` cycles after first valid symbol; `engine_steerings[0]` increments by 1. | TBD |
| B018 | D | `mode_mask` = `auto` (training only) | 1 | Set `mode_mask[0]=10`. Inject K28.5 on lane 0. Inject one glitch later. | Engine attaches at first lock then detaches; the glitch re-triggers attach; `engine_steerings[0]` ends at 2. | TBD |
| B019 | D | `score_accept` clamp on out-of-range write | 1 | Write `0xFFFF_FFFF` to `score_accept`. Read back. | Readback equals `2^SCORE_WINDOW_W - 1`; engine still produces accept verdicts. | TBD |
| B020 | D | `score_reject` clamp below `score_accept` | 1 | Write `score_reject = score_accept`. Read back. | Readback equals `score_accept - 1` (clamped); engine still produces reject verdicts on the rejection threshold. | TBD |

---

## 4. PHY Power-up and DPA Sequence

| ID | Method | Scenario | Iter | Stimulus | Pass Criteria | Function Reference |
|----|--------|----------|------|----------|--------------|--------------------|
| B021 | D | `coe_ctrl_pllrst` asserted out of cold reset | 1 | Hold `rsi_data_reset` then release; `coe_ctrl_plllock` deasserted. | DUT asserts `coe_ctrl_pllrst` for at least 8 cycles, then deasserts; per Intel doc 683062 §1.5.3.1 ALTLVDS_RX initialization. | TBD |
| B022 | D | DPA training released after `coe_ctrl_plllock` | 1 | After cold reset, drive `coe_ctrl_plllock=1`. | `coe_ctrl_dparst[*]` deasserts within 4 cycles; `coe_ctrl_lockrst[*]` pulses; per Intel doc 683062 §1.5.2.2. | TBD |
| B023 | D | Per-lane DPA lock acquisition | 1 | After §B022 setup, drive `coe_ctrl_dpalock[0]=1` after the harness's `dpa_lock_delay_cycles_p`. | DUT routes lane 0 into the mini-decoder data path; `coe_ctrl_dpahold[0]=0`; lane 0 begins emitting decoded bytes after sync-pattern lock. | TBD |
| B024 | D | FIFO reset issued after DPA lock | 1 | Same as §B023; observe `coe_ctrl_fiforst[0]`. | DUT pulses `coe_ctrl_fiforst[0]=1` for one cycle after `coe_ctrl_dpalock[0]` rises; per Intel doc 683062 §1.5.2.2. | TBD |
| B025 | D | DPA does not start without PLL lock | 1 | Hold `coe_ctrl_plllock=0`. | DUT keeps `coe_ctrl_dparst[*]=1`, `coe_ctrl_lockrst[*]=1`, `coe_ctrl_dpahold[*]=1` for the entire test. No CSR-visible counter changes. | TBD |
| B026 | D | Control reset release independent of data reset | 1 | Release `rsi_control_reset` only. | CSR responds to identity reads; `coe_ctrl_pllrst` stays asserted because the data domain is still in reset. | TBD |
| B027 | D | Data reset release independent of control reset | 1 | Release `rsi_data_reset` only. | DUT walks the PHY init sequence as in B021–B024; CSR is unreachable until control reset releases. | TBD |
| B028 | D | Cold reset returns IP to defaults | 1 | Run B015 (soft-reset on lane 0) and write a non-default `sync_pattern`. Then assert both resets. | After release, every CSR word reads its reset value; every counter is 0; `lane_go` is back to all-on. | TBD |

---

## 5. Mini-Decoder Bitslip Walk

| ID | Method | Scenario | Iter | Stimulus | Pass Criteria | Function Reference |
|----|--------|----------|------|----------|--------------|--------------------|
| B029 | D | Already aligned: phase-0 K28.5 | 1 | Drive K28.5 starting at the natural 10-bit phase. | DUT issues zero `coe_ctrl_bitslip[0]` pulses; lane 0 emits decoded `K28.5` bytes within `dpa_lock_delay_cycles_p + score_window_w`. | TBD |
| B030 | D | Phase-1 misalignment | 1 | Drive K28.5 with the 10b stream rotated by 1 bit. | DUT pulses `coe_ctrl_bitslip[0]` exactly 1 time; lock acquired. | TBD |
| B031 | D | Phase-2 misalignment | 1 | Same as B030 with rotation 2. | 2 bitslip pulses; lock acquired. | TBD |
| B032 | D | Phase-5 misalignment | 1 | Rotation 5. | 5 bitslip pulses; lock acquired. | TBD |
| B033 | D | Phase-9 misalignment | 1 | Rotation 9. | 9 bitslip pulses; lock acquired without rolling over. | TBD |
| B034 | D | Phase-10 rollover | 1 | Drive a stream that needs the 10th pulse, harness asserts `coe_ctrl_rollover[0]=1` per Intel doc 683062 §1.2.2 (`rx_cda_max=10`). | DUT observes rollover; `realigns[0]` increments by 1; lock acquired at the wrapped phase. | TBD |
| B035 | D | Inverted starting RD | 1 | Drive K28.5 with negative starting RD instead of the harness default positive. | Mini-decoder converges; no `code_violations` on the locked stream; one transient `disp_violations` allowed during the convergence window. | TBD |
| B036 | D | 4 lanes, all phase-5 | 1 | All lanes start at phase 5. | All lanes pulse `coe_ctrl_bitslip` 5 times; all converge within `dpa_lock_delay_cycles_p`. | TBD |
| B037 | D | 4 lanes, mixed phases (1, 3, 5, 7) | 1 | Each lane at its own phase. | Each lane independently issues `bitslip_events[i] = phase_i`; no cross-lane interference; `realigns[i]` increments only on the locked lane that hit rollover (none in this case). | TBD |
| B038 | D | `N_LANE` lanes, full phase sweep | 1 | Lane `i` starts at phase `i % 10`. | Per-lane bitslip count equals `phase_i`; all lanes lock; `engine_steerings` per lane equals 0 in `mode_mask=bit_slip` and 1 in `mode_mask=adaptive`. | TBD |
| B039 | D | `loss_sync_pattern` asserted during walk | 1 | Same as B032; observe AVST `error[2]` during the walk. | `error[2]` (`loss_sync_pattern`) stays 1 for every cycle from reset release to the cycle after lock; deasserts cleanly thereafter. | TBD |
| B040 | D | `loss_sync_pattern` cleared after lock | 1 | After B032 lock, hold K28.5 idle for 200 cycles. | `error[2]` stays 0; `comma_losses[0]` does not increment. | TBD |

---

## 6. Training to Steady Transition

| ID | Method | Scenario | Iter | Stimulus | Pass Criteria | Function Reference |
|----|--------|----------|------|----------|--------------|--------------------|
| B041 | D | Single-lane training to engine attach | 1 | `mode_mask=adaptive`. Bring up lane 0 from phase 5. | Mini-decoder locks first; engine attaches within `score_window_w` cycles after lock; `engine_steerings[0]=1`. | TBD |
| B042 | D | Single-lane engine release after sustained accept | 1 | Continue B041 traffic for `engine_release_cycles_p` (default 4096). | Engine detaches; `engine_attach_lane[0] == -1`; `engine_steerings[0]` still 1. | TBD |
| B043 | D | `N_ENGINE=1` reuse cycle | 1 | Build with `N_ENGINE=1`. Bring up lane 0, let engine release, then bring up lane 1. | Engine attaches lane 0, releases, attaches lane 1; `engine_steerings = [1, 1, 0, ...]`. | TBD |
| B044 | D | `N_ENGINE=4`, two lanes simultaneously | 1 | Build with `N_ENGINE=4, N_LANE=12`. Bring up lanes 0 and 6 from phase 3. | Engines 0 and 1 attach in parallel; lane 0 and lane 6 lock within the same window. | TBD |
| B045 | D | `N_ENGINE=N_LANE` legacy parity | 1 | Build with `N_ENGINE=N_LANE=9`. Bring up all lanes. | Each engine attaches its dedicated lane; engines never release; the decoded byte stream is bit-identical to the legacy 25.1.0631 IP for the same K28.5 input. | TBD |
| B046 | D | `lane_go=0` blocks engine attach | 1 | Set `lane_go[0]=0`. Drive K28.5 on lane 0. | Engine never attaches lane 0; `engine_steerings[0] = 0`. Other lanes work normally. | TBD |
| B047 | D | `dpa_hold` defers training | 1 | Set `dpa_hold[0]=1` at reset. Drive K28.5. | DUT does not pulse `coe_ctrl_bitslip[0]` while `dpa_hold[0]=1`; clear the bit; bitslip walk starts. | TBD |
| B048 | D | `mode_mask=bit_slip` never invokes engine | 1 | Set `mode_mask[*]=00`. Run §B038 stimulus. | All lanes lock through bit-slip only; `engine_steerings[*] = 0` throughout. | TBD |
| B049 | D | `mode_mask=adaptive` invokes engine eagerly | 1 | Set `mode_mask[*]=01`. Run §B038 stimulus. | Each lane has `engine_steerings[i] = 1` after the initial lock; engines remain attached until release window expires. | TBD |
| B050 | D | `mode_mask=auto` invokes engine only on error | 1 | Set `mode_mask[*]=10`. Run §B038 stimulus, then inject one `glitch_one_byte` on lane 3. | `engine_steerings[3] = 2` (initial training + glitch); `engine_steerings[i!=3] = 1` (initial only). | TBD |

---

## 7. Counter Aperture

| ID | Method | Scenario | Iter | Stimulus | Pass Criteria | Function Reference |
|----|--------|----------|------|----------|--------------|--------------------|
| B051 | D | `LANE_SELECT` atomic over 10 reads | 1 | After steady state, write `LANE_SELECT=3`, read 10 counter words. | All 10 reads return lane 3's counter values as captured at the cycle of `LANE_SELECT` write; no half-stale words. | TBD |
| B052 | D | `LANE_SELECT` reset default = 0 | 1 | Read `LANE_SELECT` after reset. | Returns 0. | TBD |
| B053 | D | `LANE_SELECT` change between reads | 1 | Write `LANE_SELECT=2`, read counter 0; write `LANE_SELECT=5`, read counter 0. | First read returns lane 2's counter 0; second read returns lane 5's counter 0; no leakage. | TBD |
| B054 | D | `LANE_SELECT` out-of-range | 1 | Write `LANE_SELECT=N_LANE+3`, read counter 0. | DUT clamps the index to `N_LANE-1` and returns lane `N_LANE-1`'s counter (clamp policy must be CSR-documented). | TBD |

---

## 8. Per-lane Counter Set

| ID | Method | Scenario | Iter | Stimulus | Pass Criteria | Function Reference |
|----|--------|----------|------|----------|--------------|--------------------|
| B055 | D | `code_violations` increments | 1 | Inject one `code_violation` symbol on lane 0. | `code_violations[0]` increments by 1; `error[0]` (`decode_error`) pulses; other counters unchanged. | TBD |
| B056 | D | `disp_violations` increments | 1 | Inject one `disp_violation` symbol on lane 0. | `disp_violations[0]` increments by 1; `error[1]` (`parity_error`) pulses; other counters unchanged. | TBD |
| B057 | D | `comma_losses` on K28.5 dropout | 1 | After lock, drive non-K28.5 for `comma_loss_cycles_p` (4 cycles). | `comma_losses[0]` increments by 1; `error[2]` (`loss_sync_pattern`) reasserts. | TBD |
| B058 | D | `bitslip_events` counts pulses | 1 | Run B032 (5 bitslip pulses needed). | `bitslip_events[0] = 5`. | TBD |
| B059 | D | `dpa_unlocks` on `dpalock` falling edge | 1 | Inject a `dpa_unlock_pulse` on lane 0. | `dpa_unlocks[0]` increments by 1. | TBD |
| B060 | D | `realigns` on phase change | 1 | After lock at phase 0, force a phase change to phase 7 by walking bitslip. | `realigns[0]` increments by 1 (the engine picked a new phase). | TBD |
| B061 | D | `score_changes` on engine update | 1 | `mode_mask=adaptive`. Drive a phase-2 stream so the engine updates its best-score during the score window. | `score_changes[0]` increments per best-score update; the value at end of window equals the count of update cycles observed in the harness. | TBD |
| B062 | D | `engine_steerings` on attach | 1 | Use B043 setup. | `engine_steerings[0]=1` after lane 0 attach; `engine_steerings[1]=1` after lane 1 attach. | TBD |
| B063 | D | `soft_resets` counts requests | 1 | Set `soft_reset_req[0]=1` three times in a row, waiting for self-clear each time. | `soft_resets[0]=3`. | TBD |
| B064 | D | `uptime_since_lock` advances | 1 | After lane 0 lock, wait `1000` cycles, read counter. | `uptime_since_lock[0] = 1000` (±1 due to read-pipeline). | TBD |
| B065 | D | `uptime_since_lock` resets on comma loss | 1 | After §B064, inject K28.5 dropout (B057), read counter. | `uptime_since_lock[0]` resets to a small value (less than 100 cycles since lock recovered). | TBD |
| B066 | D | Two counters increment same cycle | 1 | Inject one symbol that is both `code_violation` and `disp_violation` (impossible by 8b/10b table; harness uses an illegal-RD legal-table symbol — choose one and document). Iteration alternative: inject two symbols on lane 0 and lane 1 in the same cycle, one of each class. | Cross-class case: both `code_violations[0]` and `disp_violations[1]` increment in the same `csi_data_clk` edge; no counter interference. | TBD |
| B067 | D | Aperture readback equals direct CSR shadow | 1 | After several increments, dump every lane's counters via the aperture and via a debug-mode direct address. | Both views agree exactly. | TBD |
| B068 | D | All counters readable on every enabled lane | 1 | After §B038 stimulus and §B055 + §B056 injections on every lane, dump all counters. | Every lane reports the expected counter set; no aperture aliasing between lanes. | TBD |

---

## 9. Engine Pool Steering

| ID | Method | Scenario | Iter | Stimulus | Pass Criteria | Function Reference |
|----|--------|----------|------|----------|--------------|--------------------|
| B071 | D | `N_ENGINE=1, N_LANE=12, full_xbar` reachability | 1 | Build the primary signoff config. Bring up all 12 lanes one at a time. | Engine attaches each lane in turn; `engine_steerings = [1,1,…,1]`. | TBD |
| B072 | D | `N_ENGINE=1` legacy parity falsifier | 1 | Build with `N_ENGINE=1, N_LANE=9`. Drive 9 simultaneous K28.5 streams. | The engine cycles through all 9 lanes with bounded latency; the DUT does **not** match legacy 25.1.0631 byte-stream during the cycling — the DV plan accepts this by design (degraded steady state). The decoded bytes still satisfy MuTRiG frame deassembly when accompanied by `loss_sync_pattern` sidebands. | TBD |
| B073 | D | `N_ENGINE=N_LANE, full_xbar` legacy parity | 1 | Build legacy parity config (`N_ENGINE=9, N_LANE=9`). Replay the saved 25.1.0631 trace. | Decoded byte stream is bit-identical to the saved trace. | TBD |
| B074 | D | `N_ENGINE=2, N_LANE=12, full_xbar` round-robin | 1 | Bring up all 12 lanes. | Engines 0 and 1 attach in pairs; the harness records the attach order; round-robin scoreboard expectation matches DUT behavior. | TBD |
| B075 | D | `N_ENGINE=4, butterfly_half` reachability | 1 | Build `topo_butterfly_h`. Bring up lanes 0, 3, 6, 9. | Each lane is reached by an engine in its butterfly subset within `attach_latency_cycles_p`. | TBD |
| B076 | D | `N_ENGINE=4, butterfly_quarter` reachability | 1 | Build `topo_butterfly_q`. Bring up lanes 0, 3, 6, 9. | Same as B075 with the smaller fanout subset; attach latency is recorded and compared to B075. | TBD |
| B077 | D | `N_ENGINE=4, nearest_k` reachability | 1 | Build `topo_nearest_k`. Bring up lanes 0, 3, 6, 9. | Same as B075 with `k`-neighbour fanout. | TBD |
| B078 | D | Engine release after sustained accept | 1 | `N_ENGINE=4`. Bring up lane 0; wait `engine_release_cycles_p`; observe release. | Engine 0 detaches; `engine_busy_mask` shows the change; lane 0 falls back to mini-decoder. | TBD |
| B079 | D | Engine reattach on glitch after release | 1 | Continue B078 setup; inject `glitch_one_byte` on lane 0. | An engine reattaches lane 0 within `attach_latency_cycles_p`; `engine_steerings[0]=2`. | TBD |
| B080 | D | Engine pool full-occupancy | 1 | `N_ENGINE=4`. Trigger glitches on lanes 0,3,6,9 within the same cycle. | All four engines attached; `engine_busy_mask = 0xF`; `engine_pool_occupancy_max` cover bin hit at `4/N_ENGINE`. | TBD |
