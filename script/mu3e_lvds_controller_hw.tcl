# SPDX-License-Identifier: CERN-OHL-S-2.0

package require -exact qsys 16.1

set VERSION_MAJOR_DEFAULT_CONST 26
set VERSION_MINOR_DEFAULT_CONST 2
set VERSION_PATCH_DEFAULT_CONST 0
set BUILD_DEFAULT_CONST         0x505
set VERSION_DATE_DEFAULT_CONST  0x20260505
set VERSION_GIT_DEFAULT_CONST   0x00000000
set INSTANCE_ID_DEFAULT_CONST   0
set VERSION_STRING              {26.2.0.0505}

set_module_property NAME                         {mu3e_lvds_controller}
set_module_property DISPLAY_NAME                 {Mu3e LVDS Controller with Arria V PHY}
set_module_property VERSION                      $VERSION_STRING
set_module_property DESCRIPTION                  {Mu3e LVDS controller with embedded Arria V LVDS RX PHY}
set_module_property INTERNAL                     false
set_module_property OPAQUE_ADDRESS_MAP           true
set_module_property GROUP                        {Mu3e Data Plane/Modules}
set_module_property AUTHOR                       {Yifeng Wang}
set_module_property INSTANTIATE_IN_SYSTEM_MODULE true
set_module_property EDITABLE                     true
set_module_property REPORT_TO_TALKBACK           false
set_module_property ALLOW_GREYBOX_GENERATION     false
set_module_property REPORT_HIERARCHY             false
set_module_property COMPOSITION_CALLBACK         compose
set_module_property VALIDATION_CALLBACK          validate

proc add_html_text {group_name item_name html_text} {
    add_display_item $group_name $item_name TEXT ""
    set_display_item_property $item_name DISPLAY_HINT html
    set_display_item_property $item_name TEXT $html_text
}

add_display_item "" {Configuration} GROUP tab
add_display_item "" {Identity} GROUP tab
add_display_item "" {Interfaces} GROUP tab
add_display_item "" {Register Map} GROUP tab

add_parameter N_LANE natural 12
set_parameter_property N_LANE DISPLAY_NAME {Number of LVDS lanes}
set_parameter_property N_LANE ALLOWED_RANGES {1:24}
set_parameter_property N_LANE AFFECTS_ELABORATION true
add_display_item {Configuration} N_LANE parameter

add_parameter N_ENGINE natural 1
set_parameter_property N_ENGINE DISPLAY_NAME {Super decoder-aligner engines}
set_parameter_property N_ENGINE ALLOWED_RANGES {1:24}
add_display_item {Configuration} N_ENGINE parameter

add_parameter ROUTING_TOPOLOGY natural 1
set_parameter_property ROUTING_TOPOLOGY DISPLAY_NAME {Raw-10b-to-engine routing topology}
set_parameter_property ROUTING_TOPOLOGY ALLOWED_RANGES {"0: Full crossbar" "1: Partitioned n/engine" "2: Reserved butterfly"}
set_parameter_property ROUTING_TOPOLOGY DISPLAY_HINT RADIO
add_display_item {Configuration} ROUTING_TOPOLOGY parameter

add_parameter SCORE_WINDOW_W natural 10
set_parameter_property SCORE_WINDOW_W ALLOWED_RANGES {6:16}
add_display_item {Configuration} SCORE_WINDOW_W parameter

add_parameter SCORE_ACCEPT natural 8
set_parameter_property SCORE_ACCEPT ALLOWED_RANGES {1:65535}
add_display_item {Configuration} SCORE_ACCEPT parameter

add_parameter SCORE_REJECT natural 2
set_parameter_property SCORE_REJECT ALLOWED_RANGES {0:65534}
add_display_item {Configuration} SCORE_REJECT parameter

add_parameter STEER_QUEUE_DEPTH natural 4
set_parameter_property STEER_QUEUE_DEPTH ALLOWED_RANGES {1:16}
add_display_item {Configuration} STEER_QUEUE_DEPTH parameter

add_parameter SYNC_PATTERN std_logic_vector 0x0FA
set_parameter_property SYNC_PATTERN WIDTH 10
add_display_item {Configuration} SYNC_PATTERN parameter

add_parameter DEBUG_LEVEL natural 0
set_parameter_property DEBUG_LEVEL ALLOWED_RANGES {0:3}
add_display_item {Configuration} DEBUG_LEVEL parameter

add_parameter IP_UID std_logic_vector 0x4C564453
set_parameter_property IP_UID WIDTH 32
set_parameter_property IP_UID HDL_PARAMETER true
set_parameter_property IP_UID DISPLAY_HINT hexadecimal
add_display_item {Identity} IP_UID parameter

add_parameter INSTANCE_ID natural $INSTANCE_ID_DEFAULT_CONST
set_parameter_property INSTANCE_ID HDL_PARAMETER true
add_display_item {Identity} INSTANCE_ID parameter

add_parameter VERSION_MAJOR natural $VERSION_MAJOR_DEFAULT_CONST
set_parameter_property VERSION_MAJOR HDL_PARAMETER true
set_parameter_property VERSION_MAJOR ENABLED false
add_display_item {Identity} VERSION_MAJOR parameter

add_parameter VERSION_MINOR natural $VERSION_MINOR_DEFAULT_CONST
set_parameter_property VERSION_MINOR HDL_PARAMETER true
set_parameter_property VERSION_MINOR ENABLED false
add_display_item {Identity} VERSION_MINOR parameter

add_parameter VERSION_PATCH natural $VERSION_PATCH_DEFAULT_CONST
set_parameter_property VERSION_PATCH HDL_PARAMETER true
set_parameter_property VERSION_PATCH ENABLED false
add_display_item {Identity} VERSION_PATCH parameter

add_parameter BUILD natural $BUILD_DEFAULT_CONST
set_parameter_property BUILD HDL_PARAMETER true
set_parameter_property BUILD ENABLED false
add_display_item {Identity} BUILD parameter

add_parameter VERSION_DATE natural $VERSION_DATE_DEFAULT_CONST
set_parameter_property VERSION_DATE HDL_PARAMETER true
set_parameter_property VERSION_DATE ENABLED false
add_display_item {Identity} VERSION_DATE parameter

add_parameter VERSION_GIT std_logic_vector $VERSION_GIT_DEFAULT_CONST
set_parameter_property VERSION_GIT WIDTH 32
set_parameter_property VERSION_GIT HDL_PARAMETER true
set_parameter_property VERSION_GIT ENABLED false
set_parameter_property VERSION_GIT DISPLAY_HINT hexadecimal
add_display_item {Identity} VERSION_GIT parameter

add_html_text {Configuration} {configuration_help} {
<html>
This composed IP instantiates the Mu3e SystemVerilog LVDS controller and the
existing <b>altera_lvds_rx_28nm</b> Arria V LVDS RX wrapper. The wrapper remains
in DPA FIFO mode with internal PLL, matching the current Quartus system. Set
<b>N_LANE</b> once here; the same value is pushed into both the PHY and the
controller adapter.
</html>
}

add_html_text {Identity} {identity_help} {
<html>
Runtime software reads word 0 as UID and word 1 as META. META page 0 returns
VERSION, page 1 VERSION_DATE, page 2 VERSION_GIT, and page 3 INSTANCE_ID.
The package version is 26.2.0.0505.
</html>
}

add_html_text {Interfaces} {interfaces_help} {
<html>
External interfaces: <b>serial</b> LVDS RX pins, <b>inclock</b> LVDS reference
clock, <b>outclock</b> PHY-generated data clock, <b>control_clock/reset</b> for
CSR, <b>data_reset</b> for the controller data domain, <b>csr</b>, <b>redriver</b>,
and legacy per-lane <b>decoded0..decodedN</b> Avalon-ST outputs. The PHY
<b>parallel</b> and <b>ctrl</b> conduits are wired internally to the controller.
</html>
}

add_html_text {Register Map} {register_map_help} {
<html>
<table border="1" cellpadding="3">
<tr><th>Word</th><th>Name</th><th>Access</th><th>Description</th></tr>
<tr><td>Word 0</td><td>UID</td><td>RO</td><td>IP_UID identity word.</td></tr>
<tr><td>Word 1</td><td>META</td><td>RW page / RO data</td><td>Metadata page selector. META pages: page 0 = VERSION, page 1 = DATE, page 2 = GIT, page 3 = INSTANCE_ID.</td></tr>
<tr><td>2</td><td>CAPABILITY</td><td>RO</td><td>N_LANE, N_ENGINE, score window, topology.</td></tr>
<tr><td>3</td><td>SYNC_PATTERN</td><td>RW</td><td>10-bit comma/training pattern.</td></tr>
<tr><td>4</td><td>LANE_GO</td><td>RW</td><td>Per-lane enable mask.</td></tr>
<tr><td>5</td><td>DPA_HOLD</td><td>RW</td><td>Per-lane DPA hold mask.</td></tr>
<tr><td>6</td><td>SOFT_RESET</td><td>WO pulse / RO zero</td><td>Per-lane soft-reset request.</td></tr>
<tr><td>7</td><td>MODE_MASK</td><td>RW</td><td>Global training/steering mode in current RTL.</td></tr>
<tr><td>8</td><td>SCORE_ACCEPT</td><td>RW clamp</td><td>Score threshold for lock acceptance.</td></tr>
<tr><td>9</td><td>SCORE_REJECT</td><td>RW clamp</td><td>Score threshold below accept.</td></tr>
<tr><td>10</td><td>STEER_STATUS</td><td>RO</td><td>Engine busy/attached state.</td></tr>
<tr><td>16</td><td>LANE_SELECT</td><td>RW</td><td>Lane counter aperture selector.</td></tr>
<tr><td>17..26</td><td>COUNTERS</td><td>RO aperture</td><td>Selected-lane error, training, steering, reset, and uptime counters.</td></tr>
</table>
</html>
}

proc validate {} {
    set n_lane [get_parameter_value N_LANE]
    set n_engine [get_parameter_value N_ENGINE]
    set score_accept [get_parameter_value SCORE_ACCEPT]
    set score_reject [get_parameter_value SCORE_REJECT]
    set score_window_w [get_parameter_value SCORE_WINDOW_W]
    set score_max [expr {(1 << $score_window_w) - 1}]

    if {$n_engine > $n_lane} {
        send_message ERROR "N_ENGINE must be <= N_LANE. Use N_ENGINE=N_LANE only when you intentionally want legacy per-lane engine parity."
    }
    if {$score_accept > $score_max} {
        send_message WARNING "SCORE_ACCEPT will be clamped by RTL to the SCORE_WINDOW_W maximum."
    }
    if {$score_reject >= $score_accept} {
        send_message WARNING "SCORE_REJECT will be clamped below SCORE_ACCEPT by RTL."
    }
}

proc compose {} {
    set n_lane [get_parameter_value N_LANE]

    add_instance phy altera_lvds_rx_28nm
    set_instance_parameter_value phy {N_LANE} $n_lane

    add_instance outclock_bridge altera_clock_bridge 18.1

    add_instance core mu3e_lvds_controller_phy_adapter
    foreach p {N_LANE N_ENGINE ROUTING_TOPOLOGY SCORE_WINDOW_W SCORE_ACCEPT SCORE_REJECT STEER_QUEUE_DEPTH SYNC_PATTERN DEBUG_LEVEL IP_UID INSTANCE_ID VERSION_MAJOR VERSION_MINOR VERSION_PATCH BUILD VERSION_DATE VERSION_GIT} {
        set_instance_parameter_value core $p [get_parameter_value $p]
    }
    add_connection phy.parallel core.parallel
    add_connection core.ctrl phy.ctrl
    add_connection phy.outclock core.data_clock
    add_connection phy.outclock outclock_bridge.in_clk

    add_interface serial conduit end
    set_interface_property serial EXPORT_OF phy.serial

    add_interface inclock clock sink
    set_interface_property inclock EXPORT_OF phy.inclock

    add_interface outclock clock source
    set_interface_property outclock EXPORT_OF outclock_bridge.out_clk

    add_interface data_reset reset sink
    set_interface_property data_reset EXPORT_OF core.data_reset

    add_interface control_clock clock sink
    set_interface_property control_clock EXPORT_OF core.control_clock

    add_interface control_reset reset sink
    set_interface_property control_reset EXPORT_OF core.control_reset

    add_interface csr avalon end
    set_interface_property csr EXPORT_OF core.csr

    add_interface redriver conduit end
    set_interface_property redriver EXPORT_OF core.redriver

    for {set lane 0} {$lane < $n_lane} {incr lane} {
        add_interface decoded${lane} avalon_streaming start
        set_interface_property decoded${lane} EXPORT_OF core.decoded${lane}
    }
}
