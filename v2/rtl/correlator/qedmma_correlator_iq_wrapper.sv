//=============================================================================
// QEDMMA v3.2 - Complete I/Q Dual-Channel Correlator Wrapper
// [REQ-IQ-001] Dual I/Q channel processing
// [REQ-MAG-001] Magnitude computation (|I| + |Q|)
// [REQ-PEAK-001] Global peak detection across all lanes
//
// Author: Dr. Mladen Mešter
// Copyright (c) 2026 - All Rights Reserved
//
// Top-level wrapper integrating:
//   - Dual I/Q correlator banks
//   - Magnitude computation
//   - Peak detection
//   - PISO serialization
//   - AXI-Stream output
//=============================================================================

`timescale 1ns / 1ps

module qedmma_correlator_iq_wrapper #(
    parameter int NUM_LANES      = 512,
    parameter int DATA_WIDTH     = 16,
    parameter int ACC_WIDTH      = 48,
    parameter int AXI_DATA_WIDTH = 64
)(
    input  logic                          clk,
    input  logic                          rst_n,
    
    //=========================================================================
    // ADC Input (I/Q from frontend)
    //=========================================================================
    input  logic signed [DATA_WIDTH-1:0]  i_adc_i,
    input  logic signed [DATA_WIDTH-1:0]  i_adc_q,
    input  logic                          i_valid,
    
    //=========================================================================
    // Control
    //=========================================================================
    input  logic                          i_dump_trigger,
    input  logic [19:0]                   i_lfsr_seed,
    input  logic                          i_seed_load,
    input  logic                          i_enable,
    
    //=========================================================================
    // AXI-Stream Output (I, Q, and Magnitude)
    //=========================================================================
    output logic [AXI_DATA_WIDTH-1:0]     m_axis_tdata,
    output logic                          m_axis_tvalid,
    output logic                          m_axis_tlast,
    output logic [1:0]                    m_axis_tid,       // 0=I, 1=Q, 2=Mag
    input  logic                          m_axis_tready,
    
    //=========================================================================
    // Status
    //=========================================================================
    output logic [31:0]                   o_chip_count,
    output logic [8:0]                    o_peak_lane,
    output logic [ACC_WIDTH-1:0]          o_peak_magnitude,
    output logic                          o_processing
);

    //=========================================================================
    // Internal Signals
    //=========================================================================
    
    // I Channel
    logic [NUM_LANES*ACC_WIDTH-1:0] results_i_flat;
    logic results_i_valid;
    logic [8:0] peak_lane_i;
    logic [ACC_WIDTH-1:0] peak_value_i;
    
    // Q Channel
    logic [NUM_LANES*ACC_WIDTH-1:0] results_q_flat;
    logic results_q_valid;
    logic [8:0] peak_lane_q;
    logic [ACC_WIDTH-1:0] peak_value_q;
    
    // Shared PRBS
    logic prbs_bit;
    logic [19:0] lfsr_state;
    logic lfsr_feedback;
    
    //=========================================================================
    // Shared PRBS-20 LFSR Generator
    //=========================================================================
    
    assign lfsr_feedback = lfsr_state[19] ^ lfsr_state[2];
    assign prbs_bit = lfsr_state[19];
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            lfsr_state <= 20'hFFFFF;
        end else if (i_seed_load) begin
            lfsr_state <= (i_lfsr_seed == '0) ? 20'hFFFFF : i_lfsr_seed;
        end else if (i_valid && i_enable) begin
            lfsr_state <= {lfsr_state[18:0], lfsr_feedback};
        end
    end
    
    //=========================================================================
    // I Channel Correlator Bank
    //=========================================================================
    
    qedmma_correlator_bank_v32_core #(
        .NUM_LANES(NUM_LANES),
        .DATA_WIDTH(DATA_WIDTH),
        .ACC_WIDTH(ACC_WIDTH)
    ) u_bank_i (
        .clk(clk),
        .rst_n(rst_n),
        .i_adc_sample(i_adc_i),
        .i_valid(i_valid && i_enable),
        .i_dump_trigger(i_dump_trigger),
        .i_lfsr_seed(i_lfsr_seed),
        .i_seed_load(i_seed_load),
        .o_results_flat(results_i_flat),
        .o_results_valid(results_i_valid),
        .o_chip_count(o_chip_count),
        .o_peak_lane(peak_lane_i),
        .o_peak_value(peak_value_i)
    );
    
    //=========================================================================
    // Q Channel Correlator Bank
    //=========================================================================
    
    qedmma_correlator_bank_v32_core #(
        .NUM_LANES(NUM_LANES),
        .DATA_WIDTH(DATA_WIDTH),
        .ACC_WIDTH(ACC_WIDTH)
    ) u_bank_q (
        .clk(clk),
        .rst_n(rst_n),
        .i_adc_sample(i_adc_q),
        .i_valid(i_valid && i_enable),
        .i_dump_trigger(i_dump_trigger),
        .i_lfsr_seed(i_lfsr_seed),
        .i_seed_load(i_seed_load),
        .o_results_flat(results_q_flat),
        .o_results_valid(results_q_valid),
        .o_chip_count(),  // Shared counter
        .o_peak_lane(peak_lane_q),
        .o_peak_value(peak_value_q)
    );
    
    //=========================================================================
    // Magnitude Computation and Peak Detection
    //=========================================================================
    
    logic [ACC_WIDTH-1:0] magnitude [NUM_LANES];
    logic [8:0] global_peak_lane;
    logic [ACC_WIDTH-1:0] global_peak_mag;
    
    // Compute magnitude and find global peak
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            global_peak_lane <= '0;
            global_peak_mag <= '0;
        end else if (results_i_valid && results_q_valid) begin
            logic [ACC_WIDTH-1:0] max_mag;
            logic [8:0] max_idx;
            logic [ACC_WIDTH-1:0] abs_i, abs_q, mag;
            
            max_mag = '0;
            max_idx = '0;
            
            for (int i = 0; i < NUM_LANES; i++) begin
                // Extract I and Q accumulators
                logic signed [ACC_WIDTH-1:0] acc_i, acc_q;
                acc_i = results_i_flat[(i+1)*ACC_WIDTH-1 -: ACC_WIDTH];
                acc_q = results_q_flat[(i+1)*ACC_WIDTH-1 -: ACC_WIDTH];
                
                // Absolute values
                abs_i = acc_i[ACC_WIDTH-1] ? (~acc_i + 1) : acc_i;
                abs_q = acc_q[ACC_WIDTH-1] ? (~acc_q + 1) : acc_q;
                
                // Magnitude approximation: |I| + |Q|
                mag = abs_i + abs_q;
                magnitude[i] <= mag;
                
                if (mag > max_mag) begin
                    max_mag = mag;
                    max_idx = i[8:0];
                end
            end
            
            global_peak_lane <= max_idx;
            global_peak_mag <= max_mag;
        end
    end
    
    assign o_peak_lane = global_peak_lane;
    assign o_peak_magnitude = global_peak_mag;
    
    //=========================================================================
    // Output Multiplexer (I → Q → Mag sequence)
    //=========================================================================
    
    typedef enum logic [2:0] {
        OUT_IDLE,
        OUT_I_DATA,
        OUT_Q_DATA,
        OUT_MAG_DATA,
        OUT_DONE
    } out_state_t;
    
    out_state_t out_state;
    logic [9:0] out_index;
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_state <= OUT_IDLE;
            out_index <= '0;
            m_axis_tvalid <= 1'b0;
            m_axis_tlast <= 1'b0;
            m_axis_tdata <= '0;
            m_axis_tid <= '0;
        end else begin
            case (out_state)
                OUT_IDLE: begin
                    m_axis_tvalid <= 1'b0;
                    out_index <= '0;
                    
                    if (results_i_valid) begin
                        out_state <= OUT_I_DATA;
                    end
                end
                
                OUT_I_DATA: begin
                    if (m_axis_tready || !m_axis_tvalid) begin
                        m_axis_tdata <= {6'b0, out_index, 
                            results_i_flat[(out_index+1)*ACC_WIDTH-1 -: ACC_WIDTH]};
                        m_axis_tvalid <= 1'b1;
                        m_axis_tid <= 2'b00;  // I channel
                        
                        if (out_index == NUM_LANES - 1) begin
                            m_axis_tlast <= 1'b1;
                            out_index <= '0;
                            out_state <= OUT_Q_DATA;
                        end else begin
                            m_axis_tlast <= 1'b0;
                            out_index <= out_index + 1;
                        end
                    end
                end
                
                OUT_Q_DATA: begin
                    if (m_axis_tready || !m_axis_tvalid) begin
                        m_axis_tdata <= {6'b0, out_index,
                            results_q_flat[(out_index+1)*ACC_WIDTH-1 -: ACC_WIDTH]};
                        m_axis_tvalid <= 1'b1;
                        m_axis_tid <= 2'b01;  // Q channel
                        
                        if (out_index == NUM_LANES - 1) begin
                            m_axis_tlast <= 1'b1;
                            out_index <= '0;
                            out_state <= OUT_MAG_DATA;
                        end else begin
                            m_axis_tlast <= 1'b0;
                            out_index <= out_index + 1;
                        end
                    end
                end
                
                OUT_MAG_DATA: begin
                    if (m_axis_tready || !m_axis_tvalid) begin
                        m_axis_tdata <= {6'b0, out_index, magnitude[out_index]};
                        m_axis_tvalid <= 1'b1;
                        m_axis_tid <= 2'b10;  // Magnitude
                        
                        if (out_index == NUM_LANES - 1) begin
                            m_axis_tlast <= 1'b1;
                            out_state <= OUT_DONE;
                        end else begin
                            m_axis_tlast <= 1'b0;
                            out_index <= out_index + 1;
                        end
                    end
                end
                
                OUT_DONE: begin
                    if (m_axis_tready) begin
                        m_axis_tvalid <= 1'b0;
                        m_axis_tlast <= 1'b0;
                        out_state <= OUT_IDLE;
                    end
                end
                
                default: out_state <= OUT_IDLE;
            endcase
        end
    end
    
    assign o_processing = (out_state != OUT_IDLE);

endmodule
