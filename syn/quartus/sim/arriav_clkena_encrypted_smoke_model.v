// SPDX-License-Identifier: CERN-OHL-S-2.0
// Minimal smoke-only model for the Arria V encrypted clock-enable helper.

`timescale 1 ps/1 ps

module arriav_clkena_encrypted (
    inclk,
    ena,
    enaout,
    outclk
);
    parameter clock_type             = "auto";
    parameter ena_register_mode      = "always enabled";
    parameter lpm_type               = "arriav_clkena";
    parameter ena_register_power_up  = "high";
    parameter disable_mode           = "low";
    parameter test_syn               = "high";

    input  inclk;
    input  ena;
    output enaout;
    output outclk;

    assign enaout = ena;
    assign outclk = ((ena === 1'b0) && (disable_mode == "low")) ? 1'b0 : inclk;
endmodule
