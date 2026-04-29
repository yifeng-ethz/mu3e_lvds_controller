# RTL_PLAN.md - LVDS controller RTL and synthesis plan

## 1. Scope

This plan covers the SystemVerilog rebuild of `mu3e_lvds_controller` in
standalone synthesis mode. The signoff instance uses `N_LANE=12`,
`N_ENGINE=1`, `ROUTING_TOPOLOGY=1`, `SCORE_WINDOW_W=10`, and `DEBUG_LEVEL=0`.

The target device is the active FEB Arria V part `5AGXBA7D4F31C5`. The nominal
data-path clock is 125 MHz and the nominal control/CSR clock is 156.25 MHz.
Standalone timing signoff uses the required 1.1x margin: 137.5 MHz for the data
clock and 171.875 MHz for the control clock.

## 2. Pre-Fit RTL Model

| Block | Ownership | Expected mapping | Expected bottleneck |
|---|---|---|---|
| CSR bank | `csi_control_clk` registers | FF control state and one CSR read mux | counter aperture read mux from selected lane |
| Mini decoder lanes | `csi_data_clk` pipeline | LUT compare/decode plus FF pipeline | per-lane decode compare fanout into training FSM |
| PHY training | `csi_data_clk` per-lane state | FF state, small counters, simple muxing | `lane_go`/DPA lock/reset fanout |
| Super engine | `csi_data_clk` shared engine state | FF score table, LUT rotation/decode, compare tree | 10-phase score update and best-phase selection |
| Statistics | `csi_data_clk` per-lane counters | FF counters with saturating incrementers | selected counter increment muxes |
| Output stage | `csi_data_clk` pipeline | FF valid/data/error/channel outputs | mini-vs-engine route select |

The intended long path before fitting is the data-domain super engine path:
attached-lane symbol select, ten rotated decode attempts, score update, and
best-phase selection. The second expected class is fanout from CSR state into
the data domain; it is timed only after the local two-stage data-domain capture.

The standalone timing SDC treats control and data clocks as asynchronous. This
is a timing-scope assumption, not a CDC signoff claim.

## 3. Resource Estimate

| Resource | Estimate | Basis |
|---|---:|---|
| ALMs | 3000 | 12 mini decoders, one shared engine, CSR muxes, counter incrementers |
| Registers | 6500 | 12 x 10 x 32-bit counters, output pipelines, training and engine state |
| M10K | 0 | no memory is intended for the default signoff geometry |
| DSP | 0 | no multipliers or DSP arithmetic |

Resources pass standalone signoff when actual usage is between 0.5x and 3.0x of
these estimates unless the note documents a justified plan update.

## 4. DV Requirements

The signoff DV source of truth is `tb/doc/DV_PLAN.md`. The required regression
evidence for synthesis signoff is a passing QuestaOne UVM bucket run and a
passing continuous `lvds_all_buckets_frame_test` run without changing the UVM
harness semantics.
