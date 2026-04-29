// SPDX-License-Identifier: CERN-OHL-S-2.0
// Version : 26.0.0
// Date    : 20260429
// Change  : Initial CSR aperture atomicity assertion shell.

module sva_csr_aperture #(
    parameter int ADDR_W       = 10,
    parameter int LANE_W       = 6,
    parameter int COUNTER_BASE = 17,
    parameter int COUNTER_LAST = 26
) (
    input logic              clk,
    input logic              reset,
    input logic              read,
    input logic              waitrequest,
    input logic [ADDR_W-1:0] address,
    input logic [LANE_W-1:0] lane_select
);
    logic [LANE_W-1:0] lane_select_at_issue;
    logic              aperture_read_accepted;

    assign aperture_read_accepted = read && !waitrequest && (address >= ADDR_W'(COUNTER_BASE)) && (address <= ADDR_W'(COUNTER_LAST));

    always_ff @(posedge clk) begin
        if (reset) begin
            lane_select_at_issue <= '0;
        end else if (aperture_read_accepted) begin
            lane_select_at_issue <= lane_select;
        end
    end

    a_lane_select_stable_after_issue: assert property (@(posedge clk) disable iff (reset)
        aperture_read_accepted |=> lane_select_at_issue == $past(lane_select));
    c_aperture_read: cover property (@(posedge clk) disable iff (reset) aperture_read_accepted);
endmodule
