"""
timestamp_capture Register Driver

Auto-generated from YAML - DO NOT EDIT MANUALLY
Generator: QEDMMA Forge v9.0
Generated: 2026-01-31 11:17:23
Version: 1.0.0
"""

from typing import Optional
import struct


class TimestampCaptureRegs:
    """Register access class for timestamp_capture."""

    # Register Offsets
    ADDR_CTRL = 0x000
    ADDR_STATUS = 0x004
    ADDR_IRQ_EN = 0x008
    ADDR_IRQ_STATUS = 0x00C
    ADDR_TS_SEC_LO = 0x100
    ADDR_TS_SEC_HI = 0x104
    ADDR_TS_NS = 0x108
    ADDR_TS_FRAC = 0x10C
    ADDR_TS_LATCH_CTRL = 0x110
    ADDR_CH0_CTRL = 0x200
    ADDR_CH0_TS_SEC = 0x204
    ADDR_CH0_TS_NS = 0x208
    ADDR_CH0_TS_FRAC = 0x20C
    ADDR_CH1_CTRL = 0x210
    ADDR_CH1_TS_SEC = 0x214
    ADDR_CH1_TS_NS = 0x218
    ADDR_CH1_TS_FRAC = 0x21C
    ADDR_CH2_CTRL = 0x220
    ADDR_CH2_TS_SEC = 0x224
    ADDR_CH2_TS_NS = 0x228
    ADDR_CH2_TS_FRAC = 0x22C
    ADDR_CH3_CTRL = 0x230
    ADDR_CH3_TS_SEC = 0x234
    ADDR_CH3_TS_NS = 0x238
    ADDR_CH3_TS_FRAC = 0x23C
    ADDR_CAL_CTRL = 0x300
    ADDR_CAL_OFFSET = 0x304
    ADDR_CAL_SKEW = 0x308
    ADDR_VERSION = 0xF00
    ADDR_ID = 0xF04
    ADDR_BUILD_DATE = 0xF08
    ADDR_GIT_HASH = 0xF0C

    def __init__(self, base_addr: int = 0x80000000, read_fn=None, write_fn=None):
        """Initialize with base address and optional read/write functions."""
        self.base_addr = base_addr
        self._read_fn = read_fn
        self._write_fn = write_fn

    def read(self, offset: int) -> int:
        """Read register at offset."""
        if self._read_fn:
            return self._read_fn(self.base_addr + offset)
        raise NotImplementedError("No read function provided")

    def write(self, offset: int, value: int) -> None:
        """Write register at offset."""
        if self._write_fn:
            self._write_fn(self.base_addr + offset, value)
        else:
            raise NotImplementedError("No write function provided")

    def read_ctrl(self) -> int:
        """Read CTRL register. Main control register"""
        return self.read(self.ADDR_CTRL)

    def write_ctrl(self, value: int) -> None:
        """Write CTRL register. Main control register"""
        self.write(self.ADDR_CTRL, value)

    def read_status(self) -> int:
        """Read STATUS register. Status register"""
        return self.read(self.ADDR_STATUS)

    def read_irq_en(self) -> int:
        """Read IRQ_EN register. Interrupt enable register"""
        return self.read(self.ADDR_IRQ_EN)

    def write_irq_en(self, value: int) -> None:
        """Write IRQ_EN register. Interrupt enable register"""
        self.write(self.ADDR_IRQ_EN, value)

    def read_irq_status(self) -> int:
        """Read IRQ_STATUS register. Interrupt status register (write 1 to clear)"""
        return self.read(self.ADDR_IRQ_STATUS)

    def write_irq_status(self, value: int) -> None:
        """Write IRQ_STATUS register. Interrupt status register (write 1 to clear)"""
        self.write(self.ADDR_IRQ_STATUS, value)

    def read_ts_sec_lo(self) -> int:
        """Read TS_SEC_LO register. Timestamp seconds counter [31:0]"""
        return self.read(self.ADDR_TS_SEC_LO)

    def read_ts_sec_hi(self) -> int:
        """Read TS_SEC_HI register. Timestamp seconds counter [47:32]"""
        return self.read(self.ADDR_TS_SEC_HI)

    def read_ts_ns(self) -> int:
        """Read TS_NS register. Timestamp nanoseconds within second"""
        return self.read(self.ADDR_TS_NS)

    def read_ts_frac(self) -> int:
        """Read TS_FRAC register. Sub-nanosecond fractional timestamp (TDC)"""
        return self.read(self.ADDR_TS_FRAC)

    def read_ts_latch_ctrl(self) -> int:
        """Read TS_LATCH_CTRL register. Timestamp latch control"""
        return self.read(self.ADDR_TS_LATCH_CTRL)

    def write_ts_latch_ctrl(self, value: int) -> None:
        """Write TS_LATCH_CTRL register. Timestamp latch control"""
        self.write(self.ADDR_TS_LATCH_CTRL, value)

    def read_ch0_ctrl(self) -> int:
        """Read CH0_CTRL register. Channel 0 control"""
        return self.read(self.ADDR_CH0_CTRL)

    def write_ch0_ctrl(self, value: int) -> None:
        """Write CH0_CTRL register. Channel 0 control"""
        self.write(self.ADDR_CH0_CTRL, value)

    def read_ch0_ts_sec(self) -> int:
        """Read CH0_TS_SEC register. Channel 0 captured seconds (FIFO read)"""
        return self.read(self.ADDR_CH0_TS_SEC)

    def read_ch0_ts_ns(self) -> int:
        """Read CH0_TS_NS register. Channel 0 captured nanoseconds (FIFO read)"""
        return self.read(self.ADDR_CH0_TS_NS)

    def read_ch0_ts_frac(self) -> int:
        """Read CH0_TS_FRAC register. Channel 0 captured fractional ns (FIFO read)"""
        return self.read(self.ADDR_CH0_TS_FRAC)

    def read_cal_ctrl(self) -> int:
        """Read CAL_CTRL register. Calibration control"""
        return self.read(self.ADDR_CAL_CTRL)

    def write_cal_ctrl(self, value: int) -> None:
        """Write CAL_CTRL register. Calibration control"""
        self.write(self.ADDR_CAL_CTRL, value)

    def read_cal_offset(self) -> int:
        """Read CAL_OFFSET register. Calibration offset (signed, in TDC units)"""
        return self.read(self.ADDR_CAL_OFFSET)

    def write_cal_offset(self, value: int) -> None:
        """Write CAL_OFFSET register. Calibration offset (signed, in TDC units)"""
        self.write(self.ADDR_CAL_OFFSET, value)

    def read_cal_skew(self) -> int:
        """Read CAL_SKEW register. Inter-channel skew calibration"""
        return self.read(self.ADDR_CAL_SKEW)

    def write_cal_skew(self, value: int) -> None:
        """Write CAL_SKEW register. Inter-channel skew calibration"""
        self.write(self.ADDR_CAL_SKEW, value)

    def read_version(self) -> int:
        """Read VERSION register. IP version register"""
        return self.read(self.ADDR_VERSION)

    def read_id(self) -> int:
        """Read ID register. IP identification (ASCII 'QEDT')"""
        return self.read(self.ADDR_ID)

    def read_build_date(self) -> int:
        """Read BUILD_DATE register. Build date (BCD: YYYYMMDD)"""
        return self.read(self.ADDR_BUILD_DATE)

    def read_git_hash(self) -> int:
        """Read GIT_HASH register. Git commit hash (lower 32 bits)"""
        return self.read(self.ADDR_GIT_HASH)

    # Field Access Methods
    def get_ctrl_enable(self) -> int:
        """Get ENABLE field from CTRL. Global enable for timestamp capture"""
        return (self.read_ctrl() >> 0) & 0x1

    def get_ctrl_sync_src(self) -> int:
        """Get SYNC_SRC field from CTRL. PPS synchronization source select"""
        return (self.read_ctrl() >> 121) & 0x1

    def get_ctrl_arm_mode(self) -> int:
        """Get ARM_MODE field from CTRL. Capture arm mode"""
        return (self.read_ctrl() >> 243) & 0x1

    def get_ctrl_ch_en(self) -> int:
        """Get CH_EN field from CTRL. Per-channel enable bits [CH3:CH0]"""
        return (self.read_ctrl() >> 668) & 0x1

    def get_ctrl_fifo_clr(self) -> int:
        """Get FIFO_CLR field from CTRL. Write 1 to clear all FIFOs"""
        return (self.read_ctrl() >> 16) & 0x1

    def get_ctrl_soft_trig(self) -> int:
        """Get SOFT_TRIG field from CTRL. Software trigger (self-clearing)"""
        return (self.read_ctrl() >> 24) & 0x1

    def get_ctrl_soft_rst(self) -> int:
        """Get SOFT_RST field from CTRL. Software reset (self-clearing)"""
        return (self.read_ctrl() >> 31) & 0x1

    def get_status_locked(self) -> int:
        """Get LOCKED field from STATUS. PPS lock status (1=locked)"""
        return (self.read_status() >> 0) & 0x1

    def get_status_holdover(self) -> int:
        """Get HOLDOVER field from STATUS. Holdover mode active"""
        return (self.read_status() >> 1) & 0x1

    def get_status_sync_src_act(self) -> int:
        """Get SYNC_SRC_ACT field from STATUS. Active sync source (mirrors CTRL.SYNC_SRC when locked)"""
        return (self.read_status() >> 182) & 0x1

    def get_status_fifo_empty(self) -> int:
        """Get FIFO_EMPTY field from STATUS. Per-channel FIFO empty flags"""
        return (self.read_status() >> 668) & 0x1

    def get_status_fifo_full(self) -> int:
        """Get FIFO_FULL field from STATUS. Per-channel FIFO full flags"""
        return (self.read_status() >> 912) & 0x1

    def get_status_fifo_overflow(self) -> int:
        """Get FIFO_OVERFLOW field from STATUS. Per-channel FIFO overflow (sticky)"""
        return (self.read_status() >> 1156) & 0x1

    def get_status_pps_count(self) -> int:
        """Get PPS_COUNT field from STATUS. PPS pulse counter (rolls over at 256)"""
        return (self.read_status() >> 1884) & 0x1

    def get_irq_en_capture_en(self) -> int:
        """Get CAPTURE_EN field from IRQ_EN. Per-channel capture interrupt enable"""
        return (self.read_irq_en() >> 180) & 0x1

    def get_irq_en_fifo_thresh_en(self) -> int:
        """Get FIFO_THRESH_EN field from IRQ_EN. Per-channel FIFO threshold interrupt enable"""
        return (self.read_irq_en() >> 424) & 0x1

    def get_irq_en_overflow_en(self) -> int:
        """Get OVERFLOW_EN field from IRQ_EN. Per-channel overflow interrupt enable"""
        return (self.read_irq_en() >> 668) & 0x1

    def get_irq_en_pps_en(self) -> int:
        """Get PPS_EN field from IRQ_EN. PPS event interrupt enable"""
        return (self.read_irq_en() >> 16) & 0x1

    def get_irq_en_lock_change_en(self) -> int:
        """Get LOCK_CHANGE_EN field from IRQ_EN. Lock status change interrupt enable"""
        return (self.read_irq_en() >> 17) & 0x1

    def get_irq_status_capture(self) -> int:
        """Get CAPTURE field from IRQ_STATUS. Per-channel capture event"""
        return (self.read_irq_status() >> 180) & 0x1

    def get_irq_status_fifo_thresh(self) -> int:
        """Get FIFO_THRESH field from IRQ_STATUS. Per-channel FIFO threshold reached"""
        return (self.read_irq_status() >> 424) & 0x1

    def get_irq_status_overflow(self) -> int:
        """Get OVERFLOW field from IRQ_STATUS. Per-channel FIFO overflow"""
        return (self.read_irq_status() >> 668) & 0x1

    def get_irq_status_pps(self) -> int:
        """Get PPS field from IRQ_STATUS. PPS event occurred"""
        return (self.read_irq_status() >> 16) & 0x1

    def get_irq_status_lock_change(self) -> int:
        """Get LOCK_CHANGE field from IRQ_STATUS. Lock status changed"""
        return (self.read_irq_status() >> 17) & 0x1

    def get_ts_sec_lo_value(self) -> int:
        """Get VALUE field from TS_SEC_LO. Lower 32 bits of seconds counter"""
        return (self.read_ts_sec_lo() >> 1860) & 0x1

    def get_ts_sec_hi_value(self) -> int:
        """Get VALUE field from TS_SEC_HI. Upper 16 bits of seconds counter"""
        return (self.read_ts_sec_hi() >> 900) & 0x1

    def get_ts_sec_hi_reserved(self) -> int:
        """Get RESERVED field from TS_SEC_HI. Reserved"""
        return (self.read_ts_sec_hi() >> 1876) & 0x1

    def get_ts_ns_value(self) -> int:
        """Get VALUE field from TS_NS. Nanoseconds [0-999,999,999]"""
        return (self.read_ts_ns() >> 1740) & 0x1

    def get_ts_ns_reserved(self) -> int:
        """Get RESERVED field from TS_NS. Reserved"""
        return (self.read_ts_ns() >> 1890) & 0x1

    def get_ts_frac_value(self) -> int:
        """Get VALUE field from TS_FRAC. Fractional ns (1/65536 ns resolution)"""
        return (self.read_ts_frac() >> 900) & 0x1

    def get_ts_frac_valid(self) -> int:
        """Get VALID field from TS_FRAC. TDC measurement valid"""
        return (self.read_ts_frac() >> 31) & 0x1

    def get_ts_latch_ctrl_latch(self) -> int:
        """Get LATCH field from TS_LATCH_CTRL. Write 1 to latch current time"""
        return (self.read_ts_latch_ctrl() >> 0) & 0x1

    def get_ts_latch_ctrl_auto_latch(self) -> int:
        """Get AUTO_LATCH field from TS_LATCH_CTRL. Auto-latch on PPS"""
        return (self.read_ts_latch_ctrl() >> 1) & 0x1

    def get_ch0_ctrl_edge_sel(self) -> int:
        """Get EDGE_SEL field from CH0_CTRL. Capture edge select"""
        return (self.read_ch0_ctrl() >> 0) & 0x1

    def get_ch0_ctrl_filter_en(self) -> int:
        """Get FILTER_EN field from CH0_CTRL. Enable glitch filter"""
        return (self.read_ch0_ctrl() >> 1) & 0x1

    def get_ch0_ctrl_filter_len(self) -> int:
        """Get FILTER_LEN field from CH0_CTRL. Filter length (2^N cycles)"""
        return (self.read_ch0_ctrl() >> 424) & 0x1

    def get_ch0_ctrl_fifo_thresh(self) -> int:
        """Get FIFO_THRESH field from CH0_CTRL. FIFO threshold for interrupt"""
        return (self.read_ch0_ctrl() >> 908) & 0x1

    def get_ch0_ts_sec_value(self) -> int:
        """Get VALUE field from CH0_TS_SEC. Captured seconds [31:0]"""
        return (self.read_ch0_ts_sec() >> 1860) & 0x1

    def get_ch0_ts_ns_value(self) -> int:
        """Get VALUE field from CH0_TS_NS. Captured nanoseconds"""
        return (self.read_ch0_ts_ns() >> 1740) & 0x1

    def get_ch0_ts_ns_reserved(self) -> int:
        """Get RESERVED field from CH0_TS_NS. """
        return (self.read_ch0_ts_ns() >> 1890) & 0x1

    def get_ch0_ts_frac_value(self) -> int:
        """Get VALUE field from CH0_TS_FRAC. Fractional nanoseconds"""
        return (self.read_ch0_ts_frac() >> 900) & 0x1

    def get_ch0_ts_frac_fifo_count(self) -> int:
        """Get FIFO_COUNT field from CH0_TS_FRAC. Current FIFO fill level"""
        return (self.read_ch0_ts_frac() >> 1636) & 0x1

    def get_ch0_ts_frac_valid(self) -> int:
        """Get VALID field from CH0_TS_FRAC. Valid data in FIFO"""
        return (self.read_ch0_ts_frac() >> 31) & 0x1

    def get_cal_ctrl_cal_en(self) -> int:
        """Get CAL_EN field from CAL_CTRL. Enable calibration mode"""
        return (self.read_cal_ctrl() >> 0) & 0x1

    def get_cal_ctrl_cal_src(self) -> int:
        """Get CAL_SRC field from CAL_CTRL. Calibration source"""
        return (self.read_cal_ctrl() >> 121) & 0x1

    def get_cal_ctrl_cal_start(self) -> int:
        """Get CAL_START field from CAL_CTRL. Start calibration sequence"""
        return (self.read_cal_ctrl() >> 8) & 0x1

    def get_cal_ctrl_cal_busy(self) -> int:
        """Get CAL_BUSY field from CAL_CTRL. Calibration in progress"""
        return (self.read_cal_ctrl() >> 16) & 0x1

    def get_cal_ctrl_cal_done(self) -> int:
        """Get CAL_DONE field from CAL_CTRL. Calibration complete"""
        return (self.read_cal_ctrl() >> 17) & 0x1

    def get_cal_ctrl_cal_error(self) -> int:
        """Get CAL_ERROR field from CAL_CTRL. Calibration error"""
        return (self.read_cal_ctrl() >> 18) & 0x1

    def get_cal_offset_value(self) -> int:
        """Get VALUE field from CAL_OFFSET. Offset value (signed 16-bit)"""
        return (self.read_cal_offset() >> 900) & 0x1

    def get_cal_offset_auto_apply(self) -> int:
        """Get AUTO_APPLY field from CAL_OFFSET. Automatically apply offset to captures"""
        return (self.read_cal_offset() >> 31) & 0x1

    def get_cal_skew_ch1_skew(self) -> int:
        """Get CH1_SKEW field from CAL_SKEW. Channel 1 skew vs CH0 (signed)"""
        return (self.read_cal_skew() >> 420) & 0x1

    def get_cal_skew_ch2_skew(self) -> int:
        """Get CH2_SKEW field from CAL_SKEW. Channel 2 skew vs CH0 (signed)"""
        return (self.read_cal_skew() >> 908) & 0x1

    def get_cal_skew_ch3_skew(self) -> int:
        """Get CH3_SKEW field from CAL_SKEW. Channel 3 skew vs CH0 (signed)"""
        return (self.read_cal_skew() >> 1396) & 0x1

    def get_version_patch(self) -> int:
        """Get PATCH field from VERSION. Patch version"""
        return (self.read_version() >> 420) & 0x1

    def get_version_minor(self) -> int:
        """Get MINOR field from VERSION. Minor version"""
        return (self.read_version() >> 908) & 0x1

    def get_version_major(self) -> int:
        """Get MAJOR field from VERSION. Major version"""
        return (self.read_version() >> 1396) & 0x1

    def get_version_reserved(self) -> int:
        """Get RESERVED field from VERSION. """
        return (self.read_version() >> 1884) & 0x1

    def get_id_value(self) -> int:
        """Get VALUE field from ID. ID value"""
        return (self.read_id() >> 1860) & 0x1

    def get_build_date_value(self) -> int:
        """Get VALUE field from BUILD_DATE. Build date in BCD"""
        return (self.read_build_date() >> 1860) & 0x1

    def get_git_hash_value(self) -> int:
        """Get VALUE field from GIT_HASH. Git hash"""
        return (self.read_git_hash() >> 1860) & 0x1
