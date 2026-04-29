// SPDX-License-Identifier: CERN-OHL-S-2.0
// Version : 26.0.1
// Date    : 20260429
// Change  : Add legacy per-lane decoded interfaces for system integration.

module mu3e_lvds_controller_phy_adapter #(
    parameter int          N_LANE              = 12,
    parameter int          DECODED_CHANNEL_WIDTH = 4,
    parameter int          N_ENGINE            = 1,
    parameter int          ROUTING_TOPOLOGY    = 1,
    parameter int          SCORE_WINDOW_W      = 10,
    parameter int          SCORE_ACCEPT        = 8,
    parameter int          SCORE_REJECT        = 2,
    parameter int          STEER_QUEUE_DEPTH   = 4,
    parameter int          AVMM_ADDR_W         = 10,
    parameter int          INSTANCE_ID         = 0,
    parameter logic [31:0] IP_UID              = 32'h4C564453,
    parameter int          VERSION_MAJOR       = 26,
    parameter int          VERSION_MINOR       = 0,
    parameter int          VERSION_PATCH       = 0,
    parameter int          BUILD               = 12'h429,
    parameter logic [31:0] VERSION_DATE        = 32'h20260429,
    parameter logic [31:0] VERSION_GIT         = 32'h00000000,
    parameter logic [9:0]  SYNC_PATTERN        = 10'b0011111010,
    parameter int          DEBUG_LEVEL         = 0
) (
    input  logic                         csi_control_clk,
    input  logic                         rsi_control_reset,
    input  logic                         csi_data_clk,
    input  logic                         rsi_data_reset,

    input  logic [N_LANE * 10 - 1:0]     coe_parallel_data,
    output logic                         coe_ctrl_pllrst,
    input  logic                         coe_ctrl_plllock,
    output logic [N_LANE - 1:0]          coe_ctrl_dparst,
    output logic [N_LANE - 1:0]          coe_ctrl_lockrst,
    output logic [N_LANE - 1:0]          coe_ctrl_dpahold,
    input  logic [N_LANE - 1:0]          coe_ctrl_dpalock,
    output logic [N_LANE - 1:0]          coe_ctrl_fiforst,
    output logic [N_LANE - 1:0]          coe_ctrl_bitslip,
    input  logic [N_LANE - 1:0]          coe_ctrl_rollover,
    input  logic [N_LANE - 1:0]          coe_redriver_losn,

    input  logic                         avs_csr_read,
    input  logic                         avs_csr_write,
    input  logic [AVMM_ADDR_W - 1:0]     avs_csr_address,
    input  logic [31:0]                  avs_csr_writedata,
    output logic [31:0]                  avs_csr_readdata,
    output logic                         avs_csr_waitrequest,

    output logic [8:0]                   aso_decoded0_data,
    output logic [DECODED_CHANNEL_WIDTH - 1:0] aso_decoded0_channel,
    output logic [2:0]                   aso_decoded0_error,
    output logic [8:0]                   aso_decoded1_data,
    output logic [DECODED_CHANNEL_WIDTH - 1:0] aso_decoded1_channel,
    output logic [2:0]                   aso_decoded1_error,
    output logic [8:0]                   aso_decoded2_data,
    output logic [DECODED_CHANNEL_WIDTH - 1:0] aso_decoded2_channel,
    output logic [2:0]                   aso_decoded2_error,
    output logic [8:0]                   aso_decoded3_data,
    output logic [DECODED_CHANNEL_WIDTH - 1:0] aso_decoded3_channel,
    output logic [2:0]                   aso_decoded3_error,
    output logic [8:0]                   aso_decoded4_data,
    output logic [DECODED_CHANNEL_WIDTH - 1:0] aso_decoded4_channel,
    output logic [2:0]                   aso_decoded4_error,
    output logic [8:0]                   aso_decoded5_data,
    output logic [DECODED_CHANNEL_WIDTH - 1:0] aso_decoded5_channel,
    output logic [2:0]                   aso_decoded5_error,
    output logic [8:0]                   aso_decoded6_data,
    output logic [DECODED_CHANNEL_WIDTH - 1:0] aso_decoded6_channel,
    output logic [2:0]                   aso_decoded6_error,
    output logic [8:0]                   aso_decoded7_data,
    output logic [DECODED_CHANNEL_WIDTH - 1:0] aso_decoded7_channel,
    output logic [2:0]                   aso_decoded7_error,
    output logic [8:0]                   aso_decoded8_data,
    output logic [DECODED_CHANNEL_WIDTH - 1:0] aso_decoded8_channel,
    output logic [2:0]                   aso_decoded8_error,
    output logic [8:0]                   aso_decoded9_data,
    output logic [DECODED_CHANNEL_WIDTH - 1:0] aso_decoded9_channel,
    output logic [2:0]                   aso_decoded9_error,
    output logic [8:0]                   aso_decoded10_data,
    output logic [DECODED_CHANNEL_WIDTH - 1:0] aso_decoded10_channel,
    output logic [2:0]                   aso_decoded10_error,
    output logic [8:0]                   aso_decoded11_data,
    output logic [DECODED_CHANNEL_WIDTH - 1:0] aso_decoded11_channel,
    output logic [2:0]                   aso_decoded11_error,
    output logic [8:0]                   aso_decoded12_data,
    output logic [DECODED_CHANNEL_WIDTH - 1:0] aso_decoded12_channel,
    output logic [2:0]                   aso_decoded12_error,
    output logic [8:0]                   aso_decoded13_data,
    output logic [DECODED_CHANNEL_WIDTH - 1:0] aso_decoded13_channel,
    output logic [2:0]                   aso_decoded13_error,
    output logic [8:0]                   aso_decoded14_data,
    output logic [DECODED_CHANNEL_WIDTH - 1:0] aso_decoded14_channel,
    output logic [2:0]                   aso_decoded14_error,
    output logic [8:0]                   aso_decoded15_data,
    output logic [DECODED_CHANNEL_WIDTH - 1:0] aso_decoded15_channel,
    output logic [2:0]                   aso_decoded15_error,
    output logic [8:0]                   aso_decoded16_data,
    output logic [DECODED_CHANNEL_WIDTH - 1:0] aso_decoded16_channel,
    output logic [2:0]                   aso_decoded16_error,
    output logic [8:0]                   aso_decoded17_data,
    output logic [DECODED_CHANNEL_WIDTH - 1:0] aso_decoded17_channel,
    output logic [2:0]                   aso_decoded17_error,
    output logic [8:0]                   aso_decoded18_data,
    output logic [DECODED_CHANNEL_WIDTH - 1:0] aso_decoded18_channel,
    output logic [2:0]                   aso_decoded18_error,
    output logic [8:0]                   aso_decoded19_data,
    output logic [DECODED_CHANNEL_WIDTH - 1:0] aso_decoded19_channel,
    output logic [2:0]                   aso_decoded19_error,
    output logic [8:0]                   aso_decoded20_data,
    output logic [DECODED_CHANNEL_WIDTH - 1:0] aso_decoded20_channel,
    output logic [2:0]                   aso_decoded20_error,
    output logic [8:0]                   aso_decoded21_data,
    output logic [DECODED_CHANNEL_WIDTH - 1:0] aso_decoded21_channel,
    output logic [2:0]                   aso_decoded21_error,
    output logic [8:0]                   aso_decoded22_data,
    output logic [DECODED_CHANNEL_WIDTH - 1:0] aso_decoded22_channel,
    output logic [2:0]                   aso_decoded22_error,
    output logic [8:0]                   aso_decoded23_data,
    output logic [DECODED_CHANNEL_WIDTH - 1:0] aso_decoded23_channel,
    output logic [2:0]                   aso_decoded23_error
);
    timeunit 1ns;
    timeprecision 1ps;

    localparam int MAX_LANE_CONST = 32;

    logic [MAX_LANE_CONST * 10 - 1:0] core_parallel_data;
    logic [MAX_LANE_CONST - 1:0]      core_ctrl_dparst;
    logic [MAX_LANE_CONST - 1:0]      core_ctrl_lockrst;
    logic [MAX_LANE_CONST - 1:0]      core_ctrl_dpahold;
    logic [MAX_LANE_CONST - 1:0]      core_ctrl_dpalock;
    logic [MAX_LANE_CONST - 1:0]      core_ctrl_fiforst;
    logic [MAX_LANE_CONST - 1:0]      core_ctrl_bitslip;
    logic [MAX_LANE_CONST - 1:0]      core_ctrl_rollover;
    logic [MAX_LANE_CONST - 1:0]      core_redriver_losn;
    logic [9:0]                       core_csr_address;
    logic [31:0]                      core_decoded_valid;
    logic [31:0][8:0]                 core_decoded_data;
    logic [31:0][2:0]                 core_decoded_error;
    logic [31:0][5:0]                 core_decoded_channel;

    always_comb begin
        core_parallel_data = '0;
        core_ctrl_dpalock  = '0;
        core_ctrl_rollover = '0;
        core_redriver_losn = '1;

        for (int lane = 0; lane < N_LANE; lane++) begin
            core_parallel_data[lane * 10 +: 10] = coe_parallel_data[lane * 10 +: 10];
            core_ctrl_dpalock[lane]             = coe_ctrl_dpalock[lane];
            core_ctrl_rollover[lane]            = coe_ctrl_rollover[lane];
            core_redriver_losn[lane]            = coe_redriver_losn[lane];
        end

        core_csr_address = '0;
        core_csr_address[AVMM_ADDR_W - 1:0] = avs_csr_address;
    end

    assign coe_ctrl_dparst  = core_ctrl_dparst[N_LANE - 1:0];
    assign coe_ctrl_lockrst = core_ctrl_lockrst[N_LANE - 1:0];
    assign coe_ctrl_dpahold = core_ctrl_dpahold[N_LANE - 1:0];
    assign coe_ctrl_fiforst = core_ctrl_fiforst[N_LANE - 1:0];
    assign coe_ctrl_bitslip = core_ctrl_bitslip[N_LANE - 1:0];

    assign aso_decoded0_data      = core_decoded_data[0];
    assign aso_decoded0_channel   = core_decoded_channel[0][DECODED_CHANNEL_WIDTH - 1:0];
    assign aso_decoded0_error     = core_decoded_error[0];
    assign aso_decoded1_data      = core_decoded_data[1];
    assign aso_decoded1_channel   = core_decoded_channel[1][DECODED_CHANNEL_WIDTH - 1:0];
    assign aso_decoded1_error     = core_decoded_error[1];
    assign aso_decoded2_data      = core_decoded_data[2];
    assign aso_decoded2_channel   = core_decoded_channel[2][DECODED_CHANNEL_WIDTH - 1:0];
    assign aso_decoded2_error     = core_decoded_error[2];
    assign aso_decoded3_data      = core_decoded_data[3];
    assign aso_decoded3_channel   = core_decoded_channel[3][DECODED_CHANNEL_WIDTH - 1:0];
    assign aso_decoded3_error     = core_decoded_error[3];
    assign aso_decoded4_data      = core_decoded_data[4];
    assign aso_decoded4_channel   = core_decoded_channel[4][DECODED_CHANNEL_WIDTH - 1:0];
    assign aso_decoded4_error     = core_decoded_error[4];
    assign aso_decoded5_data      = core_decoded_data[5];
    assign aso_decoded5_channel   = core_decoded_channel[5][DECODED_CHANNEL_WIDTH - 1:0];
    assign aso_decoded5_error     = core_decoded_error[5];
    assign aso_decoded6_data      = core_decoded_data[6];
    assign aso_decoded6_channel   = core_decoded_channel[6][DECODED_CHANNEL_WIDTH - 1:0];
    assign aso_decoded6_error     = core_decoded_error[6];
    assign aso_decoded7_data      = core_decoded_data[7];
    assign aso_decoded7_channel   = core_decoded_channel[7][DECODED_CHANNEL_WIDTH - 1:0];
    assign aso_decoded7_error     = core_decoded_error[7];
    assign aso_decoded8_data      = core_decoded_data[8];
    assign aso_decoded8_channel   = core_decoded_channel[8][DECODED_CHANNEL_WIDTH - 1:0];
    assign aso_decoded8_error     = core_decoded_error[8];
    assign aso_decoded9_data      = core_decoded_data[9];
    assign aso_decoded9_channel   = core_decoded_channel[9][DECODED_CHANNEL_WIDTH - 1:0];
    assign aso_decoded9_error     = core_decoded_error[9];
    assign aso_decoded10_data     = core_decoded_data[10];
    assign aso_decoded10_channel  = core_decoded_channel[10][DECODED_CHANNEL_WIDTH - 1:0];
    assign aso_decoded10_error    = core_decoded_error[10];
    assign aso_decoded11_data     = core_decoded_data[11];
    assign aso_decoded11_channel  = core_decoded_channel[11][DECODED_CHANNEL_WIDTH - 1:0];
    assign aso_decoded11_error    = core_decoded_error[11];
    assign aso_decoded12_data     = core_decoded_data[12];
    assign aso_decoded12_channel  = core_decoded_channel[12][DECODED_CHANNEL_WIDTH - 1:0];
    assign aso_decoded12_error    = core_decoded_error[12];
    assign aso_decoded13_data     = core_decoded_data[13];
    assign aso_decoded13_channel  = core_decoded_channel[13][DECODED_CHANNEL_WIDTH - 1:0];
    assign aso_decoded13_error    = core_decoded_error[13];
    assign aso_decoded14_data     = core_decoded_data[14];
    assign aso_decoded14_channel  = core_decoded_channel[14][DECODED_CHANNEL_WIDTH - 1:0];
    assign aso_decoded14_error    = core_decoded_error[14];
    assign aso_decoded15_data     = core_decoded_data[15];
    assign aso_decoded15_channel  = core_decoded_channel[15][DECODED_CHANNEL_WIDTH - 1:0];
    assign aso_decoded15_error    = core_decoded_error[15];
    assign aso_decoded16_data     = core_decoded_data[16];
    assign aso_decoded16_channel  = core_decoded_channel[16][DECODED_CHANNEL_WIDTH - 1:0];
    assign aso_decoded16_error    = core_decoded_error[16];
    assign aso_decoded17_data     = core_decoded_data[17];
    assign aso_decoded17_channel  = core_decoded_channel[17][DECODED_CHANNEL_WIDTH - 1:0];
    assign aso_decoded17_error    = core_decoded_error[17];
    assign aso_decoded18_data     = core_decoded_data[18];
    assign aso_decoded18_channel  = core_decoded_channel[18][DECODED_CHANNEL_WIDTH - 1:0];
    assign aso_decoded18_error    = core_decoded_error[18];
    assign aso_decoded19_data     = core_decoded_data[19];
    assign aso_decoded19_channel  = core_decoded_channel[19][DECODED_CHANNEL_WIDTH - 1:0];
    assign aso_decoded19_error    = core_decoded_error[19];
    assign aso_decoded20_data     = core_decoded_data[20];
    assign aso_decoded20_channel  = core_decoded_channel[20][DECODED_CHANNEL_WIDTH - 1:0];
    assign aso_decoded20_error    = core_decoded_error[20];
    assign aso_decoded21_data     = core_decoded_data[21];
    assign aso_decoded21_channel  = core_decoded_channel[21][DECODED_CHANNEL_WIDTH - 1:0];
    assign aso_decoded21_error    = core_decoded_error[21];
    assign aso_decoded22_data     = core_decoded_data[22];
    assign aso_decoded22_channel  = core_decoded_channel[22][DECODED_CHANNEL_WIDTH - 1:0];
    assign aso_decoded22_error    = core_decoded_error[22];
    assign aso_decoded23_data     = core_decoded_data[23];
    assign aso_decoded23_channel  = core_decoded_channel[23][DECODED_CHANNEL_WIDTH - 1:0];
    assign aso_decoded23_error    = core_decoded_error[23];

    mu3e_lvds_controller #(
        .N_LANE(N_LANE),
        .N_ENGINE(N_ENGINE),
        .ROUTING_TOPOLOGY(ROUTING_TOPOLOGY),
        .SCORE_WINDOW_W(SCORE_WINDOW_W),
        .SCORE_ACCEPT(SCORE_ACCEPT),
        .SCORE_REJECT(SCORE_REJECT),
        .STEER_QUEUE_DEPTH(STEER_QUEUE_DEPTH),
        .AVMM_ADDR_W(10),
        .INSTANCE_ID(INSTANCE_ID),
        .IP_UID(IP_UID),
        .VERSION_MAJOR(VERSION_MAJOR),
        .VERSION_MINOR(VERSION_MINOR),
        .VERSION_PATCH(VERSION_PATCH),
        .BUILD(BUILD),
        .VERSION_DATE(VERSION_DATE),
        .VERSION_GIT(VERSION_GIT),
        .SYNC_PATTERN(SYNC_PATTERN),
        .DEBUG_LEVEL(DEBUG_LEVEL)
    ) u_core (
        .csi_control_clk(csi_control_clk),
        .rsi_control_reset(rsi_control_reset),
        .csi_data_clk(csi_data_clk),
        .rsi_data_reset(rsi_data_reset),
        .coe_parallel_data(core_parallel_data),
        .coe_ctrl_pllrst(coe_ctrl_pllrst),
        .coe_ctrl_plllock(coe_ctrl_plllock),
        .coe_ctrl_dparst(core_ctrl_dparst),
        .coe_ctrl_lockrst(core_ctrl_lockrst),
        .coe_ctrl_dpahold(core_ctrl_dpahold),
        .coe_ctrl_dpalock(core_ctrl_dpalock),
        .coe_ctrl_fiforst(core_ctrl_fiforst),
        .coe_ctrl_bitslip(core_ctrl_bitslip),
        .coe_ctrl_rollover(core_ctrl_rollover),
        .coe_redriver_losn(core_redriver_losn),
        .avs_csr_read(avs_csr_read),
        .avs_csr_write(avs_csr_write),
        .avs_csr_address(core_csr_address),
        .avs_csr_writedata(avs_csr_writedata),
        .avs_csr_readdata(avs_csr_readdata),
        .avs_csr_waitrequest(avs_csr_waitrequest),
        .aso_decoded_valid(core_decoded_valid),
        .aso_decoded_ready(32'hFFFF_FFFF),
        .aso_decoded_data(core_decoded_data),
        .aso_decoded_error(core_decoded_error),
        .aso_decoded_channel(core_decoded_channel)
    );
endmodule
