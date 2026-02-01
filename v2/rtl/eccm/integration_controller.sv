//-----------------------------------------------------------------------------
// QEDMMA v2.0 Adaptive Integration Controller
// Author: Dr. Mladen Mešter
// Copyright (c) 2026 Dr. Mladen Mešter - All Rights Reserved
//
// Description:
//   Dynamically adjusts coherent integration time based on detected
//   jamming level. Provides +3 to +7 dB additional processing gain
//   when under electronic attack.
//
//   Integration Modes:
//   - BASELINE: 10 pulses, T_chirp = 100 ms (CPI = 1 s)
//   - ENHANCED: 20 pulses, T_chirp = 200 ms (CPI = 4 s, +3 dB)
//   - MAXIMUM:  50 pulses, T_chirp = 500 ms (CPI = 25 s, +7 dB)
//
// [REQ-ECCM-010] Adaptive integration based on J/S ratio
// [REQ-ECCM-011] Maintain track update rate constraints
// [REQ-ECCM-012] Seamless mode transitions
//-----------------------------------------------------------------------------

`timescale 1ns / 1ps

module integration_controller #(
    parameter int DATA_WIDTH = 32
)(
    input  logic        clk,
    input  logic        rst_n,
    
    //-------------------------------------------------------------------------
    // Jamming Metrics Input (from ML-CFAR)
    //-------------------------------------------------------------------------
    input  logic [DATA_WIDTH-1:0]  jam_power_estimate,
    input  logic [7:0]             jam_duty_cycle,
    input  logic                   jam_detected,
    input  logic [1:0]             jam_type,
    
    // Signal metrics (from detector)
    input  logic [DATA_WIDTH-1:0]  signal_power_estimate,
    input  logic [7:0]             current_snr_db,
    
    //-------------------------------------------------------------------------
    // Waveform Generator Control
    //-------------------------------------------------------------------------
    output logic [7:0]             cfg_n_pulses,      // Number of pulses per CPI
    output logic [31:0]            cfg_t_chirp_us,    // Chirp duration (microseconds)
    output logic [31:0]            cfg_pri_us,        // Pulse repetition interval
    output logic [31:0]            cfg_cpi_ms,        // Coherent processing interval
    output logic                   cfg_update_valid,  // New config available
    
    //-------------------------------------------------------------------------
    // Integration Mode Status
    //-------------------------------------------------------------------------
    output logic [1:0]             integration_mode,  // 0=baseline, 1=enhanced, 2=maximum
    output logic [7:0]             effective_gain_db, // Additional gain from integration
    output logic                   mode_transition,   // Mode is changing
    
    //-------------------------------------------------------------------------
    // Track Manager Interface
    //-------------------------------------------------------------------------
    input  logic [9:0]             active_track_count,
    input  logic                   priority_track_present,
    output logic                   track_update_inhibit,  // Suppress updates during long CPI
    
    //-------------------------------------------------------------------------
    // Configuration
    //-------------------------------------------------------------------------
    input  logic [7:0]             cfg_js_threshold_high,  // J/S for max integration (dB×4)
    input  logic [7:0]             cfg_js_threshold_low,   // J/S for enhanced (dB×4)
    input  logic [7:0]             cfg_min_snr_target,     // Target SNR for detection (dB×4)
    input  logic                   cfg_auto_mode_enable,   // Allow automatic mode switching
    input  logic [1:0]             cfg_manual_mode,        // Force specific mode
    
    //-------------------------------------------------------------------------
    // Status
    //-------------------------------------------------------------------------
    output logic [7:0]             current_js_ratio_db,
    output logic [31:0]            mode_transitions_count,
    output logic [31:0]            time_in_jam_mode_ms
);

    //-------------------------------------------------------------------------
    // Integration Mode Definitions
    //-------------------------------------------------------------------------
    localparam logic [1:0] MODE_BASELINE = 2'b00;
    localparam logic [1:0] MODE_ENHANCED = 2'b01;
    localparam logic [1:0] MODE_MAXIMUM  = 2'b10;
    localparam logic [1:0] MODE_RESERVED = 2'b11;
    
    // Mode parameters
    // BASELINE: 10 pulses × 100 ms = 1 s CPI, 10 dB integration gain
    // ENHANCED: 20 pulses × 200 ms = 4 s CPI, 13 dB integration gain (+3 dB)
    // MAXIMUM:  50 pulses × 500 ms = 25 s CPI, 17 dB integration gain (+7 dB)
    
    localparam logic [7:0]  BASELINE_N_PULSES  = 8'd10;
    localparam logic [31:0] BASELINE_T_CHIRP   = 32'd100_000;  // 100 ms in µs
    localparam logic [31:0] BASELINE_PRI       = 32'd100_000;  // 100 ms
    localparam logic [31:0] BASELINE_CPI       = 32'd1000;     // 1000 ms
    localparam logic [7:0]  BASELINE_GAIN      = 8'd10;        // 10 dB
    
    localparam logic [7:0]  ENHANCED_N_PULSES  = 8'd20;
    localparam logic [31:0] ENHANCED_T_CHIRP   = 32'd200_000;  // 200 ms
    localparam logic [31:0] ENHANCED_PRI       = 32'd200_000;
    localparam logic [31:0] ENHANCED_CPI       = 32'd4000;     // 4000 ms
    localparam logic [7:0]  ENHANCED_GAIN      = 8'd13;        // 13 dB
    
    localparam logic [7:0]  MAXIMUM_N_PULSES   = 8'd50;
    localparam logic [31:0] MAXIMUM_T_CHIRP    = 32'd500_000;  // 500 ms
    localparam logic [31:0] MAXIMUM_PRI        = 32'd500_000;
    localparam logic [31:0] MAXIMUM_CPI        = 32'd25000;    // 25000 ms
    localparam logic [7:0]  MAXIMUM_GAIN       = 8'd17;        // 17 dB
    
    //-------------------------------------------------------------------------
    // J/S Ratio Calculation
    //-------------------------------------------------------------------------
    logic [7:0] js_ratio_db;
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            js_ratio_db <= '0;
        end else if (signal_power_estimate > 0) begin
            // Approximate log2 for dB calculation
            // J/S (dB) ≈ 3 × log2(J/S) ≈ 3 × (log2(J) - log2(S))
            automatic logic [5:0] log2_jam = $clog2(jam_power_estimate + 1);
            automatic logic [5:0] log2_sig = $clog2(signal_power_estimate + 1);
            
            if (log2_jam > log2_sig)
                js_ratio_db <= (log2_jam - log2_sig) * 3;  // Positive J/S
            else
                js_ratio_db <= 8'd0;  // Signal stronger than jam
        end else begin
            js_ratio_db <= jam_detected ? 8'd60 : 8'd0;  // Assume high J/S if no signal
        end
    end
    
    assign current_js_ratio_db = js_ratio_db;
    
    //-------------------------------------------------------------------------
    // Mode Decision Logic
    //-------------------------------------------------------------------------
    logic [1:0] desired_mode;
    logic [1:0] current_mode;
    logic       mode_change_pending;
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            desired_mode <= MODE_BASELINE;
        end else if (cfg_auto_mode_enable) begin
            // Automatic mode selection based on J/S ratio
            if (js_ratio_db >= cfg_js_threshold_high) begin
                // High jamming - need maximum integration
                desired_mode <= MODE_MAXIMUM;
            end else if (js_ratio_db >= cfg_js_threshold_low) begin
                // Moderate jamming - enhanced integration
                desired_mode <= MODE_ENHANCED;
            end else begin
                // Low/no jamming - baseline is sufficient
                desired_mode <= MODE_BASELINE;
            end
            
            // Override: if we have many tracks or priority target, limit to enhanced
            if ((active_track_count > 50 || priority_track_present) && 
                desired_mode == MODE_MAXIMUM) begin
                desired_mode <= MODE_ENHANCED;
            end
        end else begin
            // Manual mode override
            desired_mode <= cfg_manual_mode;
        end
    end
    
    //-------------------------------------------------------------------------
    // Mode Transition State Machine
    //-------------------------------------------------------------------------
    typedef enum logic [2:0] {
        ST_IDLE,
        ST_WAIT_CPI_END,
        ST_APPLY_NEW_MODE,
        ST_STABILIZE
    } transition_state_t;
    
    transition_state_t trans_state;
    logic [15:0] stabilize_counter;
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            trans_state       <= ST_IDLE;
            current_mode      <= MODE_BASELINE;
            mode_change_pending <= 1'b0;
            stabilize_counter <= '0;
            mode_transitions_count <= '0;
        end else begin
            case (trans_state)
                ST_IDLE: begin
                    mode_change_pending <= 1'b0;
                    if (desired_mode != current_mode) begin
                        mode_change_pending <= 1'b1;
                        trans_state <= ST_WAIT_CPI_END;
                    end
                end
                
                ST_WAIT_CPI_END: begin
                    // Wait for current CPI to complete before changing
                    // This is signaled by external waveform controller
                    // For now, assume immediate transition allowed
                    trans_state <= ST_APPLY_NEW_MODE;
                end
                
                ST_APPLY_NEW_MODE: begin
                    current_mode <= desired_mode;
                    mode_transitions_count <= mode_transitions_count + 1;
                    stabilize_counter <= '0;
                    trans_state <= ST_STABILIZE;
                end
                
                ST_STABILIZE: begin
                    // Allow system to stabilize in new mode
                    stabilize_counter <= stabilize_counter + 1;
                    if (stabilize_counter >= 16'd1000) begin  // ~10 µs at 100 MHz
                        trans_state <= ST_IDLE;
                    end
                end
                
                default: trans_state <= ST_IDLE;
            endcase
        end
    end
    
    assign mode_transition = (trans_state != ST_IDLE);
    assign integration_mode = current_mode;
    
    //-------------------------------------------------------------------------
    // Output Configuration Generation
    //-------------------------------------------------------------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cfg_n_pulses     <= BASELINE_N_PULSES;
            cfg_t_chirp_us   <= BASELINE_T_CHIRP;
            cfg_pri_us       <= BASELINE_PRI;
            cfg_cpi_ms       <= BASELINE_CPI;
            cfg_update_valid <= 1'b0;
            effective_gain_db <= BASELINE_GAIN;
        end else if (trans_state == ST_APPLY_NEW_MODE) begin
            case (desired_mode)
                MODE_BASELINE: begin
                    cfg_n_pulses     <= BASELINE_N_PULSES;
                    cfg_t_chirp_us   <= BASELINE_T_CHIRP;
                    cfg_pri_us       <= BASELINE_PRI;
                    cfg_cpi_ms       <= BASELINE_CPI;
                    effective_gain_db <= BASELINE_GAIN;
                end
                
                MODE_ENHANCED: begin
                    cfg_n_pulses     <= ENHANCED_N_PULSES;
                    cfg_t_chirp_us   <= ENHANCED_T_CHIRP;
                    cfg_pri_us       <= ENHANCED_PRI;
                    cfg_cpi_ms       <= ENHANCED_CPI;
                    effective_gain_db <= ENHANCED_GAIN;
                end
                
                MODE_MAXIMUM: begin
                    cfg_n_pulses     <= MAXIMUM_N_PULSES;
                    cfg_t_chirp_us   <= MAXIMUM_T_CHIRP;
                    cfg_pri_us       <= MAXIMUM_PRI;
                    cfg_cpi_ms       <= MAXIMUM_CPI;
                    effective_gain_db <= MAXIMUM_GAIN;
                end
                
                default: begin
                    cfg_n_pulses     <= BASELINE_N_PULSES;
                    cfg_t_chirp_us   <= BASELINE_T_CHIRP;
                    cfg_pri_us       <= BASELINE_PRI;
                    cfg_cpi_ms       <= BASELINE_CPI;
                    effective_gain_db <= BASELINE_GAIN;
                end
            endcase
            cfg_update_valid <= 1'b1;
        end else begin
            cfg_update_valid <= 1'b0;
        end
    end
    
    //-------------------------------------------------------------------------
    // Track Update Inhibit
    //-------------------------------------------------------------------------
    // In maximum mode, track updates may be delayed due to long CPI
    assign track_update_inhibit = (current_mode == MODE_MAXIMUM) && mode_transition;
    
    //-------------------------------------------------------------------------
    // Time in Jam Mode Counter
    //-------------------------------------------------------------------------
    logic [31:0] jam_mode_counter;
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            time_in_jam_mode_ms <= '0;
            jam_mode_counter    <= '0;
        end else begin
            if (current_mode != MODE_BASELINE) begin
                // Count time in enhanced/maximum modes
                jam_mode_counter <= jam_mode_counter + 1;
                if (jam_mode_counter >= 32'd100_000) begin  // 1 ms at 100 MHz
                    time_in_jam_mode_ms <= time_in_jam_mode_ms + 1;
                    jam_mode_counter <= '0;
                end
            end
        end
    end

endmodule
