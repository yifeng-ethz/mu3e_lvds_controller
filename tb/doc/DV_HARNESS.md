# DV Harness — mu3e_lvds_controller (SV rebuild)

**Companion docs:** [DV_PLAN.md](DV_PLAN.md), [DV_BASIC.md](DV_BASIC.md),
[DV_EDGE.md](DV_EDGE.md), [DV_PROF.md](DV_PROF.md),
[DV_ERROR.md](DV_ERROR.md), [DV_CROSS.md](DV_CROSS.md),
[DV_FORMAL.md](DV_FORMAL.md), [DV_COV.md](DV_COV.md),
[BUG_HISTORY.md](../BUG_HISTORY.md)
**Author:** Yifeng Wang
**Plan date:** 2026-04-29

This file freezes the harness architecture before codex implements
anything. Any divergence from this plan during implementation is a
plan-drift event and must be recorded in `DV_REPORT.md` plan-drift
notes section.

---

## 1. Top-level Topology

```
                        ┌──────────────────────────────┐
                        │   tb_top.sv                  │
                        │                              │
   csi_data_clk   ──────┼──┐                           │
   csi_control_clk──────┼──┤                           │
                        │  │   ┌────────────────────┐  │
   K28.5/data           │  ├──>│ lvds_phy_lane_drv  │──┼──> coe_parallel_data[10*N_LANE-1:0]
   error inject seqs    │  │   │  (one per lane)    │  │
                        │  │   └────────────────────┘  │
                        │  │   ┌────────────────────┐  │
                        │  │   │  lvds_rx_controller│  │
                        │  │   │  (DUT)             │  │
                        │  │   └────────────────────┘  │
                        │  │     ↑      ↑       ↓      │
                        │  │ csr_agent  ctrl   aso_decoded[N_LANE]
                        │  │     │      conduit ↓      │
                        │  │     │       drv    aso_sink_agent[N_LANE]
                        │  │     │              ↓      │
                        │  │   scoreboard ←─────┘      │
                        │  │   coverage                │
                        │  │   sva_bind                │
                        │  └───────────────────────────┘
                        └──────────────────────────────┘
```

`tb_top.sv` owns:
- DUT instantiation
- both clocks (`csi_data_clk` at 125 MHz, `csi_control_clk` at 100 MHz default; per-test override)
- both resets (sync release)
- `lvds_phy_lane_drv[N_LANE]` instances (one per lane)
- a single `csr_agent` Avalon-MM driver/monitor
- a `ctrl_conduit_drv` that emulates the `altlvds_rx` conduit
  (`coe_ctrl_*`) so the DUT sees realistic `dpalock`, `rollover`,
  `plllock`, etc. responses to its requests
- one `aso_sink_agent` per `aso_decoded[i]` interface
- bind of every SVA module from `tb/uvm/sva/`
- analysis port plumbing into the scoreboard and coverage

---

## 2. Per-Lane PHY Driver (`lvds_phy_lane_drv.sv`)

This is the single most important agent. Codex implements it before
anything else.

### 2.1 Outputs to DUT (per lane)

- `coe_parallel_data[i*10 +: 10]` — 10b symbol per `csi_data_clk` cycle
- `coe_ctrl_dpalock[i]` — asserted level after a configurable delay
  (`dpa_lock_delay_cycles_p`, default 64) post `coe_ctrl_dparst`
  deassert; falls when an injection event fires `dpa_unlock`
- `coe_ctrl_rollover[i]` — pulsed when bitslip count reaches
  `rx_cda_max` (per Intel doc 683062 §1.2.2; rollover after 10 pulses
  by default)
- `coe_ctrl_plllock` (single bit, OR-driven by all lanes) — held high
  unless a test forces PLL loss

### 2.2 Inputs observed from DUT

- `coe_ctrl_dparst[i]`, `coe_ctrl_lockrst[i]`, `coe_ctrl_dpahold[i]`,
  `coe_ctrl_fiforst[i]`, `coe_ctrl_bitslip[i]`, `coe_ctrl_pllrst`

### 2.3 Per-lane sequence library

Each lane driver holds its own sequence, callable via UVM analysis ports:

| Sequence | Symbol stream |
|----------|---------------|
| `idle_k285` | continuous K28.5 with alternating RD |
| `idle_k280` | continuous K28.0 |
| `idle_k237` | continuous K23.7 |
| `framed_dxx` | K28.5 + N data bytes + K28.5 (configurable) |
| `bitslip_walk` | inject single-bit phase shift; expect DUT to walk bitslip until alignment |
| `glitch_one_byte` | one corrupted 10b symbol (random bit flip) |
| `glitch_burst` | configurable `n_burst` corrupted symbols |
| `code_violation` | drive a 10b symbol that is not in the 8b/10b table |
| `disp_violation` | drive a legal symbol but with wrong RD |
| `pattern_loss` | drop K28.5 from idle for N cycles |
| `dpa_unlock_pulse` | pulse `coe_ctrl_dpalock[i]` low for one cycle |
| `dead_low` | drive `0x000` continuously |
| `dead_high` | drive `0x3FF` continuously |

Every sequence carries a per-lane analysis port that publishes the
*intent* (expected symbol, expected error class, expected steering
event) to the scoreboard. The scoreboard never reads the wire — it
reads the intent stream and compares to DUT-emitted decoded bytes /
error sidebands / counter increments.

### 2.4 Bitslip echo model

The driver implements a 10-tap rolling buffer. On each rising edge of
`coe_ctrl_bitslip[i]`, the buffer rotates by 1. After
`rx_cda_max = 10` pulses, `coe_ctrl_rollover[i]` pulses for one
cycle. This matches Intel doc 683062 §1.2.2 behaviour. The legacy
VHDL DUT uses a similar rotation model in
`altera_lvds_rx_28nm.vhd`'s `data_align_rollover = 10`.

---

## 3. CSR Agent (`csr_agent.sv`)

Avalon-MM master driver/monitor with `readLatency = 1` and explicit
`waitrequest` handling.

API (sequence-callable):
- `task csr_write(addr, data, [wait_for_done = 0])`
- `task csr_read(addr, output data)`
- `task identity_check(uid_expected, version_expected, ...)`
- `task lane_counter_read(lane_idx, counter_idx, output u32)` —
  composite operation: `csr_write(LANE_SELECT, lane_idx)` then
  `csr_read(COUNTER_BASE + counter_idx*4)`. Includes an internal
  guard so two concurrent calls cannot interleave the aperture
  selection (`B051` proves DUT atomicity, but the harness must not
  fool itself).
- `task all_lanes_counters_dump(output u32[N_LANE][10])` — used by
  the scoreboard at end-of-test for golden comparison.

Monitor publishes every accepted CSR transaction (read or write) on
the scoreboard analysis port.

---

## 4. AVST Sink Agent (`aso_sink_agent.sv`)

One per `aso_decoded[i]` interface (or a single multi-channel sink if
`DECODED_USE_CHANNEL = 0`).

- `ready` is permanently high by default
- per-test override: `ready_pattern_p = always_ready / random / stall_burst`
- monitor records `(byte, kchar, error[2:0], cycle)` for every
  asserted `valid` beat
- scoreboard compares against the lane driver's intent stream

The DUT does not currently surface `valid` (legacy spec — every
cycle is implicitly valid). The new SV rebuild must surface `valid`
explicitly. If codex finds a reason to keep implicit-valid, that is
a plan-drift event and goes into `DV_REPORT.md` and the AVST
agent must be adjusted symmetrically.

---

## 5. Scoreboard (`lvds_scoreboard.sv`)

Per-lane state:
- expected byte stream (from intent ports)
- expected error vector
- expected counter deltas (predicted from intent events)
- engine-attach ledger (which engine is currently steering this lane,
  and since when)

End-of-test checks:
1. observed decoded bytes equal expected per lane (after a bounded
   alignment window — first lock latency is allowed to skip a few
   bytes; the window is `score_window_w + dpa_lock_delay_cycles_p`).
2. error sideband matches intent within `±1` cycle tolerance for
   `code_err` / `parity_error` / `loss_sync_pattern`.
3. counter readback exactly equals expected (counters are sticky and
   deterministic; no tolerance).
4. engine-attach ledger never has two engines on the same lane in
   the same cycle (this is also an SVA, but redundant scoreboard
   check is cheap and catches harness bugs).
5. `engine_steerings` per lane equals the count of steering events
   in the intent stream that targeted that lane (no extra, no
   missing).

The scoreboard classifies every decoded-byte mismatch into the
`rtl-modeling` skill's evidence ladder:
- `controlled` — DUT counter explains the mismatch (e.g. degraded
  mode during steering, with `engine_steerings` and
  `loss_sync_pattern` both incrementing)
- `asserted` — an SVA fired
- `inferred` — neither; this is a real bug and the test fails

---

## 6. Coverage Collector (`lvds_coverage.sv`)

Questa FSE has no `covergroup`, so every cover bin is a counter
increment under SVA `cover` and a few free-running counters.

Cover bins (functional):
- per `(N_LANE, N_ENGINE, ROUTING_TOPOLOGY)` build axis hit
- training-FSM state visited (per state)
- training-FSM transition taken (per transition)
- steering-FSM state visited / transition taken
- per-lane mode (`bit_slip`, `adaptive`, `auto`) used in steady state
- score outcome bins: `accept_immediately`, `accept_after_walk`,
  `reject_then_realign`, `tie_break_low_idx`
- counter saturation hit per counter type
- engine-pool occupancy bins (`0/N_ENGINE`, `1/N_ENGINE`,
  `2/N_ENGINE`, ..., `N_ENGINE/N_ENGINE`)
- steering-queue occupancy bins
- error-injection class hit (every entry of §2.3)
- CSR address visited (read, write, read+write)
- meta-page hit (0/1/2/3)
- LANE_SELECT value range hit (`0`, `1..N_LANE-1`, out-of-range
  read)

Code coverage is collected by the simulator under `vsim -coverage`.

---

## 7. SVA Bind Layer (`tb/uvm/sva/`)

All SVA properties are written in standalone modules that bind to
the DUT. They are reused by the formal env (`tb/formal/`) without
duplication.

| File | Module | Property |
|------|--------|----------|
| `sva_routing_excl.sv` | `sva_routing_excl` | one engine cannot read two lanes simultaneously |
| `sva_steering_queue.sv` | `sva_steering_queue` | every error event either retires or counts overflow |
| `sva_train_fsm.sv` | `sva_train_fsm` | training FSM is live (no orphan states) |
| `sva_score_sat.sv` | `sva_score_sat` | score never wraps below 0 or above `2^SCORE_WINDOW_W-1` |
| `sva_csr_aperture.sv` | `sva_csr_aperture` | LANE_SELECT atomicity under concurrent read |
| `sva_avalon_mm.sv` | `sva_avalon_mm` | standard `read/write/waitrequest/readdata` stability |
| `sva_avalon_st.sv` | `sva_avalon_st` | per-source `valid && !ready` payload-stable |
| `sva_counter_sat.sv` | `sva_counter_sat` | every counter saturates at `0xFFFFFFFF` |
| `sva_engine_attach.sv` | `sva_engine_attach` | `engine_steerings[i]` increments iff an attach event for lane `i` is observed |

Each SVA module is also covered by a directed UVM test that drives
the relevant scenario and expects the property to *hold* (no
violation). Anti-cases (proving the property would fire if the rule
were broken) are documented in `DV_FORMAL.md` and only live in
formal — UVM does not assert-fire on purpose.

---

## 8. Formal Env (`tb/formal/`)

Primary tool: `qverify` (current Mu3e standard) per the
`dv-workflow` skill note about formal direction.

Layout:
```
tb/formal/
  Makefile
  qverify_run.tcl
  bind_dut.sv             # binds every sva_*.sv to the DUT
  abstractions/
    abstract_phy_lane.sv  # over-approximates the PHY conduit
    abstract_csr_bus.sv   # legal AVMM transitions only
  proofs/
    p_routing_excl.tcl
    p_steering_queue.tcl
    p_train_liveness.tcl
    p_score_sat.tcl
    p_csr_aperture.tcl
    p_counter_sat.tcl
```

Each proof carries:
- explicit constraint set (assumes)
- assertion target (asserts)
- a cover sanity (so the proof is not vacuous)
- bounded-proof depth recorded in `DV_FORMAL.md`

---

## 9. Test Class Hierarchy

```
uvm_test
└── lvds_base_test            # CSR agent, sink agents, scoreboard, coverage,
    │                           one-time identity check, optional `bucket_frame`
    │                           replay hook
    ├── lvds_basic_test       # B-bucket parent
    │   ├── lvds_b001_uid_test
    │   ├── lvds_b002_uid_write_ignored_test
    │   ├── ...
    │   └── lvds_b080_engine_pool_full_test
    ├── lvds_edge_test
    │   ├── lvds_e001_..._test
    │   └── ...
    ├── lvds_prof_test
    │   ├── lvds_p001_..._test
    │   └── ...
    ├── lvds_error_test
    │   └── ...
    └── lvds_cross_test
        ├── lvds_bucket_frame_basic_test
        ├── lvds_bucket_frame_edge_test
        ├── lvds_bucket_frame_prof_test
        ├── lvds_bucket_frame_error_test
        └── lvds_all_buckets_frame_test
```

Test naming follows the `rtl-writing` skill convention:
`STD_<MODULE>_<ID>_<description>`. The `lvds_bNNN_..._test` SV class
name maps 1:1 to a bucket-file ID and makes regression-by-id trivial.

---

## 10. Build System

`tb/uvm/Makefile` accepts:

```
make BUILD=primary           # N_LANE=12 N_ENGINE=1  ROUTING=full_xbar       SCORE_WINDOW_W=10
make BUILD=legacy            # N_LANE=9  N_ENGINE=9  ROUTING=full_xbar       SCORE_WINDOW_W=10
make BUILD=topo_butterfly_h  # N_LANE=12 N_ENGINE=4  ROUTING=butterfly_half  SCORE_WINDOW_W=10
make BUILD=topo_butterfly_q  # N_LANE=12 N_ENGINE=4  ROUTING=butterfly_quarter SCORE_WINDOW_W=10
make BUILD=topo_nearest_k    # N_LANE=12 N_ENGINE=4  ROUTING=nearest_k       SCORE_WINDOW_W=10
make BUILD=score_w6          # N_LANE=4  N_ENGINE=2  SCORE_WINDOW_W=6
make BUILD=score_w16         # N_LANE=4  N_ENGINE=2  SCORE_WINDOW_W=16
make BUILD=sync_k280         # SYNC_PATTERN=K28.0
make BUILD=sync_k237         # SYNC_PATTERN=K23.7
make BUILD=lane1             # N_LANE=1 (formal-friendly point)
make BUILD=lane4             # N_LANE=4
```

Per-build target invocations:

```
make BUILD=<tag> TEST=lvds_b001_uid_test run        # one isolated test
make BUILD=<tag> regression                         # all planned cases
make BUILD=<tag> bucket_frame                       # all 4 buckets, no-restart
make BUILD=<tag> all_buckets_frame                  # one frame across all buckets
make BUILD=<tag> coverage                           # merge UCDBs + report
```

Per the project-global `~/CLAUDE.md` Questa FSE setup:
- `LM_LICENSE_FILE` chains the local FSE license then the ETH server.
- UVM 1.2 from `$(QUESTA_HOME)/verilog_src/uvm-1.2`.
- `vlog -sv +define+UVM_NO_DPI` for compile.
- `vsim -c -nodpiexports -suppress 19 -suppress 3009` for run.
- No `rand`/`constraint` — use the LCG-based PRNG in
  `mutrig_common_pkg` for randomised cases.
- No `covergroup` — use SVA `cover` and counter increments.

---

## 11. Debug Hooks

Every signoff build keeps these signals routed and named so SignalTap
or Questa wave loading is trivial:

- `dut.train_state[N_LANE]` — per-lane training FSM state (enum)
- `dut.steer_state` — steering FSM state (enum)
- `dut.engine_attach_lane[N_ENGINE]` — which lane each engine
  currently serves (-1 if unattached)
- `dut.engine_score[N_ENGINE][10]` — current score per phase
- `dut.engine_best_phase[N_ENGINE]` — current best phase per engine
- `dut.steer_queue_count` — depth-in-flight
- `dut.lane_counter[N_LANE][10]` — full counter array (already CSR-visible)

These are exposed at the DUT boundary as a `coe_dbg` conduit when
`DEBUG_LEVEL > 0`. At `DEBUG_LEVEL = 0` they remain internal but
SignalTap-tappable — they must not be optimised away by synthesis
(use `(* preserve = "true" *)` on the Quartus build).

---

## 12. Plan-Drift Notes

This file is frozen at plan time. Any deviation during implementation
(different agent topology, different SVA wording, different build tag
naming) must be appended below as `### YYYY-MM-DD <one-line summary>`
with rationale. Drift entries do not delete the original plan text;
they sit alongside it so the auditor can see what was changed.

(no drift yet)
