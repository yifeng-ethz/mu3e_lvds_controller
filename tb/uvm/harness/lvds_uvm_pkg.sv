// SPDX-License-Identifier: CERN-OHL-S-2.0
// Version : 26.0.0
// Date    : 20260429
// Change  : Add targeted code-coverage closure stimulus.

package lvds_uvm_pkg;
    timeunit 1ns;
    timeprecision 1ps;

    import uvm_pkg::*;
    import lvds_tb_const_pkg::*;
    `include "uvm_macros.svh"

    typedef enum int {
        LVDS_BUCKET_BASIC,
        LVDS_BUCKET_EDGE,
        LVDS_BUCKET_PROF,
        LVDS_BUCKET_ERROR,
        LVDS_BUCKET_UNKNOWN
    } lvds_bucket_e;

    typedef enum int {
        LVDS_METHOD_DIRECTED,
        LVDS_METHOD_RANDOM
    } lvds_method_e;

    typedef enum int {
        LVDS_CASE_IDENTITY,
        LVDS_CASE_CONTROL,
        LVDS_CASE_PHY_POWERUP,
        LVDS_CASE_BITSLIP,
        LVDS_CASE_TRAIN_STEADY,
        LVDS_CASE_COUNTER_APERTURE,
        LVDS_CASE_COUNTER_SET,
        LVDS_CASE_ENGINE_POOL,
        LVDS_CASE_SCORE_EDGE,
        LVDS_CASE_BITSLIP_EDGE,
        LVDS_CASE_CONTENTION,
        LVDS_CASE_ROUTING,
        LVDS_CASE_COUNTER_WINDOW,
        LVDS_CASE_MULTILANE,
        LVDS_CASE_SYNC,
        LVDS_CASE_RANDOM_SOAK,
        LVDS_CASE_THROUGHPUT,
        LVDS_CASE_SATURATION,
        LVDS_CASE_LONG_STABILITY,
        LVDS_CASE_RANDOM_SWEEP,
        LVDS_CASE_SOFT_RESET,
        LVDS_CASE_DEAD_LANE,
        LVDS_CASE_PHY_FAULT,
        LVDS_CASE_ILLEGAL_CSR,
        LVDS_CASE_SVA_PROBE,
        LVDS_CASE_RESET_RACE,
        LVDS_CASE_UNKNOWN
    } lvds_case_group_e;

    typedef struct {
        string            id;
        lvds_bucket_e     bucket;
        lvds_method_e     method;
        lvds_case_group_e group;
        int               case_num;
        int               iterations;
        string            scenario;
        string            stimulus;
        string            pass_criteria;
        bit               expect_sva_failure;
    } lvds_case_desc_t;

    localparam logic [31:0] LVDS_UID_CONST          = 32'h4C564453;
    localparam logic [31:0] LVDS_VERSION_CONST      = {8'd26, 8'd0, 4'd0, 12'h429};
    localparam logic [31:0] LVDS_VERSION_DATE_CONST = 32'h20260429;

    // OPEN: Replace these provisional offsets with the generated register model
    // once script/mu3e_lvds_controller_hw.tcl owns the final CSR map.
    localparam int LVDS_CSR_UID_WORD_CONST          = 0;
    localparam int LVDS_CSR_META_WORD_CONST         = 1;
    localparam int LVDS_CSR_CAPABILITY_WORD_CONST   = 2;
    localparam int LVDS_CSR_SYNC_PATTERN_WORD_CONST = 3;
    localparam int LVDS_CSR_LANE_GO_WORD_CONST      = 4;
    localparam int LVDS_CSR_DPA_HOLD_WORD_CONST     = 5;
    localparam int LVDS_CSR_SOFT_RESET_WORD_CONST   = 6;
    localparam int LVDS_CSR_MODE_MASK_WORD_CONST    = 7;
    localparam int LVDS_CSR_SCORE_ACCEPT_WORD_CONST = 8;
    localparam int LVDS_CSR_SCORE_REJECT_WORD_CONST = 9;
    localparam int LVDS_CSR_LANE_SELECT_WORD_CONST  = 16;
    localparam int LVDS_CSR_COUNTER_BASE_WORD_CONST = 17;

    localparam int LVDS_CNT_CODE_VIOLATIONS_CONST   = 0;
    localparam int LVDS_CNT_DISP_VIOLATIONS_CONST   = 1;
    localparam int LVDS_CNT_COMMA_LOSSES_CONST      = 2;
    localparam int LVDS_CNT_BITSLIP_EVENTS_CONST    = 3;
    localparam int LVDS_CNT_DPA_UNLOCKS_CONST       = 4;
    localparam int LVDS_CNT_REALIGNS_CONST          = 5;
    localparam int LVDS_CNT_SCORE_CHANGES_CONST     = 6;
    localparam int LVDS_CNT_ENGINE_STEER_CONST      = 7;
    localparam int LVDS_CNT_SOFT_RESETS_CONST       = 8;
    localparam int LVDS_CNT_UPTIME_CONST            = 9;

    function automatic string lvds_bucket_name(input lvds_bucket_e bucket);
        unique case (bucket)
            LVDS_BUCKET_BASIC: return "BASIC";
            LVDS_BUCKET_EDGE:  return "EDGE";
            LVDS_BUCKET_PROF:  return "PROF";
            LVDS_BUCKET_ERROR: return "ERROR";
            default:           return "UNKNOWN";
        endcase
    endfunction

    function automatic string lvds_method_name(input lvds_method_e method);
        return (method == LVDS_METHOD_RANDOM) ? "R" : "D";
    endfunction

    function automatic int lvds_case_number(input string case_id);
        int value;
        value = 0;
        if (case_id.len() >= 4) begin
            void'($sscanf(case_id.substr(1, 3), "%d", value));
        end
        return value;
    endfunction

    function automatic lvds_case_group_e lvds_group_from_id(input string case_id);
        int num;
        num = lvds_case_number(case_id);
        if (case_id.len() == 0) begin
            return LVDS_CASE_UNKNOWN;
        end
        unique case (case_id.substr(0, 0))
            "B": begin
                if (num >= 1  && num <= 10) return LVDS_CASE_IDENTITY;
                if (num >= 11 && num <= 20) return LVDS_CASE_CONTROL;
                if (num >= 21 && num <= 28) return LVDS_CASE_PHY_POWERUP;
                if (num >= 29 && num <= 40) return LVDS_CASE_BITSLIP;
                if (num >= 41 && num <= 50) return LVDS_CASE_TRAIN_STEADY;
                if (num >= 51 && num <= 54) return LVDS_CASE_COUNTER_APERTURE;
                if (num >= 55 && num <= 68) return LVDS_CASE_COUNTER_SET;
                if (num >= 71 && num <= 80) return LVDS_CASE_ENGINE_POOL;
            end
            "E": begin
                if (num >= 1  && num <= 10) return LVDS_CASE_SCORE_EDGE;
                if (num >= 11 && num <= 17) return LVDS_CASE_BITSLIP_EDGE;
                if (num >= 18 && num <= 23) return LVDS_CASE_CONTENTION;
                if (num >= 24 && num <= 28) return LVDS_CASE_ROUTING;
                if (num >= 29 && num <= 40) return LVDS_CASE_COUNTER_WINDOW;
                if (num >= 41 && num <= 45) return LVDS_CASE_MULTILANE;
                if (num >= 46 && num <= 50) return LVDS_CASE_SYNC;
            end
            "P": begin
                if (num >= 1  && num <= 10) return LVDS_CASE_RANDOM_SOAK;
                if (num >= 11 && num <= 20) return LVDS_CASE_THROUGHPUT;
                if (num >= 21 && num <= 24) return LVDS_CASE_SATURATION;
                if (num >= 25 && num <= 30) return LVDS_CASE_LONG_STABILITY;
                if (num >= 31 && num <= 40) return LVDS_CASE_RANDOM_SWEEP;
            end
            "X": begin
                if (num >= 1  && num <= 8)  return LVDS_CASE_SOFT_RESET;
                if (num >= 9  && num <= 18) return LVDS_CASE_DEAD_LANE;
                if (num >= 19 && num <= 24) return LVDS_CASE_PHY_FAULT;
                if (num >= 25 && num <= 34) return LVDS_CASE_ILLEGAL_CSR;
                if (num >= 35 && num <= 41) return LVDS_CASE_SVA_PROBE;
                if (num >= 42 && num <= 50) return LVDS_CASE_RESET_RACE;
            end
            default: begin end
        endcase
        return LVDS_CASE_UNKNOWN;
    endfunction

    `include "lvds_case_catalog.svh"

    class lvds_env_config extends uvm_object;
        `uvm_object_utils(lvds_env_config)

        virtual lvds_dut_if vif;
        int                 n_lane;
        int                 n_engine;
        int                 score_window_w;
        int                 steer_queue_depth;
        int                 symbol_cap;
        bit                 reset_between_cases;
        bit                 harness_only;

        function new(string name = "lvds_env_config");
            super.new(name);
            n_lane              = 12;
            n_engine            = 1;
            score_window_w      = 10;
            steer_queue_depth   = 4;
            symbol_cap          = 1024;
            reset_between_cases = 1'b1;
            harness_only        = 1'b0;
        endfunction
    endclass

    class lvds_case_item extends uvm_sequence_item;
        `uvm_object_utils(lvds_case_item)

        lvds_case_desc_t desc;
        bit              continuous_frame;

        function new(string name = "lvds_case_item");
            super.new(name);
        endfunction

        function string convert2string();
            return $sformatf("%s %s %s iter=%0d scenario=%s",
                desc.id,
                lvds_bucket_name(desc.bucket),
                lvds_method_name(desc.method),
                desc.iterations,
                desc.scenario);
        endfunction
    endclass

    class lvds_case_sequencer extends uvm_sequencer #(lvds_case_item);
        `uvm_component_utils(lvds_case_sequencer)

        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction
    endclass

    class lvds_case_driver extends uvm_driver #(lvds_case_item);
        `uvm_component_utils(lvds_case_driver)

        lvds_env_config cfg;
        virtual lvds_dut_if vif;
        uvm_analysis_port #(lvds_case_item) case_ap;
        logic [31:0] void_data;
        bit continuous_frame_started;

        function new(string name, uvm_component parent);
            super.new(name, parent);
            case_ap = new("case_ap", this);
        endfunction

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            if (!uvm_config_db #(lvds_env_config)::get(this, "", "cfg", cfg)) begin
                `uvm_fatal("LVDS/CFG", "lvds_case_driver missing cfg")
            end
            vif = cfg.vif;
        endfunction

        task run_phase(uvm_phase phase);
            lvds_case_item req;
            drive_initial_defaults();
            continuous_frame_started = 1'b0;
            forever begin
                seq_item_port.get_next_item(req);
                `uvm_info("LVDS/CASE", {"running ", req.convert2string()}, UVM_MEDIUM)
                drive_case(req);
                case_ap.write(req);
                seq_item_port.item_done();
            end
        endtask

        task automatic drive_initial_defaults();
            vif.rsi_control_reset   = 1'b1;
            vif.rsi_data_reset      = 1'b1;
            vif.clear_bus_master();
            vif.coe_ctrl_plllock    = 1'b1;
            vif.coe_ctrl_dpalock    = '1;
            vif.coe_ctrl_rollover   = '0;
            vif.coe_redriver_losn   = '1;
            vif.aso_decoded_ready   = '1;
            vif.drive_all_symbols(cfg.n_lane, 10'b0011111010);
        endtask

        task automatic wait_control_cycles(input int cycles);
            repeat (cycles) @(posedge vif.csi_control_clk);
        endtask

        task automatic wait_data_cycles(input int cycles);
            repeat (cycles) @(posedge vif.csi_data_clk);
        endtask

        task automatic drive_reset(input int cycles = 16);
            vif.rsi_control_reset <= 1'b1;
            vif.rsi_data_reset    <= 1'b1;
            wait_control_cycles(cycles);
            wait_data_cycles(cycles);
            vif.clear_bus_master();
            vif.rsi_control_reset <= 1'b0;
            vif.rsi_data_reset    <= 1'b0;
            wait_control_cycles(4);
            wait_data_cycles(4);
        endtask

        task automatic csr_write(input int word_addr, input logic [31:0] data);
            int guard;
            @(posedge vif.csi_control_clk);
            vif.avs_csr_address   <= LVDS_TB_AVMM_ADDR_W_CONST'(word_addr);
            vif.avs_csr_writedata <= data;
            vif.avs_csr_write     <= 1'b1;
            vif.avs_csr_read      <= 1'b0;
            guard = 0;
            while (vif.avs_csr_waitrequest && guard < 256) begin
                guard++;
                @(posedge vif.csi_control_clk);
            end
            @(posedge vif.csi_control_clk);
            vif.avs_csr_write <= 1'b0;
            if (guard >= 256) begin
                `uvm_error("LVDS/CSR", $sformatf("CSR write timeout at word %0d", word_addr))
            end
        endtask

        task automatic csr_read(input int word_addr, output logic [31:0] data);
            int guard;
            @(posedge vif.csi_control_clk);
            vif.avs_csr_address <= LVDS_TB_AVMM_ADDR_W_CONST'(word_addr);
            vif.avs_csr_read    <= 1'b1;
            vif.avs_csr_write   <= 1'b0;
            guard = 0;
            while (vif.avs_csr_waitrequest && guard < 256) begin
                guard++;
                @(posedge vif.csi_control_clk);
            end
            @(posedge vif.csi_control_clk);
            #1ps;
            data = vif.avs_csr_readdata;
            vif.avs_csr_read <= 1'b0;
            if (guard >= 256) begin
                `uvm_error("LVDS/CSR", $sformatf("CSR read timeout at word %0d", word_addr))
            end
        endtask

        task automatic expect_csr(input int word_addr, input logic [31:0] expected, input string label);
            logic [31:0] data;
            csr_read(word_addr, data);
            if (data !== expected) begin
                `uvm_error("LVDS/CSR", $sformatf("%s word %0d expected 0x%08x got 0x%08x",
                    label, word_addr, expected, data))
            end
        endtask

        task automatic expect_lane_valid(input int lane, input bit expected, input string label);
            #1ps;
            if (vif.aso_decoded_valid[lane] !== expected) begin
                `uvm_error("LVDS/AVST", $sformatf("%s lane %0d valid expected %0b got %0b",
                    label, lane, expected, vif.aso_decoded_valid[lane]))
            end
        endtask

        task automatic expect_ctrl_bit(input string signal_name, input bit actual, input bit expected, input string label);
            #1ps;
            if (actual !== expected) begin
                `uvm_error("LVDS/CTRL", $sformatf("%s %s expected %0b got %0b",
                    label, signal_name, expected, actual))
            end
        endtask

        task automatic read_lane_counter(input int lane, input int counter_idx, output logic [31:0] data);
            csr_write(LVDS_CSR_LANE_SELECT_WORD_CONST, 32'(lane));
            csr_read(LVDS_CSR_COUNTER_BASE_WORD_CONST + counter_idx, data);
        endtask

        task automatic dv_debug_set_lane_counter(input int lane, input int counter_idx, input logic [31:0] value);
`ifdef LVDS_DV_DEBUG
            if ((lane >= 0) && (lane < LVDS_TB_MAX_LANE_CONST) &&
                (counter_idx >= 0) && (counter_idx < LVDS_TB_COUNTER_COUNT_CONST)) begin
                vif.dv_debug_counter_lane  <= lane[5:0];
                vif.dv_debug_counter_idx   <= counter_idx[3:0];
                vif.dv_debug_counter_value <= value;
                vif.dv_debug_counter_we    <= 1'b1;
                wait_data_cycles(1);
                vif.dv_debug_counter_we    <= 1'b0;
                wait_data_cycles(1);
            end
`else
            `uvm_warning("LVDS/DVDBG", "LVDS_DV_DEBUG is disabled; counter preload skipped")
`endif
        endtask

        task automatic dv_debug_attach_engine(input int engine, input int lane);
`ifdef LVDS_DV_DEBUG
            if ((engine >= 0) && (engine < cfg.n_engine) &&
                (lane >= 0) && (lane < cfg.n_lane)) begin
                vif.dv_debug_engine_idx       <= engine[5:0];
                vif.dv_debug_engine_lane      <= lane[5:0];
                vif.dv_debug_engine_attach_we <= 1'b1;
                wait_data_cycles(1);
                vif.dv_debug_engine_attach_we <= 1'b0;
                wait_data_cycles(1);
            end
`else
            `uvm_warning("LVDS/DVDBG", "LVDS_DV_DEBUG is disabled; engine attach preload skipped")
`endif
        endtask

        task automatic dv_debug_set_engine_score(input int engine, input int phase, input logic [15:0] value);
`ifdef LVDS_DV_DEBUG
            if ((engine >= 0) && (engine < cfg.n_engine) &&
                (phase >= 0) && (phase < 10)) begin
                vif.dv_debug_engine_score_idx   <= engine[5:0];
                vif.dv_debug_engine_score_phase <= phase[3:0];
                vif.dv_debug_engine_score_value <= value;
                vif.dv_debug_engine_score_we    <= 1'b1;
                wait_data_cycles(1);
                vif.dv_debug_engine_score_we    <= 1'b0;
                wait_data_cycles(1);
            end
`else
            `uvm_warning("LVDS/DVDBG", "LVDS_DV_DEBUG is disabled; engine score preload skipped")
`endif
        endtask

        task automatic dv_debug_set_engine_age(input int engine, input logic [15:0] value);
`ifdef LVDS_DV_DEBUG
            if ((engine >= 0) && (engine < cfg.n_engine)) begin
                vif.dv_debug_engine_age_idx   <= engine[5:0];
                vif.dv_debug_engine_age_value <= value;
                vif.dv_debug_engine_age_we    <= 1'b1;
                wait_data_cycles(1);
                vif.dv_debug_engine_age_we    <= 1'b0;
                wait_data_cycles(1);
            end
`else
            `uvm_warning("LVDS/DVDBG", "LVDS_DV_DEBUG is disabled; engine age preload skipped")
`endif
        endtask

        task automatic dv_debug_pulse_counter_raw(input int lane, input int counter_idx);
`ifdef LVDS_DV_DEBUG
            vif.dv_debug_counter_lane  <= lane[5:0];
            vif.dv_debug_counter_idx   <= counter_idx[3:0];
            vif.dv_debug_counter_value <= 32'hCAFE0000;
            vif.dv_debug_counter_we    <= 1'b1;
            wait_data_cycles(1);
            vif.dv_debug_counter_we    <= 1'b0;
            wait_data_cycles(1);
`endif
        endtask

        task automatic dv_debug_pulse_engine_attach_raw(input int engine, input int lane);
`ifdef LVDS_DV_DEBUG
            vif.dv_debug_engine_idx       <= engine[5:0];
            vif.dv_debug_engine_lane      <= lane[5:0];
            vif.dv_debug_engine_attach_we <= 1'b1;
            wait_data_cycles(1);
            vif.dv_debug_engine_attach_we <= 1'b0;
            wait_data_cycles(1);
`endif
        endtask

        task automatic dv_debug_pulse_engine_score_raw(input int engine, input int phase);
`ifdef LVDS_DV_DEBUG
            vif.dv_debug_engine_score_idx   <= engine[5:0];
            vif.dv_debug_engine_score_phase <= phase[3:0];
            vif.dv_debug_engine_score_value <= 16'hCAFE;
            vif.dv_debug_engine_score_we    <= 1'b1;
            wait_data_cycles(1);
            vif.dv_debug_engine_score_we    <= 1'b0;
            wait_data_cycles(1);
`endif
        endtask

        task automatic dv_debug_pulse_engine_age_raw(input int engine, input logic [15:0] value);
`ifdef LVDS_DV_DEBUG
            vif.dv_debug_engine_age_idx   <= engine[5:0];
            vif.dv_debug_engine_age_value <= value;
            vif.dv_debug_engine_age_we    <= 1'b1;
            wait_data_cycles(1);
            vif.dv_debug_engine_age_we    <= 1'b0;
            wait_data_cycles(1);
`endif
        endtask

        task automatic expect_lane_counter_eq(input int lane, input int counter_idx, input logic [31:0] expected, input string label);
            logic [31:0] data;
            read_lane_counter(lane, counter_idx, data);
            if (data !== expected) begin
                `uvm_error("LVDS/CNT", $sformatf("%s lane %0d counter %0d expected 0x%08x got 0x%08x",
                    label, lane, counter_idx, expected, data))
            end
        endtask

        task automatic expect_lane_counter_min(input int lane, input int counter_idx, input logic [31:0] expected_min, input string label);
            logic [31:0] data;
            read_lane_counter(lane, counter_idx, data);
            if (data < expected_min) begin
                `uvm_error("LVDS/CNT", $sformatf("%s lane %0d counter %0d expected >= 0x%08x got 0x%08x",
                    label, lane, counter_idx, expected_min, data))
            end
        endtask

        task automatic drive_symbols(input logic [9:0] symbol, input int cycles);
            int capped_cycles;
            capped_cycles = (cycles > cfg.symbol_cap) ? cfg.symbol_cap : cycles;
            for (int cycle_idx = 0; cycle_idx < capped_cycles; cycle_idx++) begin
                vif.drive_all_symbols(cfg.n_lane, symbol);
                @(posedge vif.csi_data_clk);
            end
        endtask

        task automatic inject_lane_symbol(input int lane, input logic [9:0] symbol, input int cycles = 1);
            for (int cycle_idx = 0; cycle_idx < cycles; cycle_idx++) begin
                vif.drive_symbol(lane, symbol);
                @(posedge vif.csi_data_clk);
            end
            vif.drive_symbol(lane, 10'b0011111010);
        endtask

        task automatic drive_case(input lvds_case_item item);
            if (item.continuous_frame && !continuous_frame_started) begin
                drive_reset();
                continuous_frame_started = 1'b1;
            end else if (!item.continuous_frame) begin
                drive_reset();
                continuous_frame_started = 1'b0;
            end
            unique case (item.desc.group)
                LVDS_CASE_IDENTITY:          drive_identity_case(item.desc);
                LVDS_CASE_CONTROL:           drive_control_case(item.desc);
                LVDS_CASE_PHY_POWERUP:       drive_phy_powerup_case(item.desc);
                LVDS_CASE_BITSLIP:           drive_bitslip_case(item.desc);
                LVDS_CASE_TRAIN_STEADY:      drive_train_steady_case(item.desc);
                LVDS_CASE_COUNTER_APERTURE:  drive_counter_aperture_case(item.desc);
                LVDS_CASE_COUNTER_SET:       drive_counter_set_case(item.desc);
                LVDS_CASE_ENGINE_POOL:       drive_engine_pool_case(item.desc);
                LVDS_CASE_SCORE_EDGE:        drive_score_edge_case(item.desc);
                LVDS_CASE_BITSLIP_EDGE:      drive_bitslip_edge_case(item.desc);
                LVDS_CASE_CONTENTION:        drive_contention_case(item.desc);
                LVDS_CASE_ROUTING:           drive_routing_case(item.desc);
                LVDS_CASE_COUNTER_WINDOW:    drive_counter_window_case(item.desc);
                LVDS_CASE_MULTILANE:         drive_multilane_case(item.desc);
                LVDS_CASE_SYNC:              drive_sync_case(item.desc);
                LVDS_CASE_RANDOM_SOAK:       drive_random_soak_case(item.desc);
                LVDS_CASE_THROUGHPUT:        drive_throughput_case(item.desc);
                LVDS_CASE_SATURATION:        drive_saturation_case(item.desc);
                LVDS_CASE_LONG_STABILITY:    drive_long_stability_case(item.desc);
                LVDS_CASE_RANDOM_SWEEP:      drive_random_sweep_case(item.desc);
                LVDS_CASE_SOFT_RESET:        drive_soft_reset_case(item.desc);
                LVDS_CASE_DEAD_LANE:         drive_dead_lane_case(item.desc);
                LVDS_CASE_PHY_FAULT:         drive_phy_fault_case(item.desc);
                LVDS_CASE_ILLEGAL_CSR:       drive_illegal_csr_case(item.desc);
                LVDS_CASE_SVA_PROBE:         drive_sva_probe_case(item.desc);
                LVDS_CASE_RESET_RACE:        drive_reset_race_case(item.desc);
                default: begin
                    `uvm_warning("LVDS/CASE", {"No stimulus interpreter for ", item.desc.id})
                end
            endcase
            wait_control_cycles(2);
            wait_data_cycles(2);
            if (!item.continuous_frame && $test$plusargs("LVDS_POST_CASE_RESET")) begin
                drive_reset();
            end
        endtask

        task automatic drive_identity_case(input lvds_case_desc_t desc);
            logic [31:0] data;
            unique case (desc.case_num)
                1: expect_csr(LVDS_CSR_UID_WORD_CONST, LVDS_UID_CONST, desc.id);
                2: begin
                    expect_csr(LVDS_CSR_UID_WORD_CONST, LVDS_UID_CONST, desc.id);
                    csr_write(LVDS_CSR_UID_WORD_CONST, 32'hDEADBEEF);
                    expect_csr(LVDS_CSR_UID_WORD_CONST, LVDS_UID_CONST, desc.id);
                end
                3: begin csr_write(LVDS_CSR_META_WORD_CONST, 32'd0); expect_csr(LVDS_CSR_META_WORD_CONST, LVDS_VERSION_CONST, desc.id); end
                4: begin csr_write(LVDS_CSR_META_WORD_CONST, 32'd1); expect_csr(LVDS_CSR_META_WORD_CONST, LVDS_VERSION_DATE_CONST, desc.id); end
                5: begin csr_write(LVDS_CSR_META_WORD_CONST, 32'd2); csr_read(LVDS_CSR_META_WORD_CONST, data); end
                6: begin csr_write(LVDS_CSR_META_WORD_CONST, 32'd3); csr_read(LVDS_CSR_META_WORD_CONST, data); end
                7: begin
                    csr_write(LVDS_CSR_META_WORD_CONST, 32'd0);
                    csr_write(LVDS_CSR_META_WORD_CONST, 32'd4);
                    csr_read(LVDS_CSR_META_WORD_CONST, data);
                end
                8: csr_read(LVDS_CSR_CAPABILITY_WORD_CONST, data);
                9: expect_csr(LVDS_CSR_SYNC_PATTERN_WORD_CONST, 32'h000000FA, desc.id);
                10: begin
                    csr_write(LVDS_CSR_SYNC_PATTERN_WORD_CONST, 32'h000000F4);
                    expect_csr(LVDS_CSR_SYNC_PATTERN_WORD_CONST, 32'h000000F4, desc.id);
                    drive_symbols(10'b0011110100, cfg.score_window_w + 64);
                end
                default: begin end
            endcase
        endtask

        task automatic drive_control_case(input lvds_case_desc_t desc);
            unique case (desc.case_num)
                11: expect_csr(LVDS_CSR_LANE_GO_WORD_CONST, lane_mask(), desc.id);
                12: begin
                    csr_write(LVDS_CSR_DPA_HOLD_WORD_CONST, 32'd0);
                    csr_write(LVDS_CSR_LANE_GO_WORD_CONST, lane_mask() & ~32'h1);
                    drive_symbols(10'b0011111010, 64);
                    expect_lane_valid(0, 1'b0, desc.id);
                    if (cfg.n_lane > 1) expect_lane_valid(1, 1'b1, desc.id);
                end
                13: begin
                    csr_write(LVDS_CSR_DPA_HOLD_WORD_CONST, 32'd0);
                    csr_write(LVDS_CSR_LANE_GO_WORD_CONST, 32'd0);
                    drive_symbols(10'b0011111010, 64);
                    for (int lane = 0; lane < cfg.n_lane; lane++) begin
                        expect_lane_valid(lane, 1'b0, desc.id);
                    end
                end
                14: begin
                    csr_write(LVDS_CSR_LANE_GO_WORD_CONST, lane_mask());
                    csr_write(LVDS_CSR_DPA_HOLD_WORD_CONST, 32'h1);
                    drive_symbols(10'b0011111010, 64);
                    expect_ctrl_bit("coe_ctrl_dpahold[0]", vif.coe_ctrl_dpahold[0], 1'b1, desc.id);
                    if (cfg.n_lane > 1) begin
                        expect_ctrl_bit("coe_ctrl_dpahold[1]", vif.coe_ctrl_dpahold[1], 1'b0, desc.id);
                    end
                end
                15: begin
                    csr_write(LVDS_CSR_LANE_GO_WORD_CONST, lane_mask());
                    csr_write(LVDS_CSR_DPA_HOLD_WORD_CONST, 32'd0);
                    csr_write(LVDS_CSR_SOFT_RESET_WORD_CONST, 32'h1);
                    wait_data_cycles(64);
                    expect_csr(LVDS_CSR_SOFT_RESET_WORD_CONST, 32'd0, desc.id);
                    expect_lane_counter_min(0, 8, 32'd1, desc.id);
                end
                16: begin
                    csr_write(LVDS_CSR_LANE_GO_WORD_CONST, lane_mask());
                    csr_write(LVDS_CSR_DPA_HOLD_WORD_CONST, 32'd0);
                    csr_write(LVDS_CSR_MODE_MASK_WORD_CONST, 32'h0);
                    drive_symbols(10'b0011111010, 128);
                    expect_lane_counter_eq(0, 7, 32'd0, desc.id);
                end
                17: begin
                    csr_write(LVDS_CSR_LANE_GO_WORD_CONST, lane_mask());
                    csr_write(LVDS_CSR_DPA_HOLD_WORD_CONST, 32'd0);
                    csr_write(LVDS_CSR_MODE_MASK_WORD_CONST, 32'h1);
                    drive_symbols(10'b0011111010, 128);
                    expect_lane_counter_min(0, 7, 32'd1, desc.id);
                end
                18: begin
                    csr_write(LVDS_CSR_LANE_GO_WORD_CONST, lane_mask());
                    csr_write(LVDS_CSR_DPA_HOLD_WORD_CONST, 32'd0);
                    csr_write(LVDS_CSR_MODE_MASK_WORD_CONST, 32'h2);
                    drive_symbols(10'b0011111010, 64);
                    inject_lane_symbol(0, 10'h000);
                    wait_data_cycles(128);
                    expect_lane_counter_min(0, 7, 32'd2, desc.id);
                end
                19: begin
                    csr_write(LVDS_CSR_SCORE_ACCEPT_WORD_CONST, 32'hFFFFFFFF);
                    expect_csr(LVDS_CSR_SCORE_ACCEPT_WORD_CONST, (32'd1 << cfg.score_window_w) - 32'd1, desc.id);
                end
                20: begin
                    logic [31:0] accept_value;
                    csr_read(LVDS_CSR_SCORE_ACCEPT_WORD_CONST, accept_value);
                    csr_write(LVDS_CSR_SCORE_REJECT_WORD_CONST, 32'hFFFFFFFF);
                    expect_csr(LVDS_CSR_SCORE_REJECT_WORD_CONST, accept_value - 32'd1, desc.id);
                end
                default: begin end
            endcase
        endtask

        function automatic logic [31:0] lane_mask();
            if (cfg.n_lane >= 32) begin
                return 32'hFFFFFFFF;
            end
            return (32'h1 << cfg.n_lane) - 1;
        endfunction

        task automatic drive_phy_powerup_case(input lvds_case_desc_t desc);
            if (desc.case_num == 25) begin
                vif.coe_ctrl_plllock <= 1'b0;
                wait_data_cycles(64);
                vif.coe_ctrl_plllock <= 1'b1;
            end else if (desc.case_num == 26) begin
                vif.rsi_data_reset <= 1'b1;
                wait_control_cycles(32);
                vif.rsi_data_reset <= 1'b0;
            end else if (desc.case_num == 27) begin
                vif.rsi_control_reset <= 1'b1;
                wait_data_cycles(32);
                vif.rsi_control_reset <= 1'b0;
            end else begin
                vif.coe_ctrl_plllock <= 1'b1;
                vif.coe_ctrl_dpalock <= lane_mask();
                drive_symbols(10'b0011111010, 128);
            end
        endtask

        task automatic drive_bitslip_case(input lvds_case_desc_t desc);
            int phase;
            phase = 0;
            if (desc.case_num == 35) begin
                drive_symbols(10'b1100000101, 160);
                return;
            end
            unique case (desc.case_num)
                30: phase = 1;
                31: phase = 2;
                32: phase = 5;
                33: phase = 9;
                34: phase = 10;
                36: phase = 5;
                default: phase = desc.case_num % 10;
            endcase
            drive_rotated_k285(phase, 160);
        endtask

        task automatic drive_rotated_k285(input int phase, input int cycles);
            logic [19:0] doubled;
            logic [9:0] rotated;
            doubled = {10'b0011111010, 10'b0011111010};
            rotated = doubled[phase +: 10];
            drive_symbols(rotated, cycles);
        endtask

        task automatic drive_train_steady_case(input lvds_case_desc_t desc);
            csr_write(LVDS_CSR_MODE_MASK_WORD_CONST, (desc.case_num == 48) ? 32'd0 : 32'h55555555);
            drive_rotated_k285(desc.case_num % 10, 256);
            if (desc.case_num == 50) begin
                inject_lane_symbol(3, 10'h000, 1);
            end
        endtask

        task automatic drive_counter_aperture_case(input lvds_case_desc_t desc);
            int lane;
            lane = (desc.case_num == 54) ? cfg.n_lane + 3 : (desc.case_num == 53 ? 2 : 3);
            csr_write(LVDS_CSR_LANE_SELECT_WORD_CONST, 32'(lane));
            for (int counter_idx = 0; counter_idx < LVDS_TB_COUNTER_COUNT_CONST; counter_idx++) begin
                csr_read(LVDS_CSR_COUNTER_BASE_WORD_CONST + counter_idx, void_data);
            end
            if (desc.case_num == 53) begin
                csr_write(LVDS_CSR_LANE_SELECT_WORD_CONST, 32'd5);
                csr_read(LVDS_CSR_COUNTER_BASE_WORD_CONST, void_data);
            end
        endtask

        task automatic drive_counter_set_case(input lvds_case_desc_t desc);
            int lane;
            lane = (desc.case_num == 68) ? 0 : 0;
            unique case (desc.case_num)
                55: inject_lane_symbol(lane, 10'h000);
                56: inject_lane_symbol(lane, 10'b1110101000);
                57: begin drive_symbols(10'b0011111010, 32); inject_lane_symbol(lane, 10'b0011110100, 4); end
                58: drive_rotated_k285(5, 128);
                59: begin vif.coe_ctrl_dpalock[lane] <= 1'b0; wait_data_cycles(1); vif.coe_ctrl_dpalock[lane] <= 1'b1; end
                63: repeat (3) begin csr_write(LVDS_CSR_SOFT_RESET_WORD_CONST, 32'h1); wait_data_cycles(32); end
                64: drive_symbols(10'b0011111010, 1000);
                default: drive_symbols(10'b0011111010, 128);
            endcase
            csr_write(LVDS_CSR_LANE_SELECT_WORD_CONST, 32'(lane));
            csr_read(LVDS_CSR_COUNTER_BASE_WORD_CONST + ((desc.case_num - 55) % LVDS_TB_COUNTER_COUNT_CONST), void_data);
        endtask

        task automatic drive_engine_pool_case(input lvds_case_desc_t desc);
            drive_symbols(10'b0011111010, 64);
            for (int lane = 0; lane < cfg.n_lane; lane++) begin
                if ((desc.case_num == 80) || (lane == (desc.case_num % cfg.n_lane))) begin
                    vif.drive_symbol(lane, 10'h000);
                end
            end
            wait_data_cycles(32);
            vif.drive_all_symbols(cfg.n_lane, 10'b0011111010);
            csr_read(10, void_data);
        endtask

        task automatic drive_score_edge_case(input lvds_case_desc_t desc);
            if (desc.case_num == 4) begin
                csr_write(LVDS_CSR_SCORE_ACCEPT_WORD_CONST, 32'd1);
            end else if (desc.case_num == 5) begin
                csr_write(LVDS_CSR_SCORE_REJECT_WORD_CONST, 32'd0);
            end else begin
                csr_write(LVDS_CSR_SCORE_ACCEPT_WORD_CONST, 32'(cfg.score_window_w));
            end
            drive_rotated_k285(desc.case_num % 10, 128);
        endtask

        task automatic drive_bitslip_edge_case(input lvds_case_desc_t desc);
            if (desc.case_num == 12) begin
                csr_write(LVDS_CSR_DPA_HOLD_WORD_CONST, 32'h1);
            end
            if (desc.case_num == 16) begin
                vif.coe_ctrl_plllock <= 1'b0;
                wait_data_cycles(1);
                vif.coe_ctrl_plllock <= 1'b1;
            end
            drive_rotated_k285((desc.case_num == 13) ? 9 : 7, 160);
        endtask

        task automatic drive_contention_case(input lvds_case_desc_t desc);
            int lanes[$];
            if (desc.case_num == 22 || desc.case_num == 23) begin
                csr_write(LVDS_CSR_SCORE_ACCEPT_WORD_CONST, 32'h000003FF);
                csr_write(LVDS_CSR_MODE_MASK_WORD_CONST, 32'h1);
                dv_debug_attach_engine(0, 0);
                vif.drive_symbol(0, 10'h000);
                wait_data_cycles(4);
                if (desc.case_num == 22) begin
                    csr_write(LVDS_CSR_SOFT_RESET_WORD_CONST, 32'h1);
                end else begin
                    csr_write(LVDS_CSR_LANE_GO_WORD_CONST, lane_mask() & ~32'h1);
                end
                wait_data_cycles(32);
                csr_write(LVDS_CSR_LANE_GO_WORD_CONST, lane_mask());
                vif.drive_all_symbols(cfg.n_lane, 10'b0011111010);
                return;
            end
            unique case (desc.case_num)
                18: begin lanes.push_back(3); lanes.push_back(7); end
                19: begin lanes.push_back(0); lanes.push_back(3); lanes.push_back(7); lanes.push_back(11); end
                default: for (int lane = 0; lane < cfg.n_lane; lane++) lanes.push_back(lane);
            endcase
            foreach (lanes[idx]) begin
                vif.drive_symbol(lanes[idx], 10'h000);
            end
            wait_data_cycles(1);
            vif.drive_all_symbols(cfg.n_lane, 10'b0011111010);
            wait_data_cycles(256);
        endtask

        task automatic drive_routing_case(input lvds_case_desc_t desc);
            if (desc.case_num == 27) begin
                csr_write(LVDS_CSR_CAPABILITY_WORD_CONST, 32'hFFFFFFFF);
            end else if (desc.case_num == 28) begin
                csr_write(LVDS_CSR_MODE_MASK_WORD_CONST, 32'h1);
                if (cfg.n_engine > 0) begin
                    dv_debug_attach_engine(0, 0);
                end
            end
            drive_engine_pool_case(desc);
        endtask

        task automatic drive_counter_window_case(input lvds_case_desc_t desc);
            if (desc.case_num == 29) begin
                csr_read(LVDS_CSR_COUNTER_BASE_WORD_CONST, void_data);
                csr_write(LVDS_CSR_LANE_SELECT_WORD_CONST, 32'd2);
            end else if (desc.case_num == 30) begin
                csr_write(LVDS_CSR_LANE_SELECT_WORD_CONST, 32'hFF);
                csr_read(LVDS_CSR_COUNTER_BASE_WORD_CONST, void_data);
            end else if (desc.case_num == 40) begin
                csr_write(64, 32'hA5A55A5A);
                expect_csr(64, 32'd0, desc.id);
            end else if (desc.case_num == 34) begin
                csr_read(11, void_data);
            end else begin
                csr_write(LVDS_CSR_COUNTER_BASE_WORD_CONST + (desc.case_num % 12), 32'hDEADBEEF);
                csr_read(LVDS_CSR_COUNTER_BASE_WORD_CONST + (desc.case_num % 12), void_data);
            end
        endtask

        task automatic drive_multilane_case(input lvds_case_desc_t desc);
            drive_symbols(10'b0011111010, 64);
            inject_lane_symbol(desc.case_num % cfg.n_lane, 10'h000, 1);
            wait_data_cycles(64);
        endtask

        task automatic drive_sync_case(input lvds_case_desc_t desc);
            unique case (desc.case_num)
                46: begin
                    csr_write(LVDS_CSR_SYNC_PATTERN_WORD_CONST, 32'h000000F4);
                    drive_symbols(10'b0011110100, 64);
                    drive_symbols(10'b1100001011, 64);
                end
                47: begin
                    csr_write(LVDS_CSR_SYNC_PATTERN_WORD_CONST, 32'h000003A8);
                    drive_symbols(10'b1110101000, 64);
                    drive_symbols(10'b0001010111, 64);
                end
                50: begin csr_write(LVDS_CSR_SYNC_PATTERN_WORD_CONST, 32'h0); drive_symbols(10'b0011111010, 128); end
                default: begin csr_write(LVDS_CSR_SYNC_PATTERN_WORD_CONST, 32'h000000FA); drive_symbols(10'b0011111010, 128); end
            endcase
        endtask

        task automatic drive_random_soak_case(input lvds_case_desc_t desc);
            int cycles;
            cycles = (desc.case_num inside {1,2,3}) ? 100000 : 1000000;
            drive_pseudo_random_glitches(desc, cycles);
        endtask

        task automatic drive_throughput_case(input lvds_case_desc_t desc);
            if (desc.case_num == 12 || desc.case_num == 15) begin
                for (int cycle_idx = 0; cycle_idx < cfg.symbol_cap; cycle_idx++) begin
                    vif.aso_decoded_ready <= $urandom();
                    vif.drive_all_symbols(cfg.n_lane, 10'b0011111010);
                    @(posedge vif.csi_data_clk);
                end
                vif.aso_decoded_ready <= '1;
            end else begin
                drive_symbols(10'b0011111010, cfg.symbol_cap);
            end
        endtask

        task automatic drive_saturation_case(input lvds_case_desc_t desc);
            int counter_idx;
            unique case (desc.case_num)
                21: counter_idx = LVDS_CNT_CODE_VIOLATIONS_CONST;
                22: counter_idx = LVDS_CNT_DISP_VIOLATIONS_CONST;
                23: counter_idx = LVDS_CNT_BITSLIP_EVENTS_CONST;
                default: counter_idx = LVDS_CNT_UPTIME_CONST;
            endcase
            csr_write(LVDS_CSR_SYNC_PATTERN_WORD_CONST, 32'h000000FA);
            csr_write(LVDS_CSR_SCORE_ACCEPT_WORD_CONST, 32'd1);
            csr_write(LVDS_CSR_SCORE_REJECT_WORD_CONST, 32'd0);
            csr_write(LVDS_CSR_LANE_GO_WORD_CONST, lane_mask());
            csr_write(LVDS_CSR_DPA_HOLD_WORD_CONST, 32'd0);
            csr_write(LVDS_CSR_MODE_MASK_WORD_CONST, 32'd0);
            drive_symbols(10'b0011111010, 128);
            dv_debug_set_lane_counter(0, counter_idx, 32'hFFFF_FFFE);
            unique case (desc.case_num)
                21: repeat (3) inject_lane_symbol(0, 10'h000, 1);
                22: repeat (3) inject_lane_symbol(0, 10'h3FF, 1);
                23: drive_rotated_k285(5, 64);
                default: drive_symbols(10'b0011111010, 64);
            endcase
            expect_lane_counter_eq(0, counter_idx, 32'hFFFF_FFFF, desc.id);
        endtask

        task automatic drive_long_stability_case(input lvds_case_desc_t desc);
            int cycles;
            cycles = (desc.case_num == 25) ? (cfg.symbol_cap * 4) : cfg.symbol_cap;
            drive_symbols(10'b0011111010, cycles);
            if (desc.case_num == 28) begin
                for (int sample_idx = 0; sample_idx < 8; sample_idx++) begin
                    csr_write(LVDS_CSR_LANE_SELECT_WORD_CONST, 32'(sample_idx % cfg.n_lane));
                    csr_read(LVDS_CSR_COUNTER_BASE_WORD_CONST + LVDS_CNT_UPTIME_CONST, void_data);
                    drive_symbols(10'b0011111010, 32);
                end
            end
            if (desc.case_num == 29) begin
                repeat (3) begin
                    csr_write(LVDS_CSR_SOFT_RESET_WORD_CONST, 32'h1);
                    wait_data_cycles(32);
                    drive_symbols(10'b0011111010, 64);
                end
            end
            if (desc.case_num == 30) begin
                vif.coe_ctrl_plllock <= 1'b0;
                wait_data_cycles(1);
                vif.coe_ctrl_plllock <= 1'b1;
            end
        endtask

        task automatic drive_random_sweep_case(input lvds_case_desc_t desc);
            drive_pseudo_random_glitches(desc, 100000);
        endtask

        task automatic drive_soft_reset_case(input lvds_case_desc_t desc);
            if (desc.case_num == 5) begin
                csr_write(LVDS_CSR_SOFT_RESET_WORD_CONST, lane_mask());
            end else begin
                csr_write(LVDS_CSR_SOFT_RESET_WORD_CONST, 32'h1);
            end
            wait_data_cycles(64);
        endtask

        task automatic drive_dead_lane_case(input lvds_case_desc_t desc);
            logic [9:0] dead_symbol;
            if (desc.case_num == 15 || desc.case_num == 17) begin
                csr_write(LVDS_CSR_MODE_MASK_WORD_CONST, 32'h0);
                drive_symbols(10'b0011111010, cfg.score_window_w + 16);
                csr_write(LVDS_CSR_MODE_MASK_WORD_CONST, 32'h1);
                if (desc.case_num == 15) begin
                    vif.coe_ctrl_dpalock[0] <= 1'b0;
                    wait_data_cycles(2);
                    vif.coe_ctrl_dpalock[0] <= 1'b1;
                end else begin
                    vif.coe_redriver_losn[0] <= 1'b0;
                    wait_data_cycles(2);
                    vif.coe_redriver_losn[0] <= 1'b1;
                end
                drive_symbols(10'b0011111010, 64);
                return;
            end
            unique case (desc.case_num)
                9:  dead_symbol = 10'h3FF;
                10: dead_symbol = 10'h000;
                11: dead_symbol = 10'b1001110100;
                default: dead_symbol = 10'h155;
            endcase
            inject_lane_symbol(0, dead_symbol, cfg.symbol_cap);
        endtask

        task automatic drive_phy_fault_case(input lvds_case_desc_t desc);
            unique case (desc.case_num)
                20: begin vif.coe_ctrl_plllock <= 1'b0; wait_data_cycles(16); vif.coe_ctrl_plllock <= 1'b1; end
                21: repeat (100) begin vif.coe_ctrl_dpalock[0] <= 1'b0; wait_data_cycles(1); vif.coe_ctrl_dpalock[0] <= 1'b1; wait_data_cycles(99); end
                24: repeat (100) begin vif.coe_ctrl_rollover[0] <= 1'b1; wait_data_cycles(1); vif.coe_ctrl_rollover[0] <= 1'b0; end
                default: drive_dead_lane_case(desc);
            endcase
        endtask

        task automatic drive_illegal_csr_case(input lvds_case_desc_t desc);
            unique case (desc.case_num)
                26, 27: begin
                    vif.rsi_control_reset <= 1'b1;
                    wait_control_cycles(8);
                    vif.rsi_control_reset <= 1'b0;
                end
                29: csr_write(LVDS_CSR_LANE_GO_WORD_CONST, 32'hFFFFFFFF);
                30: csr_write(LVDS_CSR_DPA_HOLD_WORD_CONST, 32'hFFFFFFFF);
                31: csr_write(LVDS_CSR_LANE_SELECT_WORD_CONST, 32'hFFFFFFFF);
                32: csr_write(LVDS_CSR_SCORE_ACCEPT_WORD_CONST, 32'd0);
                33: csr_write(LVDS_CSR_MODE_MASK_WORD_CONST, 32'h3);
                default: begin csr_write(LVDS_CSR_UID_WORD_CONST + desc.case_num, 32'hFFFFFFFF); csr_read(LVDS_CSR_UID_WORD_CONST + desc.case_num, void_data); end
            endcase
        endtask

        task automatic drive_sva_probe_case(input lvds_case_desc_t desc);
            unique case (desc.case_num)
                35: begin
                    csr_write(LVDS_CSR_SCORE_ACCEPT_WORD_CONST, 32'h000003FF);
                    csr_write(LVDS_CSR_MODE_MASK_WORD_CONST, 32'h1);
                    dv_debug_attach_engine(0, 0);
                    inject_lane_symbol(0, 10'h000, 16);
                    wait_data_cycles(64);
                end
                36: begin
                    csr_write(LVDS_CSR_SCORE_ACCEPT_WORD_CONST, 32'h000003FF);
                    dv_debug_set_engine_score(0, 0, 16'h03FF);
                    dv_debug_attach_engine(0, 0);
                    drive_symbols(10'b0011111010, 4);
                    dv_debug_set_lane_counter(0, LVDS_CNT_CODE_VIOLATIONS_CONST, 32'hFFFF_FFFE);
                    repeat (3) inject_lane_symbol(0, 10'h000, 1);
                    expect_lane_counter_eq(0, LVDS_CNT_CODE_VIOLATIONS_CONST, 32'hFFFF_FFFF, desc.id);
                end
                37: begin
                    vif.aso_decoded_ready[0] <= 1'b0;
                    drive_symbols(10'b0011111010, 16);
                    vif.aso_decoded_ready[0] <= 1'b1;
                    wait_data_cycles(8);
                end
                38: begin
                    csr_read(LVDS_CSR_UID_WORD_CONST, void_data);
                    csr_write(LVDS_CSR_MODE_MASK_WORD_CONST, 32'h1);
                    dv_debug_pulse_counter_raw(63, LVDS_CNT_CODE_VIOLATIONS_CONST);
                    dv_debug_pulse_counter_raw(0, 15);
                end
                39: begin
                    csr_write(LVDS_CSR_LANE_SELECT_WORD_CONST, 32'd0);
                    csr_read(LVDS_CSR_COUNTER_BASE_WORD_CONST, void_data);
                    dv_debug_pulse_engine_attach_raw(63, 0);
                    dv_debug_pulse_engine_attach_raw(0, 63);
                    dv_debug_pulse_engine_score_raw(63, 0);
                    dv_debug_pulse_engine_score_raw(0, 15);
                    dv_debug_pulse_engine_score_raw(0, 0);
                    dv_debug_pulse_engine_age_raw(63, 16'h1357);
                    for (int engine = 0; engine < cfg.n_engine; engine++) begin
                        dv_debug_set_engine_age(engine, 16'hFFFF);
                        dv_debug_set_engine_age(engine, 16'h0000);
                    end
                end
                40: begin
                    csr_write(LVDS_CSR_MODE_MASK_WORD_CONST, 32'h1);
                    inject_lane_symbol(0, 10'h000, 1);
                    wait_data_cycles(96);
                    expect_lane_counter_min(0, LVDS_CNT_ENGINE_STEER_CONST, 32'd1, desc.id);
                end
                41: begin
                    vif.coe_ctrl_dpalock[0] <= 1'b0;
                    wait_data_cycles(16);
                    vif.coe_ctrl_dpalock[0] <= 1'b1;
                    drive_rotated_k285(5, 32);
                    drive_symbols(10'b0011111010, 96);
                end
                default: wait_data_cycles(32);
            endcase
        endtask

        task automatic drive_reset_race_case(input lvds_case_desc_t desc);
            unique case (desc.case_num)
                42: drive_reset(16);
                43: begin vif.rsi_control_reset <= 1'b0; wait_control_cycles(100); vif.rsi_data_reset <= 1'b0; end
                44: begin vif.rsi_data_reset <= 1'b0; wait_data_cycles(100); vif.rsi_control_reset <= 1'b0; end
                45: begin csr_write(LVDS_CSR_MODE_MASK_WORD_CONST, 32'h1); vif.rsi_control_reset <= 1'b1; wait_control_cycles(4); vif.rsi_control_reset <= 1'b0; end
                46: begin
                    vif.aso_decoded_ready[0] <= 1'b0;
                    wait_data_cycles(3);
                    @(negedge vif.csi_data_clk);
                    vif.rsi_data_reset = 1'b1;
                    wait_data_cycles(1);
                    @(negedge vif.csi_data_clk);
                    vif.rsi_data_reset = 1'b0;
                    vif.aso_decoded_ready[0] <= 1'b1;
                end
                default: begin vif.rsi_data_reset <= 1'b1; wait_data_cycles(1); vif.rsi_data_reset <= 1'b0; end
            endcase
        endtask

        task automatic drive_pseudo_random_glitches(input lvds_case_desc_t desc, input int requested_cycles);
            int cycles;
            int lfsr;
            cycles = (requested_cycles > cfg.symbol_cap) ? cfg.symbol_cap : requested_cycles;
            lfsr = 32'h1BAD0000 ^ desc.case_num;
            for (int cycle_idx = 0; cycle_idx < cycles; cycle_idx++) begin
                vif.drive_all_symbols(cfg.n_lane, 10'b0011111010);
                lfsr = (lfsr << 1) ^ (((lfsr >> 31) ^ (lfsr >> 21) ^ (lfsr >> 1) ^ lfsr) & 1);
                if ((lfsr % 100) < 5) begin
                    vif.drive_symbol(lfsr % cfg.n_lane, (lfsr[4]) ? 10'h000 : 10'h3FF);
                end
                @(posedge vif.csi_data_clk);
            end
        endtask
    endclass

    class lvds_scoreboard extends uvm_component;
        `uvm_component_utils(lvds_scoreboard)

        uvm_analysis_imp #(lvds_case_item, lvds_scoreboard) case_export;
        int unsigned case_count;
        int unsigned bucket_count[lvds_bucket_e];

        function new(string name, uvm_component parent);
            super.new(name, parent);
            case_export = new("case_export", this);
        endfunction

        function void write(lvds_case_item item);
            case_count++;
            if (!bucket_count.exists(item.desc.bucket)) begin
                bucket_count[item.desc.bucket] = 0;
            end
            bucket_count[item.desc.bucket]++;
            if (item.desc.expect_sva_failure) begin
                `uvm_info("LVDS/SB", {item.desc.id, " is an intentional SVA probe; final PASS needs assertion-fire accounting"}, UVM_LOW)
            end
        endfunction

        function void report_phase(uvm_phase phase);
            `uvm_info("LVDS/SB", $sformatf("observed %0d case transactions", case_count), UVM_LOW)
        endfunction
    endclass

    class lvds_coverage extends uvm_component;
        `uvm_component_utils(lvds_coverage)

        uvm_analysis_imp #(lvds_case_item, lvds_coverage) case_export;
        int unsigned case_hit[string];

        function new(string name, uvm_component parent);
            super.new(name, parent);
            case_export = new("case_export", this);
        endfunction

        function void write(lvds_case_item item);
            if (!case_hit.exists(item.desc.id)) begin
                case_hit[item.desc.id] = 0;
            end
            case_hit[item.desc.id]++;
        endfunction
    endclass

    class lvds_env extends uvm_env;
        `uvm_component_utils(lvds_env)

        lvds_env_config   cfg;
        lvds_case_sequencer case_seqr;
        lvds_case_driver  case_drv;
        lvds_scoreboard   scoreboard;
        lvds_coverage     coverage;

        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            if (!uvm_config_db #(lvds_env_config)::get(this, "", "cfg", cfg)) begin
                `uvm_fatal("LVDS/CFG", "lvds_env missing cfg")
            end
            uvm_config_db #(lvds_env_config)::set(this, "case_drv", "cfg", cfg);
            case_seqr  = lvds_case_sequencer::type_id::create("case_seqr", this);
            case_drv   = lvds_case_driver::type_id::create("case_drv", this);
            scoreboard = lvds_scoreboard::type_id::create("scoreboard", this);
            coverage   = lvds_coverage::type_id::create("coverage", this);
        endfunction

        function void connect_phase(uvm_phase phase);
            case_drv.seq_item_port.connect(case_seqr.seq_item_export);
            case_drv.case_ap.connect(scoreboard.case_export);
            case_drv.case_ap.connect(coverage.case_export);
        endfunction
    endclass

    class lvds_case_sequence_base extends uvm_sequence #(lvds_case_item);
        `uvm_object_utils(lvds_case_sequence_base)

        string case_id;
        bit    continuous_frame;

        function new(string name = "lvds_case_sequence_base");
            super.new(name);
            case_id          = "B001";
            continuous_frame = 1'b0;
        endfunction

        task body();
            lvds_case_item item;
            item = lvds_case_item::type_id::create({case_id, "_item"});
            item.desc = lvds_get_case_desc(case_id);
            if (item.desc.id == "") begin
                `uvm_fatal("LVDS/SEQ", {"Unknown LVDS case id ", case_id})
            end
            item.continuous_frame = continuous_frame;
            start_item(item);
            finish_item(item);
        endtask
    endclass

    class lvds_case_id_sequence extends lvds_case_sequence_base;
        `uvm_object_utils(lvds_case_id_sequence)

        function new(string name = "lvds_case_id_sequence");
            super.new(name);
        endfunction
    endclass

    `include "lvds_case_sequence_list.svh"

    class lvds_base_test extends uvm_test;
        `uvm_component_utils(lvds_base_test)

        lvds_env        env;
        lvds_env_config cfg;
        string          default_case_id;

        function new(string name, uvm_component parent);
            super.new(name, parent);
            default_case_id = "B001";
        endfunction

        function void build_phase(uvm_phase phase);
            int value;
            super.build_phase(phase);
            cfg = lvds_env_config::type_id::create("cfg");
            if (!uvm_config_db #(virtual lvds_dut_if)::get(null, "*", "vif", cfg.vif)) begin
                `uvm_fatal("LVDS/VIF", "virtual lvds_dut_if not set")
            end
            if ($value$plusargs("N_LANE=%d", value)) cfg.n_lane = value;
            if ($value$plusargs("N_ENGINE=%d", value)) cfg.n_engine = value;
            if ($value$plusargs("SCORE_WINDOW_W=%d", value)) cfg.score_window_w = value;
            if ($value$plusargs("SYMBOL_CAP=%d", value)) cfg.symbol_cap = value;
            cfg.harness_only = $test$plusargs("LVDS_HARNESS_ONLY");
            uvm_config_db #(lvds_env_config)::set(this, "env", "cfg", cfg);
            env = lvds_env::type_id::create("env", this);
        endfunction

        task run_phase(uvm_phase phase);
            string case_id;
            if (!$value$plusargs("LVDS_CASE_ID=%s", case_id)) begin
                case_id = default_case_id;
            end
            phase.raise_objection(this);
            run_one_case(case_id, 1'b0);
            phase.drop_objection(this);
        endtask

        task run_one_case(input string case_id, input bit continuous_frame);
            lvds_case_id_sequence seq;
            seq = lvds_case_id_sequence::type_id::create({"seq_", case_id});
            seq.case_id = case_id;
            seq.continuous_frame = continuous_frame;
            seq.start(env.case_seqr);
        endtask
    endclass

    class lvds_case_test_base extends lvds_base_test;
        `uvm_component_utils(lvds_case_test_base)

        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction
    endclass

    class lvds_bucket_frame_test_base extends lvds_base_test;
        `uvm_component_utils(lvds_bucket_frame_test_base)

        lvds_bucket_e bucket;

        function new(string name, uvm_component parent);
            super.new(name, parent);
            bucket = LVDS_BUCKET_BASIC;
        endfunction

        task run_phase(uvm_phase phase);
            string case_id;
            phase.raise_objection(this);
            for (int idx = 0; idx < lvds_bucket_case_count(bucket); idx++) begin
                case_id = lvds_bucket_case_id_at(bucket, idx);
                if (!lvds_skip_in_continuous_frame(case_id)) begin
                    run_one_case(case_id, 1'b1);
                end
            end
            phase.drop_objection(this);
        endtask
    endclass

    class lvds_bucket_frame_basic_test extends lvds_bucket_frame_test_base;
        `uvm_component_utils(lvds_bucket_frame_basic_test)
        function new(string name, uvm_component parent); super.new(name, parent); bucket = LVDS_BUCKET_BASIC; endfunction
    endclass

    class lvds_bucket_frame_edge_test extends lvds_bucket_frame_test_base;
        `uvm_component_utils(lvds_bucket_frame_edge_test)
        function new(string name, uvm_component parent); super.new(name, parent); bucket = LVDS_BUCKET_EDGE; endfunction
    endclass

    class lvds_bucket_frame_prof_test extends lvds_bucket_frame_test_base;
        `uvm_component_utils(lvds_bucket_frame_prof_test)
        function new(string name, uvm_component parent); super.new(name, parent); bucket = LVDS_BUCKET_PROF; endfunction
    endclass

    class lvds_bucket_frame_error_test extends lvds_bucket_frame_test_base;
        `uvm_component_utils(lvds_bucket_frame_error_test)
        function new(string name, uvm_component parent); super.new(name, parent); bucket = LVDS_BUCKET_ERROR; endfunction
    endclass

    class lvds_all_buckets_frame_test extends lvds_base_test;
        `uvm_component_utils(lvds_all_buckets_frame_test)

        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction

        task run_phase(uvm_phase phase);
            string case_id;
            phase.raise_objection(this);
            for (int idx = 0; idx < lvds_case_count(); idx++) begin
                case_id = lvds_case_id_at(idx);
                if (!lvds_skip_in_continuous_frame(case_id)) begin
                    run_one_case(case_id, 1'b1);
                end
            end
            phase.drop_objection(this);
        endtask
    endclass

    `include "lvds_case_tests.svh"

endpackage
