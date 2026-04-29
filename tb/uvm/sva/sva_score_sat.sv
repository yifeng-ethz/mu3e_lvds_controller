// SPDX-License-Identifier: CERN-OHL-S-2.0
// Version : 26.0.0
// Date    : 20260429
// Change  : Initial score saturation assertion shell.

module sva_score_sat #(
    parameter int SCORE_W = 10
) (
    input logic                 clk,
    input logic                 reset,
    input logic [SCORE_W-1:0]   score,
    input logic [SCORE_W-1:0]   score_max
);
    a_score_within_bound: assert property (@(posedge clk) disable iff (reset) score <= score_max);
    c_score_at_max:       cover property (@(posedge clk) disable iff (reset) score == score_max);
endmodule
