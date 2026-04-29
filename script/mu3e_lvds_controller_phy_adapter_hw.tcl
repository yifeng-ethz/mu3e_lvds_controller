# SPDX-License-Identifier: CERN-OHL-S-2.0

if {[catch {package require -exact qsys 18.1}]} {
    package require qsys 16.1
}

set VERSION_MAJOR_DEFAULT_CONST 26
set VERSION_MINOR_DEFAULT_CONST 0
set VERSION_PATCH_DEFAULT_CONST 0
set BUILD_DEFAULT_CONST         0x429
set VERSION_DATE_DEFAULT_CONST  0x20260429
set VERSION_GIT_DEFAULT_CONST   0x00000000
set INSTANCE_ID_DEFAULT_CONST   0
set VERSION_STRING              {26.0.0.0429}

set_module_property NAME                         {mu3e_lvds_controller_phy_adapter}
set_module_property DISPLAY_NAME                 {Mu3e LVDS Controller PHY Adapter}
set_module_property VERSION                      $VERSION_STRING
set_module_property DESCRIPTION                  {Mu3e LVDS controller internal PHY-width adapter}
set_module_property INTERNAL                     true
set_module_property OPAQUE_ADDRESS_MAP           true
set_module_property GROUP                        {Mu3e Data Plane/Internal}
set_module_property AUTHOR                       {Yifeng Wang}
set_module_property INSTANTIATE_IN_SYSTEM_MODULE true
set_module_property EDITABLE                     true
set_module_property REPORT_TO_TALKBACK           false
set_module_property ALLOW_GREYBOX_GENERATION     false
set_module_property REPORT_HIERARCHY             false
set_module_property ELABORATION_CALLBACK         elaborate
set_module_property VALIDATION_CALLBACK          validate

add_fileset synth QUARTUS_SYNTH
set_fileset_property synth TOP_LEVEL {mu3e_lvds_controller_phy_adapter}
add_fileset_file ../rtl/mu3e_lvds_controller.sv SYSTEM_VERILOG PATH ../rtl/mu3e_lvds_controller.sv
add_fileset_file ../rtl/mu3e_lvds_controller_phy_adapter.sv SYSTEM_VERILOG PATH ../rtl/mu3e_lvds_controller_phy_adapter.sv TOP_LEVEL_FILE

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
set_parameter_property N_LANE HDL_PARAMETER true
set_parameter_property N_LANE ALLOWED_RANGES {1:24}
set_parameter_property N_LANE AFFECTS_ELABORATION true
add_display_item {Configuration} N_LANE parameter

add_parameter N_ENGINE natural 1
set_parameter_property N_ENGINE DISPLAY_NAME {Super decoder-aligner engines}
set_parameter_property N_ENGINE HDL_PARAMETER true
set_parameter_property N_ENGINE ALLOWED_RANGES {1:24}
add_display_item {Configuration} N_ENGINE parameter

add_parameter ROUTING_TOPOLOGY natural 1
set_parameter_property ROUTING_TOPOLOGY DISPLAY_NAME {Routing topology}
set_parameter_property ROUTING_TOPOLOGY HDL_PARAMETER true
set_parameter_property ROUTING_TOPOLOGY ALLOWED_RANGES {"0: Full crossbar" "1: Partitioned n/engine" "2: Reserved butterfly"}
set_parameter_property ROUTING_TOPOLOGY DISPLAY_HINT RADIO
add_display_item {Configuration} ROUTING_TOPOLOGY parameter

add_parameter SCORE_WINDOW_W natural 10
set_parameter_property SCORE_WINDOW_W HDL_PARAMETER true
set_parameter_property SCORE_WINDOW_W ALLOWED_RANGES {6:16}
add_display_item {Configuration} SCORE_WINDOW_W parameter

add_parameter SCORE_ACCEPT natural 8
set_parameter_property SCORE_ACCEPT HDL_PARAMETER true
set_parameter_property SCORE_ACCEPT ALLOWED_RANGES {1:65535}
add_display_item {Configuration} SCORE_ACCEPT parameter

add_parameter SCORE_REJECT natural 2
set_parameter_property SCORE_REJECT HDL_PARAMETER true
set_parameter_property SCORE_REJECT ALLOWED_RANGES {0:65534}
add_display_item {Configuration} SCORE_REJECT parameter

add_parameter STEER_QUEUE_DEPTH natural 4
set_parameter_property STEER_QUEUE_DEPTH HDL_PARAMETER true
set_parameter_property STEER_QUEUE_DEPTH ALLOWED_RANGES {1:16}
add_display_item {Configuration} STEER_QUEUE_DEPTH parameter

add_parameter AVMM_ADDR_W natural 10
set_parameter_property AVMM_ADDR_W HDL_PARAMETER true
set_parameter_property AVMM_ADDR_W DERIVED true
set_parameter_property AVMM_ADDR_W VISIBLE false

add_parameter SYNC_PATTERN std_logic_vector 0x0FA
set_parameter_property SYNC_PATTERN WIDTH 10
set_parameter_property SYNC_PATTERN HDL_PARAMETER true
add_display_item {Configuration} SYNC_PATTERN parameter

add_parameter DEBUG_LEVEL natural 0
set_parameter_property DEBUG_LEVEL HDL_PARAMETER true
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
Internal adapter used by the composed LVDS controller. It converts the lane-width
output of the Arria V LVDS RX PHY wrapper into the fixed 32-lane debug/control
surface used by the verified SystemVerilog controller.
</html>
}

add_html_text {Interfaces} {interfaces_help} {
<html>
The <b>parallel</b> and <b>ctrl</b> conduits are intended to connect only to the
Mu3e <b>altera_lvds_rx_28nm</b> wrapper. The data clock is the PHY
<b>rx_outclock</b>. The CSR slave uses the common UID/META header.
</html>
}

add_html_text {Register Map} {register_map_help} {
<html>
<table border="1" cellpadding="3">
<tr><th>Word</th><th>Name</th><th>Description</th></tr>
<tr><td>Word 0</td><td>UID</td><td>Read-only IP_UID, default 0x4c564453.</td></tr>
<tr><td>Word 1</td><td>META</td><td>Write page selector. META pages: page 0 = VERSION, page 1 = DATE, page 2 = GIT, page 3 = INSTANCE_ID.</td></tr>
<tr><td>2..10</td><td>Global control/status</td><td>Capability, sync pattern, lane enables, DPA hold, soft reset, mode, thresholds, steering status.</td></tr>
<tr><td>16</td><td>LANE_SELECT</td><td>Selects the lane counter aperture.</td></tr>
<tr><td>17..26</td><td>COUNTERS</td><td>Readback aperture for per-lane counters.</td></tr>
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
        send_message ERROR "N_ENGINE must be <= N_LANE for a predictable engine-to-lane routing partition."
    }
    if {$score_accept > $score_max} {
        send_message WARNING "SCORE_ACCEPT will be clamped by RTL to the SCORE_WINDOW_W maximum."
    }
    if {$score_reject >= $score_accept} {
        send_message WARNING "SCORE_REJECT will be clamped below SCORE_ACCEPT by RTL."
    }
}

proc elaborate {} {
    set n_lane [get_parameter_value N_LANE]

    add_interface data_clock clock sink
    set_interface_property data_clock clockRate 0
    add_interface_port data_clock csi_data_clk clk Input 1

    add_interface data_reset reset sink
    set_interface_property data_reset associatedClock data_clock
    set_interface_property data_reset synchronousEdges BOTH
    add_interface_port data_reset rsi_data_reset reset Input 1

    add_interface control_clock clock sink
    set_interface_property control_clock clockRate 0
    add_interface_port control_clock csi_control_clk clk Input 1

    add_interface control_reset reset sink
    set_interface_property control_reset associatedClock control_clock
    set_interface_property control_reset synchronousEdges BOTH
    add_interface_port control_reset rsi_control_reset reset Input 1

    add_interface parallel conduit end
    set_interface_property parallel associatedClock data_clock
    add_interface_port parallel coe_parallel_data data Input [expr {$n_lane * 10}]

    add_interface ctrl conduit end
    add_interface_port ctrl coe_ctrl_pllrst pllrst Output 1
    add_interface_port ctrl coe_ctrl_plllock plllock Input 1
    add_interface_port ctrl coe_ctrl_dparst dparst Output $n_lane
    add_interface_port ctrl coe_ctrl_lockrst lockrst Output $n_lane
    add_interface_port ctrl coe_ctrl_dpahold dpahold Output $n_lane
    add_interface_port ctrl coe_ctrl_dpalock dpalock Input $n_lane
    add_interface_port ctrl coe_ctrl_fiforst fiforst Output $n_lane
    add_interface_port ctrl coe_ctrl_bitslip bitslip Output $n_lane
    add_interface_port ctrl coe_ctrl_rollover rollover Input $n_lane

    add_interface redriver conduit end
    add_interface_port redriver coe_redriver_losn losn Input $n_lane

    add_interface csr avalon end
    set_interface_property csr associatedClock control_clock
    set_interface_property csr associatedReset control_reset
    set_interface_property csr readLatency 1
    add_interface_port csr avs_csr_read read Input 1
    add_interface_port csr avs_csr_write write Input 1
    add_interface_port csr avs_csr_address address Input AVMM_ADDR_W
    add_interface_port csr avs_csr_writedata writedata Input 32
    add_interface_port csr avs_csr_readdata readdata Output 32
    add_interface_port csr avs_csr_waitrequest waitrequest Output 1

    add_interface decoded_bundle conduit start
    set_interface_property decoded_bundle associatedClock data_clock
    set_interface_property decoded_bundle associatedReset data_reset
    add_interface_port decoded_bundle aso_decoded_valid valid Output 32
    add_interface_port decoded_bundle aso_decoded_ready ready Input 32
    add_interface_port decoded_bundle aso_decoded_data data Output 288
    add_interface_port decoded_bundle aso_decoded_error error Output 96
    add_interface_port decoded_bundle aso_decoded_channel channel Output 192
}
