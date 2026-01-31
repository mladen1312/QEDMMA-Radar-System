// =============================================================================
// QEDMMA Timestamp Capture Unit - Top Level Module
// Author: Dr. Mladen Mešter
// Copyright (c) 2026 Dr. Mladen Mešter - All Rights Reserved
//
// Description:
//   Sub-nanosecond timestamp capture unit for TDOA processing in QEDMMA system.
//   Features:
//     - 4 independent capture channels
//     - Sub-ns resolution via TDC interpolation
//     - White Rabbit / CSAC / External PPS synchronization
//     - Per-channel FIFOs (1024 deep)
//     - AXI4-Lite register interface
//
// Traceability:
//   [REQ-TS-001] Sub-nanosecond timestamp capture synchronized to White Rabbit PPS
//   [REQ-TS-002] Holdover mode with CSAC fallback
//   [REQ-TS-003] AXI4-Lite register interface for software access
//   [REQ-TS-004] Support for multiple capture channels (4× parallel)
//   [REQ-TS-005] Timestamp FIFO depth ≥ 1024 entries
// =============================================================================

`timescale 1ns / 1ps
`default_nettype none

module timestamp_capture #(
  parameter int NUM_CHANNELS     = 4,
  parameter int FIFO_DEPTH       = 1024,
  parameter int TS_CLK_FREQ_HZ   = 250_000_000,  // 250 MHz = 4ns resolution
  parameter int AXI_ADDR_WIDTH   = 12,
  parameter int AXI_DATA_WIDTH   = 32,
  parameter bit INCLUDE_TDC      = 1,            // Include fine TDC
  parameter int TDC_BITS         = 16            // TDC resolution bits
)(
  // =========================================================================
  // Clock and Reset
  // =========================================================================
  input  wire                         axi_clk,
  input  wire                         axi_rstn,
  input  wire                         ts_clk,      // High-speed timestamp clock
  input  wire                         ts_rstn,
  
  // =========================================================================
  // AXI4-Lite Slave Interface
  // =========================================================================
  // Write Address Channel
  input  wire [AXI_ADDR_WIDTH-1:0]    s_axi_awaddr,
  input  wire [2:0]                   s_axi_awprot,
  input  wire                         s_axi_awvalid,
  output wire                         s_axi_awready,
  
  // Write Data Channel
  input  wire [AXI_DATA_WIDTH-1:0]    s_axi_wdata,
  input  wire [AXI_DATA_WIDTH/8-1:0]  s_axi_wstrb,
  input  wire                         s_axi_wvalid,
  output wire                         s_axi_wready,
  
  // Write Response Channel
  output wire [1:0]                   s_axi_bresp,
  output wire                         s_axi_bvalid,
  input  wire                         s_axi_bready,
  
  // Read Address Channel
  input  wire [AXI_ADDR_WIDTH-1:0]    s_axi_araddr,
  input  wire [2:0]                   s_axi_arprot,
  input  wire                         s_axi_arvalid,
  output wire                         s_axi_arready,
  
  // Read Data Channel
  output wire [AXI_DATA_WIDTH-1:0]    s_axi_rdata,
  output wire [1:0]                   s_axi_rresp,
  output wire                         s_axi_rvalid,
  input  wire                         s_axi_rready,
  
  // =========================================================================
  // PPS Inputs
  // =========================================================================
  input  wire                         pps_wr,      // White Rabbit PPS
  input  wire                         pps_csac,    // CSAC PPS
  input  wire                         pps_ext,     // External PPS
  
  // =========================================================================
  // Capture Inputs
  // =========================================================================
  input  wire [NUM_CHANNELS-1:0]      capture_in,  // Capture trigger inputs
  input  wire                         gate_in,     // Gating signal
  
  // =========================================================================
  // Interrupt Output
  // =========================================================================
  output wire                         irq,
  
  // =========================================================================
  // Debug/Status
  // =========================================================================
  output wire                         locked,
  output wire                         holdover,
  output wire [7:0]                   pps_count
);

  // Import register package
  import timestamp_capture_regs_pkg::*;

  // ===========================================================================
  // Local Parameters
  // ===========================================================================
  localparam int NS_PER_CLK = 1_000_000_000 / TS_CLK_FREQ_HZ;  // 4 for 250MHz
  localparam int NS_BITS    = 30;  // Max 999,999,999
  localparam int SEC_BITS   = 48;  // ~8.9 million years
  
  // FIFO width: seconds[31:0] + nanoseconds[29:0] + fractional[15:0] + valid
  localparam int FIFO_WIDTH = 32 + 30 + 16 + 1;

  // ===========================================================================
  // Signal Declarations
  // ===========================================================================
  
  // Register interface signals
  logic [31:0] reg_ctrl;
  logic [31:0] reg_status;
  logic [31:0] reg_irq_en;
  logic [31:0] reg_irq_status;
  logic [31:0] reg_ts_latch_ctrl;
  logic [31:0] reg_cal_ctrl;
  logic [31:0] reg_cal_offset;
  logic [31:0] reg_cal_skew;
  logic [31:0] reg_ch_ctrl [NUM_CHANNELS];
  
  // Timestamp counter (ts_clk domain)
  logic [SEC_BITS-1:0]  ts_seconds;
  logic [NS_BITS-1:0]   ts_nanoseconds;
  logic [TDC_BITS-1:0]  ts_fractional;
  
  // Latched timestamp (for software read)
  logic [SEC_BITS-1:0]  ts_seconds_latch;
  logic [NS_BITS-1:0]   ts_nanoseconds_latch;
  logic [TDC_BITS-1:0]  ts_fractional_latch;
  logic                 ts_latch_valid;
  
  // PPS signals
  logic pps_selected;
  logic pps_selected_d;
  logic pps_edge;
  logic [7:0] pps_counter;
  logic pps_locked;
  logic pps_holdover;
  
  // Channel capture signals
  logic [NUM_CHANNELS-1:0] capture_sync;
  logic [NUM_CHANNELS-1:0] capture_edge;
  logic [NUM_CHANNELS-1:0] capture_filtered;
  
  // FIFO signals
  logic [FIFO_WIDTH-1:0]   fifo_din   [NUM_CHANNELS];
  logic [FIFO_WIDTH-1:0]   fifo_dout  [NUM_CHANNELS];
  logic [NUM_CHANNELS-1:0] fifo_wr_en;
  logic [NUM_CHANNELS-1:0] fifo_rd_en;
  logic [NUM_CHANNELS-1:0] fifo_empty;
  logic [NUM_CHANNELS-1:0] fifo_full;
  logic [$clog2(FIFO_DEPTH):0] fifo_count [NUM_CHANNELS];
  logic [NUM_CHANNELS-1:0] fifo_overflow;
  
  // Interrupt logic
  logic [NUM_CHANNELS-1:0] irq_capture;
  logic [NUM_CHANNELS-1:0] irq_thresh;
  logic [NUM_CHANNELS-1:0] irq_overflow;
  logic irq_pps;
  logic irq_lock_change;
  logic irq_combined;
  
  // Clock domain crossing
  logic [31:0] reg_ctrl_ts;      // CTRL register in ts_clk domain
  logic        enable_ts;
  logic [1:0]  sync_src_ts;
  logic [1:0]  arm_mode_ts;
  logic [3:0]  ch_en_ts;
  
  // AXI interface state machine
  typedef enum logic [1:0] {
    AXI_IDLE,
    AXI_WRITE,
    AXI_READ,
    AXI_RESP
  } axi_state_e;
  
  axi_state_e axi_wr_state, axi_rd_state;
  logic [AXI_ADDR_WIDTH-1:0] axi_wr_addr, axi_rd_addr;
  logic [AXI_DATA_WIDTH-1:0] axi_rd_data;

  // ===========================================================================
  // [REQ-TS-003] AXI4-Lite Register Interface
  // ===========================================================================
  
  // Write state machine
  always_ff @(posedge axi_clk or negedge axi_rstn) begin
    if (!axi_rstn) begin
      axi_wr_state <= AXI_IDLE;
      axi_wr_addr  <= '0;
    end else begin
      case (axi_wr_state)
        AXI_IDLE: begin
          if (s_axi_awvalid && s_axi_wvalid) begin
            axi_wr_addr  <= s_axi_awaddr;
            axi_wr_state <= AXI_WRITE;
          end
        end
        
        AXI_WRITE: begin
          axi_wr_state <= AXI_RESP;
        end
        
        AXI_RESP: begin
          if (s_axi_bready) begin
            axi_wr_state <= AXI_IDLE;
          end
        end
        
        default: axi_wr_state <= AXI_IDLE;
      endcase
    end
  end
  
  assign s_axi_awready = (axi_wr_state == AXI_IDLE);
  assign s_axi_wready  = (axi_wr_state == AXI_IDLE);
  assign s_axi_bvalid  = (axi_wr_state == AXI_RESP);
  assign s_axi_bresp   = 2'b00;  // OKAY
  
  // Register write logic
  always_ff @(posedge axi_clk or negedge axi_rstn) begin
    if (!axi_rstn) begin
      reg_ctrl         <= CTRL_RESET;
      reg_irq_en       <= IRQ_EN_RESET;
      reg_irq_status   <= IRQ_STATUS_RESET;
      reg_ts_latch_ctrl<= '0;
      reg_cal_ctrl     <= CAL_CTRL_RESET;
      reg_cal_offset   <= CAL_OFFSET_RESET;
      reg_cal_skew     <= CAL_SKEW_RESET;
      for (int i = 0; i < NUM_CHANNELS; i++) begin
        reg_ch_ctrl[i] <= CH_CTRL_RESET;
      end
    end else begin
      // Self-clearing bits
      reg_ctrl[CTRL_FIFO_CLR_BIT]  <= 1'b0;
      reg_ctrl[CTRL_SOFT_TRIG_BIT] <= 1'b0;
      reg_ctrl[CTRL_SOFT_RST_BIT]  <= 1'b0;
      reg_ts_latch_ctrl[0]         <= 1'b0;
      reg_cal_ctrl[8]              <= 1'b0;
      
      // W1C for IRQ_STATUS (clear on write 1)
      // Handled separately below
      
      if (axi_wr_state == AXI_WRITE) begin
        case (axi_wr_addr)
          ADDR_CTRL: begin
            // Apply write strobes
            for (int i = 0; i < 4; i++) begin
              if (s_axi_wstrb[i]) begin
                reg_ctrl[i*8 +: 8] <= s_axi_wdata[i*8 +: 8];
              end
            end
          end
          
          ADDR_IRQ_EN: begin
            for (int i = 0; i < 4; i++) begin
              if (s_axi_wstrb[i]) begin
                reg_irq_en[i*8 +: 8] <= s_axi_wdata[i*8 +: 8];
              end
            end
          end
          
          ADDR_IRQ_STATUS: begin
            // W1C behavior
            for (int i = 0; i < 4; i++) begin
              if (s_axi_wstrb[i]) begin
                reg_irq_status[i*8 +: 8] <= reg_irq_status[i*8 +: 8] & ~s_axi_wdata[i*8 +: 8];
              end
            end
          end
          
          ADDR_TS_LATCH_CTRL: begin
            if (s_axi_wstrb[0]) begin
              reg_ts_latch_ctrl[7:0] <= s_axi_wdata[7:0];
            end
          end
          
          ADDR_CAL_CTRL: begin
            for (int i = 0; i < 4; i++) begin
              if (s_axi_wstrb[i]) begin
                reg_cal_ctrl[i*8 +: 8] <= s_axi_wdata[i*8 +: 8];
              end
            end
          end
          
          ADDR_CAL_OFFSET: begin
            for (int i = 0; i < 4; i++) begin
              if (s_axi_wstrb[i]) begin
                reg_cal_offset[i*8 +: 8] <= s_axi_wdata[i*8 +: 8];
              end
            end
          end
          
          ADDR_CAL_SKEW: begin
            for (int i = 0; i < 4; i++) begin
              if (s_axi_wstrb[i]) begin
                reg_cal_skew[i*8 +: 8] <= s_axi_wdata[i*8 +: 8];
              end
            end
          end
          
          ADDR_CH0_BASE: reg_ch_ctrl[0] <= s_axi_wdata;
          ADDR_CH1_BASE: reg_ch_ctrl[1] <= s_axi_wdata;
          ADDR_CH2_BASE: reg_ch_ctrl[2] <= s_axi_wdata;
          ADDR_CH3_BASE: reg_ch_ctrl[3] <= s_axi_wdata;
          
          default: ; // Ignore writes to read-only or invalid addresses
        endcase
      end
      
      // Set interrupt status bits
      for (int ch = 0; ch < NUM_CHANNELS; ch++) begin
        if (irq_capture[ch])  reg_irq_status[ch]     <= 1'b1;
        if (irq_thresh[ch])   reg_irq_status[ch+4]   <= 1'b1;
        if (irq_overflow[ch]) reg_irq_status[ch+8]   <= 1'b1;
      end
      if (irq_pps)         reg_irq_status[16] <= 1'b1;
      if (irq_lock_change) reg_irq_status[17] <= 1'b1;
    end
  end
  
  // Read state machine
  always_ff @(posedge axi_clk or negedge axi_rstn) begin
    if (!axi_rstn) begin
      axi_rd_state <= AXI_IDLE;
      axi_rd_addr  <= '0;
      axi_rd_data  <= '0;
    end else begin
      case (axi_rd_state)
        AXI_IDLE: begin
          if (s_axi_arvalid) begin
            axi_rd_addr  <= s_axi_araddr;
            axi_rd_state <= AXI_READ;
          end
        end
        
        AXI_READ: begin
          // Register read mux
          case (axi_rd_addr)
            ADDR_CTRL:          axi_rd_data <= reg_ctrl;
            ADDR_STATUS:        axi_rd_data <= reg_status;
            ADDR_IRQ_EN:        axi_rd_data <= reg_irq_en;
            ADDR_IRQ_STATUS:    axi_rd_data <= reg_irq_status;
            
            ADDR_TS_SEC_LO:     axi_rd_data <= ts_seconds_latch[31:0];
            ADDR_TS_SEC_HI:     axi_rd_data <= {16'b0, ts_seconds_latch[47:32]};
            ADDR_TS_NS:         axi_rd_data <= {2'b0, ts_nanoseconds_latch};
            ADDR_TS_FRAC:       axi_rd_data <= {ts_latch_valid, 15'b0, ts_fractional_latch};
            ADDR_TS_LATCH_CTRL: axi_rd_data <= reg_ts_latch_ctrl;
            
            // Channel FIFO reads handled specially
            ADDR_CH0_BASE + CH_OFFSET_CTRL:    axi_rd_data <= reg_ch_ctrl[0];
            ADDR_CH0_BASE + CH_OFFSET_TS_SEC:  axi_rd_data <= fifo_dout[0][78:47];
            ADDR_CH0_BASE + CH_OFFSET_TS_NS:   axi_rd_data <= {2'b0, fifo_dout[0][46:17]};
            ADDR_CH0_BASE + CH_OFFSET_TS_FRAC: axi_rd_data <= {fifo_dout[0][0], 3'b0, fifo_count[0], fifo_dout[0][16:1]};
            
            ADDR_CH1_BASE + CH_OFFSET_CTRL:    axi_rd_data <= reg_ch_ctrl[1];
            ADDR_CH1_BASE + CH_OFFSET_TS_SEC:  axi_rd_data <= fifo_dout[1][78:47];
            ADDR_CH1_BASE + CH_OFFSET_TS_NS:   axi_rd_data <= {2'b0, fifo_dout[1][46:17]};
            ADDR_CH1_BASE + CH_OFFSET_TS_FRAC: axi_rd_data <= {fifo_dout[1][0], 3'b0, fifo_count[1], fifo_dout[1][16:1]};
            
            ADDR_CH2_BASE + CH_OFFSET_CTRL:    axi_rd_data <= reg_ch_ctrl[2];
            ADDR_CH2_BASE + CH_OFFSET_TS_SEC:  axi_rd_data <= fifo_dout[2][78:47];
            ADDR_CH2_BASE + CH_OFFSET_TS_NS:   axi_rd_data <= {2'b0, fifo_dout[2][46:17]};
            ADDR_CH2_BASE + CH_OFFSET_TS_FRAC: axi_rd_data <= {fifo_dout[2][0], 3'b0, fifo_count[2], fifo_dout[2][16:1]};
            
            ADDR_CH3_BASE + CH_OFFSET_CTRL:    axi_rd_data <= reg_ch_ctrl[3];
            ADDR_CH3_BASE + CH_OFFSET_TS_SEC:  axi_rd_data <= fifo_dout[3][78:47];
            ADDR_CH3_BASE + CH_OFFSET_TS_NS:   axi_rd_data <= {2'b0, fifo_dout[3][46:17]};
            ADDR_CH3_BASE + CH_OFFSET_TS_FRAC: axi_rd_data <= {fifo_dout[3][0], 3'b0, fifo_count[3], fifo_dout[3][16:1]};
            
            ADDR_CAL_CTRL:      axi_rd_data <= reg_cal_ctrl;
            ADDR_CAL_OFFSET:    axi_rd_data <= reg_cal_offset;
            ADDR_CAL_SKEW:      axi_rd_data <= reg_cal_skew;
            
            ADDR_VERSION:       axi_rd_data <= VERSION_VALUE;
            ADDR_ID:            axi_rd_data <= ID_VALUE;
            ADDR_BUILD_DATE:    axi_rd_data <= BUILD_DATE_VALUE;
            ADDR_GIT_HASH:      axi_rd_data <= 32'h0;  // Populated at build time
            
            default:            axi_rd_data <= 32'hDEADBEEF;
          endcase
          axi_rd_state <= AXI_RESP;
        end
        
        AXI_RESP: begin
          if (s_axi_rready) begin
            axi_rd_state <= AXI_IDLE;
          end
        end
        
        default: axi_rd_state <= AXI_IDLE;
      endcase
    end
  end
  
  assign s_axi_arready = (axi_rd_state == AXI_IDLE);
  assign s_axi_rvalid  = (axi_rd_state == AXI_RESP);
  assign s_axi_rdata   = axi_rd_data;
  assign s_axi_rresp   = 2'b00;  // OKAY
  
  // FIFO read enable on TS_FRAC register read
  generate
    for (genvar ch = 0; ch < NUM_CHANNELS; ch++) begin : gen_fifo_rd
      assign fifo_rd_en[ch] = (axi_rd_state == AXI_READ) && 
                              (axi_rd_addr == (ADDR_CH0_BASE + ch*16 + CH_OFFSET_TS_FRAC));
    end
  endgenerate

  // ===========================================================================
  // Status Register Assembly
  // ===========================================================================
  assign reg_status = {
    pps_counter,                    // [31:24]
    4'b0,                           // [23:20]
    fifo_overflow,                  // [19:16]
    fifo_full,                      // [15:12]
    fifo_empty,                     // [11:8]
    4'b0,                           // [7:4]
    reg_ctrl[CTRL_SYNC_SRC_MSB:CTRL_SYNC_SRC_LSB], // [3:2] Active sync src
    pps_holdover,                   // [1]
    pps_locked                      // [0]
  };

  // ===========================================================================
  // [REQ-TS-002] PPS Selection and Lock Detection
  // ===========================================================================
  
  // PPS multiplexer
  always_comb begin
    case (sync_src_e'(reg_ctrl[CTRL_SYNC_SRC_MSB:CTRL_SYNC_SRC_LSB]))
      SYNC_SRC_WHITE_RABBIT: pps_selected = pps_wr;
      SYNC_SRC_CSAC:         pps_selected = pps_csac;
      SYNC_SRC_EXTERNAL:     pps_selected = pps_ext;
      SYNC_SRC_FREERUN:      pps_selected = 1'b0;
      default:               pps_selected = pps_wr;
    endcase
  end
  
  // PPS edge detection (ts_clk domain)
  always_ff @(posedge ts_clk or negedge ts_rstn) begin
    if (!ts_rstn) begin
      pps_selected_d <= 1'b0;
    end else begin
      pps_selected_d <= pps_selected;
    end
  end
  
  assign pps_edge = pps_selected && !pps_selected_d;
  
  // PPS counter and lock detection
  always_ff @(posedge ts_clk or negedge ts_rstn) begin
    if (!ts_rstn) begin
      pps_counter  <= 8'd0;
      pps_locked   <= 1'b0;
      pps_holdover <= 1'b0;
    end else begin
      if (pps_edge) begin
        pps_counter <= pps_counter + 1'b1;
        pps_locked  <= 1'b1;
        pps_holdover <= 1'b0;
      end
      // TODO: Add holdover detection based on PPS timeout
    end
  end

  // ===========================================================================
  // [REQ-TS-001] Timestamp Counter (ts_clk domain)
  // ===========================================================================
  
  always_ff @(posedge ts_clk or negedge ts_rstn) begin
    if (!ts_rstn) begin
      ts_seconds     <= '0;
      ts_nanoseconds <= '0;
    end else if (reg_ctrl[CTRL_SOFT_RST_BIT]) begin
      ts_seconds     <= '0;
      ts_nanoseconds <= '0;
    end else if (reg_ctrl[CTRL_ENABLE_BIT]) begin
      if (pps_edge && pps_locked) begin
        // Synchronize to PPS
        ts_seconds     <= ts_seconds + 1'b1;
        ts_nanoseconds <= '0;
      end else begin
        // Normal counting
        if (ts_nanoseconds >= (1_000_000_000 - NS_PER_CLK)) begin
          ts_nanoseconds <= '0;
          ts_seconds     <= ts_seconds + 1'b1;
        end else begin
          ts_nanoseconds <= ts_nanoseconds + NS_PER_CLK;
        end
      end
    end
  end
  
  // TDC (Time-to-Digital Converter) for sub-ns resolution
  generate
    if (INCLUDE_TDC) begin : gen_tdc
      // Simplified TDC using phase interpolation
      // In real implementation, use carry-chain delay line or Vernier TDC
      logic [TDC_BITS-1:0] tdc_phase;
      
      always_ff @(posedge ts_clk or negedge ts_rstn) begin
        if (!ts_rstn) begin
          tdc_phase <= '0;
        end else begin
          // Placeholder: In real implementation, sample delay line
          tdc_phase <= tdc_phase + 1'b1;  // Free-running for now
        end
      end
      
      assign ts_fractional = tdc_phase;
    end else begin : gen_no_tdc
      assign ts_fractional = '0;
    end
  endgenerate
  
  // Timestamp latch for software read
  always_ff @(posedge axi_clk or negedge axi_rstn) begin
    if (!axi_rstn) begin
      ts_seconds_latch     <= '0;
      ts_nanoseconds_latch <= '0;
      ts_fractional_latch  <= '0;
      ts_latch_valid       <= 1'b0;
    end else begin
      if (reg_ts_latch_ctrl[0]) begin  // Manual latch
        ts_seconds_latch     <= ts_seconds;
        ts_nanoseconds_latch <= ts_nanoseconds;
        ts_fractional_latch  <= ts_fractional;
        ts_latch_valid       <= 1'b1;
      end else if (reg_ts_latch_ctrl[1] && pps_edge) begin  // Auto-latch on PPS
        ts_seconds_latch     <= ts_seconds;
        ts_nanoseconds_latch <= ts_nanoseconds;
        ts_fractional_latch  <= ts_fractional;
        ts_latch_valid       <= 1'b1;
      end
    end
  end

  // ===========================================================================
  // [REQ-TS-004] Multi-Channel Capture Logic
  // ===========================================================================
  
  generate
    for (genvar ch = 0; ch < NUM_CHANNELS; ch++) begin : gen_channel
      // Input synchronizer (2-FF for metastability)
      logic capture_sync1, capture_sync2, capture_sync3;
      
      always_ff @(posedge ts_clk or negedge ts_rstn) begin
        if (!ts_rstn) begin
          capture_sync1 <= 1'b0;
          capture_sync2 <= 1'b0;
          capture_sync3 <= 1'b0;
        end else begin
          capture_sync1 <= capture_in[ch];
          capture_sync2 <= capture_sync1;
          capture_sync3 <= capture_sync2;
        end
      end
      
      assign capture_sync[ch] = capture_sync2;
      
      // Edge detection based on channel configuration
      logic edge_detected;
      always_comb begin
        if (reg_ch_ctrl[ch][0]) begin  // EDGE_SEL = falling
          edge_detected = capture_sync3 && !capture_sync2;
        end else begin  // EDGE_SEL = rising
          edge_detected = !capture_sync3 && capture_sync2;
        end
      end
      
      // Glitch filter (optional)
      logic [15:0] filter_counter;
      logic filter_active;
      
      always_ff @(posedge ts_clk or negedge ts_rstn) begin
        if (!ts_rstn) begin
          filter_counter   <= '0;
          capture_filtered[ch] <= 1'b0;
          filter_active    <= 1'b0;
        end else begin
          if (reg_ch_ctrl[ch][1]) begin  // FILTER_EN
            if (edge_detected && !filter_active) begin
              filter_active  <= 1'b1;
              filter_counter <= '0;
            end else if (filter_active) begin
              filter_counter <= filter_counter + 1'b1;
              if (filter_counter >= (1 << reg_ch_ctrl[ch][7:4])) begin
                capture_filtered[ch] <= 1'b1;
                filter_active <= 1'b0;
              end
            end else begin
              capture_filtered[ch] <= 1'b0;
            end
          end else begin
            capture_filtered[ch] <= edge_detected;
          end
        end
      end
      
      assign capture_edge[ch] = capture_filtered[ch];
    end
  endgenerate

  // ===========================================================================
  // [REQ-TS-005] Timestamp FIFOs
  // ===========================================================================
  
  generate
    for (genvar ch = 0; ch < NUM_CHANNELS; ch++) begin : gen_fifo
      
      // Capture data assembly
      logic [FIFO_WIDTH-1:0] capture_data;
      logic capture_valid;
      
      always_ff @(posedge ts_clk or negedge ts_rstn) begin
        if (!ts_rstn) begin
          capture_valid <= 1'b0;
          capture_data  <= '0;
        end else begin
          capture_valid <= 1'b0;
          
          if (capture_edge[ch] && 
              reg_ctrl[CTRL_ENABLE_BIT] && 
              reg_ctrl[CTRL_CH_EN_LSB + ch]) begin
            
            // Apply calibration offset
            logic [TDC_BITS-1:0] cal_frac;
            logic signed [TDC_BITS:0] frac_with_offset;
            
            frac_with_offset = $signed({1'b0, ts_fractional}) + 
                               $signed(reg_cal_offset[15:0]);
            
            if (frac_with_offset < 0) begin
              cal_frac = '0;
            end else if (frac_with_offset >= (1 << TDC_BITS)) begin
              cal_frac = {TDC_BITS{1'b1}};
            end else begin
              cal_frac = frac_with_offset[TDC_BITS-1:0];
            end
            
            capture_data <= {
              ts_seconds[31:0],      // [78:47]
              ts_nanoseconds,        // [46:17]
              cal_frac,              // [16:1]
              1'b1                   // [0] valid
            };
            capture_valid <= 1'b1;
          end
        end
      end
      
      assign fifo_din[ch] = capture_data;
      assign fifo_wr_en[ch] = capture_valid && !fifo_full[ch];
      
      // Synchronous FIFO instance
      sync_fifo #(
        .WIDTH(FIFO_WIDTH),
        .DEPTH(FIFO_DEPTH)
      ) u_fifo (
        .clk      (ts_clk),
        .rst_n    (ts_rstn && !reg_ctrl[CTRL_FIFO_CLR_BIT]),
        .wr_en    (fifo_wr_en[ch]),
        .wr_data  (fifo_din[ch]),
        .rd_en    (fifo_rd_en[ch]),
        .rd_data  (fifo_dout[ch]),
        .empty    (fifo_empty[ch]),
        .full     (fifo_full[ch]),
        .count    (fifo_count[ch])
      );
      
      // Overflow detection
      always_ff @(posedge ts_clk or negedge ts_rstn) begin
        if (!ts_rstn || reg_ctrl[CTRL_FIFO_CLR_BIT]) begin
          fifo_overflow[ch] <= 1'b0;
        end else if (capture_valid && fifo_full[ch]) begin
          fifo_overflow[ch] <= 1'b1;
        end
      end
      
      // Interrupt generation
      assign irq_capture[ch]  = capture_valid;
      assign irq_thresh[ch]   = (fifo_count[ch] >= reg_ch_ctrl[ch][15:8]);
      assign irq_overflow[ch] = fifo_overflow[ch];
      
    end
  endgenerate

  // ===========================================================================
  // Interrupt Logic
  // ===========================================================================
  
  assign irq_pps = pps_edge;
  
  logic pps_locked_d;
  always_ff @(posedge axi_clk or negedge axi_rstn) begin
    if (!axi_rstn) begin
      pps_locked_d <= 1'b0;
    end else begin
      pps_locked_d <= pps_locked;
    end
  end
  assign irq_lock_change = pps_locked != pps_locked_d;
  
  // Combined interrupt
  assign irq_combined = 
    |((irq_capture  | reg_irq_status[3:0])   & reg_irq_en[3:0])   |
    |((irq_thresh   | reg_irq_status[7:4])   & reg_irq_en[7:4])   |
    |((irq_overflow | reg_irq_status[11:8])  & reg_irq_en[11:8])  |
    ((irq_pps        | reg_irq_status[16])    & reg_irq_en[16])    |
    ((irq_lock_change| reg_irq_status[17])    & reg_irq_en[17]);
  
  assign irq = irq_combined;

  // ===========================================================================
  // Output Assignments
  // ===========================================================================
  
  assign locked    = pps_locked;
  assign holdover  = pps_holdover;
  assign pps_count = pps_counter;

endmodule : timestamp_capture


// =============================================================================
// Synchronous FIFO Module
// =============================================================================
module sync_fifo #(
  parameter int WIDTH = 32,
  parameter int DEPTH = 1024
)(
  input  wire              clk,
  input  wire              rst_n,
  input  wire              wr_en,
  input  wire [WIDTH-1:0]  wr_data,
  input  wire              rd_en,
  output wire [WIDTH-1:0]  rd_data,
  output wire              empty,
  output wire              full,
  output wire [$clog2(DEPTH):0] count
);

  localparam int ADDR_WIDTH = $clog2(DEPTH);
  
  logic [WIDTH-1:0] mem [DEPTH];
  logic [ADDR_WIDTH:0] wr_ptr, rd_ptr;
  logic [ADDR_WIDTH:0] fill_count;
  
  assign count = fill_count;
  assign empty = (fill_count == 0);
  assign full  = (fill_count == DEPTH);
  
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wr_ptr     <= '0;
      rd_ptr     <= '0;
      fill_count <= '0;
    end else begin
      if (wr_en && !full) begin
        mem[wr_ptr[ADDR_WIDTH-1:0]] <= wr_data;
        wr_ptr <= wr_ptr + 1'b1;
      end
      
      if (rd_en && !empty) begin
        rd_ptr <= rd_ptr + 1'b1;
      end
      
      // Update count
      case ({wr_en && !full, rd_en && !empty})
        2'b10:   fill_count <= fill_count + 1'b1;
        2'b01:   fill_count <= fill_count - 1'b1;
        default: fill_count <= fill_count;
      endcase
    end
  end
  
  assign rd_data = mem[rd_ptr[ADDR_WIDTH-1:0]];

endmodule : sync_fifo

`default_nettype wire
