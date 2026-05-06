package require Tcl 8.5

set script_dir [file dirname [info script]]
set helper_file [file normalize [file join $script_dir .. toolkits infra cmsis_svd lib mu3e_cmsis_svd.tcl]]
source $helper_file

namespace eval ::mu3e::cmsis::spec {}

proc ::mu3e::cmsis::spec::clamp {value min_value max_value} {
    if {$value < $min_value} {
        return $min_value
    }
    if {$value > $max_value} {
        return $max_value
    }
    return $value
}

proc ::mu3e::cmsis::spec::lane_mask {n_lane} {
    if {$n_lane >= 32} {
        return 0xFFFFFFFF
    }
    return [format "0x%08X" [expr {(1 << $n_lane) - 1}]]
}

proc ::mu3e::cmsis::spec::version_word {major minor patch build} {
    return [format "0x%08X" [expr {(($major & 0xFF) << 24) |
        (($minor & 0xFF) << 16) |
        (($patch & 0xF) << 12) |
        ($build & 0xFFF)}]]
}

proc ::mu3e::cmsis::spec::capability_word {routing_topology score_window_w n_engine n_lane counter_count} {
    return [format "0x%08X" [expr {(($routing_topology & 0xF) << 28) |
        (($score_window_w & 0xF) << 24) |
        (($n_engine & 0xFF) << 16) |
        (($n_lane & 0xFF) << 8) |
        ($counter_count & 0xFF)}]]
}

proc ::mu3e::cmsis::spec::value_field {name description access} {
    return [list [::mu3e::cmsis::svd::field $name 0 32 \
        -description $description \
        -access $access]]
}

proc ::mu3e::cmsis::spec::build_registers {spec} {
    set n_lane [dict get $spec n_lane]
    set n_engine [dict get $spec n_engine]
    set routing_topology [dict get $spec routing_topology]
    set score_window_w [dict get $spec score_window_w]
    set score_accept [dict get $spec score_accept]
    set score_reject [dict get $spec score_reject]
    set sync_pattern [dict get $spec sync_pattern]
    set counter_count 10
    set lane_mask [::mu3e::cmsis::spec::lane_mask $n_lane]
    set capability_reset [::mu3e::cmsis::spec::capability_word \
        $routing_topology $score_window_w $n_engine $n_lane $counter_count]

    set registers [list \
        [::mu3e::cmsis::svd::register UID 0x00 \
            -description {Software-visible LVDS controller UID. Default ASCII "LVDS" (0x4C564453).} \
            -access read-only \
            -resetValue 0x4C564453 \
            -fields [::mu3e::cmsis::spec::value_field value \
                {Compile-time or integration-time LVDS UID word.} read-only]] \
        [::mu3e::cmsis::svd::register META 0x04 \
            -description {Read-multiplexed metadata word. Write page[1:0] before reading back: 0=VERSION, 1=VERSION_DATE, 2=VERSION_GIT, 3=INSTANCE_ID.} \
            -access read-write \
            -fields [list \
                [::mu3e::cmsis::svd::field page 0 2 \
                    -description {Selects the metadata read page.} \
                    -access read-write] \
                [::mu3e::cmsis::svd::field reserved 2 30 \
                    -description {Reserved, read as zero.} \
                    -access read-only]]] \
        [::mu3e::cmsis::svd::register CAPABILITY 0x08 \
            -description {Packed capability word for the compiled lane/engine/routing profile.} \
            -access read-only \
            -resetValue $capability_reset \
            -fields [list \
                [::mu3e::cmsis::svd::field counter_count 0 8 \
                    -description {Number of per-lane counters exposed through the selected-lane counter window.} \
                    -access read-only] \
                [::mu3e::cmsis::svd::field n_lane 8 8 \
                    -description {Number of active LVDS lanes after RTL parameter clamping.} \
                    -access read-only] \
                [::mu3e::cmsis::svd::field n_engine 16 8 \
                    -description {Number of shared decode engines after RTL parameter clamping.} \
                    -access read-only] \
                [::mu3e::cmsis::svd::field score_window_w 24 4 \
                    -description {Score-window width used by the engine steering score saturators.} \
                    -access read-only] \
                [::mu3e::cmsis::svd::field routing_topology 28 4 \
                    -description {Compiled routing topology selector.} \
                    -access read-only]]] \
        [::mu3e::cmsis::svd::register SYNC_PATTERN 0x0C \
            -description {Training/control symbol accepted as the lane synchronization pattern. Writes are accepted only for RTL-recognized K28.5/K28.0/K23.7 encodings.} \
            -access read-write \
            -resetValue [format "0x%08X" $sync_pattern] \
            -fields [list \
                [::mu3e::cmsis::svd::field pattern 0 10 \
                    -description {10-bit synchronization symbol.} \
                    -access read-write] \
                [::mu3e::cmsis::svd::field reserved 10 22 \
                    -description {Reserved, read as zero.} \
                    -access read-only]]] \
        [::mu3e::cmsis::svd::register LANE_GO 0x10 \
            -description {Per-lane enable mask, clipped by the compiled active-lane mask.} \
            -access read-write \
            -resetValue $lane_mask \
            -fields [::mu3e::cmsis::spec::value_field lane_mask \
                {One bit per physical LVDS lane.} read-write]] \
        [::mu3e::cmsis::svd::register DPA_HOLD 0x14 \
            -description {Per-lane DPA hold request mask, clipped by the compiled active-lane mask.} \
            -access read-write \
            -resetValue 0x00000000 \
            -fields [::mu3e::cmsis::spec::value_field lane_mask \
                {One bit per physical LVDS lane.} read-write]] \
        [::mu3e::cmsis::svd::register SOFT_RESET 0x18 \
            -description {Per-lane soft-reset request latch. Writing 1 requests a lane soft reset; RTL clears the bit after the hold interval completes.} \
            -access read-write \
            -resetValue 0x00000000 \
            -fields [::mu3e::cmsis::spec::value_field lane_mask \
                {One bit per physical LVDS lane.} read-write]] \
        [::mu3e::cmsis::svd::register MODE_MASK 0x1C \
            -description {Global two-bit lane mode in the current RTL. The full word is stored, but lane_mode() currently consumes bits [1:0].} \
            -access read-write \
            -resetValue 0x00000000 \
            -fields [list \
                [::mu3e::cmsis::svd::field mode 0 2 \
                    -description {0=bitslipping, 1=adapting, 2=autoing.} \
                    -access read-write] \
                [::mu3e::cmsis::svd::field reserved_storage 2 30 \
                    -description {Stored by RTL for future per-lane mode expansion; currently not decoded by lane_mode().} \
                    -access read-write]]] \
        [::mu3e::cmsis::svd::register SCORE_ACCEPT 0x20 \
            -description {Engine steering accept threshold, clamped by the RTL score window.} \
            -access read-write \
            -resetValue [format "0x%08X" $score_accept] \
            -fields [list \
                [::mu3e::cmsis::svd::field threshold 0 16 \
                    -description {Accept threshold.} \
                    -access read-write] \
                [::mu3e::cmsis::svd::field reserved 16 16 \
                    -description {Reserved, read as zero.} \
                    -access read-only]]] \
        [::mu3e::cmsis::svd::register SCORE_REJECT 0x24 \
            -description {Engine steering reject threshold, clamped not to exceed SCORE_ACCEPT.} \
            -access read-write \
            -resetValue [format "0x%08X" $score_reject] \
            -fields [list \
                [::mu3e::cmsis::svd::field threshold 0 16 \
                    -description {Reject threshold.} \
                    -access read-write] \
                [::mu3e::cmsis::svd::field reserved 16 16 \
                    -description {Reserved, read as zero.} \
                    -access read-only]]] \
        [::mu3e::cmsis::svd::register STEER_STATUS 0x28 \
            -description {Snapshot status from the data-clock steering queue. This read may wait while the control clock requests the data-clock snapshot.} \
            -access read-only \
            -fields [list \
                [::mu3e::cmsis::svd::field steer_queue_count 0 6 \
                    -description {Current queued engine-steering decisions.} \
                    -access read-only] \
                [::mu3e::cmsis::svd::field reserved 6 10 \
                    -description {Reserved, read as zero.} \
                    -access read-only] \
                [::mu3e::cmsis::svd::field steer_overflow_count_low 16 16 \
                    -description {Low 16 bits of the saturating steering-queue overflow counter.} \
                    -access read-only]]] \
        [::mu3e::cmsis::svd::register LANE_SELECT 0x40 \
            -description {Selected lane for the counter snapshot window. Writes above the last active lane clamp to the last active lane.} \
            -access read-write \
            -resetValue 0x00000000 \
            -fields [list \
                [::mu3e::cmsis::svd::field lane 0 6 \
                    -description {Zero-based lane index for counter snapshot reads.} \
                    -access read-write] \
                [::mu3e::cmsis::svd::field reserved 6 26 \
                    -description {Reserved, read as zero.} \
                    -access read-only]]]]

    foreach {name description} [list \
        CODE_VIOLATIONS {Illegal or unexpected 8b/10b symbol events observed on the selected lane.} \
        DISP_VIOLATIONS {Disparity violation events observed on the selected lane.} \
        COMMA_LOSSES {Selected-lane comma/sync-pattern loss events.} \
        BITSLIP_EVENTS {Selected-lane bitslip control events.} \
        DPA_UNLOCKS {Selected-lane DPA unlock events.} \
        REALIGNS {Selected-lane realignment events.} \
        SCORE_CHANGES {Selected-lane engine-score change events.} \
        ENGINE_STEER {Selected-lane engine steering decisions.} \
        SOFT_RESETS {Selected-lane soft-reset completions.} \
        UPTIME {Selected-lane uptime counter in data-clock cycles.}] {
        set idx [llength $registers]
        set counter_index [expr {$idx - 12}]
        set offset [format "0x%02X" [expr {0x44 + ($counter_index * 4)}]]
        lappend registers [::mu3e::cmsis::svd::register $name $offset \
            -description "$description The lane is selected by LANE_SELECT and the value is returned through the RTL snapshot path." \
            -access read-only \
            -resetValue 0x00000000 \
            -fields [::mu3e::cmsis::spec::value_field value \
                {Selected-lane saturating counter value.} read-only]]
    }

    return $registers
}

proc ::mu3e::cmsis::spec::build_device {args} {
    set spec [dict create \
        n_lane 9 \
        n_engine 1 \
        routing_topology 1 \
        score_window_w 10 \
        score_accept 8 \
        score_reject 2 \
        avmm_addr_w 10 \
        sync_pattern 0x0FA \
        version 26.2.1.0506]
    foreach {key value} $args {
        dict set spec $key $value
    }

    set n_lane [::mu3e::cmsis::spec::clamp [dict get $spec n_lane] 1 32]
    set n_engine_bound [::mu3e::cmsis::spec::clamp [dict get $spec n_engine] 1 32]
    if {$n_engine_bound > $n_lane} {
        set n_engine $n_lane
    } else {
        set n_engine $n_engine_bound
    }
    set score_window_w [::mu3e::cmsis::spec::clamp [dict get $spec score_window_w] 6 16]
    dict set spec n_lane $n_lane
    dict set spec n_engine $n_engine
    dict set spec score_window_w $score_window_w

    set address_block_size [format "0x%X" [expr {(1 << [dict get $spec avmm_addr_w]) * 4}]]
    set description [format \
        {CMSIS-SVD description of the current SystemVerilog mu3e_lvds_controller CSR window for N_LANE=%d, N_ENGINE=%d, ROUTING_TOPOLOGY=%d, and AVMM_ADDR_W=%d. This map matches mu3e_lvds_controller.sv version 26.2.1: UID/META at words 0/1, capability at word 2, global control words at 3..10, lane selector at word 16, and the selected-lane counter snapshot window at words 17..26. BaseAddress is 0 because this file describes the relative IP CSR aperture; system integration supplies the live SC-hub or JTAG base address.} \
        $n_lane $n_engine [dict get $spec routing_topology] [dict get $spec avmm_addr_w]]

    return [::mu3e::cmsis::svd::device MU3E_LVDS_RX_CONTROLLER_PRO \
        -version [dict get $spec version] \
        -description $description \
        -peripherals [list \
            [::mu3e::cmsis::svd::peripheral LVDS_RX_CONTROLLER_PRO_CSR 0x0 \
                -description {Relative CSR aperture for the current SystemVerilog LVDS receive controller.} \
                -groupName MU3E_LVDS_CONTROLLER \
                -addressBlockSize $address_block_size \
                -registers [::mu3e::cmsis::spec::build_registers $spec]]]]
}

proc ::mu3e::cmsis::spec::parse_cli_args {argv} {
    set options [dict create \
        n_lane 9 \
        n_engine 1 \
        routing_topology 1 \
        score_window_w 10 \
        score_accept 8 \
        score_reject 2 \
        avmm_addr_w 10 \
        sync_pattern 0x0FA \
        out_path ""]
    set positional {}

    for {set idx 0} {$idx < [llength $argv]} {incr idx} {
        set arg [lindex $argv $idx]
        switch -- $arg {
            -n_lane - --n_lane - -n-lane - --n-lane {
                incr idx
                dict set options n_lane [lindex $argv $idx]
            }
            -n_engine - --n_engine - -n-engine - --n-engine {
                incr idx
                dict set options n_engine [lindex $argv $idx]
            }
            -routing_topology - --routing_topology - -routing-topology - --routing-topology {
                incr idx
                dict set options routing_topology [lindex $argv $idx]
            }
            -score_window_w - --score_window_w - -score-window-w - --score-window-w {
                incr idx
                dict set options score_window_w [lindex $argv $idx]
            }
            -score_accept - --score_accept - -score-accept - --score-accept {
                incr idx
                dict set options score_accept [lindex $argv $idx]
            }
            -score_reject - --score_reject - -score-reject - --score-reject {
                incr idx
                dict set options score_reject [lindex $argv $idx]
            }
            -avmm_addr_w - --avmm_addr_w - -avmm-addr-w - --avmm-addr-w {
                incr idx
                dict set options avmm_addr_w [lindex $argv $idx]
            }
            -sync_pattern - --sync_pattern - -sync-pattern - --sync-pattern {
                incr idx
                dict set options sync_pattern [lindex $argv $idx]
            }
            -o - -output - --output {
                incr idx
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
            n_lane [dict get $options n_lane] \
            n_engine [dict get $options n_engine] \
            routing_topology [dict get $options routing_topology] \
            score_window_w [dict get $options score_window_w] \
            score_accept [dict get $options score_accept] \
            score_reject [dict get $options score_reject] \
            avmm_addr_w [dict get $options avmm_addr_w] \
            sync_pattern [dict get $options sync_pattern]] \
        $out_path
}
