# LVDS Controller Standalone Quartus Signoff

This project compiles only the SystemVerilog LVDS controller and a small
synthesizable activity harness. It targets the active FEB Arria V device
(`5AGXBA7D4F31C5`) and constrains the standalone clocks at 1.1x of the nominal
integration clocks.

Run:

```bash
quartus_sh --flow compile lvds_controller_syn -c lvds_controller_syn
```

The wrapper is for area/timing preservation only. It is not a functional
replacement for the UVM harness under `tb/uvm/`.
