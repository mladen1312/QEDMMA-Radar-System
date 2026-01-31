// =============================================================================
// QEDMMA Timestamp Capture Unit - Register Package
// Author: Dr. Mladen Mešter
// Copyright (c) 2026 Dr. Mladen Mešter - All Rights Reserved
//
// Auto-generated from: timestamp_capture_regs.yaml
// DO NOT EDIT MANUALLY - Regenerate from YAML source
// =============================================================================
// =============================================================================
// [REQ-TS-003] AXI4-Lite register interface

`ifndef TIMESTAMP_CAPTURE_REGS_PKG_SV
`define TIMESTAMP_CAPTURE_REGS_PKG_SV

package timestamp_capture_regs_pkg;

  // ===========================================================================
  // Address Map Constants
  // ===========================================================================
  localparam int ADDR_WIDTH = 12;
  localparam int DATA_WIDTH = 32;
  
  // Control/Status Registers
  localparam logic [ADDR_WIDTH-1:0] ADDR_CTRL           = 12'h000;
  localparam logic [ADDR_WIDTH-1:0] ADDR_STATUS         = 12'h004;
  localparam logic [ADDR_WIDTH-1:0] ADDR_IRQ_EN         = 12'h008;
  localparam logic [ADDR_WIDTH-1:0] ADDR_IRQ_STATUS     = 12'h00C;
  
  // Timestamp Counter Registers
  localparam logic [ADDR_WIDTH-1:0] ADDR_TS_SEC_LO      = 12'h100;
  localparam logic [ADDR_WIDTH-1:0] ADDR_TS_SEC_HI      = 12'h104;
  localparam logic [ADDR_WIDTH-1:0] ADDR_TS_NS          = 12'h108;
  localparam logic [ADDR_WIDTH-1:0] ADDR_TS_FRAC        = 12'h10C;
  localparam logic [ADDR_WIDTH-1:0] ADDR_TS_LATCH_CTRL  = 12'h110;
  
  // Channel Registers (base addresses)
  localparam logic [ADDR_WIDTH-1:0] ADDR_CH0_BASE       = 12'h200;
  localparam logic [ADDR_WIDTH-1:0] ADDR_CH1_BASE       = 12'h210;
  localparam logic [ADDR_WIDTH-1:0] ADDR_CH2_BASE       = 12'h220;
  localparam logic [ADDR_WIDTH-1:0] ADDR_CH3_BASE       = 12'h230;
  
  // Channel register offsets
  localparam logic [3:0] CH_OFFSET_CTRL    = 4'h0;
  localparam logic [3:0] CH_OFFSET_TS_SEC  = 4'h4;
  localparam logic [3:0] CH_OFFSET_TS_NS   = 4'h8;
  localparam logic [3:0] CH_OFFSET_TS_FRAC = 4'hC;
  
  // Calibration Registers
  localparam logic [ADDR_WIDTH-1:0] ADDR_CAL_CTRL       = 12'h300;
  localparam logic [ADDR_WIDTH-1:0] ADDR_CAL_OFFSET     = 12'h304;
  localparam logic [ADDR_WIDTH-1:0] ADDR_CAL_SKEW       = 12'h308;
  
  // Version/ID Registers
  localparam logic [ADDR_WIDTH-1:0] ADDR_VERSION        = 12'hF00;
  localparam logic [ADDR_WIDTH-1:0] ADDR_ID             = 12'hF04;
  localparam logic [ADDR_WIDTH-1:0] ADDR_BUILD_DATE     = 12'hF08;
  localparam logic [ADDR_WIDTH-1:0] ADDR_GIT_HASH       = 12'hF0C;

  // ===========================================================================
  // Field Bit Definitions
  // ===========================================================================
  
  // CTRL Register Fields
  localparam int CTRL_ENABLE_BIT        = 0;
  localparam int CTRL_SYNC_SRC_LSB      = 1;
  localparam int CTRL_SYNC_SRC_MSB      = 2;
  localparam int CTRL_ARM_MODE_LSB      = 3;
  localparam int CTRL_ARM_MODE_MSB      = 4;
  localparam int CTRL_CH_EN_LSB         = 8;
  localparam int CTRL_CH_EN_MSB         = 11;
  localparam int CTRL_FIFO_CLR_BIT      = 16;
  localparam int CTRL_SOFT_TRIG_BIT     = 24;
  localparam int CTRL_SOFT_RST_BIT      = 31;
  
  // SYNC_SRC enumeration
  typedef enum logic [1:0] {
    SYNC_SRC_WHITE_RABBIT = 2'b00,
    SYNC_SRC_CSAC         = 2'b01,
    SYNC_SRC_EXTERNAL     = 2'b10,
    SYNC_SRC_FREERUN      = 2'b11
  } sync_src_e;
  
  // ARM_MODE enumeration
  typedef enum logic [1:0] {
    ARM_MODE_CONTINUOUS   = 2'b00,
    ARM_MODE_SINGLE       = 2'b01,
    ARM_MODE_TRIGGERED    = 2'b10,
    ARM_MODE_GATED        = 2'b11
  } arm_mode_e;
  
  // STATUS Register Fields
  localparam int STATUS_LOCKED_BIT         = 0;
  localparam int STATUS_HOLDOVER_BIT       = 1;
  localparam int STATUS_SYNC_SRC_ACT_LSB   = 2;
  localparam int STATUS_SYNC_SRC_ACT_MSB   = 3;
  localparam int STATUS_FIFO_EMPTY_LSB     = 8;
  localparam int STATUS_FIFO_EMPTY_MSB     = 11;
  localparam int STATUS_FIFO_FULL_LSB      = 12;
  localparam int STATUS_FIFO_FULL_MSB      = 15;
  localparam int STATUS_FIFO_OVERFLOW_LSB  = 16;
  localparam int STATUS_FIFO_OVERFLOW_MSB  = 19;
  localparam int STATUS_PPS_COUNT_LSB      = 24;
  localparam int STATUS_PPS_COUNT_MSB      = 31;

  // ===========================================================================
  // Register Structs (for simulation/verification)
  // ===========================================================================
  
  typedef struct packed {
    logic        soft_rst;        // [31]
    logic [6:0]  reserved1;       // [30:24]
    logic        soft_trig;       // [24]
    logic [6:0]  reserved2;       // [23:17]
    logic        fifo_clr;        // [16]
    logic [3:0]  reserved3;       // [15:12]
    logic [3:0]  ch_en;           // [11:8]
    logic [2:0]  reserved4;       // [7:5]
    arm_mode_e   arm_mode;        // [4:3]
    sync_src_e   sync_src;        // [2:1]
    logic        enable;          // [0]
  } ctrl_reg_t;
  
  typedef struct packed {
    logic [7:0]  pps_count;       // [31:24]
    logic [3:0]  reserved1;       // [23:20]
    logic [3:0]  fifo_overflow;   // [19:16]
    logic [3:0]  fifo_full;       // [15:12]
    logic [3:0]  fifo_empty;      // [11:8]
    logic [3:0]  reserved2;       // [7:4]
    logic [1:0]  sync_src_act;    // [3:2]
    logic        holdover;        // [1]
    logic        locked;          // [0]
  } status_reg_t;
  
  typedef struct packed {
    logic [47:0] seconds;         // Seconds counter
    logic [29:0] nanoseconds;     // Nanoseconds within second
    logic [15:0] fractional;      // Sub-nanosecond (TDC)
    logic        valid;           // Measurement valid
  } timestamp_t;
  
  // ===========================================================================
  // Reset Values
  // ===========================================================================
  localparam logic [31:0] CTRL_RESET        = 32'h00000000;
  localparam logic [31:0] STATUS_RESET      = 32'h00000000;
  localparam logic [31:0] IRQ_EN_RESET      = 32'h00000000;
  localparam logic [31:0] IRQ_STATUS_RESET  = 32'h00000000;
  localparam logic [31:0] CH_CTRL_RESET     = 32'h00000801;  // Edge=falling, thresh=128
  localparam logic [31:0] CAL_CTRL_RESET    = 32'h00000000;
  localparam logic [31:0] CAL_OFFSET_RESET  = 32'h00000000;
  localparam logic [31:0] CAL_SKEW_RESET    = 32'h00000000;
  
  // Version info (compile-time constants)
  localparam logic [31:0] VERSION_VALUE     = 32'h01_00_00_00;  // v1.0.0
  localparam logic [31:0] ID_VALUE          = 32'h51454454;     // "QEDT" ASCII
  localparam logic [31:0] BUILD_DATE_VALUE  = 32'h20260131;     // 2026-01-31 BCD

  // ===========================================================================
  // Helper Functions
  // ===========================================================================
  
  // Extract sync_src field from CTRL register
  function automatic sync_src_e get_sync_src(input logic [31:0] ctrl);
    return sync_src_e'(ctrl[CTRL_SYNC_SRC_MSB:CTRL_SYNC_SRC_LSB]);
  endfunction
  
  // Extract arm_mode field from CTRL register
  function automatic arm_mode_e get_arm_mode(input logic [31:0] ctrl);
    return arm_mode_e'(ctrl[CTRL_ARM_MODE_MSB:CTRL_ARM_MODE_LSB]);
  endfunction
  
  // Check if channel is enabled
  function automatic logic is_channel_enabled(input logic [31:0] ctrl, input int ch);
    return ctrl[CTRL_CH_EN_LSB + ch];
  endfunction
  
  // Convert nanoseconds to fractional representation
  function automatic logic [15:0] ns_to_frac(input real ns_frac);
    return logic'($rtoi(ns_frac * 65536.0));
  endfunction
  
  // Convert fractional to nanoseconds
  function automatic real frac_to_ns(input logic [15:0] frac);
    return real'(frac) / 65536.0;
  endfunction

endpackage : timestamp_capture_regs_pkg

`endif // TIMESTAMP_CAPTURE_REGS_PKG_SV
