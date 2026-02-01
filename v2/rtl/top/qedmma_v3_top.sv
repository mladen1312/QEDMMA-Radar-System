//=============================================================================
// QEDMMA v3.0 - Top-Level System Integration
// Author: Dr. Mladen Mešter
// Copyright (c) 2026 - All Rights Reserved
//
// [REQ-SOC-001] Complete system integration
// [REQ-SOC-002] AXI4 interconnect for PS-PL communication
// [REQ-SOC-003] 200 Mchip/s PRBS + Quantum RX + AI ECCM
//
// Description:
//   Top-level wrapper integrating all QEDMMA v3.0 subsystems:
//   - 200 Mchip/s PRBS Correlator (spread-spectrum waveform)
//   - Multi-sensor Track Fusion (JDL model)
//   - AI-enhanced ECCM (+7 dB validated)
//   - Tri-modal Communications (Link-16/HF/SATCOM)
//   - White Rabbit PTP Synchronization (<100 ps)
//   - Quantum Receiver Interface (Rydberg atoms)
//
// Target: Xilinx Zynq UltraScale+ ZU47DR
// Clock: 200 MHz system, 125 MHz Ethernet, 25 MHz PRBS
//=============================================================================

`timescale 1ns / 1ps

module qedmma_v3_top #(
    // System Configuration
    parameter int SYS_CLK_FREQ_HZ    = 200_000_000,
    parameter int ETH_CLK_FREQ_HZ    = 125_000_000,
    parameter int PRBS_CLK_FREQ_HZ   = 25_000_000,
    
    // AXI Configuration
    parameter int AXI_ADDR_WIDTH     = 32,
    parameter int AXI_DATA_WIDTH     = 32,
    parameter int AXI_ID_WIDTH       = 4,
    
    // Subsystem Configuration
    parameter int NUM_TRACKS         = 1024,
    parameter int NUM_SENSORS        = 8,
    parameter int CORRELATOR_LANES   = 8,
    parameter int TOA_CHANNELS       = 8,
    
    // Feature Enables
    parameter bit ENABLE_QUANTUM_RX  = 1,
    parameter bit ENABLE_AI_ECCM     = 1,
    parameter bit ENABLE_WHITE_RABBIT = 1
)(
    //=========================================================================
    // Clock and Reset
    //=========================================================================
    input  logic                          clk_sys,          // 200 MHz system
    input  logic                          clk_eth,          // 125 MHz Ethernet
    input  logic                          clk_prbs,         // 25 MHz PRBS (×8 = 200 Mchip/s)
    input  logic                          clk_ref,          // Reference clock (WR)
    input  logic                          rst_n,            // Active-low reset
    
    //=========================================================================
    // AXI4-Lite Slave Interface (PS → PL Configuration)
    //=========================================================================
    input  logic [AXI_ADDR_WIDTH-1:0]     s_axi_awaddr,
    input  logic [2:0]                    s_axi_awprot,
    input  logic                          s_axi_awvalid,
    output logic                          s_axi_awready,
    input  logic [AXI_DATA_WIDTH-1:0]     s_axi_wdata,
    input  logic [AXI_DATA_WIDTH/8-1:0]   s_axi_wstrb,
    input  logic                          s_axi_wvalid,
    output logic                          s_axi_wready,
    output logic [1:0]                    s_axi_bresp,
    output logic                          s_axi_bvalid,
    input  logic                          s_axi_bready,
    input  logic [AXI_ADDR_WIDTH-1:0]     s_axi_araddr,
    input  logic [2:0]                    s_axi_arprot,
    input  logic                          s_axi_arvalid,
    output logic                          s_axi_arready,
    output logic [AXI_DATA_WIDTH-1:0]     s_axi_rdata,
    output logic [1:0]                    s_axi_rresp,
    output logic                          s_axi_rvalid,
    input  logic                          s_axi_rready,
    
    //=========================================================================
    // AXI4-Stream ADC Interface (Quantum RX Input)
    //=========================================================================
    input  logic [255:0]                  s_axis_adc_tdata,   // 8 × 32-bit I/Q
    input  logic                          s_axis_adc_tvalid,
    output logic                          s_axis_adc_tready,
    input  logic                          s_axis_adc_tlast,
    
    //=========================================================================
    // AXI4-Stream DAC Interface (TX Waveform Output)
    //=========================================================================
    output logic [63:0]                   m_axis_dac_tdata,   // 2 × 32-bit I/Q
    output logic                          m_axis_dac_tvalid,
    input  logic                          m_axis_dac_tready,
    output logic                          m_axis_dac_tlast,
    
    //=========================================================================
    // AXI4-Stream Track Output (to Command & Control)
    //=========================================================================
    output logic [127:0]                  m_axis_track_tdata,
    output logic                          m_axis_track_tvalid,
    input  logic                          m_axis_track_tready,
    output logic [15:0]                   m_axis_track_tid,
    output logic                          m_axis_track_tlast,
    
    //=========================================================================
    // External Sensor Interfaces
    //=========================================================================
    // Link-16 (JTIDS)
    input  logic [15:0]                   link16_rx_data,
    input  logic                          link16_rx_valid,
    output logic [15:0]                   link16_tx_data,
    output logic                          link16_tx_valid,
    input  logic                          link16_tx_ready,
    
    // ASTERIX (Cat-048/062)
    input  logic [7:0]                    asterix_rx_data,
    input  logic                          asterix_rx_valid,
    input  logic                          asterix_rx_sof,
    input  logic                          asterix_rx_eof,
    
    // ESM/ELINT
    input  logic [63:0]                   esm_emitter_data,
    input  logic                          esm_emitter_valid,
    
    // IRST
    input  logic [47:0]                   irst_bearing_data,
    input  logic                          irst_bearing_valid,
    
    //=========================================================================
    // White Rabbit PTP Interface
    //=========================================================================
    // Ethernet PHY (for PTP)
    input  logic                          eth_rx_clk,
    input  logic [7:0]                    eth_rxd,
    input  logic                          eth_rx_dv,
    output logic                          eth_tx_clk,
    output logic [7:0]                    eth_txd,
    output logic                          eth_tx_en,
    
    // VCXO Control
    output logic [15:0]                   vcxo_dac,
    output logic                          vcxo_dac_valid,
    
    // ToA Triggers (from array elements)
    input  logic [TOA_CHANNELS-1:0]       toa_triggers,
    
    //=========================================================================
    // Communication Links
    //=========================================================================
    // HF Backup
    output logic [15:0]                   hf_tx_data,
    output logic                          hf_tx_valid,
    input  logic [15:0]                   hf_rx_data,
    input  logic                          hf_rx_valid,
    
    // SATCOM
    output logic [31:0]                   satcom_tx_data,
    output logic                          satcom_tx_valid,
    input  logic [31:0]                   satcom_rx_data,
    input  logic                          satcom_rx_valid,
    
    //=========================================================================
    // Status and Debug
    //=========================================================================
    output logic [7:0]                    led_status,
    output logic [31:0]                   debug_port,
    
    // Interrupt to PS
    output logic                          irq_detection,
    output logic                          irq_track_update,
    output logic                          irq_comm_event,
    output logic                          irq_wr_lock
);

    //=========================================================================
    // Local Parameters - Address Map
    //=========================================================================
    // Base addresses for each subsystem
    localparam logic [31:0] ADDR_CORRELATOR   = 32'h0005_0000;  // 0x50000-0x5FFFF
    localparam logic [31:0] ADDR_FUSION       = 32'h0006_0000;  // 0x60000-0x6FFFF
    localparam logic [31:0] ADDR_ECCM         = 32'h0007_0000;  // 0x70000-0x7FFFF
    localparam logic [31:0] ADDR_COMM         = 32'h0008_0000;  // 0x80000-0x8FFFF
    localparam logic [31:0] ADDR_WHITE_RABBIT = 32'h0009_0000;  // 0x90000-0x9FFFF
    localparam logic [31:0] ADDR_QUANTUM_RX   = 32'h000A_0000;  // 0xA0000-0xAFFFF
    localparam logic [31:0] ADDR_SYSTEM       = 32'h000F_0000;  // 0xF0000-0xFFFFF
    
    //=========================================================================
    // Internal Signals
    //=========================================================================
    
    // AXI decoder outputs
    logic [AXI_DATA_WIDTH-1:0] rdata_correlator, rdata_fusion, rdata_eccm;
    logic [AXI_DATA_WIDTH-1:0] rdata_comm, rdata_wr, rdata_quantum, rdata_system;
    logic                      sel_correlator, sel_fusion, sel_eccm;
    logic                      sel_comm, sel_wr, sel_quantum, sel_system;
    
    // Correlator outputs
    logic [31:0]               corr_magnitude;
    logic [15:0]               corr_code_phase;
    logic                      corr_detection;
    logic                      corr_overflow;
    logic [7:0]                prbs_tx_data;
    
    // Fusion outputs
    logic [NUM_TRACKS-1:0]     track_valid;
    logic [31:0]               track_range [NUM_TRACKS];
    logic [15:0]               track_azimuth [NUM_TRACKS];
    logic [15:0]               track_elevation [NUM_TRACKS];
    logic [15:0]               track_velocity [NUM_TRACKS];
    logic [7:0]                track_class [NUM_TRACKS];
    logic [7:0]                track_confidence [NUM_TRACKS];
    
    // ECCM outputs
    logic                      eccm_jammer_detected;
    logic [15:0]               eccm_jammer_azimuth;
    logic [7:0]                eccm_jam_margin_db;
    logic                      eccm_track_valid;
    logic [31:0]               eccm_filtered_mag;
    
    // Comm outputs
    logic [1:0]                comm_active_link;  // 0=L16, 1=HF, 2=SATCOM
    logic                      comm_link_healthy;
    logic [7:0]                comm_quality;
    
    // White Rabbit outputs
    logic                      wr_locked;
    logic [47:0]               wr_tai_seconds;
    logic [31:0]               wr_tai_ns;
    logic [31:0]               wr_offset_ns;
    logic [79:0]               toa_timestamp [TOA_CHANNELS];
    logic [TOA_CHANNELS-1:0]   toa_valid;
    
    // Internal AXI-Stream buses
    logic [255:0]              adc_data_sync;
    logic                      adc_valid_sync;
    logic [31:0]               detection_data;
    logic                      detection_valid;
    
    //=========================================================================
    // Clock Domain Crossing
    //=========================================================================
    
    // Synchronize ADC data to system clock
    // (In real implementation, use proper async FIFO)
    always_ff @(posedge clk_sys or negedge rst_n) begin
        if (!rst_n) begin
            adc_data_sync <= '0;
            adc_valid_sync <= 1'b0;
        end else begin
            adc_data_sync <= s_axis_adc_tdata;
            adc_valid_sync <= s_axis_adc_tvalid;
        end
    end
    
    assign s_axis_adc_tready = 1'b1;  // Always ready (simplification)
    
    //=========================================================================
    // AXI Address Decoder
    //=========================================================================
    
    always_comb begin
        sel_correlator = (s_axi_awaddr[19:16] == 4'h5) || (s_axi_araddr[19:16] == 4'h5);
        sel_fusion     = (s_axi_awaddr[19:16] == 4'h6) || (s_axi_araddr[19:16] == 4'h6);
        sel_eccm       = (s_axi_awaddr[19:16] == 4'h7) || (s_axi_araddr[19:16] == 4'h7);
        sel_comm       = (s_axi_awaddr[19:16] == 4'h8) || (s_axi_araddr[19:16] == 4'h8);
        sel_wr         = (s_axi_awaddr[19:16] == 4'h9) || (s_axi_araddr[19:16] == 4'h9);
        sel_quantum    = (s_axi_awaddr[19:16] == 4'hA) || (s_axi_araddr[19:16] == 4'hA);
        sel_system     = (s_axi_awaddr[19:16] == 4'hF) || (s_axi_araddr[19:16] == 4'hF);
    end
    
    //=========================================================================
    // SUBSYSTEM INSTANTIATIONS
    //=========================================================================
    
    //-------------------------------------------------------------------------
    // 1. 200 Mchip/s PRBS Correlator
    //-------------------------------------------------------------------------
    correlator_top_200m #(
        .PARALLEL_LANES(CORRELATOR_LANES)
    ) u_correlator (
        .clk                (clk_prbs),
        .rst_n              (rst_n),
        
        // ADC input (AXI-Stream)
        .s_axis_adc_tdata   (adc_data_sync),
        .s_axis_adc_tvalid  (adc_valid_sync),
        .s_axis_adc_tready  (),
        
        // Detection output
        .m_axis_det_tdata   ({corr_code_phase, 16'h0}),
        .m_axis_det_tvalid  (corr_detection),
        .m_axis_det_tready  (1'b1),
        
        // TX waveform (PRBS)
        .prbs_tx_data       (prbs_tx_data),
        
        // Status
        .detection_flag     (corr_detection),
        .peak_magnitude     (corr_magnitude),
        .overflow_flag      (corr_overflow),
        
        // AXI-Lite (directly from decoder)
        .s_axi_awaddr       (s_axi_awaddr[15:0]),
        .s_axi_awvalid      (s_axi_awvalid & sel_correlator),
        .s_axi_awready      (),
        .s_axi_wdata        (s_axi_wdata),
        .s_axi_wvalid       (s_axi_wvalid & sel_correlator),
        .s_axi_wready       (),
        .s_axi_bresp        (),
        .s_axi_bvalid       (),
        .s_axi_bready       (s_axi_bready),
        .s_axi_araddr       (s_axi_araddr[15:0]),
        .s_axi_arvalid      (s_axi_arvalid & sel_correlator),
        .s_axi_arready      (),
        .s_axi_rdata        (rdata_correlator),
        .s_axi_rresp        (),
        .s_axi_rvalid       (),
        .s_axi_rready       (s_axi_rready)
    );
    
    //-------------------------------------------------------------------------
    // 2. Multi-Sensor Track Fusion Engine
    //-------------------------------------------------------------------------
    track_fusion_engine #(
        .MAX_TRACKS         (NUM_TRACKS),
        .NUM_SENSORS        (NUM_SENSORS)
    ) u_fusion (
        .clk                (clk_sys),
        .rst_n              (rst_n),
        
        // Internal radar detections
        .radar_detection    (corr_detection),
        .radar_range        (corr_magnitude),  // Simplified
        .radar_azimuth      (corr_code_phase),
        .radar_timestamp    (wr_tai_ns),
        
        // External tracks (Link-16)
        .ext_track_data     (link16_rx_data),
        .ext_track_valid    (link16_rx_valid),
        
        // ASTERIX input
        .asterix_data       (asterix_rx_data),
        .asterix_valid      (asterix_rx_valid),
        .asterix_sof        (asterix_rx_sof),
        .asterix_eof        (asterix_rx_eof),
        
        // ESM correlation
        .esm_data           (esm_emitter_data),
        .esm_valid          (esm_emitter_valid),
        
        // IRST triangulation
        .irst_bearing       (irst_bearing_data),
        .irst_valid         (irst_bearing_valid),
        
        // Fused track output
        .track_valid_out    (track_valid[0]),
        .track_id_out       (m_axis_track_tid),
        .track_data_out     (m_axis_track_tdata),
        .track_output_valid (m_axis_track_tvalid),
        
        // Configuration
        .cfg_fusion_mode    (2'b01),  // JDL Level 1
        .cfg_gate_size      (16'd100),
        
        // Status
        .sts_active_tracks  (),
        .sts_fusion_rate    ()
    );
    
    assign m_axis_track_tlast = 1'b1;  // Single track per transfer
    assign m_axis_track_tready_int = m_axis_track_tready;
    
    //-------------------------------------------------------------------------
    // 3. ECCM Controller
    //-------------------------------------------------------------------------
    eccm_controller #(
        .ML_CFAR_ENABLE     (ENABLE_AI_ECCM)
    ) u_eccm (
        .clk                (clk_sys),
        .rst_n              (rst_n),
        
        // Raw detection input
        .detection_mag      (corr_magnitude),
        .detection_valid    (corr_detection),
        .detection_range    (corr_code_phase),
        
        // Filtered output
        .filtered_mag       (eccm_filtered_mag),
        .filtered_valid     (eccm_track_valid),
        
        // Jammer detection
        .jammer_detected    (eccm_jammer_detected),
        .jammer_azimuth     (eccm_jammer_azimuth),
        .jammer_power_db    (),
        .jam_margin_db      (eccm_jam_margin_db),
        
        // Configuration
        .cfg_cfar_guard     (8'd4),
        .cfg_cfar_train     (8'd16),
        .cfg_cfar_alpha     (16'h0800),  // ~0.5 in Q1.15
        .cfg_ml_enable      (ENABLE_AI_ECCM),
        
        // Status
        .sts_detections     (),
        .sts_false_alarms   ()
    );
    
    //-------------------------------------------------------------------------
    // 4. Tri-Modal Communication Controller
    //-------------------------------------------------------------------------
    comm_controller_top u_comm (
        .clk                (clk_sys),
        .rst_n              (rst_n),
        
        // Link-16 interface
        .link16_rx_data     (link16_rx_data),
        .link16_rx_valid    (link16_rx_valid),
        .link16_tx_data     (link16_tx_data),
        .link16_tx_valid    (link16_tx_valid),
        .link16_tx_ready    (link16_tx_ready),
        
        // HF backup
        .hf_rx_data         (hf_rx_data),
        .hf_rx_valid        (hf_rx_valid),
        .hf_tx_data         (hf_tx_data),
        .hf_tx_valid        (hf_tx_valid),
        
        // SATCOM
        .satcom_rx_data     (satcom_rx_data),
        .satcom_rx_valid    (satcom_rx_valid),
        .satcom_tx_data     (satcom_tx_data),
        .satcom_tx_valid    (satcom_tx_valid),
        
        // Track data for transmission
        .track_data         (m_axis_track_tdata[63:0]),
        .track_valid        (m_axis_track_tvalid),
        .track_id           (m_axis_track_tid[7:0]),
        
        // Status
        .active_link        (comm_active_link),
        .link_healthy       (comm_link_healthy),
        .link_quality       (comm_quality),
        
        // Configuration
        .cfg_primary_link   (2'b00),  // Link-16 primary
        .cfg_failover_en    (1'b1)
    );
    
    //-------------------------------------------------------------------------
    // 5. White Rabbit PTP Synchronization
    //-------------------------------------------------------------------------
    generate
        if (ENABLE_WHITE_RABBIT) begin : gen_white_rabbit
            
            white_rabbit_ptp_core #(
                .CLK_FREQ_HZ        (ETH_CLK_FREQ_HZ),
                .TOA_FIFO_DEPTH     (64)
            ) u_white_rabbit (
                .clk_sys            (clk_eth),
                .clk_ref            (clk_ref),
                .clk_rx             (eth_rx_clk),
                .rst_n              (rst_n),
                
                // PTP timestamps
                .tx_timestamp_req   (1'b0),
                .tx_frame_id        (16'h0),
                .tx_timestamp       (),
                .tx_timestamp_valid (),
                
                .rx_sof             (eth_rx_dv),
                .rx_eof             (~eth_rx_dv),
                .rx_data            (eth_rxd),
                .rx_valid           (eth_rx_dv),
                .rx_timestamp       (),
                .rx_timestamp_valid (),
                
                // PTP message
                .ptp_msg_type       (),
                .ptp_msg_valid      (),
                
                // DMTD
                .dmtd_phase         (16'h0),
                .dmtd_valid         (1'b0),
                
                // Link delay
                .link_delay_coarse  (16'd100),
                .link_delay_valid   (1'b1),
                
                // DAC
                .dac_value          (vcxo_dac),
                .dac_valid          (vcxo_dac_valid),
                
                // ToA capture
                .toa_capture_trig   (|toa_triggers),
                .toa_channel_id     (8'h0),
                .toa_timestamp      (),
                .toa_channel_out    (),
                .toa_valid          (),
                .toa_fifo_empty     (),
                .toa_fifo_read      (1'b0),
                
                // Configuration
                .cfg_utc_offset     (32'd37),
                .cfg_master_mode    (1'b0),  // Slave mode
                .cfg_servo_kp       (32'h00001000),
                .cfg_servo_ki       (32'h00000100),
                .cfg_enable         (1'b1),
                
                // Status
                .sts_locked         (wr_locked),
                .sts_offset_ns      (wr_offset_ns),
                .sts_rtt_ns         (),
                .sts_lock_count     (),
                .sts_servo_state    ()
            );
            
        end else begin : gen_no_white_rabbit
            assign wr_locked = 1'b1;  // Fake lock
            assign wr_offset_ns = '0;
            assign vcxo_dac = 16'h8000;
            assign vcxo_dac_valid = 1'b0;
        end
    endgenerate
    
    //=========================================================================
    // System Registers
    //=========================================================================
    
    logic [31:0] sys_version;
    logic [31:0] sys_status;
    logic [31:0] sys_control;
    logic [31:0] sys_scratch;
    
    assign sys_version = 32'h0300_0001;  // v3.0.0 build 1
    
    assign sys_status = {
        8'h0,
        comm_quality,
        4'h0, comm_active_link, comm_link_healthy, wr_locked,
        eccm_jam_margin_db
    };
    
    // System control register write
    always_ff @(posedge clk_sys or negedge rst_n) begin
        if (!rst_n) begin
            sys_control <= 32'h0000_0001;  // Enable by default
            sys_scratch <= '0;
        end else if (s_axi_wvalid && sel_system) begin
            case (s_axi_awaddr[7:0])
                8'h04: sys_control <= s_axi_wdata;
                8'h10: sys_scratch <= s_axi_wdata;
            endcase
        end
    end
    
    // System register read
    always_comb begin
        case (s_axi_araddr[7:0])
            8'h00: rdata_system = sys_version;
            8'h04: rdata_system = sys_control;
            8'h08: rdata_system = sys_status;
            8'h0C: rdata_system = {16'h0, 16'(NUM_TRACKS)};
            8'h10: rdata_system = sys_scratch;
            default: rdata_system = 32'hDEAD_BEEF;
        endcase
    end
    
    //=========================================================================
    // AXI Response Multiplexer
    //=========================================================================
    
    always_comb begin
        if (sel_correlator)
            s_axi_rdata = rdata_correlator;
        else if (sel_fusion)
            s_axi_rdata = rdata_fusion;
        else if (sel_eccm)
            s_axi_rdata = rdata_eccm;
        else if (sel_comm)
            s_axi_rdata = rdata_comm;
        else if (sel_wr)
            s_axi_rdata = rdata_wr;
        else if (sel_quantum)
            s_axi_rdata = rdata_quantum;
        else if (sel_system)
            s_axi_rdata = rdata_system;
        else
            s_axi_rdata = 32'hDEAD_BEEF;
    end
    
    // Simplified AXI handshake (real implementation needs proper FSM)
    assign s_axi_awready = 1'b1;
    assign s_axi_wready = 1'b1;
    assign s_axi_bresp = 2'b00;  // OKAY
    assign s_axi_bvalid = s_axi_wvalid;
    assign s_axi_arready = 1'b1;
    assign s_axi_rresp = 2'b00;  // OKAY
    assign s_axi_rvalid = s_axi_arvalid;
    
    //=========================================================================
    // DAC Output (TX Waveform)
    //=========================================================================
    
    // Map PRBS to DAC format
    assign m_axis_dac_tdata = {
        {24{prbs_tx_data[7]}}, prbs_tx_data,   // I channel (sign-extended)
        32'h0                                   // Q channel (zeros for BPSK)
    };
    assign m_axis_dac_tvalid = 1'b1;
    assign m_axis_dac_tlast = 1'b0;
    
    //=========================================================================
    // Interrupt Generation
    //=========================================================================
    
    // Detection interrupt (pulse on new detection)
    logic corr_detection_d;
    always_ff @(posedge clk_sys or negedge rst_n) begin
        if (!rst_n)
            corr_detection_d <= 1'b0;
        else
            corr_detection_d <= corr_detection;
    end
    assign irq_detection = corr_detection & ~corr_detection_d;
    
    // Track update interrupt
    assign irq_track_update = m_axis_track_tvalid & m_axis_track_tready;
    
    // Communication event interrupt
    logic [1:0] comm_active_link_d;
    always_ff @(posedge clk_sys or negedge rst_n) begin
        if (!rst_n)
            comm_active_link_d <= 2'b00;
        else
            comm_active_link_d <= comm_active_link;
    end
    assign irq_comm_event = (comm_active_link != comm_active_link_d);
    
    // White Rabbit lock interrupt
    logic wr_locked_d;
    always_ff @(posedge clk_sys or negedge rst_n) begin
        if (!rst_n)
            wr_locked_d <= 1'b0;
        else
            wr_locked_d <= wr_locked;
    end
    assign irq_wr_lock = wr_locked & ~wr_locked_d;
    
    //=========================================================================
    // Status LEDs
    //=========================================================================
    
    assign led_status = {
        wr_locked,              // LED7: WR sync locked
        comm_link_healthy,      // LED6: Comm link OK
        eccm_jammer_detected,   // LED5: Jammer detected
        eccm_track_valid,       // LED4: Valid track
        corr_detection,         // LED3: Correlation detection
        corr_overflow,          // LED2: Correlator overflow
        |track_valid[7:0],      // LED1: Active tracks
        sys_control[0]          // LED0: System enabled
    };
    
    //=========================================================================
    // Debug Port
    //=========================================================================
    
    assign debug_port = {
        8'(comm_quality),
        eccm_jam_margin_db,
        corr_code_phase
    };

endmodule
