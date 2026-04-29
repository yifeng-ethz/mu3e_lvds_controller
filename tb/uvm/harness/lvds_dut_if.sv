// SPDX-License-Identifier: CERN-OHL-S-2.0
// Version : 26.0.0
// Date    : 20260429
// Change  : Initial UVM harness DUT interface for SV rebuild.

interface lvds_dut_if;
    timeunit 1ns;
    timeprecision 1ps;

    import lvds_tb_const_pkg::*;

    logic csi_control_clk;
    logic rsi_control_reset;
    logic csi_data_clk;
    logic rsi_data_reset;

    logic [LVDS_TB_MAX_LANE_CONST * 10 - 1:0] coe_parallel_data;

    logic                                     coe_ctrl_pllrst;
    logic                                     coe_ctrl_plllock;
    logic [LVDS_TB_MAX_LANE_CONST - 1:0]      coe_ctrl_dparst;
    logic [LVDS_TB_MAX_LANE_CONST - 1:0]      coe_ctrl_lockrst;
    logic [LVDS_TB_MAX_LANE_CONST - 1:0]      coe_ctrl_dpahold;
    logic [LVDS_TB_MAX_LANE_CONST - 1:0]      coe_ctrl_dpalock;
    logic [LVDS_TB_MAX_LANE_CONST - 1:0]      coe_ctrl_fiforst;
    logic [LVDS_TB_MAX_LANE_CONST - 1:0]      coe_ctrl_bitslip;
    logic [LVDS_TB_MAX_LANE_CONST - 1:0]      coe_ctrl_rollover;
    logic [LVDS_TB_MAX_LANE_CONST - 1:0]      coe_redriver_losn;

    logic                                     avs_csr_read;
    logic                                     avs_csr_write;
    logic [LVDS_TB_AVMM_ADDR_W_CONST - 1:0]   avs_csr_address;
    logic [31:0]                              avs_csr_writedata;
    logic [31:0]                              avs_csr_readdata;
    logic                                     avs_csr_waitrequest;

    logic [LVDS_TB_MAX_LANE_CONST - 1:0]      aso_decoded_valid;
    logic [LVDS_TB_MAX_LANE_CONST - 1:0]      aso_decoded_ready;
    logic [LVDS_TB_MAX_LANE_CONST - 1:0][8:0] aso_decoded_data;
    logic [LVDS_TB_MAX_LANE_CONST - 1:0][2:0] aso_decoded_error;
    logic [LVDS_TB_MAX_LANE_CONST - 1:0][LVDS_TB_CHANNEL_W_CONST - 1:0] aso_decoded_channel;

`ifdef LVDS_DV_DEBUG
    logic        dv_debug_counter_we;
    logic [5:0]  dv_debug_counter_lane;
    logic [3:0]  dv_debug_counter_idx;
    logic [31:0] dv_debug_counter_value;
    logic        dv_debug_engine_attach_we;
    logic [5:0]  dv_debug_engine_idx;
    logic [5:0]  dv_debug_engine_lane;
    logic        dv_debug_engine_score_we;
    logic [5:0]  dv_debug_engine_score_idx;
    logic [3:0]  dv_debug_engine_score_phase;
    logic [15:0] dv_debug_engine_score_value;
    logic        dv_debug_engine_age_we;
    logic [5:0]  dv_debug_engine_age_idx;
    logic [15:0] dv_debug_engine_age_value;
`endif

    task automatic drive_symbol(input int lane, input logic [9:0] symbol);
        if (lane >= 0 && lane < LVDS_TB_MAX_LANE_CONST) begin
            coe_parallel_data[lane * 10 +: 10] = symbol;
        end
    endtask

    task automatic drive_all_symbols(input int n_lane, input logic [9:0] symbol);
        for (int lane = 0; lane < LVDS_TB_MAX_LANE_CONST; lane++) begin
            drive_symbol(lane, (lane < n_lane) ? symbol : 10'h000);
        end
    endtask

    task automatic clear_bus_master();
        avs_csr_read      = 1'b0;
        avs_csr_write     = 1'b0;
        avs_csr_address   = '0;
        avs_csr_writedata = '0;
`ifdef LVDS_DV_DEBUG
        dv_debug_counter_we          = 1'b0;
        dv_debug_counter_lane        = '0;
        dv_debug_counter_idx         = '0;
        dv_debug_counter_value       = '0;
        dv_debug_engine_attach_we    = 1'b0;
        dv_debug_engine_idx          = '0;
        dv_debug_engine_lane         = '0;
        dv_debug_engine_score_we     = 1'b0;
        dv_debug_engine_score_idx    = '0;
        dv_debug_engine_score_phase  = '0;
        dv_debug_engine_score_value  = '0;
        dv_debug_engine_age_we       = 1'b0;
        dv_debug_engine_age_idx      = '0;
        dv_debug_engine_age_value    = '0;
`endif
    endtask

endinterface
