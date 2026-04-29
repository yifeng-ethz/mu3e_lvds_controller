// SPDX-License-Identifier: CERN-OHL-S-2.0
// Version : 26.0.0
// Date    : 20260429
// Change  : Add standalone Quartus timing signoff harness.

module lvds_controller_syn_top (
    input  logic        control_clk,
    input  logic        control_reset,
    input  logic        data_clk,
    input  logic        data_reset,
    input  logic        stim_seed,
    output logic [31:0] csr_readdata_tap,
    output logic [31:0] decoded_valid_tap,
    output logic [31:0] control_tap,
    output logic [31:0] checksum_tap
);
    timeunit 1ns;
    timeprecision 1ps;

    localparam int N_LANE_CONST         = 12;
    localparam int N_ENGINE_CONST       = 1;
    localparam int MAX_LANE_CONST       = 32;
    localparam logic [9:0] SYMBOL_K285P = 10'b0011111010;
    localparam logic [9:0] SYMBOL_K285N = 10'b1100000101;
    localparam logic [9:0] SYMBOL_K280P = 10'b0011110100;
    localparam logic [9:0] SYMBOL_K237P = 10'b1110101000;

    (* preserve *) logic [31:0] control_lfsr;
    (* preserve *) logic [31:0] data_lfsr;
    (* preserve *) logic [15:0] control_count;
    (* preserve *) logic [15:0] data_count;
    (* preserve *) logic [31:0] checksum;

    logic [MAX_LANE_CONST * 10 - 1:0] coe_parallel_data;
    logic                             coe_ctrl_pllrst;
    logic                             coe_ctrl_plllock;
    logic [31:0]                      coe_ctrl_dparst;
    logic [31:0]                      coe_ctrl_lockrst;
    logic [31:0]                      coe_ctrl_dpahold;
    logic [31:0]                      coe_ctrl_dpalock;
    logic [31:0]                      coe_ctrl_fiforst;
    logic [31:0]                      coe_ctrl_bitslip;
    logic [31:0]                      coe_ctrl_rollover;
    logic [31:0]                      coe_redriver_losn;

    logic                             avs_csr_read;
    logic                             avs_csr_write;
    logic [9:0]                       avs_csr_address;
    logic [31:0]                      avs_csr_writedata;
    logic [31:0]                      avs_csr_readdata;
    logic                             avs_csr_waitrequest;

    logic [31:0]                      aso_decoded_valid;
    logic [31:0]                      aso_decoded_ready;
    logic [31:0][8:0]                 aso_decoded_data;
    logic [31:0][2:0]                 aso_decoded_error;
    logic [31:0][5:0]                 aso_decoded_channel;

    function automatic logic [31:0] next_lfsr(input logic [31:0] value, input logic entropy);
        logic feedback;

        feedback = value[31] ^ value[21] ^ value[1] ^ value[0] ^ entropy;
        return {value[30:0], feedback};
    endfunction

    function automatic logic [9:0] symbol_for_lane(
        input logic [31:0] lfsr_value,
        input logic [15:0] count_value,
        input int          lane
    );
        logic [9:0] random_symbol;

        random_symbol = {
            lfsr_value[(lane + 9) % 32],
            lfsr_value[(lane + 8) % 32],
            lfsr_value[(lane + 7) % 32],
            lfsr_value[(lane + 6) % 32],
            lfsr_value[(lane + 5) % 32],
            lfsr_value[(lane + 4) % 32],
            lfsr_value[(lane + 3) % 32],
            lfsr_value[(lane + 2) % 32],
            lfsr_value[(lane + 1) % 32],
            lfsr_value[lane % 32]
        };

        unique case ({count_value[(lane + 2) % 16], lfsr_value[(lane + 3) % 32]})
            2'b00:   return SYMBOL_K285P;
            2'b01:   return SYMBOL_K285N;
            2'b10:   return SYMBOL_K280P;
            default: return (count_value[5]) ? SYMBOL_K237P : random_symbol;
        endcase
    endfunction

    always_ff @(posedge control_clk) begin: control_stimulus
        if (control_reset) begin
            control_lfsr      <= 32'h1ACE_B00C ^ {31'd0, stim_seed};
            control_count     <= 16'd0;
            avs_csr_read      <= 1'b0;
            avs_csr_write     <= 1'b0;
            avs_csr_address   <= 10'd0;
            avs_csr_writedata <= 32'd0;
            csr_readdata_tap  <= 32'd0;
            control_tap       <= 32'd0;
        end else begin
            control_lfsr  <= next_lfsr(control_lfsr, stim_seed);
            control_count <= control_count + 16'd1;

            avs_csr_read      <= control_count[0];
            avs_csr_write     <= (control_count[3:0] == 4'h3);
            avs_csr_address   <= {4'd0, control_count[9:4]};
            avs_csr_writedata <= control_lfsr ^ {16'd0, control_count};

            unique case (control_count[7:4])
                4'h0: begin
                    avs_csr_address   <= 10'd1;
                    avs_csr_writedata <= {30'd0, control_count[9:8]};
                end
                4'h1: begin
                    avs_csr_address   <= 10'd3;
                    avs_csr_writedata <= {22'd0, SYMBOL_K285P};
                end
                4'h2: begin
                    avs_csr_address   <= 10'd4;
                    avs_csr_writedata <= 32'h0000_0FFF;
                end
                4'h3: begin
                    avs_csr_address   <= 10'd5;
                    avs_csr_writedata <= {20'd0, control_lfsr[11:0]};
                end
                4'h4: begin
                    avs_csr_address   <= 10'd6;
                    avs_csr_writedata <= 32'h0000_0001 << control_count[3:0];
                end
                4'h5: begin
                    avs_csr_address   <= 10'd7;
                    avs_csr_writedata <= {30'd0, control_count[9:8]};
                end
                4'h6: begin
                    avs_csr_address   <= 10'd8;
                    avs_csr_writedata <= 32'd8 + {30'd0, control_count[9:8]};
                end
                4'h7: begin
                    avs_csr_address   <= 10'd9;
                    avs_csr_writedata <= 32'd2 + {30'd0, control_count[9:8]};
                end
                4'h8: begin
                    avs_csr_address   <= 10'd16;
                    avs_csr_writedata <= {28'd0, control_count[11:8]};
                end
                default: begin
                end
            endcase

            csr_readdata_tap <= avs_csr_readdata;
            control_tap      <= control_tap ^ avs_csr_readdata ^
                                {22'd0, avs_csr_address} ^
                                {30'd0, avs_csr_read, avs_csr_write};
        end
    end

    always_ff @(posedge data_clk) begin: data_stimulus
        if (data_reset) begin
            data_lfsr          <= 32'hC001_D00D ^ {30'd0, stim_seed, ~stim_seed};
            data_count         <= 16'd0;
            coe_parallel_data  <= '0;
            coe_ctrl_plllock   <= 1'b0;
            coe_ctrl_dpalock   <= 32'd0;
            coe_ctrl_rollover  <= 32'd0;
            coe_redriver_losn  <= 32'd0;
            aso_decoded_ready  <= 32'hFFFF_FFFF;
            checksum           <= 32'd0;
            decoded_valid_tap  <= 32'd0;
            checksum_tap       <= 32'd0;
        end else begin
            data_lfsr         <= next_lfsr(data_lfsr, stim_seed ^ data_count[0]);
            data_count        <= data_count + 16'd1;
            coe_ctrl_plllock  <= data_count[5];
            coe_ctrl_rollover <= 32'd0;

            for (int lane_idx = 0; lane_idx < MAX_LANE_CONST; lane_idx++) begin
                coe_parallel_data[lane_idx * 10 +: 10] <= symbol_for_lane(data_lfsr, data_count, lane_idx);
                if (lane_idx < N_LANE_CONST) begin
                    coe_ctrl_dpalock[lane_idx]  <= data_count[5] &&
                                                   (data_count[9:4] != lane_idx[5:0]);
                    coe_redriver_losn[lane_idx] <= (data_count[10:5] != lane_idx[5:0]);
                    coe_ctrl_rollover[lane_idx] <= (data_count[4:0] == lane_idx[4:0]);
                    aso_decoded_ready[lane_idx] <= data_lfsr[lane_idx % 32] | data_count[3];
                end else begin
                    coe_ctrl_dpalock[lane_idx]  <= 1'b0;
                    coe_redriver_losn[lane_idx] <= 1'b0;
                    aso_decoded_ready[lane_idx] <= 1'b1;
                end
            end

            checksum <= checksum ^
                        aso_decoded_valid ^
                        coe_ctrl_bitslip ^
                        coe_ctrl_dparst ^
                        coe_ctrl_fiforst ^
                        {23'd0, aso_decoded_data[0]} ^
                        {29'd0, aso_decoded_error[0]} ^
                        {26'd0, aso_decoded_channel[0]} ^
                        {31'd0, coe_ctrl_pllrst};

            decoded_valid_tap <= aso_decoded_valid;
            checksum_tap      <= checksum;
        end
    end

    mu3e_lvds_controller #(
        .N_LANE(N_LANE_CONST),
        .N_ENGINE(N_ENGINE_CONST),
        .ROUTING_TOPOLOGY(1),
        .SCORE_WINDOW_W(10),
        .SCORE_ACCEPT(8),
        .SCORE_REJECT(2),
        .STEER_QUEUE_DEPTH(4),
        .AVMM_ADDR_W(6),
        .INSTANCE_ID(0),
        .DEBUG_LEVEL(0)
    ) u_dut (
        .csi_control_clk(control_clk),
        .rsi_control_reset(control_reset),
        .csi_data_clk(data_clk),
        .rsi_data_reset(data_reset),
        .coe_parallel_data(coe_parallel_data),
        .coe_ctrl_pllrst(coe_ctrl_pllrst),
        .coe_ctrl_plllock(coe_ctrl_plllock),
        .coe_ctrl_dparst(coe_ctrl_dparst),
        .coe_ctrl_lockrst(coe_ctrl_lockrst),
        .coe_ctrl_dpahold(coe_ctrl_dpahold),
        .coe_ctrl_dpalock(coe_ctrl_dpalock),
        .coe_ctrl_fiforst(coe_ctrl_fiforst),
        .coe_ctrl_bitslip(coe_ctrl_bitslip),
        .coe_ctrl_rollover(coe_ctrl_rollover),
        .coe_redriver_losn(coe_redriver_losn),
        .avs_csr_read(avs_csr_read),
        .avs_csr_write(avs_csr_write),
        .avs_csr_address(avs_csr_address),
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
