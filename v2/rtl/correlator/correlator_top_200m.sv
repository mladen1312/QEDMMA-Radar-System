//-----------------------------------------------------------------------------
// QEDMMA v3.0 - 200 Mchip/s Correlator Top Level
// Author: Dr. Mladen Mešter
// Copyright (c) 2026 - All Rights Reserved
//
// [REQ-CORR-001] through [REQ-CORR-023] - Complete correlator subsystem
//
// Description:
//   Top-level integration of 200 Mchip/s PRBS correlator.
//   Includes PRBS generation, parallel correlation, peak detection,
//   and AXI interfaces.
//
// Interfaces:
//   - AXI-Stream slave: ADC samples (256-bit @ 25 MHz = 200 MSPS effective)
//   - AXI-Stream master: Correlation results
//   - AXI-Lite: Configuration and status registers
//-----------------------------------------------------------------------------

`timescale 1ns / 1ps

module correlator_top_200m #(
    parameter int PARALLEL_WIDTH  = 8,
    parameter int SAMPLE_WIDTH    = 16,
    parameter int ACC_WIDTH       = 48,
    parameter int OUTPUT_WIDTH    = 32,
    parameter int MAX_CODE_LEN    = 65536,
    parameter int AXI_DATA_WIDTH  = 256,      // 8 × 32-bit samples
    parameter int AXI_LITE_WIDTH  = 32
)(
    input  logic        clk,                   // 25 MHz processing clock
    input  logic        rst_n,
    
    //=========================================================================
    // AXI-Stream Slave - ADC Input
    //=========================================================================
    input  logic [AXI_DATA_WIDTH-1:0] s_axis_adc_tdata,   // 8 × (I16 + Q16)
    input  logic                      s_axis_adc_tvalid,
    output logic                      s_axis_adc_tready,
    
    //=========================================================================
    // AXI-Stream Master - Correlation Output
    //=========================================================================
    output logic [OUTPUT_WIDTH-1:0]   m_axis_corr_tdata,
    output logic [15:0]               m_axis_corr_tuser,   // Code phase
    output logic                      m_axis_corr_tvalid,
    input  logic                      m_axis_corr_tready,
    
    //=========================================================================
    // AXI-Lite Configuration Interface
    //=========================================================================
    input  logic [11:0]               s_axi_awaddr,
    input  logic                      s_axi_awvalid,
    output logic                      s_axi_awready,
    input  logic [AXI_LITE_WIDTH-1:0] s_axi_wdata,
    input  logic [3:0]                s_axi_wstrb,
    input  logic                      s_axi_wvalid,
    output logic                      s_axi_wready,
    output logic [1:0]                s_axi_bresp,
    output logic                      s_axi_bvalid,
    input  logic                      s_axi_bready,
    input  logic [11:0]               s_axi_araddr,
    input  logic                      s_axi_arvalid,
    output logic                      s_axi_arready,
    output logic [AXI_LITE_WIDTH-1:0] s_axi_rdata,
    output logic [1:0]                s_axi_rresp,
    output logic                      s_axi_rvalid,
    input  logic                      s_axi_rready,
    
    //=========================================================================
    // PRBS TX Output (to DAC)
    //=========================================================================
    output logic [PARALLEL_WIDTH-1:0] prbs_tx_data,
    output logic                      prbs_tx_valid,
    
    //=========================================================================
    // Status
    //=========================================================================
    output logic                      correlation_active,
    output logic                      detection_valid,
    output logic [OUTPUT_WIDTH-1:0]   peak_magnitude,
    output logic [15:0]               peak_code_phase
);

    //=========================================================================
    // Register Map (Base: 0x00050000)
    //=========================================================================
    // 0x000: CTRL       - Enable, code_type, mode
    // 0x004: STATUS     - Busy, overflow, detection
    // 0x008: CODE_LEN   - Integration length
    // 0x00C: CODE_SEED  - PRBS seed
    // 0x010: THRESHOLD  - Detection threshold
    // 0x014: PEAK_MAG   - Peak magnitude (RO)
    // 0x018: PEAK_PHASE - Peak code phase (RO)
    // 0x01C: CORR_CNT   - Correlation count (RO)
    // 0x0FC: VERSION    - IP version (RO)
    
    logic [31:0] reg_ctrl;
    logic [31:0] reg_code_len;
    logic [31:0] reg_code_seed;
    logic [31:0] reg_threshold;
    logic [31:0] reg_corr_count;
    
    // Control bits
    logic cfg_enable;
    logic cfg_tx_enable;
    logic [1:0] cfg_code_type;
    logic cfg_continuous;
    logic cfg_clear;
    
    assign cfg_enable     = reg_ctrl[0];
    assign cfg_tx_enable  = reg_ctrl[1];
    assign cfg_code_type  = reg_ctrl[3:2];
    assign cfg_continuous = reg_ctrl[4];
    assign cfg_clear      = reg_ctrl[31];
    
    //=========================================================================
    // Input Unpacking
    //=========================================================================
    logic signed [SAMPLE_WIDTH-1:0] adc_i [PARALLEL_WIDTH];
    logic signed [SAMPLE_WIDTH-1:0] adc_q [PARALLEL_WIDTH];
    
    generate
        for (genvar i = 0; i < PARALLEL_WIDTH; i++) begin : gen_unpack
            assign adc_i[i] = s_axis_adc_tdata[i*32 +: 16];
            assign adc_q[i] = s_axis_adc_tdata[i*32 + 16 +: 16];
        end
    endgenerate
    
    //=========================================================================
    // PRBS Generator Instance
    //=========================================================================
    logic [PARALLEL_WIDTH-1:0] prbs_code;
    logic                      prbs_valid_int;
    logic [19:0]               prbs_chip_count;
    logic                      prbs_wrap;
    
    prbs_generator_parallel #(
        .PARALLEL_WIDTH(PARALLEL_WIDTH),
        .MAX_LFSR_LEN(20),
        .COUNTER_WIDTH(20)
    ) u_prbs_gen (
        .clk(clk),
        .rst_n(rst_n),
        .enable(cfg_enable && s_axis_adc_tvalid),
        .sync_reset(cfg_clear),
        .code_type(cfg_code_type),
        .seed_primary(reg_code_seed[19:0]),
        .seed_secondary(20'hFFFFF),
        .prbs_out(prbs_code),
        .prbs_valid(prbs_valid_int),
        .chip_count(prbs_chip_count),
        .sequence_wrap(prbs_wrap)
    );
    
    // TX output
    assign prbs_tx_data = cfg_tx_enable ? prbs_code : '0;
    assign prbs_tx_valid = cfg_tx_enable && prbs_valid_int;
    
    //=========================================================================
    // Correlator Engine Instance
    //=========================================================================
    logic [OUTPUT_WIDTH-1:0]   corr_mag;
    logic signed [ACC_WIDTH-1:0] corr_i_raw, corr_q_raw;
    logic                        corr_valid_int;
    logic [15:0]                 corr_phase;
    logic                        corr_overflow;
    logic                        integration_complete;
    
    parallel_correlator_engine #(
        .PARALLEL_WIDTH(PARALLEL_WIDTH),
        .SAMPLE_WIDTH(SAMPLE_WIDTH),
        .ACC_WIDTH(ACC_WIDTH),
        .OUTPUT_WIDTH(OUTPUT_WIDTH),
        .MAX_CODE_LEN(MAX_CODE_LEN),
        .CODE_ADDR_WIDTH(16)
    ) u_correlator (
        .clk(clk),
        .rst_n(rst_n),
        .sample_i(adc_i),
        .sample_q(adc_q),
        .sample_valid(s_axis_adc_tvalid),
        .sample_ready(s_axis_adc_tready),
        .code_chips(prbs_code),
        .code_valid(prbs_valid_int),
        .cfg_code_length(reg_code_len[15:0]),
        .cfg_enable(cfg_enable),
        .cfg_accumulate(cfg_continuous),
        .cfg_clear(cfg_clear),
        .corr_magnitude_sq(corr_mag),
        .corr_i(corr_i_raw),
        .corr_q(corr_q_raw),
        .corr_valid(corr_valid_int),
        .corr_chip_count(corr_phase),
        .overflow_detected(corr_overflow),
        .integration_done(integration_complete)
    );
    
    //=========================================================================
    // Peak Detector
    //=========================================================================
    logic [OUTPUT_WIDTH-1:0] current_peak_mag;
    logic [15:0]             current_peak_phase;
    logic                    peak_detected;
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_peak_mag <= '0;
            current_peak_phase <= '0;
            peak_detected <= 1'b0;
        end else if (cfg_clear) begin
            current_peak_mag <= '0;
            current_peak_phase <= '0;
            peak_detected <= 1'b0;
        end else if (corr_valid_int) begin
            if (corr_mag > current_peak_mag && corr_mag > reg_threshold) begin
                current_peak_mag <= corr_mag;
                current_peak_phase <= corr_phase;
                peak_detected <= 1'b1;
            end
        end
    end
    
    assign peak_magnitude = current_peak_mag;
    assign peak_code_phase = current_peak_phase;
    assign detection_valid = peak_detected && (current_peak_mag > reg_threshold);
    
    //=========================================================================
    // Output Interface
    //=========================================================================
    logic output_pending;
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            m_axis_corr_tdata <= '0;
            m_axis_corr_tuser <= '0;
            m_axis_corr_tvalid <= 1'b0;
            output_pending <= 1'b0;
            reg_corr_count <= '0;
        end else begin
            if (corr_valid_int && !output_pending) begin
                m_axis_corr_tdata <= corr_mag;
                m_axis_corr_tuser <= corr_phase;
                m_axis_corr_tvalid <= 1'b1;
                output_pending <= 1'b1;
                reg_corr_count <= reg_corr_count + 1;
            end else if (m_axis_corr_tvalid && m_axis_corr_tready) begin
                m_axis_corr_tvalid <= 1'b0;
                output_pending <= 1'b0;
            end
        end
    end
    
    assign correlation_active = cfg_enable && !output_pending;
    
    //=========================================================================
    // AXI-Lite Register Interface
    //=========================================================================
    // Simplified AXI-Lite slave
    
    logic [11:0] wr_addr, rd_addr;
    logic        wr_en, rd_en;
    
    // Write channel
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axi_awready <= 1'b1;
            s_axi_wready <= 1'b1;
            s_axi_bvalid <= 1'b0;
            s_axi_bresp <= 2'b00;
            wr_addr <= '0;
            wr_en <= 1'b0;
        end else begin
            // Address phase
            if (s_axi_awvalid && s_axi_awready) begin
                wr_addr <= s_axi_awaddr;
                s_axi_awready <= 1'b0;
            end
            
            // Data phase
            if (s_axi_wvalid && s_axi_wready) begin
                wr_en <= 1'b1;
                s_axi_wready <= 1'b0;
            end else begin
                wr_en <= 1'b0;
            end
            
            // Response
            if (wr_en) begin
                s_axi_bvalid <= 1'b1;
            end else if (s_axi_bvalid && s_axi_bready) begin
                s_axi_bvalid <= 1'b0;
                s_axi_awready <= 1'b1;
                s_axi_wready <= 1'b1;
            end
        end
    end
    
    // Register writes
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg_ctrl <= 32'h0;
            reg_code_len <= 32'd2047;    // Default PRBS-11
            reg_code_seed <= 32'h7FF;
            reg_threshold <= 32'h1000;
        end else if (wr_en) begin
            case (wr_addr[7:0])
                8'h00: reg_ctrl <= s_axi_wdata;
                8'h08: reg_code_len <= s_axi_wdata;
                8'h0C: reg_code_seed <= s_axi_wdata;
                8'h10: reg_threshold <= s_axi_wdata;
            endcase
            
            // Self-clearing bits
            if (wr_addr[7:0] == 8'h00 && s_axi_wdata[31]) begin
                reg_ctrl[31] <= 1'b0;  // Clear bit auto-clears
            end
        end
    end
    
    // Read channel
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axi_arready <= 1'b1;
            s_axi_rvalid <= 1'b0;
            s_axi_rresp <= 2'b00;
            s_axi_rdata <= '0;
        end else begin
            if (s_axi_arvalid && s_axi_arready) begin
                rd_addr <= s_axi_araddr;
                s_axi_arready <= 1'b0;
                
                // Read data
                case (s_axi_araddr[7:0])
                    8'h00: s_axi_rdata <= reg_ctrl;
                    8'h04: s_axi_rdata <= {28'b0, corr_overflow, peak_detected, integration_complete, cfg_enable};
                    8'h08: s_axi_rdata <= reg_code_len;
                    8'h0C: s_axi_rdata <= reg_code_seed;
                    8'h10: s_axi_rdata <= reg_threshold;
                    8'h14: s_axi_rdata <= current_peak_mag;
                    8'h18: s_axi_rdata <= {16'b0, current_peak_phase};
                    8'h1C: s_axi_rdata <= reg_corr_count;
                    8'hFC: s_axi_rdata <= 32'h03000001;  // Version 3.0.0 build 1
                    default: s_axi_rdata <= 32'hDEADBEEF;
                endcase
                
                s_axi_rvalid <= 1'b1;
            end else if (s_axi_rvalid && s_axi_rready) begin
                s_axi_rvalid <= 1'b0;
                s_axi_arready <= 1'b1;
            end
        end
    end

endmodule
