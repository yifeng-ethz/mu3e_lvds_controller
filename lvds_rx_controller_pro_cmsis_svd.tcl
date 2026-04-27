package require Tcl 8.5

set script_dir [file dirname [info script]]
set helper_file [file normalize [file join $script_dir .. toolkit infra cmsis_svd lib mu3e_cmsis_svd.tcl]]
source $helper_file

namespace eval ::mu3e::cmsis::spec {}

proc ::mu3e::cmsis::spec::build_device {} {
    return [::mu3e::cmsis::svd::device MU3E_LVDS_RX_CONTROLLER_PRO \
        -version 26.0.402 \
        -description "CMSIS-SVD description of the lvds_rx_controller_pro CSR window. This conservative first-pass contract exposes the 16-word relative CSR aperture as read-only WORD registers until the IP author refines individual control/status fields." \
        -peripherals [list \
            [::mu3e::cmsis::svd::peripheral LVDS_RX_CONTROLLER_PRO_CSR 0x0 \
                -description "Relative 16-word CSR aperture for the LVDS receive controller." \
                -groupName MU3E_DATA_PATH \
                -addressBlockSize 0x40 \
                -registers [::mu3e::cmsis::svd::word_window_registers 16 \
                    -descriptionPrefix "LVDS RX controller CSR word" \
                    -fieldDescriptionPrefix "Raw LVDS RX controller CSR word" \
                    -access read-only]]]]
}

if {[info exists ::argv0] &&
    [file normalize $::argv0] eq [file normalize [info script]]} {
    set out_path [file join $script_dir lvds_rx_controller_pro.svd]
    if {[llength $::argv] >= 1} {
        set out_path [lindex $::argv 0]
    }
    ::mu3e::cmsis::svd::write_device_file \
        [::mu3e::cmsis::spec::build_device] $out_path
}
