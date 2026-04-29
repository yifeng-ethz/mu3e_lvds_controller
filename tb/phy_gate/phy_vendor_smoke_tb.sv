// SPDX-License-Identifier: CERN-OHL-S-2.0
// Version : 26.0.2
// Date    : 20260429
// Change  : Add Arria V LVDS RX vendor-model bring-up and bitslip smoke test.

module phy_vendor_smoke_tb;
    timeunit 1ns;
    timeprecision 1ps;

    localparam int N_LANE_CONST = 1;

    logic                          pll_areset;
    logic [N_LANE_CONST - 1:0]     rx_channel_data_align;
    logic [N_LANE_CONST - 1:0]     rx_dpa_lock_reset;
    logic [N_LANE_CONST - 1:0]     rx_dpll_hold;
    logic [N_LANE_CONST - 1:0]     rx_fifo_reset;
    logic [N_LANE_CONST - 1:0]     rx_in;
    logic                          rx_inclock;
    logic [N_LANE_CONST - 1:0]     rx_reset;
    wire  [N_LANE_CONST - 1:0]     rx_cda_max;
    wire  [N_LANE_CONST - 1:0]     rx_dpa_locked;
    wire                           rx_locked;
    wire  [N_LANE_CONST * 10 - 1:0] rx_out;
    wire                           rx_outclock;

    altera_lvds_rx_28nm #(
        .N_LANE(N_LANE_CONST)
    ) dut (
        .pll_areset(pll_areset),
        .rx_channel_data_align(rx_channel_data_align),
        .rx_dpa_lock_reset(rx_dpa_lock_reset),
        .rx_dpll_hold(rx_dpll_hold),
        .rx_fifo_reset(rx_fifo_reset),
        .rx_in(rx_in),
        .rx_inclock(rx_inclock),
        .rx_reset(rx_reset),
        .rx_cda_max(rx_cda_max),
        .rx_dpa_locked(rx_dpa_locked),
        .rx_locked(rx_locked),
        .rx_out(rx_out),
        .rx_outclock(rx_outclock)
    );

    always #4ns rx_inclock = ~rx_inclock;

    initial begin: serial_k285_driver
        logic [9:0] symbol;

        symbol = 10'b0011111010;
        rx_in  = '0;
        forever begin
            for (int bit_idx = 0; bit_idx < 10; bit_idx++) begin
                rx_in[0] = symbol[bit_idx];
                #800ps;
            end
        end
    end

    initial begin: stimulus
        pll_areset             = 1'b1;
        rx_channel_data_align  = '0;
        rx_dpa_lock_reset      = '1;
        rx_dpll_hold           = '1;
        rx_fifo_reset          = '1;
        rx_inclock             = 1'b0;
        rx_reset               = '1;

        repeat (16) @(posedge rx_inclock);
        pll_areset        = 1'b0;
        rx_reset          = '0;
        rx_dpa_lock_reset = '0;
        rx_dpll_hold      = '0;
        rx_fifo_reset     = '0;

        repeat (128) @(posedge rx_inclock);
        rx_channel_data_align[0] = 1'b1;
        @(posedge rx_inclock);
        rx_channel_data_align[0] = 1'b0;

        repeat (128) @(posedge rx_inclock);
        if (!rx_locked || !rx_dpa_locked[0] || $isunknown(rx_out)) begin
            $fatal(1, "Arria V LVDS RX vendor smoke did not lock cleanly: rx_locked=%0b rx_dpa_locked=%0b rx_out=%h",
                   rx_locked, rx_dpa_locked[0], rx_out);
        end
        $display("PHY_VENDOR_SMOKE rx_locked=%0b rx_dpa_locked=%0b rx_cda_max=%0b rx_out=%h",
                 rx_locked, rx_dpa_locked[0], rx_cda_max[0], rx_out);
        $finish;
    end
endmodule
