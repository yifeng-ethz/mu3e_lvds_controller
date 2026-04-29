// SPDX-License-Identifier: CERN-OHL-S-2.0
// Version : 26.0.0
// Date    : 20260429
// Change  : Initial UVM top for LVDS controller SV rebuild.

`ifndef LVDS_N_LANE
`define LVDS_N_LANE 12
`endif

`ifndef LVDS_N_ENGINE
`define LVDS_N_ENGINE 1
`endif

module tb_top;
    timeunit 1ns;
    timeprecision 1ps;

    import uvm_pkg::*;
    import lvds_tb_const_pkg::*;
    import lvds_uvm_pkg::*;

    lvds_dut_if dut_if();

    initial begin: control_clock_gen
        dut_if.csi_control_clk = 1'b0;
        forever #5 dut_if.csi_control_clk = ~dut_if.csi_control_clk;
    end

    initial begin: data_clock_gen
        dut_if.csi_data_clk = 1'b0;
        forever #4 dut_if.csi_data_clk = ~dut_if.csi_data_clk;
    end

    mu3e_lvds_controller #(
        .N_LANE(`LVDS_N_LANE),
        .N_ENGINE(`LVDS_N_ENGINE),
        .AVMM_ADDR_W(6),
        .INSTANCE_ID(0)
    ) dut (
        .csi_control_clk(dut_if.csi_control_clk),
        .rsi_control_reset(dut_if.rsi_control_reset),
        .csi_data_clk(dut_if.csi_data_clk),
        .rsi_data_reset(dut_if.rsi_data_reset),
        .coe_parallel_data(dut_if.coe_parallel_data),
        .coe_ctrl_pllrst(dut_if.coe_ctrl_pllrst),
        .coe_ctrl_plllock(dut_if.coe_ctrl_plllock),
        .coe_ctrl_dparst(dut_if.coe_ctrl_dparst),
        .coe_ctrl_lockrst(dut_if.coe_ctrl_lockrst),
        .coe_ctrl_dpahold(dut_if.coe_ctrl_dpahold),
        .coe_ctrl_dpalock(dut_if.coe_ctrl_dpalock),
        .coe_ctrl_fiforst(dut_if.coe_ctrl_fiforst),
        .coe_ctrl_bitslip(dut_if.coe_ctrl_bitslip),
        .coe_ctrl_rollover(dut_if.coe_ctrl_rollover),
        .coe_redriver_losn(dut_if.coe_redriver_losn),
        .avs_csr_read(dut_if.avs_csr_read),
        .avs_csr_write(dut_if.avs_csr_write),
        .avs_csr_address(dut_if.avs_csr_address),
        .avs_csr_writedata(dut_if.avs_csr_writedata),
        .avs_csr_readdata(dut_if.avs_csr_readdata),
        .avs_csr_waitrequest(dut_if.avs_csr_waitrequest),
        .aso_decoded_valid(dut_if.aso_decoded_valid),
        .aso_decoded_ready(dut_if.aso_decoded_ready),
        .aso_decoded_data(dut_if.aso_decoded_data),
        .aso_decoded_error(dut_if.aso_decoded_error),
        .aso_decoded_channel(dut_if.aso_decoded_channel)
    );

    sva_avalon_mm #(
        .ADDR_W(LVDS_TB_AVMM_ADDR_W_CONST)
    ) u_sva_avalon_mm (
        .clk(dut_if.csi_control_clk),
        .reset(dut_if.rsi_control_reset),
        .read(dut_if.avs_csr_read),
        .write(dut_if.avs_csr_write),
        .waitrequest(dut_if.avs_csr_waitrequest),
        .address(dut_if.avs_csr_address),
        .writedata(dut_if.avs_csr_writedata)
    );

    generate
        for (genvar lane = 0; lane < `LVDS_N_LANE; lane++) begin: g_avst_sva
            sva_avalon_st #(
                .DATA_W(9),
                .ERROR_W(3),
                .CHANNEL_W(LVDS_TB_CHANNEL_W_CONST)
            ) u_sva_avalon_st (
                .clk(dut_if.csi_data_clk),
                .reset(dut_if.rsi_data_reset),
                .valid(dut_if.aso_decoded_valid[lane]),
                .ready(dut_if.aso_decoded_ready[lane]),
                .data(dut_if.aso_decoded_data[lane]),
                .error(dut_if.aso_decoded_error[lane]),
                .channel(dut_if.aso_decoded_channel[lane])
            );
        end
    endgenerate

    initial begin: uvm_start
        uvm_config_db #(virtual lvds_dut_if)::set(null, "*", "vif", dut_if);
        run_test();
    end
endmodule
