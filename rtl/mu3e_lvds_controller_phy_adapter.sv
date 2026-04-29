// SPDX-License-Identifier: CERN-OHL-S-2.0
// Version : 26.0.0
// Date    : 20260429
// Change  : Add Platform Designer LVDS PHY width adapter.

module mu3e_lvds_controller_phy_adapter #(
    parameter int          N_LANE              = 12,
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

    output logic [31:0]                  aso_decoded_valid,
    input  logic [31:0]                  aso_decoded_ready,
    output logic [31:0][8:0]             aso_decoded_data,
    output logic [31:0][2:0]             aso_decoded_error,
    output logic [31:0][5:0]             aso_decoded_channel
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
        .aso_decoded_valid(aso_decoded_valid),
        .aso_decoded_ready(aso_decoded_ready),
        .aso_decoded_data(aso_decoded_data),
        .aso_decoded_error(aso_decoded_error),
        .aso_decoded_channel(aso_decoded_channel)
    );
endmodule
