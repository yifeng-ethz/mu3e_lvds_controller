// SPDX-License-Identifier: CERN-OHL-S-2.0
// Version : 26.0.0
// Date    : 20260429
// Change  : Initial engine attach counter assertion shell.

module sva_engine_attach (
    input logic        clk,
    input logic        reset,
    input logic        attach_event,
    input logic [31:0] engine_steerings
);
    a_attach_counter_matches_event: assert property (@(posedge clk) disable iff (reset)
        (engine_steerings != $past(engine_steerings)) |-> attach_event);
    c_attach_seen: cover property (@(posedge clk) disable iff (reset) attach_event);
endmodule
