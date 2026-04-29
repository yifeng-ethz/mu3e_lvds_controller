// SPDX-License-Identifier: CERN-OHL-S-2.0
// Version : 26.0.0
// Date    : 20260429
// Change  : Initial routing exclusivity assertion shell.

module sva_routing_excl #(
    parameter int N_LANE   = 12,
    parameter int N_ENGINE = 1,
    parameter int LANE_W   = 6
) (
    input logic clk,
    input logic reset,
    input logic [N_ENGINE-1:0] engine_attached,
    input wire [N_ENGINE-1:0][LANE_W-1:0] engine_attach_lane
);
    function automatic int lane_use_count(input int lane_idx);
        int count;
        count = 0;
        for (int engine = 0; engine < N_ENGINE; engine++) begin
            if (engine_attached[engine] && (engine_attach_lane[engine] == LANE_W'(lane_idx))) begin
                count++;
            end
        end
        return count;
    endfunction

    generate
        for (genvar lane = 0; lane < N_LANE; lane++) begin: g_lane
            a_one_engine_per_lane: assert property (@(posedge clk) disable iff (reset) lane_use_count(lane) <= 1);
            c_lane_attached:       cover property (@(posedge clk) disable iff (reset) lane_use_count(lane) == 1);
        end
    endgenerate
endmodule
