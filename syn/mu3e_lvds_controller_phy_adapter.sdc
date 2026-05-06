# mu3e_lvds_controller_phy_adapter.sdc
#
# CDC timing intent for the explicit control/data handshakes inside
# mu3e_lvds_controller. The control clock owns Avalon-MM CSR access; the data
# clock is the PHY-generated LVDS RX outclock. These constraints target only
# the synchronizer and held-bundle paths inside this IP and do not globally cut
# clocks for the integrating system.

proc mlvds_get_registers_any {patterns} {
    set nodes [get_registers -nowarn __mlvds_no_match__]
    foreach pattern $patterns {
        set matches [get_registers -nowarn $pattern]
        if {[get_collection_size $matches] > 0} {
            set nodes [add_to_collection $nodes $matches]
        }
    }
    return $nodes
}

proc mlvds_node_patterns {leaf_name} {
    return [list \
        "mu3e_lvds_controller:*|$leaf_name" \
        "*|mu3e_lvds_controller:*|$leaf_name" \
        "*mu3e_lvds_controller*|$leaf_name"]
}

proc mlvds_apply_false_path_pair {from_nodes to_nodes} {
    if {[get_collection_size $from_nodes] > 0 && [get_collection_size $to_nodes] > 0} {
        set_false_path -from $from_nodes -to $to_nodes
    }
}

proc constrain_mlvds_control_to_data_cdc {} {
    # CSR configuration and snapshot-lane selection are held stable until the
    # data domain observes the matching toggle and acknowledges the transfer.
    set cfg_req_src     [mlvds_get_registers_any [mlvds_node_patterns {cfg_req_toggle_control}]]
    set cfg_req_meta    [mlvds_get_registers_any [mlvds_node_patterns {cfg_req_toggle_data_d1}]]
    set cfg_bus_src     [mlvds_get_registers_any [mlvds_node_patterns {cfg_control_bus*}]]
    set cfg_bus_dst     [mlvds_get_registers_any [mlvds_node_patterns {cfg_data*}]]

    set snap_req_src    [mlvds_get_registers_any [mlvds_node_patterns {snapshot_req_toggle_control}]]
    set snap_req_meta   [mlvds_get_registers_any [mlvds_node_patterns {snapshot_req_toggle_data_d1}]]
    set snap_lane_src   [mlvds_get_registers_any [mlvds_node_patterns {snapshot_lane_control*}]]
    set snap_count_dst  [mlvds_get_registers_any [mlvds_node_patterns {snapshot_counter_data_bus*}]]

    mlvds_apply_false_path_pair $cfg_req_src    $cfg_req_meta
    mlvds_apply_false_path_pair $cfg_bus_src    $cfg_bus_dst
    mlvds_apply_false_path_pair $snap_req_src   $snap_req_meta
    mlvds_apply_false_path_pair $snap_lane_src  $snap_count_dst
}

proc constrain_mlvds_data_to_control_cdc {} {
    # Data-domain status/counter snapshots are sampled by the CSR readback mux
    # only after the data-domain acknowledge toggle passes through the two-flop
    # control-domain synchronizer.
    set cfg_ack_src      [mlvds_get_registers_any [mlvds_node_patterns {cfg_ack_toggle_data}]]
    set cfg_ack_meta     [mlvds_get_registers_any [mlvds_node_patterns {cfg_ack_toggle_control_d1}]]
    set snap_ack_src     [mlvds_get_registers_any [mlvds_node_patterns {snapshot_ack_toggle_data}]]
    set snap_ack_meta    [mlvds_get_registers_any [mlvds_node_patterns {snapshot_ack_toggle_control_d1}]]
    set snap_status_src  [mlvds_get_registers_any [mlvds_node_patterns {snapshot_status_data_bus*}]]
    set snap_counter_src [mlvds_get_registers_any [mlvds_node_patterns {snapshot_counter_data_bus*}]]
    set snap_read_dst    [mlvds_get_registers_any [mlvds_node_patterns {avs_csr_readdata*}]]

    mlvds_apply_false_path_pair $cfg_ack_src       $cfg_ack_meta
    mlvds_apply_false_path_pair $snap_ack_src      $snap_ack_meta
    mlvds_apply_false_path_pair $snap_status_src   $snap_read_dst
    mlvds_apply_false_path_pair $snap_counter_src  $snap_read_dst
}

proc constrain_mlvds_phy_status_syncs {} {
    # PHY status conduits are asynchronous to the consuming logic and enter the
    # controller through local two-flop synchronizers.
    set phy_status_meta [mlvds_get_registers_any [concat \
        [mlvds_node_patterns {plllock_control_d1}] \
        [mlvds_node_patterns {plllock_data_d1}] \
        [mlvds_node_patterns {dpalock_data_d1*}] \
        [mlvds_node_patterns {rollover_data_d1*}] \
        [mlvds_node_patterns {redriver_losn_data_d1*}]]]

    if {[get_collection_size $phy_status_meta] > 0} {
        set_false_path -to $phy_status_meta
    }
}

constrain_mlvds_control_to_data_cdc
constrain_mlvds_data_to_control_cdc
constrain_mlvds_phy_status_syncs
