# DV Prof — mu3e_lvds_controller (SV rebuild)

**Companion docs:** [DV_PLAN.md](DV_PLAN.md), [DV_HARNESS.md](DV_HARNESS.md),
[DV_BASIC.md](DV_BASIC.md), [DV_EDGE.md](DV_EDGE.md),
[DV_ERROR.md](DV_ERROR.md), [DV_CROSS.md](DV_CROSS.md),
[DV_FORMAL.md](DV_FORMAL.md), [DV_COV.md](DV_COV.md),
[BUG_HISTORY.md](../BUG_HISTORY.md)

**Parent:** [DV_PLAN.md](DV_PLAN.md)
**ID Range:** P001-P040
**Total:** 40 cases (0 implemented / 0 waived)

**Methodology key:**
- **D** = Directed (hand-crafted stimulus, deterministic)
- **R** = Constrained-random (LCG-based PRNG from `mutrig_common_pkg`; no SystemVerilog `rand`)

The P-bucket targets stress, soak, throughput, contention, and counter
saturation. The point is not to prove the IP works — BASIC and EDGE
already do that. The point is to prove the IP keeps working when:

- the engine pool is overloaded for long stretches;
- counters approach saturation;
- the AVST sink applies backpressure;
- glitches arrive on every lane every few thousand symbols for
  millions of symbols;
- the harness exercises every legal corner of the
  `(N_LANE, N_ENGINE, ROUTING_TOPOLOGY, SCORE_WINDOW_W, SYNC_PATTERN)`
  matrix.

---

## 1. Summary

| Section | Cases | ID Range | What it Proves | Current Case |
|---------|-------|----------|----------------|--------------|
| 2. Random Glitch Soak | 10 | P001-P010 | nominal-load behavior over millions of symbols | 0/10 |
| 3. Throughput and Backpressure | 10 | P011-P020 | line-rate sustainment under various AVST ready patterns | 0/10 |
| 4. Counter Saturation | 4 | P021-P024 | every counter saturates at 0xFFFFFFFF, never wraps | 0/4 |
| 5. Long-run Stability | 6 | P025-P030 | no phantom events, no slow leaks under sustained idle | 0/6 |
| 6. Random Steering Sweep | 10 | P031-P040 | parameter-randomised closure across the build matrix | 0/10 |

---

## 2. Random Glitch Soak

| ID | Method | Scenario | Iter | Stimulus | Pass Criteria | Function Reference |
|----|--------|----------|------|----------|--------------|--------------------|
| P001 | D | 100k K28.5 idle, no glitch | 1 | All lanes K28.5 idle for 100,000 symbols. | Every counter except `uptime_since_lock` stays 0; decoded byte stream is exactly `K28.5` repeated. | TBD |
| P002 | R | 100k symbols, 1% glitch on all lanes | 4 | Per-cycle 1% probability of `glitch_one_byte` on each lane, independent. PRNG seeded per iteration. | Total injected glitches across all lanes = sum of per-lane `code_violations + disp_violations + comma_losses` (within ±2 per lane); `engine_steerings` total equals the harness's expected steering count. | TBD |
| P003 | R | 100k symbols, contention sweep | 4 | `N_ENGINE=1`. Per-cycle 5% probability of glitch on each of 12 lanes. | `aggregate_steering_queue_overflows` matches harness expectation; lanes that overflowed produce degraded bytes with `loss_sync_pattern` continuously while not engine-served; the scoreboard records every degraded byte as a `controlled` loss tier. | TBD |
| P004 | R | 1M symbols, 0.1% glitch rate | 1 | Per-cycle 0.1% per lane. | Same scoreboard contract as P002 but at 10× length; counter values match within ±0.5%. | TBD |
| P005 | R | 1M symbols, 1% glitch rate | 1 | Per-cycle 1% per lane. | Same as P004; counter values match within ±0.5%. | TBD |
| P006 | D | Worst-case steering latency | 1 | `N_ENGINE=1`. Inject one glitch on lane 0, immediately followed (next cycle) by one glitch on lane 11; repeat every 100 symbols for 100,000 symbols. | Worst observed steering latency for lane 11 ≤ `attach_latency_cycles_p + score_window_w + 1`; record the 99th-percentile and max into `DV_REPORT.json` for the txn-growth curve. | TBD |
| P007 | R | Mixed framed traffic + glitches | 4 | 1M symbols of `framed_dxx` (K28.5 + 32 data bytes + K28.5) with 1% per-symbol glitch. | Decoded byte order is preserved on every lane (no reordering); every glitch is accompanied by a corresponding `error[2:0]` pulse; no silent byte loss. | TBD |
| P008 | D | 100M-symbol K28.5 line-rate sustainment | 1 | All `N_LANE` lanes at 1.25 Gbps × 10b deserialised → 125 MHz parallel; 100M symbols. | No counter saturation (all stay below 0xFFFFFFFF); throughput in beats/cycle = 1 on every lane (excluding rare backpressure cycles introduced by the AVST sink). | TBD |
| P009 | R | Random sync-pattern transient changes | 2 | Random per-iteration sequence of `sync_pattern` writes (K28.5 ↔ K28.0 ↔ K23.7) every 50,000 symbols, for 1M symbols. | Each transient triggers `comma_losses++` on every locked lane; subsequent recovery is bounded; total `comma_losses[i]` matches the harness's expected count. | TBD |
| P010 | R | Random soft-resets during soak | 2 | Random `soft_reset_req[i]` every 100k cycles per lane, for 1M cycles. | Each soft-reset event clears that lane's counters and increments `soft_resets[i]`; other lanes' counters are unchanged; no DUT deadlock. | TBD |

---

## 3. Throughput and Backpressure

| ID | Method | Scenario | Iter | Stimulus | Pass Criteria | Function Reference |
|----|--------|----------|------|----------|--------------|--------------------|
| P011 | D | 1M-cycle line-rate sustainment | 1 | All lanes K28.5 idle. AVST sink permanently `ready=1`. | Throughput per lane = 1 beat/cycle exactly (no `valid` skipped); `aso_decoded[i].error == 0` every cycle. | TBD |
| P012 | R | 50% random backpressure | 4 | AVST sink `ready` toggles at 50% per cycle. | Decoded byte sequence preserved; the harness's expected byte-count delivered equals what was injected. AVST hold contract (`valid && !ready` → payload stable) holds — `sva_avalon_st` covers it. | TBD |
| P013 | D | Burst stalls | 1 | AVST sink `ready=0` for 10 cycles every 1000 beats. | Decoded byte sequence preserved; no FIFO overflow inside the DUT (the legacy IP does not have an AVST FIFO, so the DUT relies on backpressure to upstream — verify this is preserved). | TBD |
| P014 | D | Permanent backpressure on one lane | 1 | AVST sink for lane 5 has `ready=0` permanently. | DUT does not stall the entire IP; other lanes still produce decoded bytes. Lane 5's mini-decoder asserts `loss_sync_pattern` after the internal stall window expires (codex must define and document the window). | TBD |
| P015 | R | Mixed ready patterns per lane | 4 | Lane 0: always-ready. Lane 1: 50% random. Lane 2: stall_burst. Lane 3: permanent backpressure. Repeat for `N_LANE=12`. | Per-lane behavior independent; no cross-lane perturbation; counters per lane match per-lane expectation. | TBD |
| P016 | R | Throughput with engine churn | 2 | Run P008 stimulus + 1% glitch per lane. | Throughput per lane ≥ 0.99 beats/cycle when glitches dominate steering; lower bound captured for the build's degraded-mode budget; record into `DV_REPORT.json`. | TBD |
| P017 | R | Throughput with periodic DPA unlock | 2 | One `dpa_unlock_pulse` per lane every 50,000 cycles. | Each unlock triggers a brief degraded mode (≤ `dpa_lock_delay_cycles_p + score_window_w` cycles); steady-state throughput recovers. `dpa_unlocks` per lane matches injection count. | TBD |
| P018 | R | Throughput with sync-pattern flips | 2 | Toggle `sync_pattern` every 100k cycles. | Each flip triggers per-lane re-lock; throughput dips by exactly the lock latency; recover and continue. | TBD |
| P019 | D | Minimum lane count | 1 | Build with `N_LANE=1`. Run P008 stimulus. | Single lane sustains line rate; no `N_LANE>0` invariant violation. | TBD |
| P020 | D | Maximum lane count | 1 | Build with `N_LANE=32`. Run P008 stimulus. | All 32 lanes sustain line rate; CSR aperture handles 32 lanes (`LANE_SELECT[5:0]`); no decode aliasing. | TBD |

---

## 4. Counter Saturation

| ID | Method | Scenario | Iter | Stimulus | Pass Criteria | Function Reference |
|----|--------|----------|------|----------|--------------|--------------------|
| P021 | D | `code_violations` saturates | 1 | Inject `code_violation` on lane 0 every cycle until `code_violations[0] == 0xFFFFFFFF`. Continue injection for 1000 more cycles. | Counter saturates at `0xFFFFFFFF`, does not wrap to 0; `sva_counter_sat` holds. | TBD |
| P022 | D | `disp_violations` saturates | 1 | Same approach with `disp_violation` injection. | Same saturation behavior. | TBD |
| P023 | D | `bitslip_events` saturates | 1 | Continuous `bitslip_walk` to force `bitslip_events[0] == 0xFFFFFFFF`. | Same saturation behavior. | TBD |
| P024 | D | `uptime_since_lock` saturates | 1 | Lock lane 0 and run idle for 2^32 cycles (or use a debug knob to advance the counter to 0xFFFFFFFE then run idle for 2 cycles). | Counter saturates at `0xFFFFFFFF`. | TBD |

---

## 5. Long-run Stability

| ID | Method | Scenario | Iter | Stimulus | Pass Criteria | Function Reference |
|----|--------|----------|------|----------|--------------|--------------------|
| P025 | D | 10G-symbol soak (24h-sim equivalent) | 1 | All lanes K28.5 idle for 10G symbols (use checkpoint UCDBs at log-spaced intervals: `1M, 2M, 4M, ..., 10G`). | No phantom counter increments; `code_violations`, `disp_violations`, `comma_losses` stay 0; checkpoint UCDB curve in `tb/uvm/cov_after/txn_growth/P025_*` is monotone-flat in functional-coverage axes that should not increase. | TBD |
| P026 | D | No phantom error events under idle | 1 | Same as P025 with shorter horizon (1M symbols). | `error[2:0]` stays 0 every cycle; no spurious `loss_sync_pattern`. | TBD |
| P027 | D | No phantom engine_steerings under idle | 1 | Same setup. | `engine_steerings[i]` per lane equals the count from initial training only (1 with `mode_mask=adaptive`, 0 with `mode_mask=bit_slip`). | TBD |
| P028 | D | Periodic counter readback during idle | 1 | Read every counter on every lane every 1000 cycles for 1M cycles. | Counter values either monotonically increase or stay flat; no decreases. | TBD |
| P029 | D | Periodic soft-reset during idle | 1 | Issue `soft_reset_req[lane]` for round-robin lanes every 1M cycles for 10M cycles. | Each soft-reset cleanly resets that lane; no drift in unaffected lanes. | TBD |
| P030 | D | PLL lock churn | 1 | Pulse `coe_ctrl_plllock=0` for 1 cycle every 100k cycles for 1M cycles. | Each pulse triggers full re-init from §B021; `dpa_unlocks` per lane matches the pulse count. | TBD |

---

## 6. Random Steering Sweep

| ID | Method | Scenario | Iter | Stimulus | Pass Criteria | Function Reference |
|----|--------|----------|------|----------|--------------|--------------------|
| P031 | R | Random glitch class per cycle | 10000 | Per cycle pick from {none, code_violation, disp_violation, comma_loss, bitslip} with weights (90, 4, 3, 2, 1). 100k cycles per iteration. | All counters match the harness's per-class injection count within ±0.1%. | TBD |
| P032 | R | Random lane targeting | 10000 | Per glitch event, target one lane uniformly at random. 100k cycles. | Per-lane counter sums match the per-lane uniform expectation within ±0.5%. | TBD |
| P033 | R | Random engine attach delay | 10000 | Sweep `engine_release_cycles_p` and `attach_latency_cycles_p` randomly per iteration. | Engine release/attach is bounded; `engine_steerings` count matches harness expectation. | TBD |
| P034 | R | Random score window changes | 10000 | Random CSR writes to `score_accept` and `score_reject` every 10k cycles. | Engine never drops below `score_reject` without producing a reject; never exceeds `score_accept` without producing an accept; no CSR-induced deadlock. | TBD |
| P035 | R | Random sync-pattern changes | 10000 | Random `sync_pattern` writes every 100k cycles, drawn from {K28.5, K28.0, K23.7}. | Per-lane re-lock observed for every change; `comma_losses` per lane matches change count. | TBD |
| P036 | R | Random `mode_mask` flips | 10000 | Random per-lane `mode_mask` writes every 50k cycles. | Per-lane behavior switches per spec; counters preserved across the change (codex must commit and document whether `mode_mask` change resets counters; the DV plan's expectation is *no reset*). | TBD |
| P037 | R | Random build matrix sweep | 18 | One iteration per legal `(N_LANE, N_ENGINE, ROUTING_TOPOLOGY, SCORE_WINDOW_W, SYNC_PATTERN, INSTANCE_ID)` corner from the DV_PLAN sweep matrix. Run a 100k-symbol soak per build. | Every build closes with zero `uvm_error_count`; functional-coverage cross-axes hit per `DV_CROSS.md`. | TBD |
| P038 | R | Random `LANE_SELECT` cadence | 10000 | Random `LANE_SELECT` writes interleaved with random counter reads. | LANE_SELECT atomicity (`sva_csr_aperture`) holds; no half-stale reads. | TBD |
| P039 | R | Random soft-reset cadence | 10000 | Random `soft_reset_req[i]` every 10k–1M cycles. | Each request cleanly resets that lane; `soft_resets` per lane matches request count. | TBD |
| P040 | R | 1G-cycle mixed random workload | 1 | All randomisation knobs above active simultaneously for 1G cycles. Checkpoint UCDBs at log-spaced txn boundaries (`1k, 2k, 4k, ..., 1G`). | No deadlock, no `uvm_error`, no SVA violation; `txn_growth_curve` published into `DV_REPORT.json`. | TBD |
