# INTEGRATION_REVIEW.md - LVDS controller Platform Designer integration

## 2026-04-29 Pin-Level Review

The branch is already based on `master` after fetching `origin/master` at
`776cc3f`; `git merge master` reports `Already up to date`.

Current Phase 5 systems instantiate the legacy pair:

- `lvds_rx_28nm_0` (`altera_lvds_rx_28nm`)
- `lvds_rx_controller_pro_0` (`lvds_rx_controller_pro`)

The active systems connect `lvds_rx_controller_pro_0.decoded0` through
`decoded7` into lane muxes and export/use `decoded8`, with each decoded
interface carrying only `data`, `channel`, and `error`. There is no
ready/valid handshake on this legacy stream surface.

## Upgrade Decision

The rebuilt controller package now preserves that pin-level surface:

- `mu3e_lvds_controller_phy_adapter` exposes `decoded0..decodedN` as
  Avalon-ST starts with 9-bit data, derived channel width, and 3-bit error.
- The adapter ties the rebuilt core ready vector high, matching the old
  no-backpressure contract.
- The composed `mu3e_lvds_controller` exports the same decoded interfaces while
  absorbing `altera_lvds_rx_28nm` internally.
- The composed IP exports `outclock` through an internal `altera_clock_bridge`
  so the PHY outclock can feed the controller and still be visible to the
  current system clock wiring.

## Integration Guidance

For a low-risk current-system swap, replace the legacy controller instance with
`mu3e_lvds_controller_phy_adapter` first and keep the existing
`lvds_rx_28nm_0` instance. This keeps `parallel`, `ctrl`, `redriver`, `csr`,
`control_clock`, `control_reset`, `data_clock`, `data_reset`, and
`decoded0..decoded8` at the old connection level.

For the later absorbed-PHY swap, replace both legacy instances with
`mu3e_lvds_controller`, then reconnect the existing top-level `serial`,
`inclock`, `outclock`, `redriver`, `csr`, clock/reset, and `decoded0..decoded8`
interfaces to the composed instance.

The CSR map is not pin-level compatible with `lvds_rx_controller_pro`; software
must use the new UID/META header and widened counter aperture.

## Evidence

```text
git fetch https://github.com/yifeng-ethz/mu3e_lvds_controller.git master:refs/remotes/origin/master
git merge --no-edit master
```

```text
ip-make-ipx --source-directory=$(pwd) --output=/tmp/mu3e_lvds_controller_components.ipx --thorough-descent
```

```text
qsys-script --package-version=16.1 --search-path="$(pwd),$" ...
qsys-generate /tmp/test_lvds_composed_connected.qsys --synthesis=VERILOG --search-path="$(pwd),$"
```

The generated composed smoke system exposes `decoded0..decoded8`, `serial`,
`redriver`, and `outclock` for `N_LANE=9` and completes `qsys-generate`.
