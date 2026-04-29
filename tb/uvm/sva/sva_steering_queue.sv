// SPDX-License-Identifier: CERN-OHL-S-2.0
// Version : 26.0.0
// Date    : 20260429
// Change  : Initial steering queue conservation assertion shell.

module sva_steering_queue #(
    parameter int STEER_BOUND = 32
) (
    input logic        clk,
    input logic        reset,
    input logic        steering_event,
    input logic        engine_attach_event,
    input logic [31:0] overflow_count
);
    property p_steering_event_conserved;
        @(posedge clk) disable iff (reset)
            steering_event |-> ##[1:STEER_BOUND] (engine_attach_event || (overflow_count > $past(overflow_count)));
    endproperty

    a_steering_event_conserved: assert property (p_steering_event_conserved);
    c_steering_overflow:        cover property (@(posedge clk) disable iff (reset) steering_event ##[1:STEER_BOUND] (overflow_count > $past(overflow_count)));
endmodule
