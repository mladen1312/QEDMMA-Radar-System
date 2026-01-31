// =============================================================================
// TIMESTAMP_CAPTURE Register Package
// Auto-generated from YAML - DO NOT EDIT MANUALLY
// Generator: QEDMMA Forge v9.0
// Generated: 2026-01-31 11:17:23
// Version: 1.0.0
// =============================================================================

`ifndef TIMESTAMP_CAPTURE_REGS_PKG_SV
`define TIMESTAMP_CAPTURE_REGS_PKG_SV

package timestamp_capture_regs_pkg;

  // Address Map Constants
  localparam int ADDR_WIDTH = 12;
  localparam int DATA_WIDTH = 32;

  // Register Addresses
  localparam logic [11:0] ADDR_CTRL = 12'h000; // Main control register
  localparam logic [11:0] ADDR_STATUS = 12'h004; // Status register
  localparam logic [11:0] ADDR_IRQ_EN = 12'h008; // Interrupt enable register
  localparam logic [11:0] ADDR_IRQ_STATUS = 12'h00C; // Interrupt status register (write 1 to clear)
  localparam logic [11:0] ADDR_TS_SEC_LO = 12'h100; // Timestamp seconds counter [31:0]
  localparam logic [11:0] ADDR_TS_SEC_HI = 12'h104; // Timestamp seconds counter [47:32]
  localparam logic [11:0] ADDR_TS_NS = 12'h108; // Timestamp nanoseconds within second
  localparam logic [11:0] ADDR_TS_FRAC = 12'h10C; // Sub-nanosecond fractional timestamp (TDC)
  localparam logic [11:0] ADDR_TS_LATCH_CTRL = 12'h110; // Timestamp latch control
  localparam logic [11:0] ADDR_CH0_CTRL = 12'h200; // Channel 0 control
  localparam logic [11:0] ADDR_CH0_TS_SEC = 12'h204; // Channel 0 captured seconds (FIFO read)
  localparam logic [11:0] ADDR_CH0_TS_NS = 12'h208; // Channel 0 captured nanoseconds (FIFO read)
  localparam logic [11:0] ADDR_CH0_TS_FRAC = 12'h20C; // Channel 0 captured fractional ns (FIFO read)
  localparam logic [11:0] ADDR_CH1_CTRL = 12'h210; // Channel 1 control (same fields as CH0)
  localparam logic [11:0] ADDR_CH1_TS_SEC = 12'h214; // 
  localparam logic [11:0] ADDR_CH1_TS_NS = 12'h218; // 
  localparam logic [11:0] ADDR_CH1_TS_FRAC = 12'h21C; // 
  localparam logic [11:0] ADDR_CH2_CTRL = 12'h220; // 
  localparam logic [11:0] ADDR_CH2_TS_SEC = 12'h224; // 
  localparam logic [11:0] ADDR_CH2_TS_NS = 12'h228; // 
  localparam logic [11:0] ADDR_CH2_TS_FRAC = 12'h22C; // 
  localparam logic [11:0] ADDR_CH3_CTRL = 12'h230; // 
  localparam logic [11:0] ADDR_CH3_TS_SEC = 12'h234; // 
  localparam logic [11:0] ADDR_CH3_TS_NS = 12'h238; // 
  localparam logic [11:0] ADDR_CH3_TS_FRAC = 12'h23C; // 
  localparam logic [11:0] ADDR_CAL_CTRL = 12'h300; // Calibration control
  localparam logic [11:0] ADDR_CAL_OFFSET = 12'h304; // Calibration offset (signed, in TDC units)
  localparam logic [11:0] ADDR_CAL_SKEW = 12'h308; // Inter-channel skew calibration
  localparam logic [11:0] ADDR_VERSION = 12'hF00; // IP version register
  localparam logic [11:0] ADDR_ID = 12'hF04; // IP identification (ASCII 'QEDT')
  localparam logic [11:0] ADDR_BUILD_DATE = 12'hF08; // Build date (BCD: YYYYMMDD)
  localparam logic [11:0] ADDR_GIT_HASH = 12'hF0C; // Git commit hash (lower 32 bits)

  // Field Bit Positions
  localparam int CTRL_ENABLE_BIT = 0;
  localparam int CTRL_SYNC_SRC_BIT = 121;
  localparam int CTRL_ARM_MODE_BIT = 243;
  localparam int CTRL_CH_EN_BIT = 668;
  localparam int CTRL_FIFO_CLR_BIT = 16;
  localparam int CTRL_SOFT_TRIG_BIT = 24;
  localparam int CTRL_SOFT_RST_BIT = 31;
  localparam int STATUS_LOCKED_BIT = 0;
  localparam int STATUS_HOLDOVER_BIT = 1;
  localparam int STATUS_SYNC_SRC_ACT_BIT = 182;
  localparam int STATUS_FIFO_EMPTY_BIT = 668;
  localparam int STATUS_FIFO_FULL_BIT = 912;
  localparam int STATUS_FIFO_OVERFLOW_BIT = 1156;
  localparam int STATUS_PPS_COUNT_BIT = 1884;
  localparam int IRQ_EN_CAPTURE_EN_BIT = 180;
  localparam int IRQ_EN_FIFO_THRESH_EN_BIT = 424;
  localparam int IRQ_EN_OVERFLOW_EN_BIT = 668;
  localparam int IRQ_EN_PPS_EN_BIT = 16;
  localparam int IRQ_EN_LOCK_CHANGE_EN_BIT = 17;
  localparam int IRQ_STATUS_CAPTURE_BIT = 180;
  localparam int IRQ_STATUS_FIFO_THRESH_BIT = 424;
  localparam int IRQ_STATUS_OVERFLOW_BIT = 668;
  localparam int IRQ_STATUS_PPS_BIT = 16;
  localparam int IRQ_STATUS_LOCK_CHANGE_BIT = 17;
  localparam int TS_SEC_LO_VALUE_BIT = 1860;
  localparam int TS_SEC_HI_VALUE_BIT = 900;
  localparam int TS_SEC_HI_RESERVED_BIT = 1876;
  localparam int TS_NS_VALUE_BIT = 1740;
  localparam int TS_NS_RESERVED_BIT = 1890;
  localparam int TS_FRAC_VALUE_BIT = 900;
  localparam int TS_FRAC_VALID_BIT = 31;
  localparam int TS_LATCH_CTRL_LATCH_BIT = 0;
  localparam int TS_LATCH_CTRL_AUTO_LATCH_BIT = 1;
  localparam int CH0_CTRL_EDGE_SEL_BIT = 0;
  localparam int CH0_CTRL_FILTER_EN_BIT = 1;
  localparam int CH0_CTRL_FILTER_LEN_BIT = 424;
  localparam int CH0_CTRL_FIFO_THRESH_BIT = 908;
  localparam int CH0_TS_SEC_VALUE_BIT = 1860;
  localparam int CH0_TS_NS_VALUE_BIT = 1740;
  localparam int CH0_TS_NS_RESERVED_BIT = 1890;
  localparam int CH0_TS_FRAC_VALUE_BIT = 900;
  localparam int CH0_TS_FRAC_FIFO_COUNT_BIT = 1636;
  localparam int CH0_TS_FRAC_VALID_BIT = 31;
  localparam int CAL_CTRL_CAL_EN_BIT = 0;
  localparam int CAL_CTRL_CAL_SRC_BIT = 121;
  localparam int CAL_CTRL_CAL_START_BIT = 8;
  localparam int CAL_CTRL_CAL_BUSY_BIT = 16;
  localparam int CAL_CTRL_CAL_DONE_BIT = 17;
  localparam int CAL_CTRL_CAL_ERROR_BIT = 18;
  localparam int CAL_OFFSET_VALUE_BIT = 900;
  localparam int CAL_OFFSET_AUTO_APPLY_BIT = 31;
  localparam int CAL_SKEW_CH1_SKEW_BIT = 420;
  localparam int CAL_SKEW_CH2_SKEW_BIT = 908;
  localparam int CAL_SKEW_CH3_SKEW_BIT = 1396;
  localparam int VERSION_PATCH_BIT = 420;
  localparam int VERSION_MINOR_BIT = 908;
  localparam int VERSION_MAJOR_BIT = 1396;
  localparam int VERSION_RESERVED_BIT = 1884;
  localparam int ID_VALUE_BIT = 1860;
  localparam int BUILD_DATE_VALUE_BIT = 1860;
  localparam int GIT_HASH_VALUE_BIT = 1860;

  // Enumerations
  typedef enum logic [0:0] {
    SYNC_SRC_WHITE_RABBIT = 1'd0,
    SYNC_SRC_CSAC = 1'd1,
    SYNC_SRC_EXTERNAL = 1'd2,
    SYNC_SRC_FREERUN = 1'd3
  } sync_src_e;

  typedef enum logic [0:0] {
    ARM_MODE_CONTINUOUS = 1'd0,
    ARM_MODE_SINGLE = 1'd1,
    ARM_MODE_TRIGGERED = 1'd2,
    ARM_MODE_GATED = 1'd3
  } arm_mode_e;

  typedef enum logic [0:0] {
    EDGE_SEL_RISING = 1'd0,
    EDGE_SEL_FALLING = 1'd1
  } edge_sel_e;

  typedef enum logic [0:0] {
    CAL_SRC_INTERNAL = 1'd0,
    CAL_SRC_EXTERNAL = 1'd1,
    CAL_SRC_PPS = 1'd2
  } cal_src_e;

  // Reset Values
  localparam logic [31:0] CTRL_RESET = 32'h00000000;
  localparam logic [31:0] STATUS_RESET = 32'h00000000;
  localparam logic [31:0] IRQ_EN_RESET = 32'h00000000;
  localparam logic [31:0] IRQ_STATUS_RESET = 32'h00000000;
  localparam logic [31:0] TS_SEC_LO_RESET = 32'h00000000;
  localparam logic [31:0] TS_SEC_HI_RESET = 32'h00000000;
  localparam logic [31:0] TS_NS_RESET = 32'h00000000;
  localparam logic [31:0] TS_FRAC_RESET = 32'h00000000;
  localparam logic [31:0] TS_LATCH_CTRL_RESET = 32'h00000000;
  localparam logic [31:0] CH0_CTRL_RESET = 32'h00000001;
  localparam logic [31:0] CH0_TS_SEC_RESET = 32'h00000000;
  localparam logic [31:0] CH0_TS_NS_RESET = 32'h00000000;
  localparam logic [31:0] CH0_TS_FRAC_RESET = 32'h00000000;
  localparam logic [31:0] CAL_CTRL_RESET = 32'h00000000;
  localparam logic [31:0] CAL_OFFSET_RESET = 32'h00000000;
  localparam logic [31:0] CAL_SKEW_RESET = 32'h00000000;
  localparam logic [31:0] VERSION_RESET = 32'h01000000;
  localparam logic [31:0] ID_RESET = 32'h51454454;
  localparam logic [31:0] BUILD_DATE_RESET = 32'h20260131;
  localparam logic [31:0] GIT_HASH_RESET = 32'h00000000;

endpackage : timestamp_capture_regs_pkg

`endif // TIMESTAMP_CAPTURE_REGS_PKG_SV