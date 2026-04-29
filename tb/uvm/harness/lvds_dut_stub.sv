// SPDX-License-Identifier: CERN-OHL-S-2.0
// Version : 26.0.0
// Date    : 20260429
// Change  : Optional smoke-only DUT stub for UVM harness bring-up.

`ifndef LVDS_USE_STUB_DUT
`define LVDS_DUT_STUB_NOT_COMPILED
`else

module mu3e_lvds_controller #(
    parameter int          N_LANE          = 12,
    parameter int          N_ENGINE        = 1,
    parameter int          AVMM_ADDR_W     = 6,
    parameter int          INSTANCE_ID     = 0,
    parameter logic [31:0] IP_UID          = 32'h4C564453,
    parameter int          VERSION_MAJOR   = 26,
    parameter int          VERSION_MINOR   = 0,
    parameter int          VERSION_PATCH   = 0,
    parameter int          BUILD           = 12'h429,
    parameter logic [31:0] VERSION_DATE    = 32'h20260429,
    parameter logic [31:0] VERSION_GIT     = 32'h00000000,
    parameter logic [9:0]  SYNC_PATTERN    = 10'b0011111010
) (
    input  logic csi_control_clk,
    input  logic rsi_control_reset,
    input  logic csi_data_clk,
    input  logic rsi_data_reset,
    input  logic [lvds_tb_const_pkg::LVDS_TB_MAX_LANE_CONST * 10 - 1:0] coe_parallel_data,
    output logic                                     coe_ctrl_pllrst,
    input  logic                                     coe_ctrl_plllock,
    output logic [lvds_tb_const_pkg::LVDS_TB_MAX_LANE_CONST - 1:0] coe_ctrl_dparst,
    output logic [lvds_tb_const_pkg::LVDS_TB_MAX_LANE_CONST - 1:0] coe_ctrl_lockrst,
    output logic [lvds_tb_const_pkg::LVDS_TB_MAX_LANE_CONST - 1:0] coe_ctrl_dpahold,
    input  logic [lvds_tb_const_pkg::LVDS_TB_MAX_LANE_CONST - 1:0] coe_ctrl_dpalock,
    output logic [lvds_tb_const_pkg::LVDS_TB_MAX_LANE_CONST - 1:0] coe_ctrl_fiforst,
    output logic [lvds_tb_const_pkg::LVDS_TB_MAX_LANE_CONST - 1:0] coe_ctrl_bitslip,
    input  logic [lvds_tb_const_pkg::LVDS_TB_MAX_LANE_CONST - 1:0] coe_ctrl_rollover,
    input  logic [lvds_tb_const_pkg::LVDS_TB_MAX_LANE_CONST - 1:0] coe_redriver_losn,
    input  logic                                     avs_csr_read,
    input  logic                                     avs_csr_write,
    input  logic [lvds_tb_const_pkg::LVDS_TB_AVMM_ADDR_W_CONST - 1:0] avs_csr_address,
    input  logic [31:0]                              avs_csr_writedata,
    output logic [31:0]                              avs_csr_readdata,
    output logic                                     avs_csr_waitrequest,
    output logic [lvds_tb_const_pkg::LVDS_TB_MAX_LANE_CONST - 1:0] aso_decoded_valid,
    input  logic [lvds_tb_const_pkg::LVDS_TB_MAX_LANE_CONST - 1:0] aso_decoded_ready,
    output logic [lvds_tb_const_pkg::LVDS_TB_MAX_LANE_CONST - 1:0][8:0] aso_decoded_data,
    output logic [lvds_tb_const_pkg::LVDS_TB_MAX_LANE_CONST - 1:0][2:0] aso_decoded_error,
    output logic [lvds_tb_const_pkg::LVDS_TB_MAX_LANE_CONST - 1:0][lvds_tb_const_pkg::LVDS_TB_CHANNEL_W_CONST - 1:0] aso_decoded_channel
);
    import lvds_tb_const_pkg::*;

    localparam logic [31:0] VERSION_WORD_CONST = {8'(VERSION_MAJOR), 8'(VERSION_MINOR), 4'(VERSION_PATCH), 12'(BUILD)};

    logic [1:0] meta_page;
    logic [31:0] sync_pattern_word;

    always_ff @(posedge csi_control_clk) begin: csr_stub
        if (rsi_control_reset) begin
            meta_page         <= 2'd0;
            sync_pattern_word <= {22'd0, SYNC_PATTERN};
            avs_csr_readdata  <= 32'd0;
        end else begin
            if (avs_csr_write && !avs_csr_waitrequest) begin
                unique case (avs_csr_address[5:0])
                    6'd1: meta_page         <= avs_csr_writedata[1:0];
                    6'd3: sync_pattern_word <= {22'd0, avs_csr_writedata[9:0]};
                    default: begin end
                endcase
            end
            if (avs_csr_read && !avs_csr_waitrequest) begin
                unique case (avs_csr_address[5:0])
                    6'd0: avs_csr_readdata <= IP_UID;
                    6'd1: begin
                        unique case (meta_page)
                            2'd0: avs_csr_readdata <= VERSION_WORD_CONST;
                            2'd1: avs_csr_readdata <= VERSION_DATE;
                            2'd2: avs_csr_readdata <= VERSION_GIT;
                            2'd3: avs_csr_readdata <= 32'(INSTANCE_ID);
                        endcase
                    end
                    6'd2: avs_csr_readdata <= {8'(N_ENGINE), 8'(N_LANE), 16'd10};
                    6'd3: avs_csr_readdata <= sync_pattern_word;
                    default: avs_csr_readdata <= 32'd0;
                endcase
            end
        end
    end

    always_comb begin: conduit_stub
        coe_ctrl_pllrst      = rsi_data_reset || !coe_ctrl_plllock;
        coe_ctrl_dparst      = {LVDS_TB_MAX_LANE_CONST{rsi_data_reset || !coe_ctrl_plllock}};
        coe_ctrl_lockrst     = coe_ctrl_dparst;
        coe_ctrl_dpahold     = coe_ctrl_dparst;
        coe_ctrl_fiforst     = '0;
        coe_ctrl_bitslip     = '0;
        avs_csr_waitrequest  = 1'b0;
        aso_decoded_valid    = '0;
        aso_decoded_data     = '{default: 9'h1BC};
        aso_decoded_error    = '{default: 3'b000};
        aso_decoded_channel  = '{default: '0};
        for (int lane = 0; lane < N_LANE; lane++) begin
            aso_decoded_valid[lane]   = !rsi_data_reset && coe_ctrl_plllock && coe_ctrl_dpalock[lane] && aso_decoded_ready[lane];
            aso_decoded_channel[lane] = LVDS_TB_CHANNEL_W_CONST'(lane);
        end
    end

endmodule

`endif
