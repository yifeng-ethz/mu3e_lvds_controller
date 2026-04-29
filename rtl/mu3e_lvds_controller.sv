// SPDX-License-Identifier: CERN-OHL-S-2.0
// Version : 26.0.2
// Date    : 20260429
// Change  : Add explicit control/data CDC handshakes for CSR configuration and status.

module mu3e_lvds_controller #(
    parameter int          N_LANE              = 12,
    parameter int          N_ENGINE            = 1,
    parameter int          ROUTING_TOPOLOGY    = 1,
    parameter int          SCORE_WINDOW_W      = 10,
    parameter int          SCORE_ACCEPT        = 8,
    parameter int          SCORE_REJECT        = 2,
    parameter int          STEER_QUEUE_DEPTH   = 4,
    parameter int          AVMM_ADDR_W         = 6,
    parameter int          INSTANCE_ID         = 0,
    parameter logic [31:0] IP_UID              = 32'h4C564453,
    parameter int          VERSION_MAJOR       = 26,
    parameter int          VERSION_MINOR       = 0,
    parameter int          VERSION_PATCH       = 2,
    parameter int          BUILD               = 12'h429,
    parameter logic [31:0] VERSION_DATE        = 32'h20260429,
    parameter logic [31:0] VERSION_GIT         = 32'h00000000,
    parameter logic [9:0]  SYNC_PATTERN        = 10'b0011111010,
    parameter int          DEBUG_LEVEL         = 0
) (
    input  logic                  csi_control_clk,
    input  logic                  rsi_control_reset,
    input  logic                  csi_data_clk,
    input  logic                  rsi_data_reset,

    input  logic [32 * 10 - 1:0]  coe_parallel_data,
    output logic                  coe_ctrl_pllrst,
    input  logic                  coe_ctrl_plllock,
    output logic [31:0]           coe_ctrl_dparst,
    output logic [31:0]           coe_ctrl_lockrst,
    output logic [31:0]           coe_ctrl_dpahold,
    input  logic [31:0]           coe_ctrl_dpalock,
    output logic [31:0]           coe_ctrl_fiforst,
    output logic [31:0]           coe_ctrl_bitslip,
    input  logic [31:0]           coe_ctrl_rollover,
    input  logic [31:0]           coe_redriver_losn,

    input  logic                  avs_csr_read,
    input  logic                  avs_csr_write,
    input  logic [9:0]            avs_csr_address,
    input  logic [31:0]           avs_csr_writedata,
    output logic [31:0]           avs_csr_readdata,
    output logic                  avs_csr_waitrequest,

    output logic [31:0]           aso_decoded_valid,
    input  logic [31:0]           aso_decoded_ready,
    output logic [31:0][8:0]      aso_decoded_data,
    output logic [31:0][2:0]      aso_decoded_error,
    output logic [31:0][5:0]      aso_decoded_channel
`ifdef LVDS_DV_DEBUG
    ,
    input  logic                  dv_debug_counter_we,
    input  logic [5:0]            dv_debug_counter_lane,
    input  logic [3:0]            dv_debug_counter_idx,
    input  logic [31:0]           dv_debug_counter_value,
    input  logic                  dv_debug_engine_attach_we,
    input  logic [5:0]            dv_debug_engine_idx,
    input  logic [5:0]            dv_debug_engine_lane,
    input  logic                  dv_debug_engine_score_we,
    input  logic [5:0]            dv_debug_engine_score_idx,
    input  logic [3:0]            dv_debug_engine_score_phase,
    input  logic [15:0]           dv_debug_engine_score_value,
    input  logic                  dv_debug_engine_age_we,
    input  logic [5:0]            dv_debug_engine_age_idx,
    input  logic [15:0]           dv_debug_engine_age_value
`endif
);
    timeunit 1ns;
    timeprecision 1ps;

    localparam int MAX_LANE_CONST              = 32;
    localparam int MAX_ENGINE_CONST            = 32;
    localparam int COUNTER_COUNT_CONST         = 10;
    localparam int CHANNEL_W_CONST             = 6;
    localparam int SCORE_PHASE_COUNT_CONST     = 10;
    localparam int SCORE_W_CONST               = 16;
    localparam int SOFT_RESET_HOLD_CYCLES_CONST = 8;
    localparam int PLL_RESET_CYCLES_CONST      = 8;
    localparam logic [7:0] SNAPSHOT_TIMEOUT_CYCLES_CONST = 8'd128;

    localparam int N_LANE_CLAMP_CONST          =
        (N_LANE < 1) ? 1 : ((N_LANE > MAX_LANE_CONST) ? MAX_LANE_CONST : N_LANE);
    localparam int N_ENGINE_BOUND_CONST        =
        (N_ENGINE < 1) ? 1 : ((N_ENGINE > MAX_ENGINE_CONST) ? MAX_ENGINE_CONST : N_ENGINE);
    localparam int N_ENGINE_CLAMP_CONST        =
        (N_ENGINE_BOUND_CONST > N_LANE_CLAMP_CONST) ? N_LANE_CLAMP_CONST : N_ENGINE_BOUND_CONST;
    localparam int SCORE_WINDOW_CLAMP_CONST    =
        (SCORE_WINDOW_W < 6) ? 6 : ((SCORE_WINDOW_W > 16) ? 16 : SCORE_WINDOW_W);
    localparam int SCORE_MAX_INT_CONST         = (1 << SCORE_WINDOW_CLAMP_CONST) - 1;
    localparam int STEER_QUEUE_DEPTH_CONST     =
        (STEER_QUEUE_DEPTH < 1) ? 1 : ((STEER_QUEUE_DEPTH > 16) ? 16 : STEER_QUEUE_DEPTH);
    localparam logic [31:0] ACTIVE_LANE_MASK_CONST =
        (N_LANE_CLAMP_CONST >= MAX_LANE_CONST) ? 32'hFFFF_FFFF : ((32'h1 << N_LANE_CLAMP_CONST) - 32'h1);
    localparam logic [31:0] ACTIVE_ENGINE_MASK_CONST =
        (N_ENGINE_CLAMP_CONST >= MAX_ENGINE_CONST) ? 32'hFFFF_FFFF : ((32'h1 << N_ENGINE_CLAMP_CONST) - 32'h1);
    localparam logic [5:0] LAST_LANE_INDEX_CONST = N_LANE_CLAMP_CONST - 1;

    localparam logic [9:0] CSR_UID_ADDR_CONST          = 10'd0;
    localparam logic [9:0] CSR_META_ADDR_CONST         = 10'd1;
    localparam logic [9:0] CSR_CAPABILITY_ADDR_CONST   = 10'd2;
    localparam logic [9:0] CSR_SYNC_PATTERN_ADDR_CONST = 10'd3;
    localparam logic [9:0] CSR_LANE_GO_ADDR_CONST      = 10'd4;
    localparam logic [9:0] CSR_DPA_HOLD_ADDR_CONST     = 10'd5;
    localparam logic [9:0] CSR_SOFT_RESET_ADDR_CONST   = 10'd6;
    localparam logic [9:0] CSR_MODE_MASK_ADDR_CONST    = 10'd7;
    localparam logic [9:0] CSR_SCORE_ACCEPT_ADDR_CONST = 10'd8;
    localparam logic [9:0] CSR_SCORE_REJECT_ADDR_CONST = 10'd9;
    localparam logic [9:0] CSR_STEER_STATUS_ADDR_CONST = 10'd10;
    localparam logic [9:0] CSR_LANE_SELECT_ADDR_CONST  = 10'd16;
    localparam logic [9:0] CSR_COUNTER_BASE_ADDR_CONST = 10'd17;
    localparam logic [9:0] CSR_COUNTER_LAST_ADDR_CONST = CSR_COUNTER_BASE_ADDR_CONST + COUNTER_COUNT_CONST - 1;

    localparam int COUNTER_CODE_VIOLATIONS_CONST = 0;
    localparam int COUNTER_DISP_VIOLATIONS_CONST = 1;
    localparam int COUNTER_COMMA_LOSSES_CONST    = 2;
    localparam int COUNTER_BITSLIP_EVENTS_CONST  = 3;
    localparam int COUNTER_DPA_UNLOCKS_CONST     = 4;
    localparam int COUNTER_REALIGNS_CONST        = 5;
    localparam int COUNTER_SCORE_CHANGES_CONST   = 6;
    localparam int COUNTER_ENGINE_STEER_CONST    = 7;
    localparam int COUNTER_SOFT_RESETS_CONST     = 8;
    localparam int COUNTER_UPTIME_CONST          = 9;

    localparam logic [9:0] SYMBOL_K285_P_CONST = 10'b0011111010;
    localparam logic [9:0] SYMBOL_K285_N_CONST = 10'b1100000101;
    localparam logic [9:0] SYMBOL_K280_P_CONST = 10'b0011110100;
    localparam logic [9:0] SYMBOL_K280_N_CONST = 10'b1100001011;
    localparam logic [9:0] SYMBOL_K237_P_CONST = 10'b1110101000;
    localparam logic [9:0] SYMBOL_K237_N_CONST = 10'b0001010111;

    localparam logic [1:0] MODE_BITSLIPPING_CONST = 2'd0;
    localparam logic [1:0] MODE_ADAPTING_CONST    = 2'd1;
    localparam logic [1:0] MODE_AUTOING_CONST     = 2'd2;

    typedef enum logic [3:0] {
        TRAIN_IDLING,
        TRAIN_WAITING_PLL,
        TRAIN_RESETTING_DPA,
        TRAIN_WAITING_DPA,
        TRAIN_RESETTING_FIFO,
        TRAIN_BITSLIPPING,
        TRAIN_LOCKING,
        TRAIN_HOLDING_LOCK,
        TRAIN_DEGRADING
    } train_state_t;

    typedef enum logic [1:0] {
        STEER_IDLING,
        STEER_SCANNING,
        STEER_ATTACHING,
        STEER_RELEASING
    } steer_state_t;

    typedef struct packed {
        logic [8:0] data;
        logic [2:0] error;
        logic       legal;
    } decode_result_t;

    typedef struct packed {
        logic [1:0]  meta_page;
        logic [9:0]  sync_pattern;
        logic [31:0] lane_go;
        logic [31:0] dpa_hold;
        logic [31:0] soft_reset_req;
        logic [31:0] mode_mask;
        logic [15:0] score_accept;
        logic [15:0] score_reject;
        logic [5:0]  lane_select;
    } csr_state_t;

    typedef struct packed {
        logic [9:0]  sync_pattern;
        logic [31:0] lane_go;
        logic [31:0] dpa_hold;
        logic [31:0] soft_reset_req;
        logic [31:0] mode_mask;
        logic [15:0] score_accept;
        logic [15:0] score_reject;
    } data_cfg_t;

    typedef logic [COUNTER_COUNT_CONST - 1:0][31:0] counter_snapshot_t;

    csr_state_t csr;
    data_cfg_t  cfg_control_bus;
    data_cfg_t  cfg_data;

    train_state_t train_state [0:MAX_LANE_CONST - 1];
    steer_state_t steer_state;

    logic [MAX_LANE_CONST - 1:0][COUNTER_COUNT_CONST - 1:0][31:0] lane_counter;

    logic cfg_req_toggle_control;
    logic cfg_idle_control;
    logic cfg_resend_control;
    logic cfg_ack_toggle_control_d1;
    logic cfg_ack_toggle_control_d2;
    logic cfg_req_toggle_data_d1;
    logic cfg_req_toggle_data_d2;
    logic cfg_req_toggle_data_seen;
    logic cfg_ack_toggle_data;

    logic data_reset_control_d1;
    logic data_reset_control_d2;
    logic data_reset_control_d3;

    logic snapshot_req_toggle_control;
    logic snapshot_pending_control;
    logic snapshot_response_valid_control;
    logic [9:0] snapshot_pending_addr_control;
    logic [5:0] snapshot_lane_control;
    logic [7:0] snapshot_timeout_control;
    logic snapshot_timed_out_control;
    logic snapshot_ack_toggle_control_d1;
    logic snapshot_ack_toggle_control_d2;
    logic snapshot_ack_toggle_control_seen;
    logic snapshot_req_toggle_data_d1;
    logic snapshot_req_toggle_data_d2;
    logic snapshot_req_toggle_data_seen;
    logic snapshot_ack_toggle_data;
    logic [31:0] snapshot_status_data_bus;
    counter_snapshot_t snapshot_counter_data_bus;

    logic        plllock_control_d1;
    logic        plllock_control_d2;
    logic        plllock_control_d3;
    logic [3:0]  pll_reset_count_control;

    logic        plllock_data_d1;
    logic        plllock_data_d2;
    logic [31:0] dpalock_data_d1;
    logic [31:0] dpalock_data_d2;
    logic [31:0] rollover_data_d1;
    logic [31:0] rollover_data_d2;
    logic [31:0] redriver_losn_data_d1;
    logic [31:0] redriver_losn_data_d2;

    logic [MAX_ENGINE_CONST - 1:0]                         engine_attached;
    logic [MAX_ENGINE_CONST - 1:0]                         engine_busy;
    logic [MAX_ENGINE_CONST - 1:0][CHANNEL_W_CONST - 1:0]  engine_attach_lane;
    logic [MAX_ENGINE_CONST - 1:0][SCORE_PHASE_COUNT_CONST - 1:0][SCORE_W_CONST - 1:0] engine_score;
    logic [MAX_ENGINE_CONST - 1:0][3:0]                    engine_best_phase;
    logic [MAX_ENGINE_CONST - 1:0][SCORE_W_CONST - 1:0]    engine_best_score;
    logic [MAX_ENGINE_CONST - 1:0][3:0]                    engine_score_scan_phase;
    logic [MAX_ENGINE_CONST - 1:0][9:0]                    engine_score_symbol_d1;
    logic [MAX_ENGINE_CONST - 1:0]                         engine_score_symbol_valid_d1;
    logic [MAX_ENGINE_CONST - 1:0][15:0]                   engine_age;
    logic [MAX_ENGINE_CONST - 1:0]                         engine_attach_event;
    logic [5:0]                                            steer_queue_count;
    logic [31:0]                                           steer_overflow_count;

    logic [MAX_LANE_CONST - 1:0][7:0] lane_good_count;
    logic [MAX_LANE_CONST - 1:0]      lane_engine_seen;
    logic [MAX_LANE_CONST - 1:0]      lane_engine_request_d1;
    logic [MAX_LANE_CONST - 1:0]      lane_engine_error_d1;
    logic [MAX_LANE_CONST - 1:0]      score_change_event_d1;
    logic [MAX_LANE_CONST - 1:0]      loss_sync_d1;
    logic [MAX_LANE_CONST - 1:0]      dpalock_d1;
    logic [MAX_LANE_CONST - 1:0]      rollover_d1;

    logic [31:0] lane_go_data_d1;
    logic [31:0] lane_go_data_d2;
    logic [31:0] dpa_hold_data_d1;
    logic [31:0] dpa_hold_data_d2;
    logic [31:0] soft_reset_req_data_d1;
    logic [31:0] soft_reset_req_data_d2;
    logic [31:0] soft_reset_req_data_d3;
    logic [31:0] mode_mask_data_d1;
    logic [31:0] mode_mask_data_d2;
    logic [9:0]  sync_pattern_data_d1;
    logic [9:0]  sync_pattern_data_d2;
    logic [15:0] score_accept_data_d1;
    logic [15:0] score_accept_data_d2;
    logic [15:0] score_reject_data_d1;
    logic [15:0] score_reject_data_d2;

    logic [31:0] soft_reset_rise;
    logic [3:0]  soft_reset_hold_count [0:MAX_LANE_CONST - 1];

    logic [MAX_LANE_CONST - 1:0]      mini_valid_d1;
    logic [MAX_LANE_CONST - 1:0][8:0] mini_data_d1;
    logic [MAX_LANE_CONST - 1:0][2:0] mini_error_d1;
    logic [MAX_LANE_CONST - 1:0][5:0] mini_channel_d1;

    logic [MAX_LANE_CONST - 1:0]      mini_valid_d2;
    logic [MAX_LANE_CONST - 1:0][8:0] mini_data_d2;
    logic [MAX_LANE_CONST - 1:0][2:0] mini_error_d2;
    logic [MAX_LANE_CONST - 1:0][5:0] mini_channel_d2;

    logic [MAX_LANE_CONST - 1:0]      engine_valid_d1;
    logic [MAX_LANE_CONST - 1:0][8:0] engine_data_d1;
    logic [MAX_LANE_CONST - 1:0][2:0] engine_error_d1;
    logic [MAX_LANE_CONST - 1:0][5:0] engine_channel_d1;

    logic [MAX_LANE_CONST - 1:0]      engine_valid_d2;
    logic [MAX_LANE_CONST - 1:0][8:0] engine_data_d2;
    logic [MAX_LANE_CONST - 1:0][2:0] engine_error_d2;
    logic [MAX_LANE_CONST - 1:0][5:0] engine_channel_d2;

    logic [31:0] csr_read_mux;
    logic [31:0] csr_capability_word;
    logic [31:0] csr_version_word;

    assign avs_csr_waitrequest = snapshot_pending_control ||
                                 (avs_csr_read &&
                                  csr_read_needs_snapshot(avs_csr_address) &&
                                  !snapshot_response_valid_control &&
                                  !snapshot_timed_out_control);
    assign cfg_idle_control     = (cfg_ack_toggle_control_d2 == cfg_req_toggle_control);
    assign soft_reset_rise     = soft_reset_req_data_d2 & ~soft_reset_req_data_d3;

    function automatic logic [7:0] int_to_u8(input int value);
        return value[7:0];
    endfunction

    function automatic logic [3:0] int_to_u4(input int value);
        return value[3:0];
    endfunction

    function automatic logic [11:0] int_to_u12(input int value);
        return value[11:0];
    endfunction

    function automatic logic [15:0] clamp_score_accept(input logic [31:0] value);
        if (value == 32'd0) begin
            return 16'd1;
        end
        if (value > SCORE_MAX_INT_CONST[31:0]) begin
            return SCORE_MAX_INT_CONST[15:0];
        end
        return value[15:0];
    endfunction

    function automatic logic [15:0] clamp_score_reject(input logic [31:0] value, input logic [15:0] accept);
        if (value >= {16'd0, accept}) begin
            return accept - 16'd1;
        end
        return value[15:0];
    endfunction

    function automatic data_cfg_t data_cfg_default();
        data_cfg_t cfg_value;

        cfg_value.sync_pattern   = SYNC_PATTERN;
        cfg_value.lane_go        = ACTIVE_LANE_MASK_CONST;
        cfg_value.dpa_hold       = 32'd0;
        cfg_value.soft_reset_req = 32'd0;
        cfg_value.mode_mask      = 32'h0000_0000;
        cfg_value.score_accept   = clamp_score_accept(SCORE_ACCEPT);
        cfg_value.score_reject   = clamp_score_reject(SCORE_REJECT, clamp_score_accept(SCORE_ACCEPT));
        return cfg_value;
    endfunction

    function automatic data_cfg_t data_cfg_from_csr(input csr_state_t state);
        data_cfg_t cfg_value;

        cfg_value.sync_pattern   = state.sync_pattern;
        cfg_value.lane_go        = state.lane_go;
        cfg_value.dpa_hold       = state.dpa_hold;
        cfg_value.soft_reset_req = state.soft_reset_req;
        cfg_value.mode_mask      = state.mode_mask;
        cfg_value.score_accept   = state.score_accept;
        cfg_value.score_reject   = state.score_reject;
        return cfg_value;
    endfunction

    function automatic logic csr_read_needs_snapshot(input logic [9:0] address);
        return (address == CSR_STEER_STATUS_ADDR_CONST) ||
               ((address >= CSR_COUNTER_BASE_ADDR_CONST) && (address <= CSR_COUNTER_LAST_ADDR_CONST));
    endfunction

    function automatic logic [31:0] snapshot_read_word(
        input logic [ 9    :0]   address,
        input logic [31    :0]   status_word,
        input counter_snapshot_t counters
    );
        unique case (address)
            CSR_STEER_STATUS_ADDR_CONST:                 return status_word;
            CSR_COUNTER_BASE_ADDR_CONST + 10'd0:          return counters[0];
            CSR_COUNTER_BASE_ADDR_CONST + 10'd1:          return counters[1];
            CSR_COUNTER_BASE_ADDR_CONST + 10'd2:          return counters[2];
            CSR_COUNTER_BASE_ADDR_CONST + 10'd3:          return counters[3];
            CSR_COUNTER_BASE_ADDR_CONST + 10'd4:          return counters[4];
            CSR_COUNTER_BASE_ADDR_CONST + 10'd5:          return counters[5];
            CSR_COUNTER_BASE_ADDR_CONST + 10'd6:          return counters[6];
            CSR_COUNTER_BASE_ADDR_CONST + 10'd7:          return counters[7];
            CSR_COUNTER_BASE_ADDR_CONST + 10'd8:          return counters[8];
            CSR_COUNTER_BASE_ADDR_CONST + 10'd9:          return counters[9];
            default:                                      return 32'd0;
        endcase
    endfunction

    function automatic logic sync_pattern_is_legal(input logic [9:0] pattern);
        return (pattern == SYMBOL_K285_P_CONST) || (pattern == SYMBOL_K285_N_CONST) ||
               (pattern == SYMBOL_K280_P_CONST) || (pattern == SYMBOL_K280_N_CONST) ||
               (pattern == SYMBOL_K237_P_CONST) || (pattern == SYMBOL_K237_N_CONST);
    endfunction

    function automatic logic [31:0] saturating_inc(input logic [31:0] value);
        if (value == 32'hFFFF_FFFF) begin
            return value;
        end
        return value + 32'd1;
    endfunction

    function automatic logic [15:0] saturating_score_inc(input logic [15:0] value);
        if (value >= SCORE_MAX_INT_CONST[15:0]) begin
            return SCORE_MAX_INT_CONST[15:0];
        end
        return value + 16'd1;
    endfunction

    function automatic logic [15:0] score_decay(input logic [15:0] value);
        if (value == 16'd0) begin
            return 16'd0;
        end
        return value - 16'd1;
    endfunction

    function automatic logic [9:0] rotate_symbol(input logic [9:0] symbol, input int phase);
        logic [19:0] doubled;
        doubled = {symbol, symbol};
        return doubled[phase +: 10];
    endfunction

    // This is intentionally a mini decoder: it recognizes the training/control
    // symbols used by the current DV plan and marks everything else observable.
    // OPEN: replace this with the complete table decoder when the final packet
    // stream coding contract is frozen.
    function automatic decode_result_t decode_symbol(input logic [9:0] symbol, input logic [9:0] sync_pattern);
        decode_result_t result;

        result.data  = 9'h000;
        result.error = 3'b000;
        result.legal = 1'b1;

        unique case (symbol)
            SYMBOL_K285_P_CONST,
            SYMBOL_K285_N_CONST: result.data = 9'h1BC;

            SYMBOL_K280_P_CONST,
            SYMBOL_K280_N_CONST: result.data = 9'h11C;

            SYMBOL_K237_P_CONST,
            SYMBOL_K237_N_CONST: begin
                result.data = 9'h1F7;
                if ((sync_pattern != SYMBOL_K237_P_CONST) && (sync_pattern != SYMBOL_K237_N_CONST)) begin
                    result.error[1] = 1'b1;
                end
            end

            default: begin
                result.data     = {1'b0, symbol[7:0]};
                result.error[0] = 1'b1;
                result.legal    = 1'b0;
            end
        endcase

        if (symbol != sync_pattern) begin
            result.error[2] = 1'b1;
        end
        if (symbol == 10'h3FF) begin
            result.error[1] = 1'b1;
        end

        return result;
    endfunction

    function automatic logic lane_is_live(input int lane, input logic [31:0] lane_go);
        return (lane >= 0) && (lane < N_LANE_CLAMP_CONST) && lane_go[lane];
    endfunction

    function automatic int engine_for_lane(input int lane);
        int engine;

        if (N_ENGINE_CLAMP_CONST <= 1) begin
            engine = 0;
        end else if (N_ENGINE_CLAMP_CONST >= N_LANE_CLAMP_CONST) begin
            engine = lane;
        end else begin
            engine = (lane * N_ENGINE_CLAMP_CONST) / N_LANE_CLAMP_CONST;
        end

        return engine;
    endfunction

    // OPEN: the final CSR map should decide whether mode_mask is global or
    // two bits per lane. The current UVM plan writes 0/1/2 as a global mode.
    function automatic logic [1:0] lane_mode(input logic [31:0] mode_mask, input int lane);
        return mode_mask[1:0];
    endfunction

    assign csr_version_word = {
        int_to_u8(VERSION_MAJOR),
        int_to_u8(VERSION_MINOR),
        int_to_u4(VERSION_PATCH),
        int_to_u12(BUILD)
    };

    assign csr_capability_word = {
        int_to_u4(ROUTING_TOPOLOGY),
        int_to_u4(SCORE_WINDOW_CLAMP_CONST),
        int_to_u8(N_ENGINE_CLAMP_CONST),
        int_to_u8(N_LANE_CLAMP_CONST),
        int_to_u8(COUNTER_COUNT_CONST)
    };

    always_comb begin: csr_read_decode
        csr_read_mux = 32'd0;

        unique case (avs_csr_address)
            CSR_UID_ADDR_CONST:          csr_read_mux = IP_UID;
            CSR_CAPABILITY_ADDR_CONST:   csr_read_mux = csr_capability_word;
            CSR_SYNC_PATTERN_ADDR_CONST: csr_read_mux = {22'd0, csr.sync_pattern};
            CSR_LANE_GO_ADDR_CONST:      csr_read_mux = csr.lane_go;
            CSR_DPA_HOLD_ADDR_CONST:     csr_read_mux = csr.dpa_hold;
            CSR_SOFT_RESET_ADDR_CONST:   csr_read_mux = csr.soft_reset_req;
            CSR_MODE_MASK_ADDR_CONST:    csr_read_mux = csr.mode_mask;
            CSR_SCORE_ACCEPT_ADDR_CONST: csr_read_mux = {16'd0, csr.score_accept};
            CSR_SCORE_REJECT_ADDR_CONST: csr_read_mux = {16'd0, csr.score_reject};
            CSR_STEER_STATUS_ADDR_CONST: csr_read_mux = 32'd0;
            CSR_LANE_SELECT_ADDR_CONST:  csr_read_mux = {26'd0, csr.lane_select};
            CSR_META_ADDR_CONST: begin
                unique case (csr.meta_page)
                    2'd0:    csr_read_mux = csr_version_word;
                    2'd1:    csr_read_mux = VERSION_DATE;
                    2'd2:    csr_read_mux = VERSION_GIT;
                    default: csr_read_mux = INSTANCE_ID[31:0];
                endcase
            end
            CSR_COUNTER_BASE_ADDR_CONST + 10'd0: csr_read_mux = 32'd0;
            CSR_COUNTER_BASE_ADDR_CONST + 10'd1: csr_read_mux = 32'd0;
            CSR_COUNTER_BASE_ADDR_CONST + 10'd2: csr_read_mux = 32'd0;
            CSR_COUNTER_BASE_ADDR_CONST + 10'd3: csr_read_mux = 32'd0;
            CSR_COUNTER_BASE_ADDR_CONST + 10'd4: csr_read_mux = 32'd0;
            CSR_COUNTER_BASE_ADDR_CONST + 10'd5: csr_read_mux = 32'd0;
            CSR_COUNTER_BASE_ADDR_CONST + 10'd6: csr_read_mux = 32'd0;
            CSR_COUNTER_BASE_ADDR_CONST + 10'd7: csr_read_mux = 32'd0;
            CSR_COUNTER_BASE_ADDR_CONST + 10'd8: csr_read_mux = 32'd0;
            CSR_COUNTER_BASE_ADDR_CONST + 10'd9: csr_read_mux = 32'd0;
            default:                            csr_read_mux = 32'd0;
        endcase
    end

    always_ff @(posedge csi_control_clk) begin: csr_registers
        if (rsi_control_reset) begin
            csr.meta_page         <= 2'd0;
            csr.sync_pattern      <= SYNC_PATTERN;
            csr.lane_go           <= ACTIVE_LANE_MASK_CONST;
            csr.dpa_hold          <= 32'd0;
            csr.soft_reset_req    <= 32'd0;
            csr.mode_mask         <= 32'h0000_0000;
            csr.score_accept      <= clamp_score_accept(SCORE_ACCEPT);
            csr.score_reject      <= clamp_score_reject(SCORE_REJECT, clamp_score_accept(SCORE_ACCEPT));
            csr.lane_select       <= 6'd0;
            avs_csr_readdata      <= 32'd0;

            cfg_control_bus           <= data_cfg_default();
            cfg_req_toggle_control    <= 1'b0;
            cfg_resend_control        <= 1'b1;

            cfg_ack_toggle_control_d1    <= 1'b0;
            cfg_ack_toggle_control_d2    <= 1'b0;

            data_reset_control_d1    <= 1'b1;
            data_reset_control_d2    <= 1'b1;
            data_reset_control_d3    <= 1'b1;

            snapshot_req_toggle_control        <= 1'b0;
            snapshot_pending_control           <= 1'b0;
            snapshot_response_valid_control    <= 1'b0;
            snapshot_pending_addr_control      <= 10'd0;
            snapshot_lane_control              <= 6'd0;
            snapshot_timeout_control           <= 8'd0;
            snapshot_timed_out_control         <= 1'b0;

            snapshot_ack_toggle_control_d1      <= 1'b0;
            snapshot_ack_toggle_control_d2      <= 1'b0;
            snapshot_ack_toggle_control_seen    <= 1'b0;

            plllock_control_d1         <= 1'b0;
            plllock_control_d2         <= 1'b0;
            plllock_control_d3         <= 1'b0;
            pll_reset_count_control    <= PLL_RESET_CYCLES_CONST[3:0];
            coe_ctrl_pllrst            <= 1'b1;
            for (int lane_idx = 0; lane_idx < MAX_LANE_CONST; lane_idx++) begin
                soft_reset_hold_count[lane_idx] <= 4'd0;
            end
        end else begin
            plllock_control_d1    <= coe_ctrl_plllock;
            plllock_control_d2    <= plllock_control_d1;
            plllock_control_d3    <= plllock_control_d2;

            if (plllock_control_d3 && !plllock_control_d2) begin
                pll_reset_count_control    <= PLL_RESET_CYCLES_CONST[3:0];
                coe_ctrl_pllrst            <= 1'b1;
            end else if (pll_reset_count_control != 4'd0) begin
                pll_reset_count_control    <= pll_reset_count_control - 4'd1;
                coe_ctrl_pllrst            <= 1'b1;
            end else begin
                coe_ctrl_pllrst <= 1'b0;
            end

            cfg_ack_toggle_control_d1    <= cfg_ack_toggle_data;
            cfg_ack_toggle_control_d2    <= cfg_ack_toggle_control_d1;

            data_reset_control_d1    <= rsi_data_reset;
            data_reset_control_d2    <= data_reset_control_d1;
            data_reset_control_d3    <= data_reset_control_d2;

            snapshot_ack_toggle_control_d1    <= snapshot_ack_toggle_data;
            snapshot_ack_toggle_control_d2    <= snapshot_ack_toggle_control_d1;

            if (!snapshot_pending_control &&
                (snapshot_ack_toggle_control_d2 != snapshot_ack_toggle_control_seen)) begin
                snapshot_ack_toggle_control_seen    <= snapshot_ack_toggle_control_d2;
                snapshot_timed_out_control          <= 1'b0;
            end

            for (int lane_idx = 0; lane_idx < MAX_LANE_CONST; lane_idx++) begin
                if (csr.soft_reset_req[lane_idx]) begin
                    if (cfg_idle_control && cfg_control_bus.soft_reset_req[lane_idx]) begin
                        if (soft_reset_hold_count[lane_idx] >= SOFT_RESET_HOLD_CYCLES_CONST[3:0]) begin
                            csr.soft_reset_req[lane_idx]       <= 1'b0;
                            soft_reset_hold_count[lane_idx]    <= 4'd0;
                        end else begin
                            soft_reset_hold_count[lane_idx] <= soft_reset_hold_count[lane_idx] + 4'd1;
                        end
                    end
                end else begin
                    soft_reset_hold_count[lane_idx] <= 4'd0;
                end
            end

            if (data_reset_control_d3 && !data_reset_control_d2) begin
                cfg_resend_control <= 1'b1;
            end

            if (!avs_csr_waitrequest && avs_csr_write) begin
                unique case (avs_csr_address)
                    CSR_META_ADDR_CONST: begin
                        if (avs_csr_writedata <= 32'd3) begin
                            csr.meta_page <= avs_csr_writedata[1:0];
                        end
                    end
                    CSR_SYNC_PATTERN_ADDR_CONST: begin
                        if (sync_pattern_is_legal(avs_csr_writedata[9:0])) begin
                            csr.sync_pattern <= avs_csr_writedata[9:0];
                        end
                    end
                    CSR_LANE_GO_ADDR_CONST: begin
                        csr.lane_go <= avs_csr_writedata & ACTIVE_LANE_MASK_CONST;
                    end
                    CSR_DPA_HOLD_ADDR_CONST: begin
                        csr.dpa_hold <= avs_csr_writedata & ACTIVE_LANE_MASK_CONST;
                    end
                    CSR_SOFT_RESET_ADDR_CONST: begin
                        csr.soft_reset_req <= (csr.soft_reset_req | avs_csr_writedata) & ACTIVE_LANE_MASK_CONST;
                        for (int lane_idx = 0; lane_idx < MAX_LANE_CONST; lane_idx++) begin
                            if (avs_csr_writedata[lane_idx]) begin
                                soft_reset_hold_count[lane_idx] <= 4'd0;
                            end
                        end
                    end
                    CSR_MODE_MASK_ADDR_CONST: begin
                        csr.mode_mask <= avs_csr_writedata;
                    end
                    CSR_SCORE_ACCEPT_ADDR_CONST: begin
                        csr.score_accept    <= clamp_score_accept(avs_csr_writedata);
                        csr.score_reject    <= clamp_score_reject({16'd0, csr.score_reject}, clamp_score_accept(avs_csr_writedata));
                    end
                    CSR_SCORE_REJECT_ADDR_CONST: begin
                        csr.score_reject <= clamp_score_reject(avs_csr_writedata, csr.score_accept);
                    end
                    CSR_LANE_SELECT_ADDR_CONST: begin
                        if (avs_csr_writedata[31:0] >= N_LANE_CLAMP_CONST[31:0]) begin
                            csr.lane_select <= LAST_LANE_INDEX_CONST;
                        end else begin
                            csr.lane_select <= avs_csr_writedata[5:0];
                        end
                    end
                    default: begin
                    end
                endcase
            end

            if (cfg_idle_control &&
                (cfg_resend_control || (cfg_control_bus != data_cfg_from_csr(csr)))) begin
                cfg_control_bus           <= data_cfg_from_csr(csr);
                cfg_req_toggle_control    <= ~cfg_req_toggle_control;
                cfg_resend_control        <= 1'b0;
            end

            if (snapshot_pending_control) begin
                if (snapshot_ack_toggle_control_d2 != snapshot_ack_toggle_control_seen) begin
                    snapshot_ack_toggle_control_seen    <= snapshot_ack_toggle_control_d2;
                    avs_csr_readdata                    <= snapshot_read_word(
                        snapshot_pending_addr_control,
                        snapshot_status_data_bus,
                        snapshot_counter_data_bus
                    );
                    snapshot_pending_control           <= 1'b0;
                    snapshot_response_valid_control    <= 1'b1;
                    snapshot_timeout_control           <= 8'd0;
                    snapshot_timed_out_control         <= 1'b0;
                end else if (snapshot_timeout_control >= SNAPSHOT_TIMEOUT_CYCLES_CONST) begin
                    avs_csr_readdata                    <= snapshot_read_word(
                        snapshot_pending_addr_control,
                        snapshot_status_data_bus,
                        snapshot_counter_data_bus
                    );
                    snapshot_pending_control           <= 1'b0;
                    snapshot_response_valid_control    <= 1'b1;
                    snapshot_timeout_control           <= 8'd0;
                    snapshot_timed_out_control         <= 1'b1;
                end else begin
                    snapshot_timeout_control <= snapshot_timeout_control + 8'd1;
                end
            end else begin
                if (snapshot_response_valid_control &&
                    avs_csr_read &&
                    !avs_csr_waitrequest) begin
                    snapshot_response_valid_control <= 1'b0;
                end else if (snapshot_timed_out_control &&
                    avs_csr_read &&
                    csr_read_needs_snapshot(avs_csr_address) &&
                    !avs_csr_waitrequest) begin
                    avs_csr_readdata <= snapshot_read_word(
                        avs_csr_address,
                        snapshot_status_data_bus,
                        snapshot_counter_data_bus
                    );
                end else if (!snapshot_response_valid_control &&
                    !snapshot_timed_out_control &&
                    avs_csr_read &&
                    csr_read_needs_snapshot(avs_csr_address)) begin
                    snapshot_lane_control            <= csr.lane_select;
                    snapshot_pending_addr_control    <= avs_csr_address;
                    snapshot_timeout_control         <= 8'd0;
                    snapshot_req_toggle_control      <= ~snapshot_req_toggle_control;
                    snapshot_pending_control         <= 1'b1;
                end else if (avs_csr_read && !avs_csr_waitrequest) begin
                    avs_csr_readdata <= csr_read_mux;
                end
            end
        end
    end

    always_ff @(posedge csi_data_clk) begin: data_path
        decode_result_t data_v_decode;
        decode_result_t data_v_phase_decode;
        logic           data_v_lane_live;
        logic           data_v_error_event;
        logic           data_v_engine_request;
        logic [1:0]     data_v_mode;
        logic [9:0]     data_v_symbol;
        logic [9:0]     data_v_phase_symbol;
        logic [3:0]     data_v_scan_phase;
        logic [MAX_ENGINE_CONST - 1:0] data_v_engine_taken;
        logic [MAX_LANE_CONST - 1:0]   data_v_score_change_event;
        int             data_v_engine;
        int             data_v_attached_lane;

        if (rsi_data_reset) begin
            coe_ctrl_dparst        <= 32'hFFFF_FFFF;
            coe_ctrl_lockrst       <= 32'hFFFF_FFFF;
            coe_ctrl_dpahold       <= 32'hFFFF_FFFF;
            coe_ctrl_fiforst       <= 32'hFFFF_FFFF;
            coe_ctrl_bitslip       <= 32'd0;
            aso_decoded_valid      <= 32'd0;
            aso_decoded_data       <= '0;
            aso_decoded_error      <= '0;
            aso_decoded_channel    <= '0;

            lane_go_data_d1           <= ACTIVE_LANE_MASK_CONST;
            lane_go_data_d2           <= ACTIVE_LANE_MASK_CONST;
            dpa_hold_data_d1          <= 32'd0;
            dpa_hold_data_d2          <= 32'd0;
            soft_reset_req_data_d1    <= 32'd0;
            soft_reset_req_data_d2    <= 32'd0;
            soft_reset_req_data_d3    <= 32'd0;
            mode_mask_data_d1         <= 32'h0000_0000;
            mode_mask_data_d2         <= 32'h0000_0000;
            sync_pattern_data_d1      <= SYNC_PATTERN;
            sync_pattern_data_d2      <= SYNC_PATTERN;
            score_accept_data_d1      <= clamp_score_accept(SCORE_ACCEPT);
            score_accept_data_d2      <= clamp_score_accept(SCORE_ACCEPT);
            score_reject_data_d1      <= clamp_score_reject(SCORE_REJECT, clamp_score_accept(SCORE_ACCEPT));
            score_reject_data_d2      <= clamp_score_reject(SCORE_REJECT, clamp_score_accept(SCORE_ACCEPT));

            mini_valid_d1        <= '0;
            mini_data_d1         <= '0;
            mini_error_d1        <= '0;
            mini_channel_d1      <= '0;
            mini_valid_d2        <= '0;
            mini_data_d2         <= '0;
            mini_error_d2        <= '0;
            mini_channel_d2      <= '0;
            engine_valid_d1      <= '0;
            engine_data_d1       <= '0;
            engine_error_d1      <= '0;
            engine_channel_d1    <= '0;
            engine_valid_d2      <= '0;
            engine_data_d2       <= '0;
            engine_error_d2      <= '0;
            engine_channel_d2    <= '0;

            steer_state                     <= STEER_IDLING;
            steer_queue_count               <= 6'd0;
            steer_overflow_count            <= 32'd0;
            engine_attached                 <= '0;
            engine_busy                     <= '0;
            engine_attach_lane              <= '0;
            engine_score                    <= '0;
            engine_best_phase               <= '0;
            engine_best_score               <= '0;
            engine_score_scan_phase         <= '0;
            engine_score_symbol_d1          <= '0;
            engine_score_symbol_valid_d1    <= '0;
            engine_age                      <= '0;
            engine_attach_event             <= '0;

            lane_good_count           <= '0;
            lane_engine_seen          <= '0;
            lane_engine_request_d1    <= '0;
            lane_engine_error_d1      <= '0;
            score_change_event_d1     <= '0;
            loss_sync_d1              <= '0;
            dpalock_d1                <= '0;
            rollover_d1               <= '0;
            lane_counter              <= '0;

            cfg_data                    <= data_cfg_default();
            cfg_req_toggle_data_d1      <= 1'b0;
            cfg_req_toggle_data_d2      <= 1'b0;
            cfg_req_toggle_data_seen    <= 1'b0;
            cfg_ack_toggle_data         <= 1'b0;

            snapshot_req_toggle_data_d1      <= 1'b0;
            snapshot_req_toggle_data_d2      <= 1'b0;
            snapshot_req_toggle_data_seen    <= 1'b0;
            snapshot_ack_toggle_data         <= 1'b0;
            snapshot_status_data_bus         <= 32'd0;
            snapshot_counter_data_bus        <= '0;

            plllock_data_d1          <= 1'b0;
            plllock_data_d2          <= 1'b0;
            dpalock_data_d1          <= 32'd0;
            dpalock_data_d2          <= 32'd0;
            rollover_data_d1         <= 32'd0;
            rollover_data_d2         <= 32'd0;
            redriver_losn_data_d1    <= 32'hFFFF_FFFF;
            redriver_losn_data_d2    <= 32'hFFFF_FFFF;

            for (int lane_idx = 0; lane_idx < MAX_LANE_CONST; lane_idx++) begin
                train_state[lane_idx] <= TRAIN_IDLING;
            end
        end else begin
            cfg_req_toggle_data_d1    <= cfg_req_toggle_control;
            cfg_req_toggle_data_d2    <= cfg_req_toggle_data_d1;

            snapshot_req_toggle_data_d1    <= snapshot_req_toggle_control;
            snapshot_req_toggle_data_d2    <= snapshot_req_toggle_data_d1;

            plllock_data_d1          <= coe_ctrl_plllock;
            plllock_data_d2          <= plllock_data_d1;
            dpalock_data_d1          <= coe_ctrl_dpalock;
            dpalock_data_d2          <= dpalock_data_d1;
            rollover_data_d1         <= coe_ctrl_rollover;
            rollover_data_d2         <= rollover_data_d1;
            redriver_losn_data_d1    <= coe_redriver_losn;
            redriver_losn_data_d2    <= redriver_losn_data_d1;

            if (cfg_req_toggle_data_d2 != cfg_req_toggle_data_seen) begin
                cfg_data                    <= cfg_control_bus;
                cfg_req_toggle_data_seen    <= cfg_req_toggle_data_d2;
                cfg_ack_toggle_data         <= cfg_req_toggle_data_d2;
            end

            if (snapshot_req_toggle_data_d2 != snapshot_req_toggle_data_seen) begin
                snapshot_req_toggle_data_seen    <= snapshot_req_toggle_data_d2;
                snapshot_status_data_bus         <= {steer_overflow_count[15:0], 10'd0, steer_queue_count};
                snapshot_counter_data_bus        <= lane_counter[snapshot_lane_control];
                snapshot_ack_toggle_data         <= snapshot_req_toggle_data_d2;
            end

            lane_go_data_d1           <= cfg_data.lane_go;
            lane_go_data_d2           <= lane_go_data_d1;
            dpa_hold_data_d1          <= cfg_data.dpa_hold;
            dpa_hold_data_d2          <= dpa_hold_data_d1;
            soft_reset_req_data_d1    <= cfg_data.soft_reset_req;
            soft_reset_req_data_d2    <= soft_reset_req_data_d1;
            soft_reset_req_data_d3    <= soft_reset_req_data_d2;
            mode_mask_data_d1         <= cfg_data.mode_mask;
            mode_mask_data_d2         <= mode_mask_data_d1;
            sync_pattern_data_d1      <= cfg_data.sync_pattern;
            sync_pattern_data_d2      <= sync_pattern_data_d1;
            score_accept_data_d1      <= cfg_data.score_accept;
            score_accept_data_d2      <= score_accept_data_d1;
            score_reject_data_d1      <= cfg_data.score_reject;
            score_reject_data_d2      <= score_reject_data_d1;

            coe_ctrl_bitslip       <= 32'd0;
            engine_attach_event    <= '0;
            engine_valid_d1        <= '0;
            engine_data_d1         <= '0;
            engine_error_d1        <= '0;
            engine_channel_d1      <= '0;

            data_v_engine_taken = engine_busy;
            data_v_score_change_event = '0;
            dpalock_d1     <= dpalock_data_d2;
            rollover_d1    <= rollover_data_d2;

            for (int lane_idx = 0; lane_idx < MAX_LANE_CONST; lane_idx++) begin
                data_v_symbol     = coe_parallel_data[lane_idx * 10 +: 10];
                data_v_decode     = decode_symbol(data_v_symbol, sync_pattern_data_d2);
                data_v_lane_live  = lane_is_live(lane_idx, lane_go_data_d2) &&
                                    plllock_data_d2 &&
                                    redriver_losn_data_d2[lane_idx];
                data_v_error_event = data_v_lane_live &&
                                     dpalock_data_d2[lane_idx] &&
                                     (data_v_decode.error != 3'b000);
                data_v_mode = lane_mode(mode_mask_data_d2, lane_idx);
                data_v_engine_request = 1'b0;
                if ((data_v_mode != MODE_BITSLIPPING_CONST) && data_v_error_event) begin
                    data_v_engine_request = 1'b1;
                end
                if (((data_v_mode == MODE_ADAPTING_CONST) || (data_v_mode == MODE_AUTOING_CONST)) &&
                    data_v_lane_live &&
                    dpalock_data_d2[lane_idx] &&
                    !lane_engine_seen[lane_idx] &&
                    !data_v_decode.error[2] &&
                    (lane_good_count[lane_idx] >= score_accept_data_d2[7:0])) begin
                    data_v_engine_request = 1'b1;
                end

                mini_valid_d1[lane_idx]             <= data_v_lane_live && dpalock_data_d2[lane_idx];
                mini_data_d1[lane_idx]              <= data_v_decode.data;
                mini_error_d1[lane_idx]             <= data_v_decode.error;
                mini_channel_d1[lane_idx]           <= lane_idx[5:0];
                lane_engine_request_d1[lane_idx]    <= data_v_engine_request;
                lane_engine_error_d1[lane_idx]      <= data_v_error_event;

                mini_valid_d2[lane_idx]      <= mini_valid_d1[lane_idx];
                mini_data_d2[lane_idx]       <= mini_data_d1[lane_idx];
                mini_error_d2[lane_idx]      <= mini_error_d1[lane_idx];
                mini_channel_d2[lane_idx]    <= mini_channel_d1[lane_idx];

                engine_valid_d2[lane_idx]      <= engine_valid_d1[lane_idx];
                engine_data_d2[lane_idx]       <= engine_data_d1[lane_idx];
                engine_error_d2[lane_idx]      <= engine_error_d1[lane_idx];
                engine_channel_d2[lane_idx]    <= engine_channel_d1[lane_idx];

                if (lane_idx >= N_LANE_CLAMP_CONST) begin
                    train_state[lane_idx]         <= TRAIN_IDLING;
                    lane_good_count[lane_idx]     <= 8'd0;
                    lane_engine_seen[lane_idx]    <= 1'b0;
                    coe_ctrl_dparst[lane_idx]     <= 1'b0;
                    coe_ctrl_lockrst[lane_idx]    <= 1'b0;
                    coe_ctrl_dpahold[lane_idx]    <= 1'b0;
                    coe_ctrl_fiforst[lane_idx]    <= 1'b0;
                end else if (!lane_go_data_d2[lane_idx]) begin
                    train_state[lane_idx]         <= TRAIN_IDLING;
                    lane_good_count[lane_idx]     <= 8'd0;
                    lane_engine_seen[lane_idx]    <= 1'b0;
                    coe_ctrl_dparst[lane_idx]     <= 1'b1;
                    coe_ctrl_lockrst[lane_idx]    <= 1'b1;
                    coe_ctrl_dpahold[lane_idx]    <= 1'b0;
                    coe_ctrl_fiforst[lane_idx]    <= 1'b1;
                end else if (soft_reset_rise[lane_idx]) begin
                    train_state[lane_idx]         <= TRAIN_RESETTING_DPA;
                    lane_good_count[lane_idx]     <= 8'd0;
                    lane_engine_seen[lane_idx]    <= 1'b0;
                    coe_ctrl_dparst[lane_idx]     <= 1'b1;
                    coe_ctrl_lockrst[lane_idx]    <= 1'b1;
                    coe_ctrl_dpahold[lane_idx]    <= 1'b0;
                    coe_ctrl_fiforst[lane_idx]    <= 1'b1;
                    for (int counter_idx = 0; counter_idx < COUNTER_COUNT_CONST; counter_idx++) begin
                        lane_counter[lane_idx][counter_idx] <= 32'd0;
                    end
                    lane_counter[lane_idx][COUNTER_SOFT_RESETS_CONST] <=
                        saturating_inc(lane_counter[lane_idx][COUNTER_SOFT_RESETS_CONST]);
                end else if (!plllock_data_d2 || !redriver_losn_data_d2[lane_idx]) begin
                    train_state[lane_idx]         <= TRAIN_WAITING_PLL;
                    lane_good_count[lane_idx]     <= 8'd0;
                    lane_engine_seen[lane_idx]    <= 1'b0;
                    coe_ctrl_dparst[lane_idx]     <= 1'b1;
                    coe_ctrl_lockrst[lane_idx]    <= 1'b1;
                    coe_ctrl_dpahold[lane_idx]    <= 1'b0;
                    coe_ctrl_fiforst[lane_idx]    <= 1'b1;
                end else if (!dpalock_data_d2[lane_idx]) begin
                    train_state[lane_idx]         <= TRAIN_WAITING_DPA;
                    lane_good_count[lane_idx]     <= 8'd0;
                    lane_engine_seen[lane_idx]    <= 1'b0;
                    coe_ctrl_dparst[lane_idx]     <= 1'b0;
                    coe_ctrl_lockrst[lane_idx]    <= 1'b0;
                    coe_ctrl_dpahold[lane_idx]    <= 1'b0;
                    coe_ctrl_fiforst[lane_idx]    <= 1'b1;
                end else if (data_v_decode.error[2]) begin
                    train_state[lane_idx]         <= TRAIN_BITSLIPPING;
                    lane_good_count[lane_idx]     <= 8'd0;
                    coe_ctrl_dparst[lane_idx]     <= 1'b0;
                    coe_ctrl_lockrst[lane_idx]    <= 1'b0;
                    coe_ctrl_dpahold[lane_idx]    <= dpa_hold_data_d2[lane_idx];
                    coe_ctrl_fiforst[lane_idx]    <= 1'b0;
                    if (!dpa_hold_data_d2[lane_idx]) begin
                        coe_ctrl_bitslip[lane_idx]                              <= 1'b1;
                        lane_counter[lane_idx][COUNTER_BITSLIP_EVENTS_CONST]    <=
                            saturating_inc(lane_counter[lane_idx][COUNTER_BITSLIP_EVENTS_CONST]);
                    end
                end else begin
                    coe_ctrl_dparst[lane_idx]     <= 1'b0;
                    coe_ctrl_lockrst[lane_idx]    <= 1'b0;
                    coe_ctrl_dpahold[lane_idx]    <= dpa_hold_data_d2[lane_idx];
                    coe_ctrl_fiforst[lane_idx]    <= !dpalock_d1[lane_idx] && dpalock_data_d2[lane_idx];

                    if (!dpa_hold_data_d2[lane_idx] &&
                        (lane_good_count[lane_idx] < score_accept_data_d2[7:0])) begin
                        lane_good_count[lane_idx]    <= lane_good_count[lane_idx] + 8'd1;
                        train_state[lane_idx]        <= TRAIN_LOCKING;
                    end else begin
                        train_state[lane_idx]     <= TRAIN_HOLDING_LOCK;
                    end
                end

                if (data_v_lane_live && dpalock_data_d2[lane_idx]) begin
                    if (data_v_decode.error[0]) begin
                        lane_counter[lane_idx][COUNTER_CODE_VIOLATIONS_CONST] <=
                            saturating_inc(lane_counter[lane_idx][COUNTER_CODE_VIOLATIONS_CONST]);
                    end
                    if (data_v_decode.error[1]) begin
                        lane_counter[lane_idx][COUNTER_DISP_VIOLATIONS_CONST] <=
                            saturating_inc(lane_counter[lane_idx][COUNTER_DISP_VIOLATIONS_CONST]);
                    end
                    if (!loss_sync_d1[lane_idx] && data_v_decode.error[2]) begin
                        lane_counter[lane_idx][COUNTER_COMMA_LOSSES_CONST] <=
                            saturating_inc(lane_counter[lane_idx][COUNTER_COMMA_LOSSES_CONST]);
                    end
                    if (train_state[lane_idx] == TRAIN_HOLDING_LOCK && !data_v_decode.error[2]) begin
                        lane_counter[lane_idx][COUNTER_UPTIME_CONST] <=
                            saturating_inc(lane_counter[lane_idx][COUNTER_UPTIME_CONST]);
                    end
                end

                if (dpalock_d1[lane_idx] && !dpalock_data_d2[lane_idx]) begin
                    lane_counter[lane_idx][COUNTER_DPA_UNLOCKS_CONST] <=
                        saturating_inc(lane_counter[lane_idx][COUNTER_DPA_UNLOCKS_CONST]);
                end
                if (!rollover_d1[lane_idx] && rollover_data_d2[lane_idx]) begin
                    lane_counter[lane_idx][COUNTER_REALIGNS_CONST] <=
                        saturating_inc(lane_counter[lane_idx][COUNTER_REALIGNS_CONST]);
                end
                if (score_change_event_d1[lane_idx] && !soft_reset_rise[lane_idx]) begin
                    lane_counter[lane_idx][COUNTER_SCORE_CHANGES_CONST] <=
                        saturating_inc(lane_counter[lane_idx][COUNTER_SCORE_CHANGES_CONST]);
                end

                if (lane_engine_request_d1[lane_idx] &&
                    lane_is_live(lane_idx, lane_go_data_d2) &&
                    plllock_data_d2 &&
                    redriver_losn_data_d2[lane_idx] &&
                    dpalock_data_d2[lane_idx]) begin
                    data_v_engine = engine_for_lane(lane_idx);
                    if (!data_v_engine_taken[data_v_engine] ||
                        lane_engine_error_d1[lane_idx] ||
                        (engine_attach_lane[data_v_engine] == lane_idx[5:0])) begin
                        if (!engine_busy[data_v_engine] ||
                            lane_engine_error_d1[lane_idx]) begin
                            data_v_engine_taken[data_v_engine]                       = 1'b1;
                            engine_busy[data_v_engine]                            <= 1'b1;
                            engine_attached[data_v_engine]                        <= 1'b1;
                            engine_attach_lane[data_v_engine]                     <= lane_idx[5:0];
                            engine_best_score[data_v_engine]                      <= '0;
                            engine_score_scan_phase[data_v_engine]                <= 4'd0;
                            engine_score_symbol_valid_d1[data_v_engine]           <= 1'b0;
                            engine_age[data_v_engine]                             <= 16'd0;
                            engine_attach_event[data_v_engine]                    <= 1'b1;
                            lane_engine_seen[lane_idx]                            <= 1'b1;
                            lane_counter[lane_idx][COUNTER_ENGINE_STEER_CONST]    <=
                                saturating_inc(lane_counter[lane_idx][COUNTER_ENGINE_STEER_CONST]);
                            steer_state                            <= STEER_ATTACHING;
                        end
                    end else begin
                        steer_state <= STEER_SCANNING;
                        if (steer_queue_count < STEER_QUEUE_DEPTH_CONST[5:0]) begin
                            steer_queue_count <= steer_queue_count + 6'd1;
                        end else begin
                            steer_overflow_count <= saturating_inc(steer_overflow_count);
                        end
                    end
                end

                loss_sync_d1[lane_idx] <= data_v_decode.error[2];
            end

            for (int engine_idx = 0; engine_idx < MAX_ENGINE_CONST; engine_idx++) begin
                if (engine_idx >= N_ENGINE_CLAMP_CONST) begin
                    engine_busy[engine_idx]                     <= 1'b0;
                    engine_attached[engine_idx]                 <= 1'b0;
                    engine_attach_lane[engine_idx]              <= '0;
                    engine_age[engine_idx]                      <= '0;
                    engine_score[engine_idx]                    <= '0;
                    engine_best_phase[engine_idx]               <= 4'd0;
                    engine_best_score[engine_idx]               <= '0;
                    engine_score_scan_phase[engine_idx]         <= 4'd0;
                    engine_score_symbol_d1[engine_idx]          <= '0;
                    engine_score_symbol_valid_d1[engine_idx]    <= 1'b0;
                end else if (engine_busy[engine_idx]) begin
                    data_v_attached_lane = engine_attach_lane[engine_idx];
                    data_v_symbol        = coe_parallel_data[data_v_attached_lane * 10 +: 10];
                    data_v_decode        = decode_symbol(data_v_symbol, sync_pattern_data_d2);
                    data_v_scan_phase    = engine_score_scan_phase[engine_idx];

                    engine_score_symbol_d1[engine_idx]          <= data_v_symbol;
                    engine_score_symbol_valid_d1[engine_idx]    <= 1'b1;

                    if (engine_score_symbol_valid_d1[engine_idx]) begin
                        for (int phase_idx = 0; phase_idx < SCORE_PHASE_COUNT_CONST; phase_idx++) begin
                            data_v_phase_symbol = rotate_symbol(engine_score_symbol_d1[engine_idx], phase_idx);
                            data_v_phase_decode = decode_symbol(data_v_phase_symbol, sync_pattern_data_d2);
                            if (!data_v_phase_decode.error[0] && !data_v_phase_decode.error[2]) begin
                                engine_score[engine_idx][phase_idx] <=
                                    saturating_score_inc(engine_score[engine_idx][phase_idx]);
                            end else begin
                                engine_score[engine_idx][phase_idx] <=
                                    score_decay(engine_score[engine_idx][phase_idx]);
                            end
                        end

                        if (engine_score[engine_idx][data_v_scan_phase] > engine_best_score[engine_idx]) begin
                            engine_best_score[engine_idx] <= engine_score[engine_idx][data_v_scan_phase];
                            if (engine_best_phase[engine_idx] != data_v_scan_phase) begin
                                engine_best_phase[engine_idx]                 <= data_v_scan_phase;
                                data_v_score_change_event[data_v_attached_lane] = 1'b1;
                            end
                        end
                        if (data_v_scan_phase >= (SCORE_PHASE_COUNT_CONST - 1)) begin
                            engine_score_scan_phase[engine_idx] <= 4'd0;
                        end else begin
                            engine_score_scan_phase[engine_idx] <= data_v_scan_phase + 4'd1;
                        end
                    end

                    engine_valid_d1[data_v_attached_lane]      <= mini_valid_d1[data_v_attached_lane];
                    engine_data_d1[data_v_attached_lane]       <= data_v_decode.data;
                    engine_error_d1[data_v_attached_lane]      <= data_v_decode.error;
                    engine_channel_d1[data_v_attached_lane]    <= data_v_attached_lane[5:0];
                    engine_age[engine_idx]                     <= engine_age[engine_idx] + 16'd1;

                    if (soft_reset_req_data_d2[data_v_attached_lane] ||
                        !lane_go_data_d2[data_v_attached_lane] ||
                        (engine_age[engine_idx] >= {1'b0, score_accept_data_d2[14:0]}) ||
                        (engine_best_score[engine_idx] >= score_accept_data_d2)) begin
                        engine_busy[engine_idx]                     <= 1'b0;
                        engine_attached[engine_idx]                 <= 1'b0;
                        engine_age[engine_idx]                      <= 16'd0;
                        engine_best_score[engine_idx]               <= '0;
                        engine_score_scan_phase[engine_idx]         <= 4'd0;
                        engine_score_symbol_valid_d1[engine_idx]    <= 1'b0;
                        if (steer_queue_count != 6'd0) begin
                            steer_queue_count <= steer_queue_count - 6'd1;
                        end
                        steer_state <= STEER_RELEASING;
                    end
                end
            end
            score_change_event_d1 <= data_v_score_change_event;

            if ((engine_busy & ACTIVE_ENGINE_MASK_CONST) == '0) begin
                if (steer_queue_count == 6'd0) begin
                    steer_state <= STEER_IDLING;
                end
            end

            for (int lane_idx = 0; lane_idx < MAX_LANE_CONST; lane_idx++) begin
                if (lane_idx >= N_LANE_CLAMP_CONST) begin
                    aso_decoded_valid[lane_idx]      <= 1'b0;
                    aso_decoded_data[lane_idx]       <= 9'd0;
                    aso_decoded_error[lane_idx]      <= 3'd0;
                    aso_decoded_channel[lane_idx]    <= lane_idx[5:0];
                end else if (!aso_decoded_valid[lane_idx] || aso_decoded_ready[lane_idx]) begin
                    if (engine_valid_d2[lane_idx]) begin
                        aso_decoded_valid[lane_idx]      <= engine_valid_d2[lane_idx];
                        aso_decoded_data[lane_idx]       <= engine_data_d2[lane_idx];
                        aso_decoded_error[lane_idx]      <= engine_error_d2[lane_idx];
                        aso_decoded_channel[lane_idx]    <= engine_channel_d2[lane_idx];
                    end else begin
                        aso_decoded_valid[lane_idx]      <= mini_valid_d2[lane_idx];
                        aso_decoded_data[lane_idx]       <= mini_data_d2[lane_idx];
                        aso_decoded_error[lane_idx]      <= mini_error_d2[lane_idx];
                        aso_decoded_channel[lane_idx]    <= mini_channel_d2[lane_idx];
                    end
                end
            end

`ifdef LVDS_DV_DEBUG
            if (dv_debug_counter_we &&
                (int'(dv_debug_counter_lane) < MAX_LANE_CONST) &&
                (int'(dv_debug_counter_idx) < COUNTER_COUNT_CONST)) begin
                lane_counter[dv_debug_counter_lane][dv_debug_counter_idx] <= dv_debug_counter_value;
            end
            if (dv_debug_engine_attach_we &&
                (int'(dv_debug_engine_idx) < MAX_ENGINE_CONST) &&
                (int'(dv_debug_engine_lane) < MAX_LANE_CONST)) begin
                engine_busy[dv_debug_engine_idx]                     <= 1'b1;
                engine_attached[dv_debug_engine_idx]                 <= 1'b1;
                engine_attach_lane[dv_debug_engine_idx]              <= dv_debug_engine_lane;
                engine_best_score[dv_debug_engine_idx]               <= '0;
                engine_score_scan_phase[dv_debug_engine_idx]         <= 4'd0;
                engine_score_symbol_valid_d1[dv_debug_engine_idx]    <= 1'b0;
                engine_age[dv_debug_engine_idx]                      <= 16'd0;
            end
            if (dv_debug_engine_score_we &&
                (int'(dv_debug_engine_score_idx) < MAX_ENGINE_CONST) &&
                (int'(dv_debug_engine_score_phase) < SCORE_PHASE_COUNT_CONST)) begin
                engine_score[dv_debug_engine_score_idx][dv_debug_engine_score_phase] <= dv_debug_engine_score_value;
            end
            if (dv_debug_engine_age_we &&
                (int'(dv_debug_engine_age_idx) < MAX_ENGINE_CONST)) begin
                engine_age[dv_debug_engine_age_idx] <= dv_debug_engine_age_value;
            end
`endif
        end
    end
endmodule
