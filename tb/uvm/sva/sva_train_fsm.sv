// SPDX-License-Identifier: CERN-OHL-S-2.0
// Version : 26.0.0
// Date    : 20260429
// Change  : Initial training FSM liveness assertion shell.

module sva_train_fsm #(
    parameter int TRAIN_BOUND = 80,
    parameter int STATE_W     = 4,
    parameter logic [STATE_W-1:0] IDLE_STATE   = '0,
    parameter logic [STATE_W-1:0] LOCKED_STATE = 4'd5
) (
    input logic               clk,
    input logic               reset,
    input logic [STATE_W-1:0] train_state
);
    property p_train_eventually_idle_or_locked;
        @(posedge clk) disable iff (reset)
            (train_state != IDLE_STATE && train_state != LOCKED_STATE) |->
                ##[1:TRAIN_BOUND] (train_state == IDLE_STATE || train_state == LOCKED_STATE);
    endproperty

    a_train_eventually_idle_or_locked: assert property (p_train_eventually_idle_or_locked);
    c_train_active:                    cover property (@(posedge clk) disable iff (reset) train_state != IDLE_STATE);
endmodule
