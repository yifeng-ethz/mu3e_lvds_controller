# rtl_note.md - LVDS controller standalone signoff

## 1. Targets

| Item | Value |
|---|---|
| Device | Arria V `5AGXBA7D4F31C5` |
| Quartus | 18.1 Standard |
| Nominal control clock | 156.25 MHz |
| Standalone control signoff clock | 171.875 MHz, 5.818 ns |
| Nominal data clock | 125 MHz |
| Standalone data signoff clock | 137.5 MHz, 7.273 ns |
| Fitter effort | Standard Fit, no seed scan |

The standalone project is `syn/quartus/lvds_controller_syn.qpf`. The harness
instantiates `mu3e_lvds_controller` with `N_LANE=12`, `N_ENGINE=1`, and
`DEBUG_LEVEL=0`.

## 2. Pre-Fit Model

The data domain owns the training FSM, mini-decode pipeline, shared engine,
score table, statistics counters, and decoded Avalon-ST output registers. The
control domain owns only the CSR bank and readback path.

Expected resource classes are FF counters and state, LUT compare/decode logic,
and no RAM or DSP. The predicted top timing bottleneck is the shared engine
update path: attached-lane select, 10 phase rotations, decode/score updates, and
best-phase selection. Secondary risks are the CSR counter aperture read mux and
fanout-heavy data-domain control captures.

The timing SDC groups `control_clk` and `data_clk` asynchronously. That matches
the current standalone timing scope; CDC closure remains a separate signoff item
and is not claimed here.

## 3. DV Evidence

| Run | Command | Result |
|---|---|---|
| Targeted score counter | `make -C tb/uvm TEST=lvds_b061_score_changes_on_engine_update_test SYMBOL_CAP=256 RUN_LOG=log/primary/b061_after_score_event_pipe.log run` | PASS: 1 transaction, zero UVM errors/fatals |
| Targeted engine release | `make -C tb/uvm TEST=lvds_b078_engine_release_after_sustained_accept_test SYMBOL_CAP=256 RUN_LOG=log/primary/b078_after_score_event_pipe.log run` | PASS: 1 transaction, zero UVM errors/fatals |
| Bucket frame | `make -C tb/uvm bucket_frame SYMBOL_CAP=256` | PASS: BASIC 78, EDGE 50, PROF 40, ERROR 50, zero UVM errors/fatals |
| All buckets frame | `make -C tb/uvm TEST=lvds_all_buckets_frame_test SYMBOL_CAP=256 RUN_LOG=log/primary/all_buckets_frame_after_timing_close.log run` | PASS: 218 transactions, zero UVM errors/fatals |

## 4. Timing Evidence

Final standalone compile:

```text
/data1/intelFPGA/18.1/quartus/bin/quartus_sh --flow compile lvds_controller_syn -c lvds_controller_syn
```

| Corner | Clock | Setup slack | Setup TNS | Hold slack | Hold TNS |
|---|---|---:|---:|---:|---:|
| Slow 1100 mV 85 C | `control_clk` | 0.202 ns | 0.000 | 0.260 ns | 0.000 |
| Slow 1100 mV 85 C | `data_clk` | 0.427 ns | 0.000 | 0.283 ns | 0.000 |
| Slow 1100 mV 0 C | `control_clk` | 0.403 ns | 0.000 | 0.243 ns | 0.000 |
| Slow 1100 mV 0 C | `data_clk` | 0.523 ns | 0.000 | 0.263 ns | 0.000 |
| Fast 1100 mV 85 C | `control_clk` | 2.386 ns | 0.000 | 0.162 ns | 0.000 |
| Fast 1100 mV 85 C | `data_clk` | 3.211 ns | 0.000 | 0.172 ns | 0.000 |
| Fast 1100 mV 0 C | `control_clk` | 2.722 ns | 0.000 | 0.153 ns | 0.000 |
| Fast 1100 mV 0 C | `data_clk` | 3.542 ns | 0.000 | 0.159 ns | 0.000 |

The final generated reports are:

- `syn/quartus/output_files/lvds_controller_syn.sta.summary`
- `syn/quartus/output_files/lvds_controller_syn.data_setup.paths.rpt`
- `syn/quartus/output_files/lvds_controller_syn.control_setup.paths.rpt`
- `syn/quartus/output_files/lvds_controller_syn.data_hold.paths.rpt`
- `syn/quartus/output_files/lvds_controller_syn.control_hold.paths.rpt`

The path-fix sequence was:

| Iteration | Worst result | Fix |
|---|---:|---|
| Initial standalone fit | data setup WNS -22.059 ns, control setup WNS -0.766 ns | Identified same-cycle super-engine score reduction and release path. |
| Best-score scan pipeline | data setup WNS -1.978 ns, control setup WNS -0.050 ns | Registered 10-phase best-score scan. |
| Engine symbol/request pipelines | data setup WNS -0.485 ns, control setup WNS +0.291 ns | Registered selected score symbol, per-lane engine requests, and direct CSR counter aperture decode. |
| Score-change one-hot event | data setup WNS +0.427 ns, control setup WNS +0.202 ns | Moved score-change counter writes to one-hot per-lane event pipeline. |

## 5. Resource Evidence

Final fitter summary:

| Resource | Estimate | Actual | Limit check |
|---|---:|---:|---|
| ALMs | 3000 | 6157 / 91680, 7% | PASS: within 0.5x to 3.0x estimate |
| Registers | 6500 | 5563 | PASS: within 0.5x to 3.0x estimate |
| M10K | 0 | 0 / 1366 | PASS |
| DSP | 0 | 0 / 800 | PASS |
| Pins | n/a | 133 / 426, 31% | Informational standalone harness pins |

`output_files/` is generated evidence and is ignored by git; the numbers above
are copied from `lvds_controller_syn.fit.summary`.

## 6. Gate-Level Evidence

Quartus EDA netlist generation:

```text
/data1/intelFPGA/18.1/quartus/bin/quartus_eda lvds_controller_syn -c lvds_controller_syn --simulation=on --tool=modelsim --format=verilog --output_directory=simulation/modelsim
```

Result: PASS, with Quartus warning 10905 that this Arria V flow emits a
functional simulation netlist as the only supported netlist type for the
device.

QuestaOne netlist smoke:

```text
vlog -work simulation/gls_work3 \
  /data1/intelFPGA/18.1/quartus/eda/sim_lib/altera_primitives.v \
  /data1/intelFPGA/18.1/quartus/eda/sim_lib/220model.v \
  /data1/intelFPGA/18.1/quartus/eda/sim_lib/arriav_atoms.v \
  sim/arriav_clkena_encrypted_smoke_model.v \
  simulation/modelsim/lvds_controller_syn.vo \
  sim/lvds_controller_syn_gls_smoke_tb.sv

vsim -c -work simulation/gls_work3 -suppress 3016 \
  lvds_controller_syn_gls_smoke_tb -do "run -all; quit -f"
```

Result: PASS, compile `Errors: 0, Warnings: 0`, simulation `Errors: 0,
Warnings: 0`. The smoke-only `arriav_clkena_encrypted_smoke_model.v` is needed
because this QuestaOne installation does not expose Intel's encrypted helper
behind `arriav_clkena`; it is a pass-through clock-enable model used only for
the standalone generated netlist smoke.

## 7. Requirement Mapping

| Requirement | Status | Evidence |
|---|---|---|
| `tb/doc/DV_PLAN.md` RTL regression | Covered | QuestaOne bucket and all-buckets frame runs |
| `doc/RTL_PLAN.md` pre-fit model | Covered | This note and `doc/RTL_PLAN.md` |
| 1.1x standalone timing | Covered | Final Quartus STA has positive setup/hold slack at all analyzed corners |
| Standard Fit, no seed scan | Covered | `syn/quartus/lvds_controller_syn.qsf`; one compile, no seed sweep |
| Resource estimate comparison | Covered | Final fitter resources within `doc/RTL_PLAN.md` bounds |
| Gate-level simulation | Covered with limitation | Quartus functional netlist generated; QuestaOne netlist smoke run passes |
