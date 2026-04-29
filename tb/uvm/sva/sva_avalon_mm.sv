// SPDX-License-Identifier: CERN-OHL-S-2.0
// Version : 26.0.0
// Date    : 20260429
// Change  : Initial Avalon-MM protocol assertion for LVDS UVM/formal.

module sva_avalon_mm #(
    parameter int ADDR_W = 10
) (
    input logic              clk,
    input logic              reset,
    input logic              read,
    input logic              write,
    input logic              waitrequest,
    input logic [ADDR_W-1:0] address,
    input logic [31:0]       writedata
);
    property p_avmm_request_stable;
        @(posedge clk) disable iff (reset)
            ((read || write) && waitrequest) |=> $stable(address) && $stable(writedata) && $stable(read) && $stable(write);
    endproperty

    a_avmm_request_stable: assert property (p_avmm_request_stable);
    c_avmm_wait_seen:      cover property (@(posedge clk) disable iff (reset) (read || write) && waitrequest);
endmodule
