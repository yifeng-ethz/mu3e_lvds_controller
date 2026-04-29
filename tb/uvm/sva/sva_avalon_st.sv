// SPDX-License-Identifier: CERN-OHL-S-2.0
// Version : 26.0.0
// Date    : 20260429
// Change  : Initial Avalon-ST protocol assertion for LVDS decoded lanes.

module sva_avalon_st #(
    parameter int DATA_W    = 9,
    parameter int ERROR_W   = 3,
    parameter int CHANNEL_W = 6
) (
    input logic                 clk,
    input logic                 reset,
    input logic                 valid,
    input logic                 ready,
    input logic [DATA_W-1:0]    data,
    input logic [ERROR_W-1:0]   error,
    input logic [CHANNEL_W-1:0] channel
);
    property p_avst_payload_stable;
        @(posedge clk) disable iff (reset)
            (valid && !ready) |=> $stable(data) && $stable(error) && $stable(channel) && valid;
    endproperty

    a_avst_payload_stable: assert property (p_avst_payload_stable);
    c_avst_backpressure:   cover property (@(posedge clk) disable iff (reset) valid && !ready);
endmodule
