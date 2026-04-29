// SPDX-License-Identifier: CERN-OHL-S-2.0
// Smoke testbench for the Quartus-generated standalone simulation netlist.

module lvds_controller_syn_gls_smoke_tb;
    timeunit 1ps;
    timeprecision 1ps;

    logic        control_clk;
    logic        control_reset;
    logic        data_clk;
    logic        data_reset;
    logic        stim_seed;
    logic [31:0] csr_readdata_tap;
    logic [31:0] decoded_valid_tap;
    logic [31:0] control_tap;
    logic [31:0] checksum_tap;

    lvds_controller_syn_top dut (
        .control_clk       (control_clk),
        .control_reset     (control_reset),
        .data_clk          (data_clk),
        .data_reset        (data_reset),
        .stim_seed         (stim_seed),
        .csr_readdata_tap  (csr_readdata_tap),
        .decoded_valid_tap (decoded_valid_tap),
        .control_tap       (control_tap),
        .checksum_tap      (checksum_tap)
    );

    initial begin
        control_clk = 1'b0;
        forever #2909 control_clk = ~control_clk;
    end

    initial begin
        data_clk = 1'b0;
        forever #3636 data_clk = ~data_clk;
    end

    initial begin
        control_reset = 1'b1;
        data_reset    = 1'b1;
        stim_seed     = 1'b0;

        repeat (8) @(posedge control_clk);
        control_reset = 1'b0;
        repeat (8) @(posedge data_clk);
        data_reset = 1'b0;

        repeat (256) begin
            @(posedge data_clk);
            stim_seed = ~stim_seed;
        end

        if ($isunknown({csr_readdata_tap, decoded_valid_tap[11:0]})) begin
            $error("netlist smoke CSR or active-lane valid outputs contain X/Z");
        end
        $display("netlist smoke taps csr=%08h valid=%08h control=%08h checksum=%08h",
                 csr_readdata_tap,
                 decoded_valid_tap,
                 control_tap,
                 checksum_tap);
        $finish;
    end
endmodule
