//-----------------------------------------------------------------------------
// QEDMMA Digital Down Converter (DDC) Core
// Author: Dr. Mladen Mešter
// Copyright (c) 2026 Dr. Mladen Mešter - All Rights Reserved
//
// Features:
//   - NCO (Numerically Controlled Oscillator) with 32-bit phase accumulator
//   - Complex mixer (I/Q demodulation)
//   - CIC decimation filter (configurable R=4 to R=64)
//   - AXI4-Stream interfaces
//
// [REQ-DDC-001] Instantaneous bandwidth: 100 MHz
// [REQ-DDC-002] Decimation factor: programmable 4-64
// [REQ-DDC-003] NCO frequency resolution: < 1 Hz
// [REQ-DDC-004] SFDR: > 90 dB
//-----------------------------------------------------------------------------
`timescale 1ns / 1ps

module ddc_core #(
    parameter DATA_WIDTH     = 16,
    parameter NCO_WIDTH      = 32,
    parameter CIC_STAGES     = 4,
    parameter MAX_DECIMATION = 64
)(
    // Clock and Reset
    input  logic                    clk,
    input  logic                    rst_n,
    
    // AXI4-Stream Input (Real ADC samples)
    input  logic [DATA_WIDTH-1:0]   s_axis_tdata,
    input  logic                    s_axis_tvalid,
    output logic                    s_axis_tready,
    
    // AXI4-Stream Output (Complex baseband I/Q)
    output logic [2*DATA_WIDTH-1:0] m_axis_tdata,  // {Q, I}
    output logic                    m_axis_tvalid,
    input  logic                    m_axis_tready,
    
    // Configuration
    input  logic [NCO_WIDTH-1:0]    cfg_nco_freq,      // NCO frequency word
    input  logic [5:0]              cfg_decimation,    // Decimation factor (4-64)
    input  logic                    cfg_bypass_cic,    // Bypass CIC filter
    input  logic                    cfg_enable
);

    //-------------------------------------------------------------------------
    // Local Parameters
    //-------------------------------------------------------------------------
    localparam CIC_WIDTH = DATA_WIDTH + CIC_STAGES * $clog2(MAX_DECIMATION);
    
    //-------------------------------------------------------------------------
    // NCO - Numerically Controlled Oscillator
    //-------------------------------------------------------------------------
    logic [NCO_WIDTH-1:0]   nco_phase;
    logic [DATA_WIDTH-1:0]  nco_cos, nco_sin;
    
    // Phase accumulator
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            nco_phase <= '0;
        end else if (cfg_enable && s_axis_tvalid && s_axis_tready) begin
            nco_phase <= nco_phase + cfg_nco_freq;
        end
    end
    
    // CORDIC or LUT-based sin/cos generation
    // Using top 12 bits of phase for 4096-entry quarter-wave LUT
    logic [11:0] phase_addr;
    logic [1:0]  phase_quadrant;
    
    assign phase_quadrant = nco_phase[NCO_WIDTH-1:NCO_WIDTH-2];
    assign phase_addr     = nco_phase[NCO_WIDTH-3:NCO_WIDTH-14];
    
    // Quarter-wave symmetry ROM (synthesizable)
    logic [DATA_WIDTH-1:0] sin_lut [0:1023];
    logic [DATA_WIDTH-1:0] sin_raw, cos_raw;
    
    // Initialize LUT (in real design, use .mem file or IP)
    initial begin
        for (int i = 0; i < 1024; i++) begin
            sin_lut[i] = $rtoi($sin(3.14159265359 * i / 2048.0) * (2**(DATA_WIDTH-1)-1));
        end
    end
    
    // LUT lookup with quadrant correction
    always_ff @(posedge clk) begin
        case (phase_quadrant)
            2'b00: begin  // 0-90°
                sin_raw <=  sin_lut[phase_addr[9:0]];
                cos_raw <=  sin_lut[1023 - phase_addr[9:0]];
            end
            2'b01: begin  // 90-180°
                sin_raw <=  sin_lut[1023 - phase_addr[9:0]];
                cos_raw <= -sin_lut[phase_addr[9:0]];
            end
            2'b10: begin  // 180-270°
                sin_raw <= -sin_lut[phase_addr[9:0]];
                cos_raw <= -sin_lut[1023 - phase_addr[9:0]];
            end
            2'b11: begin  // 270-360°
                sin_raw <= -sin_lut[1023 - phase_addr[9:0]];
                cos_raw <=  sin_lut[phase_addr[9:0]];
            end
        endcase
    end
    
    assign nco_cos = cos_raw;
    assign nco_sin = sin_raw;
    
    //-------------------------------------------------------------------------
    // Complex Mixer
    //-------------------------------------------------------------------------
    logic signed [DATA_WIDTH-1:0]   adc_signed;
    logic signed [2*DATA_WIDTH-1:0] mix_i_full, mix_q_full;
    logic signed [DATA_WIDTH-1:0]   mix_i, mix_q;
    logic                           mix_valid;
    
    assign adc_signed = s_axis_tdata;
    
    // I = ADC * cos(nco)
    // Q = ADC * sin(nco)
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mix_i_full <= '0;
            mix_q_full <= '0;
            mix_valid  <= 1'b0;
        end else if (cfg_enable && s_axis_tvalid && s_axis_tready) begin
            mix_i_full <= $signed(adc_signed) * $signed(nco_cos);
            mix_q_full <= $signed(adc_signed) * $signed(nco_sin);
            mix_valid  <= 1'b1;
        end else begin
            mix_valid  <= 1'b0;
        end
    end
    
    // Truncate to DATA_WIDTH (keep MSBs)
    assign mix_i = mix_i_full[2*DATA_WIDTH-2:DATA_WIDTH-1];
    assign mix_q = mix_q_full[2*DATA_WIDTH-2:DATA_WIDTH-1];
    
    //-------------------------------------------------------------------------
    // CIC Decimation Filter (I channel)
    //-------------------------------------------------------------------------
    logic signed [CIC_WIDTH-1:0] cic_i_integ [0:CIC_STAGES-1];
    logic signed [CIC_WIDTH-1:0] cic_i_comb  [0:CIC_STAGES-1];
    logic signed [CIC_WIDTH-1:0] cic_i_comb_z[0:CIC_STAGES-1];
    logic signed [CIC_WIDTH-1:0] cic_i_decim;
    
    // CIC Integrator stages (at input rate)
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int i = 0; i < CIC_STAGES; i++) begin
                cic_i_integ[i] <= '0;
            end
        end else if (mix_valid) begin
            cic_i_integ[0] <= cic_i_integ[0] + {{(CIC_WIDTH-DATA_WIDTH){mix_i[DATA_WIDTH-1]}}, mix_i};
            for (int i = 1; i < CIC_STAGES; i++) begin
                cic_i_integ[i] <= cic_i_integ[i] + cic_i_integ[i-1];
            end
        end
    end
    
    // Decimation counter
    logic [5:0] decim_cnt;
    logic       decim_tick;
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            decim_cnt  <= '0;
            decim_tick <= 1'b0;
        end else if (mix_valid) begin
            if (decim_cnt >= cfg_decimation - 1) begin
                decim_cnt  <= '0;
                decim_tick <= 1'b1;
            end else begin
                decim_cnt  <= decim_cnt + 1'b1;
                decim_tick <= 1'b0;
            end
        end else begin
            decim_tick <= 1'b0;
        end
    end
    
    // CIC Comb stages (at output rate)
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int i = 0; i < CIC_STAGES; i++) begin
                cic_i_comb[i]   <= '0;
                cic_i_comb_z[i] <= '0;
            end
            cic_i_decim <= '0;
        end else if (decim_tick) begin
            // First comb stage
            cic_i_comb[0]   <= cic_i_integ[CIC_STAGES-1] - cic_i_comb_z[0];
            cic_i_comb_z[0] <= cic_i_integ[CIC_STAGES-1];
            // Subsequent comb stages
            for (int i = 1; i < CIC_STAGES; i++) begin
                cic_i_comb[i]   <= cic_i_comb[i-1] - cic_i_comb_z[i];
                cic_i_comb_z[i] <= cic_i_comb[i-1];
            end
            cic_i_decim <= cic_i_comb[CIC_STAGES-1];
        end
    end
    
    //-------------------------------------------------------------------------
    // CIC Decimation Filter (Q channel) - Identical structure
    //-------------------------------------------------------------------------
    logic signed [CIC_WIDTH-1:0] cic_q_integ [0:CIC_STAGES-1];
    logic signed [CIC_WIDTH-1:0] cic_q_comb  [0:CIC_STAGES-1];
    logic signed [CIC_WIDTH-1:0] cic_q_comb_z[0:CIC_STAGES-1];
    logic signed [CIC_WIDTH-1:0] cic_q_decim;
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int i = 0; i < CIC_STAGES; i++) begin
                cic_q_integ[i] <= '0;
            end
        end else if (mix_valid) begin
            cic_q_integ[0] <= cic_q_integ[0] + {{(CIC_WIDTH-DATA_WIDTH){mix_q[DATA_WIDTH-1]}}, mix_q};
            for (int i = 1; i < CIC_STAGES; i++) begin
                cic_q_integ[i] <= cic_q_integ[i] + cic_q_integ[i-1];
            end
        end
    end
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int i = 0; i < CIC_STAGES; i++) begin
                cic_q_comb[i]   <= '0;
                cic_q_comb_z[i] <= '0;
            end
            cic_q_decim <= '0;
        end else if (decim_tick) begin
            cic_q_comb[0]   <= cic_q_integ[CIC_STAGES-1] - cic_q_comb_z[0];
            cic_q_comb_z[0] <= cic_q_integ[CIC_STAGES-1];
            for (int i = 1; i < CIC_STAGES; i++) begin
                cic_q_comb[i]   <= cic_q_comb[i-1] - cic_q_comb_z[i];
                cic_q_comb_z[i] <= cic_q_comb[i-1];
            end
            cic_q_decim <= cic_q_comb[CIC_STAGES-1];
        end
    end
    
    //-------------------------------------------------------------------------
    // Output Gain Compensation & Truncation
    //-------------------------------------------------------------------------
    // CIC gain = R^N where R=decimation, N=stages
    // Bit growth = N * log2(R) bits
    // We truncate the appropriate number of MSBs
    
    localparam OUT_SHIFT = CIC_STAGES * 6;  // Assuming max R=64 -> 6 bits
    
    logic signed [DATA_WIDTH-1:0] out_i, out_q;
    logic                         out_valid;
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_i     <= '0;
            out_q     <= '0;
            out_valid <= 1'b0;
        end else if (cfg_bypass_cic) begin
            // Bypass mode - output mixer directly
            out_i     <= mix_i;
            out_q     <= mix_q;
            out_valid <= mix_valid;
        end else if (decim_tick) begin
            // CIC output with gain compensation
            out_i     <= cic_i_decim[CIC_WIDTH-1:CIC_WIDTH-DATA_WIDTH];
            out_q     <= cic_q_decim[CIC_WIDTH-1:CIC_WIDTH-DATA_WIDTH];
            out_valid <= 1'b1;
        end else begin
            out_valid <= 1'b0;
        end
    end
    
    //-------------------------------------------------------------------------
    // AXI4-Stream Output
    //-------------------------------------------------------------------------
    assign s_axis_tready = cfg_enable && (!m_axis_tvalid || m_axis_tready);
    assign m_axis_tdata  = {out_q, out_i};
    assign m_axis_tvalid = out_valid;

endmodule
