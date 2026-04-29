# DV Plan — mu3e_lvds_controller (SystemVerilog rebuild)

**DUT:** `rtl/mu3e_lvds_controller.sv` (to be authored by codex)
**Packaging:** `script/mu3e_lvds_controller_hw.tcl` (to be authored by codex)
**Companion docs:** [DV_HARNESS.md](DV_HARNESS.md), [DV_BASIC.md](DV_BASIC.md),
[DV_EDGE.md](DV_EDGE.md), [DV_PROF.md](DV_PROF.md),
[DV_ERROR.md](DV_ERROR.md), [DV_CROSS.md](DV_CROSS.md),
[DV_FORMAL.md](DV_FORMAL.md), [DV_COV.md](DV_COV.md),
[BUG_HISTORY.md](../BUG_HISTORY.md)
**Author:** Yifeng Wang (yifenwan@phys.ethz.ch)
**Plan date:** 2026-04-29
**IP target version:** 26.0.0.0429 (legacy VHDL/terp 25.1.0631 is reference only)

---

## 1. Purpose

Replace the VHDL/terp `lvds_rx_controller_pro` with a SystemVerilog
implementation that:

1. Compresses per-lane decoder/aligner area by sharing a small pool of
   "super decoder-aligner engines" (`N_ENGINE`, default `1`,
   max = `N_LANE`).
2. Adds a runtime training/steady split so per-lane logic is minimal
   during bring-up and full scoring is only spent where there is an
   active error event.
3. Carries a peer-grade per-lane counter set (industry parallel to
   Xilinx Aurora `soft_err`/`hard_err`, IEEE 802.3 Cl.49 `block_lock` /
   `hi_ber`, MDIO BIP-error counts) exposed through a port-mapped
   aperture rather than one fixed word per counter per lane.
4. Carries the common identity header (UID at word 0, META at word 1
   with the four metadata pages) per the `ip-packaging` skill.
5. Has a formal-verification surface for the routing fabric and a
   classic UVM regression for everything sequence-heavy.

Legacy `25.1.0631` semantics are preserved exactly when
`N_ENGINE = N_LANE` and `routing_topology = full_xbar` — the new IP
must not silently break boards already programmed against
`lvds_rx_controller_pro_25_1_0631.svd`.

---

## 2. DUT Contract

### 2.1 External interfaces

| Group | Direction | Bus | Width | Notes |
|-------|-----------|-----|-------|-------|
| `csi_control_clk` | in | clock | 1 | free-running, 50–125 MHz |
| `rsi_control_reset` | in | reset | 1 | sync release on `csi_control_clk` |
| `csi_data_clk` | in | clock | 1 | LVDS rx_outclock, ~125 MHz |
| `rsi_data_reset` | in | reset | 1 | sync release on `csi_data_clk` |
| `coe_parallel_data` | in | conduit | `N_LANE*10` | raw 10b parallel words from `altlvds_rx` |
| `coe_ctrl_pllrst` | out | conduit | 1 | LVDS PLL reset |
| `coe_ctrl_plllock` | in | conduit | 1 | LVDS PLL lock |
| `coe_ctrl_dparst` | out | conduit | `N_LANE` | per-lane DPA reset |
| `coe_ctrl_lockrst` | out | conduit | `N_LANE` | per-lane DPA lock-detector reset |
| `coe_ctrl_dpahold` | out | conduit | `N_LANE` | per-lane DPA hold |
| `coe_ctrl_dpalock` | in | conduit | `N_LANE` | per-lane DPA locked |
| `coe_ctrl_fiforst` | out | conduit | `N_LANE` | per-lane DPA FIFO reset |
| `coe_ctrl_bitslip` | out | conduit | `N_LANE` | rising-edge bitslip request |
| `coe_ctrl_rollover` | in | conduit | `N_LANE` | rx_cda_max rollover indication |
| `coe_redriver_losn` | in | conduit | `N_LANE` | optional redriver LOS-N (active low; tie high if absent) |
| `avs_csr_*` | both | Avalon-MM | 32 | slave; `readLatency=1`; `address` width is `AVMM_ADDR_W` |
| `aso_decoded[i]_*` | out | Avalon-ST | 9 | per-lane 8b1k decoded byte (`{kchar, byte}`); error[2:0] = `{loss_sync_pattern, parity_error, decode_error}` |

**Hard spec — interface naming follows `rtl-writing` skill.** No raw
`i_/o_` prefixes. Per-domain prefix only (`csi_/rsi_/coe_/avs_/aso_`).

### 2.2 Compile-time generics

| Generic | Range | Default | Notes |
|---------|-------|---------|-------|
| `N_LANE` | 1 .. 32 | 12 | physical RX lanes |
| `N_ENGINE` | 1 .. `N_LANE` | 1 | size of shared scoring pool (legacy = `N_LANE`) |
| `ROUTING_TOPOLOGY` | `full_xbar`, `butterfly_half`, `butterfly_quarter`, `nearest_k` | `full_xbar` | reduction of the lane→engine mux |
| `SCORE_WINDOW_W` | 6 .. 16 | 10 | matched-bit window length per phase |
| `SCORE_ACCEPT` | 1 .. 2^`SCORE_WINDOW_W`-1 | 8 | accept threshold (CSR-overridable) |
| `SCORE_REJECT` | 0 .. `SCORE_ACCEPT`-1 | 2 | reject threshold (CSR-overridable) |
| `STEER_QUEUE_DEPTH` | 1 .. 16 | 4 | depth of the steering request queue |
| `AVMM_ADDR_W` | 6 .. 10 | 6 | CSR aperture width (sized to identity + control + counter aperture) |
| `IP_UID` | 32-bit | `"LVDS"` ASCII | overridable UID |
| `INSTANCE_ID` | 8-bit | 0 | integrator-set distinguishing tag |
| `VERSION_MAJOR` | 8-bit | `26` | locked at `_hw.tcl` time |
| `VERSION_MINOR` | 8-bit | `0` | locked |
| `VERSION_PATCH` | 4-bit | `0` | locked |
| `BUILD` | 12-bit | `0x429` | locked (MMDD) |
| `VERSION_DATE` | 32-bit | `0x20260429` | locked |
| `VERSION_GIT` | 32-bit | packaging-time git stamp | locked |
| `SYNC_PATTERN` | 10-bit | `0011111010` (K28.5) | runtime-overridable via CSR |
| `DEBUG_LEVEL` | 0 .. 5 | 0 | bring-up only; signoff at `0` |

### 2.3 Runtime CSR model (overview only — full map lives in `script/mu3e_lvds_controller_hw.tcl`)

The plan deliberately does **not** restate the CSR map here. Per the
`dv-workflow` lint, the CSR map is owned by the IP packaging skill.
This plan only references the CSR *behaviour* the DV must prove:

- Identity header at word 0 (UID, R/O) and word 1 (META, RW with
  four read pages: VERSION, DATE, GIT, INSTANCE_ID).
- Capability word (R/O) reporting `N_LANE`, `N_ENGINE`,
  `ROUTING_TOPOLOGY`, `SCORE_WINDOW_W`.
- Sync-pattern word (RW, 10b live).
- Per-lane control words: `lane_go`, `dpa_hold`, `soft_reset_req`,
  `mode_mask` (bit-slip vs adaptive vs auto).
- Score-threshold words: `score_accept`, `score_reject`,
  `score_window` (clamped within compile bounds).
- Steering CSR: queue depth in flight, queue-overflow count,
  engine-busy mask.
- **Counter aperture** (the new diagnostic surface): a `LANE_SELECT`
  word followed by `N_PER_LANE_COUNTERS` (= 10) read-only counter
  words. Software writes `LANE_SELECT`, then reads the bank.

The 10 per-lane counters (industry parallels in brackets):

| # | Name | Mu3e symbol | Industry parallel |
|---|------|-------------|-------------------|
| 0 | `code_violations` | 8b/10b not-in-table count | Xilinx GTH `RXNOTINTABLE` strobe-counted (`UG576`) |
| 1 | `disp_violations` | running-disparity violation count | Xilinx `RXDISPERR` strobe-counted (`UG576`) |
| 2 | `comma_losses` | sync-pattern lost transitions | IEEE 802.3 Cl.49 `block_lock` falling edges |
| 3 | `bitslip_events` | rising edges of `coe_ctrl_bitslip` | vendor-specific |
| 4 | `dpa_unlocks` | falling edges of `coe_ctrl_dpalock` | vendor-specific |
| 5 | `realigns` | byte-boundary phase changes | vendor-specific |
| 6 | `score_changes` | engine best-score updates while attached to this lane | Mu3e-specific |
| 7 | `engine_steerings` | times an engine was assigned to this lane | Mu3e-specific |
| 8 | `soft_resets` | soft-reset request count | vendor-specific |
| 9 | `uptime_since_lock` | sticky cycles since last initial sync lock | IEEE 802.3 Cl.49 latch-low MDIO `3.33.15` analogue |

All counters saturate at `0xFFFFFFFF` (no wrap). The DV plan
explicitly tests saturation and the `LANE_SELECT` aperture
behaviour (`P-bucket` / `E-bucket`).

---

## 3. Architecture Critique (Honest)

The user proposed a two-phase split: lightweight per-lane mini-decoder
during PHY training, plus a small `N_ENGINE` pool of full
score-and-decode engines that gets steered to whichever lane just
glitched. The plan freezes that direction with the following blunt
findings written into the verification surface so codex cannot drift
away from them:

1. **The split is correct in principle but not free.** A naive
   `N_LANE → N_ENGINE` 10-bit mux is `N_LANE × N_ENGINE × 10` 2-input
   selects plus a one-hot encoder per engine. For `N_LANE=12, N_ENGINE=4`
   that is on the order of 480 fanout-12 LUTs — comparable to four full
   per-lane scorers. The savings come from `N_ENGINE ≪ N_LANE` and from
   the engine being able to score *all 10 phase candidates* in parallel
   instead of one. If `N_ENGINE = N_LANE`, the routing fabric is
   strictly worse than the legacy per-lane layout. **Required DV proof:**
   `B071–B073` and the routing-fabric crosses in `DV_CROSS.md`.

2. **The "reduced butterfly" / partitioned routing is the right cost
   knob.** It must be a compile-time parameter
   (`ROUTING_TOPOLOGY ∈ {full_xbar, butterfly_half, butterfly_quarter,
   nearest_k}`), and it must be DV-swept. The DV plan does not silently
   downgrade to `full_xbar` for "convenience" — `E024–E028` cover the
   restricted topologies. If a hot lane falls outside any engine's
   reachable subset, recovery fails by construction; the topology
   parameter must therefore be tied to a static reachability map and
   the harness must check it at elaboration time.

3. **Steering latency is the real risk.** Glitch → error sideband →
   steering FSM → routing fabric → engine attach → score window fill →
   accept. None of that is free. Worst case at `N_ENGINE=1, N_LANE=12,
   all_glitch_simultaneously` the last-served lane waits
   `N_LANE × score_window` cycles before it sees a fresh engine. During
   that window the mini-decoder produces wrong bytes. The DV contract is
   *not* "no data loss" — it is "fast and accountable degraded mode":
   - the mini-decoder must keep asserting `loss_sync_pattern` /
     `decode_error` continuously so MuTRiG frame deassembly can drop
     the affected packet (legacy IP already does this);
   - `engine_steerings` and `comma_losses` per lane must increment
     deterministically;
   - steering-queue overflow must be a counted event, not silent.
   Cases `P003, P006, P012` close the worst-case latency story.

4. **Mini-decoder is *not* deleted in steady state.** It stays online
   on every lane that does not currently own an engine. Killing it in
   steady state means a glitch-and-immediate-pattern-loss survival
   period of zero observability. The DV plan keeps the mini-decoder
   producing 8b1k output under all phases of life. The big engine,
   when attached, *replaces* the mini-decoder's data path on that
   lane via a 2:1 mux at the AVST source.

5. **Scoring contract.** Score = number of bits inside a sliding
   `SCORE_WINDOW_W`-symbol window where the candidate phase produced
   a legal 10b code that decoded without `code_err`. Tie-break on
   equal max-score: lowest phase index wins. CSR overrides
   (`SCORE_ACCEPT`, `SCORE_REJECT`) clamp inside compile bounds; an
   illegal CSR write does not break the engine — the prior valid
   value is held. Cases `B055–B062, E018–E022` close this.

6. **CSR counter aperture is a compression of address space, not a
   compression of state.** Per-lane counters still cost
   `N_LANE × 10 × 32` bits of register storage; the aperture only
   saves CSR-decode area. The DV plan must therefore prove
   `LANE_SELECT` race rules: a write to `LANE_SELECT` between two
   reads must atomically retarget the readback bank, with no
   half-stale words. `B051, B053, E033, E035` close this.

7. **Formal vs simulation split is enforced.** Formal proves things
   that are local and finite-state-bounded:
   routing-fabric one-engine-one-lane exclusivity, training-FSM
   liveness for one lane in isolation, score saturation, CSR
   aperture stability under read, steering-queue conservation
   (every accepted error event eventually retires *or* increments
   the overflow counter). Simulation owns everything sequence-heavy
   (long traffic with K28.5 + glitch, multi-lane contention, soak,
   bucket_frame). See [DV_FORMAL.md](DV_FORMAL.md).

8. **Anti-goals (explicit non-targets).** The IP does **not**:
   - guarantee zero corrupted bytes during steering — degraded mode
     is a counted, observable outcome, not a forbidden state;
   - implement soft-CDR (`enable_soft_cdr_mode = OFF` is locked at
     `_hw.tcl` time);
   - validate the LVDS PLL itself — the wrapped `altlvds_rx` is
     treated as a black-box conduit and its `rx_locked` is a stimulus
     input to the DV harness.

---

## 4. Verification Objectives

| Objective | Closure path | Reference cases |
|-----------|-------------|-----------------|
| Identity header behaves per `ip-packaging` skill | UVM directed | `B001–B006` |
| Single-lane bring-up under K28.5 idle | UVM directed | `B011–B020` |
| All-lane bring-up under K28.5 idle | UVM directed | `B021–B026` |
| Mini-decoder bitslip walk and lock | UVM directed + scoreboard | `B027–B040` |
| Training → steady transition | UVM directed | `B041–B050` |
| Counter aperture (LANE_SELECT atomicity) | UVM directed | `B051–B054` |
| 10-counter set increments correctly per event | UVM directed + assertions | `B055–B068` |
| Engine pool steering (`N_ENGINE=1..N_LANE`) | UVM directed × parameter sweep | `B071–B080` |
| Score window / accept / reject sweep | UVM directed | `E018–E022` |
| Routing topology (butterfly_*, nearest_k) | UVM directed × topology sweep | `E024–E028` |
| Tie-break / score saturation | UVM directed | `E018–E020` |
| CSR aperture wrap / illegal address | UVM directed | `E033–E040` |
| Steering-queue contention `N_ENGINE < hot_lanes` | UVM directed | `E044–E050` |
| Long-run soak with periodic glitch | UVM random | `P001–P020` |
| Counter saturation policy | UVM directed | `P021–P024` |
| Soft-reset during steering | UVM directed | `X001–X008` |
| Dead lane / stuck PHY | UVM directed | `X009–X018` |
| Continuous bitslip churn (DPA never locks) | UVM directed | `X019–X024` |
| Illegal CSR writes | UVM directed | `X025–X034` |
| SVA: routing-fabric exclusivity | formal + UVM bind | `DV_FORMAL.md §2.1` |
| SVA: steering-queue conservation | formal + UVM bind | `DV_FORMAL.md §2.2` |
| SVA: training-FSM liveness | formal | `DV_FORMAL.md §2.3` |
| SVA: CSR aperture stability under read | formal | `DV_FORMAL.md §2.4` |
| Bucket_frame / all_buckets_frame | UVM directed | `DV_CROSS.md §3` |

---

## 5. Bucket Split

| Bucket | File | ID range | Cases | Scope |
|--------|------|----------|-------|-------|
| BASIC | [DV_BASIC.md](DV_BASIC.md) | `B001-B999` | ~80 | identity, bring-up, training/steady, counters, default-config sanity |
| EDGE | [DV_EDGE.md](DV_EDGE.md) | `E001-E999` | ~60 | corner cases (ties, contention, fabric edges, CSR aperture wrap) |
| PROF | [DV_PROF.md](DV_PROF.md) | `P001-P999` | ~40 | stress, soak, throughput, counter saturation |
| ERROR | [DV_ERROR.md](DV_ERROR.md) | `X001-X999` | ~50 | reset / illegal / fault / dead lane |
| CROSS | [DV_CROSS.md](DV_CROSS.md) | n/a | n/a | bucket_frame, all_buckets_frame, parameter crosses |
| FORMAL | [DV_FORMAL.md](DV_FORMAL.md) | n/a | n/a | qverify primary, znformal secondary, bind into UVM for re-runs |

The numeric "~" counts are plan freezes, not hard ceilings. Codex may
add supplemental cases during closure — every supplement must be
indexed and justified in `DV_REPORT.md`.

---

## 6. Coverage Targets

| Category | Target | Notes |
|----------|--------|-------|
| Statement | ≥ 95 % | merged isolated baseline |
| Branch | ≥ 90 % | merged isolated baseline |
| Condition | ≥ 85 % | merged isolated baseline |
| Expression | ≥ 85 % | merged isolated baseline |
| FSM state | 100 % | every state of training and steering FSMs |
| FSM transition | ≥ 95 % | every legal transition; illegal transitions are SVA-forbidden |
| Toggle | ≥ 80 % | applied to ports, decoded outputs, counter MSBs |
| Functional cross | ≥ 95 % | per `DV_CROSS.md` |
| `bucket_frame` (per bucket) | merged ≥ 90 % | continuous-frame baselines |
| `all_buckets_frame` | merged ≥ 90 % | one timeframe across all signoff buckets |

`DV_COV.md` maintains the per-case rows; the running merged ordered
isolated baseline is recorded after each added case.

---

## 7. Sweep Matrix

The following compile-time and runtime sweeps are mandatory for
signoff:

| Axis | Values |
|------|--------|
| `N_LANE` | `1, 4, 9, 12` (12 is the FEB SciFi primary; 9 is the legacy default; 4 is the routing-stress point; 1 is the formal-friendly point) |
| `N_ENGINE` | `1, 2, 4, N_LANE` (1 is the worst-contention point; `N_LANE` is the legacy-equivalent point) |
| `ROUTING_TOPOLOGY` | `full_xbar, butterfly_half, butterfly_quarter, nearest_k` |
| `SCORE_WINDOW_W` | `6, 10, 16` |
| `SYNC_PATTERN` | K28.5 (`0011111010`), K28.0 (`0011110100`), K23.7 (`1110101000`) |
| `INSTANCE_ID` | `0, 0xAB` |

The full Cartesian product is `4 × 4 × 4 × 3 × 3 × 2 = 1152` build
points. The signoff matrix narrows this to:

- **Primary** (must close BASIC/EDGE/PROF/ERROR/CROSS):
  `N_LANE=12, N_ENGINE=1, ROUTING=full_xbar, SCORE_WINDOW_W=10, SYNC=K28.5, INSTANCE_ID=0`.
- **Legacy parity** (must close BASIC/EDGE/CROSS, not PROF/ERROR):
  `N_LANE=9, N_ENGINE=9, ROUTING=full_xbar, SCORE_WINDOW_W=10, SYNC=K28.5`.
- **Topology sweep** (BASIC subset + the `E024–E028` cases):
  `N_LANE=12, N_ENGINE=4`, each of the four topologies.
- **Score-window sweep** (BASIC subset + `E018–E022`):
  `N_LANE=4, N_ENGINE=2`, each of `SCORE_WINDOW_W ∈ {6, 10, 16}`.
- **Sync-pattern sweep** (B011 + B015 + B021):
  `N_LANE=4, N_ENGINE=1`, each of K28.5 / K28.0 / K23.7.

Build matrix that the `tb/uvm/Makefile` must accept as
`make BUILD=<tag>` flags is documented in `DV_HARNESS.md §10`.

---

## 8. Formal vs Simulation Split

### 8.1 Formal-owned (must close in `qverify`)

- routing-fabric one-engine-one-lane exclusivity
- training-FSM liveness for one lane in isolation
- score saturation
- CSR aperture stability under read (LANE_SELECT atomicity)
- steering-queue conservation (no silent loss)
- counter saturating-add invariant (never wraps to 0)

Detailed properties in [DV_FORMAL.md](DV_FORMAL.md).

### 8.2 Simulation-owned (UVM)

- everything sequence-heavy: K28.5 traffic, glitch injection, multi-lane
  contention, training/steady transitions, soak, bucket_frame.

### 8.3 Reused properties

Every formal property is bound into the UVM harness via
`bind` so regression catches the same invariant violations under random
stimulus.

---

## 9. Closure Gates

DV closure requires **all** of the following, in order:

1. UVM Makefile compiles cleanly under `Questa FSE` (UVM-1.2,
   `+define+UVM_NO_DPI`, `-nodpiexports`).
2. Every planned case in `DV_BASIC.md`, `DV_EDGE.md`, `DV_PROF.md`,
   `DV_ERROR.md` is implemented and runs to a deterministic verdict.
3. Per-case isolated UCDB exists and is recorded in `DV_COV.md`.
4. Running ordered-isolated merged total meets the bucket targets in
   §6.
5. `bucket_frame` and `all_buckets_frame` close per `DV_CROSS.md`.
6. `qverify` proofs in `DV_FORMAL.md` are all proven within bound or
   explicitly waived with reason recorded in `DV_REPORT.md`.
7. `BUG_HISTORY.md` has every bug fix linked to a commit hash;
   no unresolved `R`-class bugs except those explicitly waived.
8. `script/lvds_rx_controller_pro_hw.tcl` passes
   `lint_csr_header.py` (CSR-header lint).
9. `rtl/*.sv` passes `rtl_style_check.py`.
10. Legacy parity build (`N_ENGINE=N_LANE, ROUTING=full_xbar`)
    produces the exact same decoded byte stream as the legacy
    25.1.0631 IP under the same K28.5 + decoded-frame trace
    (saved as a regression vector under `tb/golden/`).

A signoff git tag (`mu3e_lvds_controller-v26.0.0.0429`) is created
**only** after gates 1–10 are green and `dv_report_format_check.py`
and `bug_history_format_check.py` both exit zero.

---

## 10. Execution Modes

Every test must be runnable in three modes per the `dv-workflow` contract:

1. `isolated` — one test, fresh DUT reset. Default. Per-case UCDB.
2. `bucket_frame` — all cases of one bucket in case-id order, no DUT
   reset between. Each directed case = 1 transaction; each random case =
   N_RAND transactions.
3. `all_buckets_frame` — bucket order `BASIC → EDGE → PROF → ERROR`,
   case-id order within each bucket, no DUT reset.

A case that cannot run without restart must say so explicitly in its
row in the bucket file (`Function Reference` column carries
`SKIP_BUCKET_FRAME` if applicable, with a one-line reason).

---

## 11. References

- Intel ALTLVDS_RX User Guide (Intel doc 683062 §1.2.2 / §1.3.2 /
  §1.5.2.2 / §1.5.3.1) — DPA / bitslip / `rx_cda_max` / DPA FIFO
  reset semantics.
- Intel KB 000082655 — `rx_channel_data_align` rising-edge bitslip
  for ALTLVDS_RX.
- Arria V Device Handbook Vol 1, Ch 6 (Intel doc 683213) —
  High-Speed Differential I/O and DPA chapter.
- Xilinx UG576 — UltraScale GTH `RXNOTINTABLE`, `RXDISPERR`.
- AMD PG046 — Aurora 8B/10B `soft_err`, `hard_err`.
- IEEE 802.3 Cl.49 — `block_lock`, `hi_ber`, MDIO `3.33.15` latch-low.
- `~/.codex/skills/dv-workflow/SKILL.md` — DV workflow contract
  (canonical).
- `~/.codex/skills/rtl-writing/SKILL.md` — RTL style and naming.
- `~/.codex/skills/ip-packaging/SKILL.md` — `_hw.tcl` GUI / identity /
  versioning.
- `~/.codex/skills/rtl-modeling/SKILL.md` — controlled / asserted /
  inferred loss tiers (used to classify steering-degraded bytes).
- Legacy reference RTL: `lvds_rx_controller_pro.terp.vhd`
  v1.4 (Mar 2025).
- Legacy reference SVD: `lvds_rx_controller_pro.svd` v25.1.0631.
