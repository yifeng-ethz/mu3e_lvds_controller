package require Tcl 8.5

set script_dir [file dirname [info script]]
set helper_file [file normalize [file join $script_dir .. toolkits infra cmsis_svd lib mu3e_cmsis_svd.tcl]]
source $helper_file

namespace eval ::mu3e::cmsis::spec {}

proc ::mu3e::cmsis::spec::lane_bit_fields {prefix description access n_lane} {
    set fields {}
    for {set lane 0} {$lane < $n_lane} {incr lane} {
        lappend fields [::mu3e::cmsis::svd::field ${prefix}${lane} $lane 1 \
            -description [format $description $lane] \
            -access $access]
    }
    return $fields
}

proc ::mu3e::cmsis::spec::ceil_log2_width {value} {
    set width [expr {int(ceil(log($value) / log(2)))}]
    if {$width < 1} {
        set width 1
    }
    return $width
}

proc ::mu3e::cmsis::spec::lane_mask {n_lane} {
    if {$n_lane >= 32} {
        return 0xFFFFFFFF
    }
    return [format "0x%08X" [expr {(1 << $n_lane) - 1}]]
}

proc ::mu3e::cmsis::spec::build_registers {n_lane decoded_channel_width avmm_addr_w} {
    set max_word [expr {(1 << $avmm_addr_w) - 1}]
    set lane_mask [::mu3e::cmsis::spec::lane_mask $n_lane]
    set capability_reset [format "0x%08X" [expr {0x00FA0000 | ($n_lane & 0xFF)}]]

    set registers [list \
        [::mu3e::cmsis::svd::register capability 0x00 \
            -description {Capability and sync-pattern register. RTL word 0: sync_pattern[25:16], N_LANE[7:0].} \
            -access read-write \
            -resetValue $capability_reset \
            -resetMask 0x03FF00FF \
            -fields [list \
                [::mu3e::cmsis::svd::field N_LANE 0 8 \
                    -description "Configured number of LVDS receive lanes." \
                    -access read-only] \
                [::mu3e::cmsis::svd::field reserved0 8 8 \
                    -description "Reserved, read as zero." \
                    -access read-only] \
                [::mu3e::cmsis::svd::field sync_pattern 16 10 \
                    -description "10-bit 8b/10b sync pattern used by the byte-boundary alignment logic." \
                    -access read-write] \
                [::mu3e::cmsis::svd::field reserved1 26 6 \
                    -description "Reserved, read as zero." \
                    -access read-only]]] \
        [::mu3e::cmsis::svd::register mode_mask 0x04 \
            -description "Per-lane byte-boundary alignment mode. 0 selects bit-slip mode; 1 selects adaptive selection." \
            -access read-write \
            -resetValue $lane_mask \
            -fields [::mu3e::cmsis::spec::lane_bit_fields mode_masks_lane \
                "Alignment mode for lane %d: 0=bit-slip, 1=adaptive selection." \
                read-write $n_lane]] \
        [::mu3e::cmsis::svd::register soft_reset_req 0x08 \
            -description "Per-lane soft-reset request. Write 1 to request a lane reset; RTL clears the bit after the lane reaches IDLE." \
            -access read-write \
            -fields [::mu3e::cmsis::spec::lane_bit_fields soft_reset_req \
                "Soft-reset request for lane %d." read-write $n_lane]] \
        [::mu3e::cmsis::svd::register dpa_hold 0x0C \
            -description "Per-lane DPA hold control." \
            -access read-write \
            -fields [::mu3e::cmsis::spec::lane_bit_fields dpa_hold \
                "Hold DPA training for lane %d when set." read-write $n_lane]] \
        [::mu3e::cmsis::svd::register lane_go 0x10 \
            -description "Per-lane enable for DPA training and decoded data output." \
            -access read-write \
            -resetValue $lane_mask \
            -fields [::mu3e::cmsis::spec::lane_bit_fields lane_go \
                "Enable lane %d training and output when set." read-write $n_lane]]]

    for {set lane 0} {$lane < $n_lane} {incr lane} {
        set offset [format "0x%02X" [expr {0x14 + ($lane * 4)}]]
        lappend registers [::mu3e::cmsis::svd::register error_counter_lane${lane} $offset \
            -description [format "Symbol error counter for lane %d. RTL returns 0xFFFFFFFF while the lane has a fatal training error." $lane] \
            -access read-only \
            -fields [list \
                [::mu3e::cmsis::svd::field error_counts 0 32 \
                    -description [format "Decode plus parity error count for lane %d." $lane] \
                    -access read-only]]]
    }

    set lane_select_offset [format "0x%02X" [expr {0x14 + ($n_lane * 4)}]]
    set dpa_unlock_offset [format "0x%02X" [expr {0x18 + ($n_lane * 4)}]]
    lappend registers \
        [::mu3e::cmsis::svd::register lane_selection $lane_select_offset \
            -description "Lane selector for the port-mapped debug registers that follow." \
            -access read-write \
            -fields [list \
                [::mu3e::cmsis::svd::field lane_selection 0 $decoded_channel_width \
                    -description "Selected lane index for lane_dpa_unlocks and, when addressable, lane_word_aligner_chosen." \
                    -access read-write]]] \
        [::mu3e::cmsis::svd::register lane_dpa_unlocks $dpa_unlock_offset \
            -description "DPA unlock counter for the lane selected by lane_selection." \
            -access read-only \
            -fields [list \
                [::mu3e::cmsis::svd::field dpa_unlocks 0 32 \
                    -description "DPA unlock count for the selected lane." \
                    -access read-only]]]

    if {[expr {$n_lane + 7}] <= $max_word} {
        set aligner_offset [format "0x%02X" [expr {0x1C + ($n_lane * 4)}]]
        lappend registers [::mu3e::cmsis::svd::register lane_word_aligner_chosen $aligner_offset \
            -description "10-bit word-aligner choice mask for the lane selected by lane_selection." \
            -access read-only \
            -fields [list \
                [::mu3e::cmsis::svd::field chosen_mask 0 10 \
                    -description "One-hot adaptive word-aligner choice mask for the selected lane." \
                    -access read-only]]]
    }

    return $registers
}

proc ::mu3e::cmsis::spec::build_device {{n_lane 9} {avmm_addr_w 4}} {
    if {$n_lane < 1 || $n_lane > 32} {
        error "n_lane must be in range 1..32"
    }
    if {$avmm_addr_w < 1 || $avmm_addr_w > 31} {
        error "avmm_addr_w must be in range 1..31"
    }

    set decoded_channel_width [::mu3e::cmsis::spec::ceil_log2_width $n_lane]
    set address_block_size [format "0x%X" [expr {(1 << $avmm_addr_w) * 4}]]
    set description [format "CMSIS-SVD description of the lvds_rx_controller_pro CSR window for N_LANE=%d and AVMM_ADDR_W=%d. It names the RTL-backed words that are addressable through this package configuration." $n_lane $avmm_addr_w]
    if {[expr {$n_lane + 7}] >= [expr {1 << $avmm_addr_w}]} {
        append description [format " RTL also decodes word N_LANE+7 (%d) for lane_word_aligner_chosen, but that word is not addressable with AVMM_ADDR_W=%d; live tools must not read it until the package/system address width is widened." [expr {$n_lane + 7}] $avmm_addr_w]
    }

    return [::mu3e::cmsis::svd::device MU3E_LVDS_RX_CONTROLLER_PRO \
        -version 25.1.0631 \
        -description $description \
        -peripherals [list \
            [::mu3e::cmsis::svd::peripheral LVDS_RX_CONTROLLER_PRO_CSR 0x0 \
                -description "Relative CSR aperture for the LVDS receive controller." \
                -groupName MU3E_DATA_PATH \
                -addressBlockSize $address_block_size \
                -registers [::mu3e::cmsis::spec::build_registers \
                    $n_lane $decoded_channel_width $avmm_addr_w]]]]
}

proc ::mu3e::cmsis::spec::parse_cli_args {argv} {
    set options [dict create n_lane 9 avmm_addr_w 4 out_path ""]
    set positional {}

    for {set idx 0} {$idx < [llength $argv]} {incr idx} {
        set arg [lindex $argv $idx]
        switch -- $arg {
            -n_lane -
            --n_lane -
            -n-lane -
            --n-lane {
                incr idx
                if {$idx >= [llength $argv]} {
                    error "$arg requires a value"
                }
                dict set options n_lane [lindex $argv $idx]
            }
            -avmm_addr_w -
            --avmm_addr_w -
            -avmm-addr-w -
            --avmm-addr-w {
                incr idx
                if {$idx >= [llength $argv]} {
                    error "$arg requires a value"
                }
                dict set options avmm_addr_w [lindex $argv $idx]
            }
            -o -
            -output -
            --output {
                incr idx
                if {$idx >= [llength $argv]} {
                    error "$arg requires a value"
                }
                dict set options out_path [lindex $argv $idx]
            }
            default {
                if {[string match "-*" $arg]} {
                    error "unknown option $arg"
                }
                lappend positional $arg
            }
        }
    }

    if {[dict get $options out_path] eq "" && [llength $positional] > 0} {
        dict set options out_path [lindex $positional 0]
        set positional [lrange $positional 1 end]
    }
    if {[llength $positional] != 0} {
        error "unexpected positional arguments: $positional"
    }

    return $options
}

if {[info exists ::argv0] &&
    [file normalize $::argv0] eq [file normalize [info script]]} {
    set options [::mu3e::cmsis::spec::parse_cli_args $::argv]
    set out_path [dict get $options out_path]
    if {$out_path eq ""} {
        set out_path [file join $script_dir lvds_rx_controller_pro.svd]
    }
    ::mu3e::cmsis::svd::write_device_file \
        [::mu3e::cmsis::spec::build_device \
            [dict get $options n_lane] \
            [dict get $options avmm_addr_w]] \
        $out_path
}
