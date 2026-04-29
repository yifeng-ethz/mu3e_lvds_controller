// SPDX-License-Identifier: CERN-OHL-S-2.0
// Version : 26.0.0
// Date    : 20260429
// Change  : Initial saturating counter assertion shell.

module sva_counter_sat (
    input logic        clk,
    input logic        reset,
    input logic [31:0] counter_value
);
    a_counter_no_wrap: assert property (@(posedge clk) disable iff (reset)
        ($past(counter_value) == 32'hFFFFFFFF) |-> counter_value == 32'hFFFFFFFF);
    c_counter_saturated: cover property (@(posedge clk) disable iff (reset) counter_value == 32'hFFFFFFFF);
endmodule
