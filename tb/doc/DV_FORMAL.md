# DV Formal — mu3e_lvds_controller (SV rebuild)

**Companion docs:** [DV_PLAN.md](DV_PLAN.md), [DV_HARNESS.md](DV_HARNESS.md),
[DV_BASIC.md](DV_BASIC.md), [DV_EDGE.md](DV_EDGE.md),
[DV_PROF.md](DV_PROF.md), [DV_ERROR.md](DV_ERROR.md),
[DV_CROSS.md](DV_CROSS.md), [DV_COV.md](DV_COV.md),
[BUG_HISTORY.md](../BUG_HISTORY.md)

This document defines what is provable in formal versus what is left
to simulation. The formal flow uses `qverify` as the primary tool
(per the dv-workflow contract on Mu3e formal direction); `znformal`
is a secondary cross-check. The harness binds every SVA module that
formal proves into the UVM env so simulation re-confirms the same
properties under random stimulus.

---

## 1. Tool and Entry Point

- Primary: `qverify` 2026 — `tb/formal/qverify_run.tcl` is the
  driver; `tb/formal/Makefile` invokes it per proof.
- Secondary: `znformal` (or `jaspergold` if available) — same SVA
  module sources, different proof engine, used to cross-check
  bounded-proof depths.
- Bind file: `tb/formal/bind_dut.sv` — same file used by UVM
  via `bind` directive in `tb_top.sv`.

Per the project-global `~/CLAUDE.md` Questa FSE constraint: no DPI
in the formal env, no `rand`/`constraint`. Formal stimulus is
constrained via `assume` directives only.

---

## 2. Provable Properties

The properties below are designed to be local enough for an
unbounded proof or a small-bound BMC. Each property is a SystemVerilog
`assert property` in a SVA module under `tb/uvm/sva/`.

### 2.1 `sva_routing_excl` — Routing-fabric exclusivity

**Statement.** No two engines may sample the same `coe_parallel_data`
lane in the same cycle, regardless of `ROUTING_TOPOLOGY`.

```systemverilog
// in sva_routing_excl
property p_routing_excl;
    @(posedge csi_data_clk) disable iff (rsi_data_reset)
        $onehot0({for_each engine: engine_attach_lane[engine] == lane_idx});
endproperty
assert property (p_routing_excl);
```

**Bound.** Unbounded proof should close with no harness assumptions
(the property is stateless — purely combinational over the engine
attach vector).

**Cover.** A directed cover that drives both engines free, then
forces an attach to the same lane via debug hook (used in `X035`).

**Closure target.** `qverify` proves unbounded.

### 2.2 `sva_steering_queue` — Steering-queue conservation

**Statement.** Every accepted error event is either retired
(an engine attached the requesting lane) or the
`aggregate_steering_queue_overflows` counter increments.

```systemverilog
// in sva_steering_queue
property p_steering_queue_conserve;
    @(posedge csi_data_clk) disable iff (rsi_data_reset)
        steering_event_in |=>
            (##[1:STEER_BOUND] engine_attach_event[lane_idx]) or
            ##[1:1] (aggregate_steering_queue_overflows[31:0] == $past(aggregate_steering_queue_overflows[31:0]) + 1);
endproperty
```

**Bound.** Bounded proof, depth `STEER_BOUND = STEER_QUEUE_DEPTH +
attach_latency_cycles_p + score_window_w` (default ≈ 32). Assume
fair input: lanes do not produce events faster than `1 per cycle`
collectively.

**Cover.** Every documented retirement path (attach, queue
overflow). Both must cover for the property to be non-vacuous.

**Closure target.** Bounded proof at `STEER_BOUND = 32`.

### 2.3 `sva_train_fsm` — Training FSM liveness

**Statement.** For a single isolated lane, from any reachable state,
the training FSM either reaches `LOCKED` within `TRAIN_BOUND` cycles
or returns to `IDLE` (via DPA reset / soft reset / lock loss).

```systemverilog
// in sva_train_fsm — per lane, abstracted PHY
property p_train_liveness(int lane);
    @(posedge csi_data_clk) disable iff (rsi_data_reset)
        (train_state[lane] != IDLE) |->
            ##[1:TRAIN_BOUND] (train_state[lane] inside {LOCKED, IDLE});
endproperty
generate
    for (genvar L = 0; L < N_LANE; L++) begin: g
        assert property (p_train_liveness(L));
    end
endgenerate
```

**Bound.** Bounded proof, depth `TRAIN_BOUND = bitslip_max +
score_window_w + dpa_lock_delay_cycles_p + soft_reset_recovery_cycles`
(default ≈ 80).

**Assumes.** `abstractions/abstract_phy_lane.sv` provides:
- `coe_ctrl_dpalock` is non-deterministic but eventually settles
  to a stable level after `dpa_lock_delay_cycles_p`;
- `coe_parallel_data` is non-deterministic 10b per cycle, with no
  forced infinite glitch (otherwise the FSM legitimately never locks
  and the property would be vacuous);
- `coe_ctrl_plllock` is non-deterministic but stable for at least
  `pll_stable_cycles` between toggles.

**Closure target.** Bounded proof at depth 80.

### 2.4 `sva_score_sat` — Score saturation

**Statement.** The engine's score never overflows above
`2^SCORE_WINDOW_W - 1` and never drops below `0`.

```systemverilog
property p_score_sat;
    @(posedge csi_data_clk) disable iff (rsi_data_reset)
        (engine_score >= 0) and (engine_score <= ((1 << SCORE_WINDOW_W) - 1));
endproperty
```

**Bound.** Unbounded proof.

**Closure target.** `qverify` proves unbounded.

### 2.5 `sva_csr_aperture` — LANE_SELECT atomicity under read

**Statement.** A CSR read at a counter aperture word returns the
counter values of the lane that was selected by `LANE_SELECT` at the
cycle the read is *issued* (not at the cycle the read completes).

```systemverilog
property p_csr_aperture_atomic;
    @(posedge csi_control_clk) disable iff (rsi_control_reset)
        (avs_csr_read && !avs_csr_waitrequest && address_in_aperture) |->
            (avs_csr_readdata == read_aperture_value(LANE_SELECT_at_issue));
endproperty
```

**Bound.** Bounded proof, depth ≥ `2` (one cycle for read pipeline
plus one for the `waitrequest` cycle).

**Assumes.** Avalon-MM master never re-issues an in-flight read
(standard contract); LANE_SELECT updates take one cycle to commit
to the aperture mux.

**Closure target.** Bounded proof at depth 4.

### 2.6 `sva_counter_sat` — Counter saturating-add

**Statement.** Every counter saturates at `0xFFFFFFFF`; never wraps
to `0`.

```systemverilog
property p_counter_no_wrap(int lane, int counter);
    @(posedge csi_data_clk) disable iff (rsi_data_reset)
        ($past(counter_value[lane][counter]) == 32'hFFFFFFFF) |->
            (counter_value[lane][counter] == 32'hFFFFFFFF);
endproperty
```

**Bound.** Unbounded proof per `(lane, counter)` instance.

**Closure target.** `qverify` proves unbounded for each instance;
on a `N_LANE=12` build that is 120 proofs (12 × 10), all close
under the same lemma so the runtime is bounded.

### 2.7 `sva_avalon_mm` — Avalon-MM contract

**Statement.** During `(read || write) && waitrequest`,
`address`, `writedata`, and `byteenable` must remain stable.

```systemverilog
property p_avmm_stable;
    @(posedge csi_control_clk) disable iff (rsi_control_reset)
        ((avs_csr_read || avs_csr_write) && avs_csr_waitrequest) |=>
            $stable(avs_csr_address) && $stable(avs_csr_writedata);
endproperty
```

**Bound.** This is a property of the *master*, not the slave; it is
asserted on the harness side and used as an `assume` for the formal
proof of slave behaviour. UVM-side it is `assert`-ed against the
csr_agent's monitor.

**Closure target.** Unbounded proof on the harness side; UVM
re-runs always-pass.

### 2.8 `sva_avalon_st` — Avalon-ST contract

**Statement.** During `valid && !ready`, `data`, `error`, and
`channel` (when present) must remain stable.

```systemverilog
property p_avst_stable;
    @(posedge csi_data_clk) disable iff (rsi_data_reset)
        (aso_decoded_valid && !aso_decoded_ready) |=>
            $stable(aso_decoded_data) && $stable(aso_decoded_error) &&
            $stable(aso_decoded_channel);
endproperty
```

**Bound.** Unbounded proof.

**Note.** The legacy IP does not surface `valid` (every cycle is
implicitly valid). The SV rebuild surfaces `valid` explicitly. If
codex commits to keeping implicit-valid for legacy compatibility,
this property simplifies to `data/error stable across $stable(ready)`
windows and the cover changes accordingly.

**Closure target.** Unbounded proof.

### 2.9 `sva_engine_attach` — Attach event correlates with counter

**Statement.** `engine_steerings[i]` increments iff a real attach
event fires on lane `i`.

```systemverilog
property p_engine_attach_count;
    @(posedge csi_data_clk) disable iff (rsi_data_reset)
        (engine_steerings_lane[i] != $past(engine_steerings_lane[i])) <->
            attach_event_lane[i];
endproperty
```

**Bound.** Unbounded proof.

**Closure target.** `qverify` proves unbounded.

---

## 3. Non-formal Properties

The following are *not* attempted in formal — only in simulation:

- decoded byte stream correctness across long traffic — sequence
  length is too long for BMC and the unbounded proof would require
  modelling the entire 8b/10b table.
- multi-lane contention scoreboard — too many state variables.
- `bucket_frame` and `all_buckets_frame` — by definition continuous
  long-run timeframes that BMC cannot reach.
- counter equality vs intent stream — needs a full traffic model.
- `txn_growth_curve` — soak runtime far exceeds formal bounds.

---

## 4. Build / Run Recipe

```
tb/formal/Makefile targets:
  make all           # run every proof
  make routing       # sva_routing_excl
  make steering      # sva_steering_queue
  make train         # sva_train_fsm
  make score         # sva_score_sat
  make csr           # sva_csr_aperture
  make counter       # sva_counter_sat
  make avmm          # sva_avalon_mm
  make avst          # sva_avalon_st
  make attach        # sva_engine_attach
  make report        # write tb/REPORT/formal/<run_id>.md
```

---

## 5. Closure Gate

For DV closure (per `DV_PLAN.md` §9 gate 6):

| Property | Tool | Status target | Waiver allowed? |
|----------|------|---------------|-----------------|
| `sva_routing_excl` | qverify unbounded | proven | no |
| `sva_steering_queue` | qverify bounded(32) | proven | no |
| `sva_train_fsm` | qverify bounded(80) | proven | with abstraction note |
| `sva_score_sat` | qverify unbounded | proven | no |
| `sva_csr_aperture` | qverify bounded(4) | proven | no |
| `sva_counter_sat` | qverify unbounded | proven | no |
| `sva_avalon_mm` | qverify unbounded | proven | no |
| `sva_avalon_st` | qverify unbounded | proven | no |
| `sva_engine_attach` | qverify unbounded | proven | no |

A waiver requires:
- explicit reason in `DV_REPORT.md` formal-section;
- a counter-example or BMC-bound trace recorded in `tb/REPORT/formal/`;
- a fallback UVM regression that exercises the property under random
  stimulus for at least 1M cycles without violation.

---

## 6. Cross-tool Sanity

For each property, run both `qverify` and `znformal` (or
`jaspergold`) on the same SVA + bind set. If a property closes in
one tool but not the other, the discrepancy is recorded as
`DEBUG_FORMAL` in `BUG_HISTORY.md` and treated as a closure blocker
until resolved.
