# SIGNOFF.md - LVDS controller standalone Quartus signoff

## Verdict

PASS. `mu3e_lvds_controller` VERSION `26.2.1.0506` meets standalone
1.1x F_target timing in isolation on the Arria V `5AGXBA7D4F31C5` signoff
project.

This run did not downgrade VERSION and did not use seed scanning.

## Target

| Item | Value |
|---|---|
| Project | `syn/quartus/lvds_controller_syn.qpf` |
| Revision | `lvds_controller_syn` |
| Top | `lvds_controller_syn_top` |
| Device | `5AGXBA7D4F31C5` |
| Quartus | `18.1.0 Build 625 09/12/2018 SJ Standard Edition` |
| Nominal control F_target | 156.25 MHz |
| Standalone control signoff | 171.875 MHz, 5.818 ns |
| Nominal data F_target | 125.000 MHz |
| Standalone data signoff | 137.500 MHz, 7.273 ns |

Quartus 18.1 reports the available final Arria V multicorner timing models for
this device as `Slow/Fast 1100mV 85C/0C`. It does not expose the requested
`900mV 100C/0C` model names for `5AGXBA7D4F31C5`; the run below uses the four
available Quartus final timing models.

## Evidence Paths

| Artifact | Path |
|---|---|
| Flow report | `syn/quartus/output_files/lvds_controller_syn.flow.rpt` |
| Fit summary | `syn/quartus/output_files/lvds_controller_syn.fit.summary` |
| STA summary | `syn/quartus/output_files/lvds_controller_syn.sta.summary` |
| STA full report with report_timing paths | `syn/quartus/output_files/lvds_controller_syn.sta.rpt` |
| Static screen transcript | `/data3/yifeng/mu3e_ip_dev/qverify/mu3e_lvds_controller_20260511/latest_static/questa_static_screen.log` |
| CDC report | `/data3/yifeng/mu3e_ip_dev/qverify/mu3e_lvds_controller_20260511/latest_static/reports/cdc.rpt` |
| RDC report | `/data3/yifeng/mu3e_ip_dev/qverify/mu3e_lvds_controller_20260511/latest_static/qverify_db/rdc.rpt` |
| Lint report | `/data3/yifeng/mu3e_ip_dev/qverify/mu3e_lvds_controller_20260511/latest_static/qverify_db/lint.rpt` |

Build timestamp: `Mon May 11 10:55:10 2026` from
`syn/quartus/output_files/lvds_controller_syn.flow.rpt`.

STA report timestamp: `2026-05-11 10:55:43 +0200` from
`syn/quartus/output_files/lvds_controller_syn.sta.rpt`.

## Commands

```text
quartus_sh --flow compile lvds_controller_syn -c lvds_controller_syn
quartus_sta --do_report_timing --multicorner=on lvds_controller_syn -c lvds_controller_syn
python3 ~/.codex/skills/rtl-linter-and-checker/scripts/questa_static_screen.py \
  --top mu3e_lvds_controller_phy_adapter \
  --filelist syn/questa_static_lvds_controller.f \
  --work-dir /data3/yifeng/mu3e_ip_dev/qverify/mu3e_lvds_controller_20260511/latest_static \
  rtl/mu3e_lvds_controller.sv rtl/mu3e_lvds_controller_phy_adapter.sv
```

## Setup Slack

| Corner | Worst setup clock | Worst setup slack | Control setup slack | Data setup slack | TNS |
|---|---|---:|---:|---:|---:|
| Slow 1100mV 85C | `control_clk` | 0.360 ns | 0.360 ns | 0.630 ns | 0.000 |
| Slow 1100mV 0C | `control_clk` | 0.559 ns | 0.559 ns | 0.911 ns | 0.000 |
| Fast 1100mV 85C | `control_clk` | 2.669 ns | 2.669 ns | 3.123 ns | 0.000 |
| Fast 1100mV 0C | `control_clk` | 2.972 ns | 2.972 ns | 3.542 ns | 0.000 |

Worst overall setup path:

| Field | Value |
|---|---|
| Corner | Slow 1100mV 85C |
| Clock | `control_clk` |
| Slack | 0.360 ns |
| From | `avs_csr_writedata[1]` |
| To | `mu3e_lvds_controller:u_dut|csr.score_reject[4]` |
| STA report | `syn/quartus/output_files/lvds_controller_syn.sta.rpt` |

## Hold Slack

| Corner | Worst hold clock | Worst hold slack | Control hold slack | Data hold slack | TNS |
|---|---|---:|---:|---:|---:|
| Slow 1100mV 85C | `data_clk` | 0.266 ns | 0.291 ns | 0.266 ns | 0.000 |
| Slow 1100mV 0C | `data_clk` | 0.246 ns | 0.275 ns | 0.246 ns | 0.000 |
| Fast 1100mV 85C | `data_clk` | 0.165 ns | 0.179 ns | 0.165 ns | 0.000 |
| Fast 1100mV 0C | `data_clk` | 0.151 ns | 0.168 ns | 0.151 ns | 0.000 |

## Resources

| Resource | Estimate | Actual | Status |
|---|---:|---:|---|
| ALMs | 3000 | 6133 / 91680, 7% | PASS |
| Registers | 6500 | 6186 | PASS |
| RAM blocks | 0 | 0 / 1366 | PASS |
| DSP blocks | 0 | 0 / 800 | PASS |

The ALM and register counts remain within the `doc/RTL_PLAN.md` 0.5x to 3.0x
standalone resource window.

## Static Screen

`questa_static_screen.py` completed successfully on both RTL files using
`syn/questa_static_lvds_controller.f`.

| Gate | Result | Evidence |
|---|---|---|
| Lint | `Error (0)` | `/data3/yifeng/mu3e_ip_dev/qverify/mu3e_lvds_controller_20260511/latest_static/qverify_db/lint.rpt` |
| CDC | `Violations (0)` | `/data3/yifeng/mu3e_ip_dev/qverify/mu3e_lvds_controller_20260511/latest_static/reports/cdc.rpt` |
| RDC | `Violation (0)` | `/data3/yifeng/mu3e_ip_dev/qverify/mu3e_lvds_controller_20260511/latest_static/qverify_db/rdc.rpt` |

## Integration Consequence

The latest committed IP passes standalone signoff in isolation. The FEB SciFi
v3 `lvds_firefly_clk` violation should therefore be treated as an integration
or pin-version problem, not as evidence that VERSION `26.2.1.0506` fails its
standalone IP timing gate.
