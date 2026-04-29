# DV Edge — mu3e_lvds_controller (SV rebuild)

**Companion docs:** [DV_PLAN.md](DV_PLAN.md), [DV_HARNESS.md](DV_HARNESS.md),
[DV_BASIC.md](DV_BASIC.md), [DV_PROF.md](DV_PROF.md),
[DV_ERROR.md](DV_ERROR.md), [DV_CROSS.md](DV_CROSS.md),
[DV_FORMAL.md](DV_FORMAL.md), [DV_COV.md](DV_COV.md),
[BUG_HISTORY.md](../BUG_HISTORY.md)

**Parent:** [DV_PLAN.md](DV_PLAN.md)
**ID Range:** E001-E050
**Total:** 50 cases (50 implemented / 0 waived)

**Methodology key:**
- **D** = Directed (hand-crafted stimulus, deterministic)
- **R** = Constrained-random (LCG-based PRNG from `mutrig_common_pkg`; no SystemVerilog `rand`)

The E-bucket exercises corners that BASIC does not reach: parameter
extremes, ties, contention beyond the engine pool size, restricted
routing topologies, counter-window wrap, and multi-lane non-interference.
A failure here is a real bug — the spec contract is precise enough
that there is no "we did not think about that" excuse.

---

## 1. Summary

| Section | Cases | ID Range | What it Proves | Current Case |
|---------|-------|----------|----------------|--------------|
| 2. Score Window and Threshold Edges | 10 | E001-E010 | score window length and threshold sweeps; tie-break rule | 10/10 |
| 3. Bitslip Walk Edges | 7 | E011-E017 | walk-off, contention with `dpa_hold`, rollover edge cases | 7/7 |
| 4. Engine Pool Contention | 6 | E018-E023 | `N_ENGINE` smaller than the hot-lane set; preempt and release | 6/6 |
| 5. Routing Topology Edges | 5 | E024-E028 | butterfly / nearest-k subsets; fabric exclusivity | 5/5 |
| 6. Counter Window Edges | 12 | E029-E040 | LANE_SELECT atomicity under stress; reserved-word policy | 12/12 |
| 7. Multi-lane Independence | 5 | E041-E045 | per-lane events do not perturb other lanes | 5/5 |
| 8. Sync Pattern Edges | 5 | E046-E050 | K28.0 / K23.7 / illegal sync pattern handling | 5/5 |

---

## 2. Score Window and Threshold Edges

| ID | Method | Scenario | Iter | Stimulus | Pass Criteria | Function Reference |
|----|--------|----------|------|----------|--------------|--------------------|
| E001 | D | `SCORE_WINDOW_W=6` build | 1 | Build with `SCORE_WINDOW_W=6`. Run B038 stimulus. | All lanes lock; engine accepts within 6 symbols when no error; `score_changes` does not exceed `2^6-1`. | TBD |
| E002 | D | `SCORE_WINDOW_W=16` build | 1 | Build with `SCORE_WINDOW_W=16`. Run B038 stimulus. | All lanes lock; engine accepts within 16 symbols; `score_changes` saturates at `2^16-1` only after sustained drift. | TBD |
| E003 | D | `score_accept = SCORE_WINDOW_W` (must-be-perfect) | 1 | Set `score_accept = SCORE_WINDOW_W`. Drive K28.5 idle. | Engine accepts only on perfect-window match; one bit-error during the window resets the score and re-accepts on the next perfect window. | TBD |
| E004 | D | `score_accept = 1` (one-bit accept) | 1 | Set `score_accept = 1`. Drive K28.5 idle. | Engine accepts on the first matching bit; tie-break selects the lowest phase index. | TBD |
| E005 | D | `score_reject = 0` always-rejects-below | 1 | Set `score_reject = 0`. Drive an unlocked stream then K28.5. | Engine reports `accept` on first match; never `reject` between accept events while `score_reject=0`. | TBD |
| E006 | D | Score tie between two phases | 1 | Inject a stream where phases 3 and 7 score the same window. | DUT picks phase 3 (lowest index); `engine_best_phase=3`; `realigns` does not increment when the tie clears in favour of phase 3. | TBD |
| E007 | D | Score tie between three phases | 1 | Inject a stream where phases 1, 4, 8 tie. | DUT picks phase 1; `engine_best_phase=1`. | TBD |
| E008 | D | Alternating accept/reject crossing threshold | 1 | Drive a stream that alternates score `score_accept` and `score_accept-1`. | Engine asserts `accept` then `reject` then `accept`; counter `score_changes` increments on every transition. | TBD |
| E009 | D | One bit error inside score window | 1 | Drive K28.5 with one bit flipped at the score window midpoint. | Score drops by 1 for that window; engine still asserts `accept` if `score >= score_accept`; `code_violations` does not increment for a flipped K28.5 (the symbol may still be table-legal). Document the symbol class chosen by the harness. | TBD |
| E010 | D | Perfect 100% score window | 1 | Drive K28.5 idle for 64 symbols. | `engine_score == SCORE_WINDOW_W`; engine accepts on first window. | TBD |

---

## 3. Bitslip Walk Edges

| ID | Method | Scenario | Iter | Stimulus | Pass Criteria | Function Reference |
|----|--------|----------|------|----------|--------------|--------------------|
| E011 | D | Bitslip walk-off (> 10 pulses) | 1 | Drive a stream that does not lock at any phase (random 10b). | DUT issues exactly 10 bitslip pulses then asserts `realigns[0]++` and requests DPA reset on lane 0; the request is observable via `coe_ctrl_dparst[0]` pulse. | TBD |
| E012 | D | Bitslip walk attempted during `dpa_hold=1` | 1 | Hold `dpa_hold[0]=1`. Drive a misaligned K28.5. | DUT issues zero bitslip pulses; lane 0 stays unlocked; clearing `dpa_hold[0]` then triggers the walk. | TBD |
| E013 | D | Back-to-back bitslip pulses | 1 | Drive a phase-9 misaligned stream. | DUT issues 9 bitslip pulses with the harness-required minimum spacing (per Intel doc 683062 — pulse must be high then low for at least 1 cycle each). The harness records the pulse sequence and asserts no spacing violation. | TBD |
| E014 | D | Bitslip walk on attached engine | 1 | `mode_mask=adaptive`; engine attached lane 0; force the lane back into bitslip-walk by injecting a glitch that the engine cannot recover. | DUT detaches the engine, lane 0 falls back to mini-decoder bitslip walk; `engine_steerings[0]` may have incremented twice (initial + retry); `realigns[0]` increments on the new phase pick. | TBD |
| E015 | D | Walk on lane 0 while lane 1 in steady state | 1 | Lane 1 already locked + engine attached. Trigger phase-7 walk on lane 0. | Lane 1 byte stream remains uninterrupted; lane 0 walks bitslip without any perturbation seen on lane 1's `aso_decoded[1]`. | TBD |
| E016 | D | Bitslip walk during PLL relock | 1 | Pulse `coe_ctrl_plllock=0` for 1 cycle while lane 0 is mid-walk. | DUT freezes lane 0 (no further bitslip pulses), reasserts `coe_ctrl_pllrst`, and replays init from §B021 once `plllock` returns. | TBD |
| E017 | D | Rollover at non-multiple-of-10 | 1 | Build with `rx_cda_max_p=7` in the harness PHY model (legal range 1..11 per Intel doc 683062 §1.2.2). Run a 7-pulse walk. | DUT observes `coe_ctrl_rollover[0]` after pulse 7; behaves identically to the 10-pulse rollover. | TBD |

---

## 4. Engine Pool Contention

| ID | Method | Scenario | Iter | Stimulus | Pass Criteria | Function Reference |
|----|--------|----------|------|----------|--------------|--------------------|
| E018 | D | `N_ENGINE=1`, glitch on 2 lanes same cycle | 1 | Build primary. Inject `glitch_one_byte` on lanes 3 and 7 in the same `csi_data_clk` cycle. | Engine attaches lane 3 first (lowest index); lane 7 enqueued; `steer_queue_count=1` peak; engine releases lane 3 then attaches lane 7; `engine_steerings = [.,.,.,1,.,.,.,1,...]`. | TBD |
| E019 | D | `N_ENGINE=1`, glitch on 4 lanes same cycle | 1 | Same as E018 with lanes 0,3,7,11. | All 4 lanes serviced sequentially; `steer_queue_count` peaks at 3; queue-overflow counter `aggregate_steering_queue_overflows` stays 0 (depth=4). | TBD |
| E020 | D | `N_ENGINE=1`, glitch on 12 lanes (queue overflow) | 1 | Build primary. Inject simultaneous glitches on all 12 lanes. | Steering queue fills to `STEER_QUEUE_DEPTH=4`; remaining 7 lanes increment `aggregate_steering_queue_overflows` by 7; lanes that did not get an engine emit degraded bytes with `loss_sync_pattern` until they self-recover via the mini-decoder bit-slip path. | TBD |
| E021 | D | `N_ENGINE=2`, glitch on 4 lanes (round-robin) | 1 | Build with `N_ENGINE=2`. Inject 4 simultaneous glitches. | Both engines busy for the entire test; service order is round-robin per the steering FSM rule documented in `DV_HARNESS.md §11`. | TBD |
| E022 | D | Engine preempted by lock loss | 1 | `mode_mask=adaptive`; engine attached lane 0. Force `coe_ctrl_dpalock[0]=0` for 1 cycle. | DUT detaches engine, increments `dpa_unlocks[0]` and `engine_steerings[0]` (release + reattach), restarts training on lane 0. | TBD |
| E023 | D | Engine attached lane goes idle | 1 | Engine attached lane 0. Write `lane_go[0]=0`. | DUT detaches engine (does not need a release window); engine becomes available; `engine_steerings[0]` does not increment further. | TBD |

---

## 5. Routing Topology Edges

| ID | Method | Scenario | Iter | Stimulus | Pass Criteria | Function Reference |
|----|--------|----------|------|----------|--------------|--------------------|
| E024 | D | `butterfly_half`: lane outside reachable subset | 1 | Build `topo_butterfly_h`. Force only engines 0 and 1 to be busy with lanes 0 and 3 (both in their subsets). Inject a glitch on lane 11 (in engine 2 or 3's subset only). | Engines 2 and 3 are still free — one of them attaches lane 11 within `attach_latency_cycles_p`. The harness verifies the partition via the elaboration-time reachability map. | TBD |
| E025 | D | `butterfly_quarter`: lane outside any free engine's subset | 1 | Build `topo_butterfly_q`. Force every engine into its subset's busiest lane. Inject glitch on lane 11 if no engine reaches it. | DUT increments `aggregate_steering_queue_overflows` for the unreachable glitch; lane 11 falls back to mini-decoder. The plan accepts this as a topology-induced degraded mode. | TBD |
| E026 | D | `nearest_k` boundary lane | 1 | Build `topo_nearest_k` with `k=2`. Inject glitch on lane 0 (boundary). | Only engines 0 and 1 (or the configured neighbours of lane 0) can attach; if both busy, the lane is queued; check the reachability map matches the static partition. | TBD |
| E027 | D | Topology change at runtime (rejected) | 1 | Attempt to write the topology selector via CSR (must not exist as RW). | The CSR address for topology is read-only or absent; any attempted write returns `waitrequest=0` and does not change behavior. The capability word still reports the compile-time topology. | TBD |
| E028 | D | Fabric one-hot exclusivity | 1 | Use the debug hook to pre-occupy an engine lane tag, then inject a routing request through the normal steering path. | `sva_routing_excl` stays quiet; no two engines claim the same lane; the runtime case contributes the exclusivity antecedent without using an expected-fail flow. | TBD |

---

## 6. Counter Window Edges

| ID | Method | Scenario | Iter | Stimulus | Pass Criteria | Function Reference |
|----|--------|----------|------|----------|--------------|--------------------|
| E029 | D | `LANE_SELECT` change mid-read | 1 | Issue `csr_read(COUNTER_BASE+0)` with `waitrequest=1` cycle injected by the harness, then write `LANE_SELECT=2` while the read is held, then release. | Read returns lane 0's counter (the lane selected at read-issue time), not lane 2's; `sva_csr_aperture` holds. | TBD |
| E030 | D | `LANE_SELECT` large value clamp | 1 | Write `LANE_SELECT=0xFF`. Read counter 0. | DUT clamps to `N_LANE-1`; readback returns lane `N_LANE-1`'s counter. | TBD |
| E031 | D | Concurrent counter increment during aperture read | 1 | After lane-0 setup, run a stream that increments `bitslip_events[0]` while the harness reads counter 3 (`bitslip_events`). | Read returns the value at the beginning of the read cycle (registered output); the next read after the increment shows the increment. No mid-read corruption. | TBD |
| E032 | D | Capability word write attempt | 1 | Write `0xFFFFFFFF` to capability word. | Read returns the capability bit field unchanged; no `waitrequest` deadlock. | TBD |
| E033 | D | Aperture word out of range read | 1 | After writing `LANE_SELECT=0`, read `COUNTER_BASE + 11*4` (one past the 10 counters). | Read returns 0 or the last valid aperture word (codex must commit and document); no `waitrequest` deadlock. | TBD |
| E034 | D | Reserved CSR word read | 1 | Read CSR word in the reserved range. | Returns 0; no side effect. | TBD |
| E035 | D | Reserved CSR word write | 1 | Write `0xDEADBEEF` to a reserved word, read back. | Read returns 0; write was silently ignored. | TBD |
| E036 | D | CSR write while `soft_reset_req[0]` self-clearing | 1 | Set `soft_reset_req[0]=1`. Immediately write to `mode_mask` while DUT is clearing the request. | Both writes complete (no `waitrequest` deadlock); `mode_mask` write takes effect after the soft-reset reaches IDLE. | TBD |
| E037 | D | Back-to-back CSR writes | 1 | Issue 8 consecutive writes to `score_accept`, `score_reject`, `mode_mask`, ..., with no gaps. | All 8 writes accepted; `waitrequest` may pulse but no write is lost; readback after all 8 matches the last write per word. | TBD |
| E038 | D | Read-modify-write of `mode_mask` | 1 | Read `mode_mask`, OR-in bit 5, write back. | Subsequent read returns the OR'd value; lane 5 switched mode. | TBD |
| E039 | D | CSR access at maximum address | 1 | Write+read at `2^AVMM_ADDR_W - 1`. | Returns the value at that aperture slot per the IP packaging definition; no decode-overflow into a wrong slot. | TBD |
| E040 | D | CSR access above maximum address | 1 | Write+read at the first address above the implemented CSR aperture. | DUT returns 0 / `waitrequest=0`; the access has no side effect on valid CSRs and remains legal in the promoted runtime frame. | TBD |

---

## 7. Multi-lane Independence

| ID | Method | Scenario | Iter | Stimulus | Pass Criteria | Function Reference |
|----|--------|----------|------|----------|--------------|--------------------|
| E041 | D | Bitslip walk lane 0 vs lane 1 steady | 1 | Lane 1 locked. Trigger phase-7 walk on lane 0. | Lane 1's decoded byte stream has zero deviation from K28.5; lane 1's `comma_losses` does not increment. | TBD |
| E042 | D | Glitch on lane 5 vs lane 6 traffic | 1 | Lane 6 locked. Inject `glitch_one_byte` on lane 5. | Lane 6's `error[0]` does not pulse; lane 6's counters do not increment. | TBD |
| E043 | D | Soft reset lane 3 vs lane 4 counters | 1 | Lane 4 has non-zero `bitslip_events[4]`. Set `soft_reset_req[3]=1`. | Lane 4's counters are unchanged; only lane 3's counters reset to zero. | TBD |
| E044 | D | DPA unlock pulse lane 2 vs engine on lane 0 | 1 | Engine attached lane 0. Pulse `coe_ctrl_dpalock[2]=0`. | Engine 0 still attached to lane 0 (no preemption from lane 2 event); `dpa_unlocks[2]` increments by 1. | TBD |
| E045 | D | Sync pattern change resets all lanes | 1 | All lanes locked on K28.5. Write `sync_pattern=K28.0`. | All lanes simultaneously assert `loss_sync_pattern`, then converge on K28.0; per-lane sequences are not cross-talked through the engine pool. | TBD |

---

## 8. Sync Pattern Edges

| ID | Method | Scenario | Iter | Stimulus | Pass Criteria | Function Reference |
|----|--------|----------|------|----------|--------------|--------------------|
| E046 | D | `sync_pattern=K28.0` lock | 1 | Build with `SYNC_PATTERN=K28.0` reset default. Drive K28.0 idle. | All lanes lock; decoded byte stream is `K28.0` repeated. | TBD |
| E047 | D | `sync_pattern=K23.7` lock | 1 | Build with `SYNC_PATTERN=K23.7`. Drive K23.7 idle. | All lanes lock; decoded byte stream is `K23.7` repeated. | TBD |
| E048 | D | Sync pattern with wrong RD start | 1 | Drive K28.5 with the alternate RD seed. | Mini-decoder asserts `disp_violations` once, then converges; `comma_losses` does not increment because the symbol is still legal-RD-pair. | TBD |
| E049 | D | Sync pattern transient change during traffic | 1 | All lanes locked on K28.5. Inject 1 cycle of K28.0 then revert. | `comma_losses` increments by 1 on each lane; `loss_sync_pattern` pulses; all lanes recover. | TBD |
| E050 | D | Illegal sync pattern (all-zero) | 1 | Write `sync_pattern=0x000`. | DUT preserves the last valid sync pattern and remains CSR-responsive; all lanes keep the documented lock/relock behavior. | TBD |
