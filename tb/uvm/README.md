# LVDS Controller UVM Harness

Generated case sequences live in `sequence/` and are derived from
`tb/doc/DV_BASIC.md`, `DV_EDGE.md`, `DV_PROF.md`, and `DV_ERROR.md`.

Useful entry points:

```bash
make -C tb/uvm regen_cases
make -C tb/uvm STUB=1 smoke_stub
make -C tb/uvm TEST=lvds_base_test run
make -C tb/uvm TEST=lvds_bucket_frame_basic_test run
```

`STUB=1` is a harness smoke mode only. Signoff runs must compile
`../../rtl/mu3e_lvds_controller.sv` and must not use the stub.
