// SPDX-License-Identifier: CERN-OHL-S-2.0
// Version : 26.0.0
// Date    : 20260429
// Change  : Initial SVA-cover shell for LVDS cross targets.

module lvds_coverage #(
    parameter int N_LANE   = 12,
    parameter int N_ENGINE = 1
) (
    input logic clk,
    input logic reset,
    input logic [N_ENGINE-1:0] engine_busy,
    input logic [N_LANE-1:0]   lane_error
);
    c_any_engine_busy: cover property (@(posedge clk) disable iff (reset) |engine_busy);
    c_all_engines_busy: cover property (@(posedge clk) disable iff (reset) &engine_busy);
    c_any_lane_error: cover property (@(posedge clk) disable iff (reset) |lane_error);
endmodule
