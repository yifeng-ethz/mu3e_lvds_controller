# mu3e_lvds_controller — DV Tree

This is the verification root for the SystemVerilog rebuild of
`lvds_rx_controller_pro`. The rebuild target IP version is
**26.0.0.0429**. The legacy VHDL/terp implementation
(`lvds_rx_controller_pro.terp.vhd`, ver 25.1.0631) remains in the
worktree as a behavioural reference only — it is not a signoff path.

## Layout

```
tb/
  README.md                 # this file (navigation only)
  uvm/                      # UVM harness (codex implements after plan freeze)
  formal/                   # qverify / znformal env (codex implements after plan freeze)
  doc/
    DV_PLAN.md              # master plan; entry point for codex
    DV_HARNESS.md           # UVM/formal harness architecture
    DV_BASIC.md             # B-bucket: bring-up + identity + training + steady-state lock
    DV_EDGE.md              # E-bucket: corner cases (ties, contention, fabric edges)
    DV_PROF.md              # P-bucket: stress / soak / saturation
    DV_ERROR.md             # X-bucket: reset / illegal / fault
    DV_CROSS.md             # cross-coverage + bucket_frame / all_buckets_frame
    DV_FORMAL.md            # formal sub-plan (qverify primary)
    DV_COV.md               # per-bucket coverage tracking tables
  BUG_HISTORY.md            # mandatory bug ledger (canonical packet_scheduler format)
```

## Reading order for codex

1. `doc/DV_PLAN.md` — scope, DUT contract, architecture critique, sweep matrix.
2. `doc/DV_HARNESS.md` — UVM topology, agents, scoreboard, formal env.
3. `doc/DV_BASIC.md` then `DV_EDGE.md`, `DV_PROF.md`, `DV_ERROR.md`, `DV_CROSS.md`.
4. `doc/DV_FORMAL.md` — what is provable in formal vs left to simulation.
5. `doc/DV_COV.md` — coverage skeleton; populate as cases land.
6. `BUG_HISTORY.md` — every bug found goes here, indexed; commit hash recorded after fix lands.

## Hard contract (do not bypass)

- Lint every bucket file after every edit:
  `python3 ~/.codex/skills/dv-workflow/scripts/dv_bucket_format_check.py tb/doc/`
- Lint the bug ledger:
  `python3 ~/.codex/skills/dv-workflow/scripts/bug_history_format_check.py tb/BUG_HISTORY.md`
- CSR map must NOT appear in any bucket file. CSR map is owned by
  `script/lvds_rx_controller_pro_hw.tcl` and the CSR-header lint inside
  the `ip-packaging` skill.
- Do not weaken the testbench to make RTL pass. Fix the RTL.
- One bug = one ledger entry with first-seen testcase, encounterability
  band, root cause, fix mechanism, before/after evidence, commit hash.
