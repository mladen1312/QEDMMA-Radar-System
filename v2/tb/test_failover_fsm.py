"""
QEDMMA v2.0 - Failover FSM Cocotb Testbench
Author: Dr. Mladen Mešter
Copyright (c) 2026 Dr. Mladen Mešter - All Rights Reserved

Tests:
  - [TC-001] Initial state selection (FSO priority)
  - [TC-002] FSO → E-band failover on packet loss
  - [TC-003] E-band → HF failover on link down
  - [TC-004] Automatic failback when primary recovers
  - [TC-005] Manual override
  - [TC-006] All links down handling
  - [TC-007] Failover timing verification (<100ms)
"""

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer, ClockCycles
from cocotb.result import TestFailure
import random

# Constants
CLK_PERIOD_NS = 4  # 250 MHz
MONITOR_INTERVAL_CYCLES = 25_000_000  # 100 ms @ 250 MHz

# Link encoding
LINK_FSO   = 0b001
LINK_EBAND = 0b010
LINK_HF    = 0b100
LINK_NONE  = 0b000


async def reset_dut(dut):
    """Reset the DUT"""
    dut.rst_n.value = 0
    dut.enable.value = 0
    dut.fso_link_up.value = 0
    dut.eband_link_up.value = 0
    dut.hf_link_up.value = 0
    dut.fso_packet_loss.value = 0
    dut.eband_packet_loss.value = 0
    dut.hf_packet_loss.value = 0
    dut.force_failover.value = 0
    dut.force_link_sel.value = 0
    dut.cfg_failover_threshold.value = 80
    dut.cfg_failback_threshold.value = 20
    dut.cfg_monitor_interval.value = 25_000_000
    
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 5)


async def wait_for_state(dut, expected_state, timeout_cycles=1000):
    """Wait for FSM to reach expected state"""
    for _ in range(timeout_cycles):
        await RisingEdge(dut.clk)
        if int(dut.current_state.value) == expected_state:
            return True
    return False


@cocotb.test()
async def test_initial_fso_selection(dut):
    """[TC-001] FSO should be selected when all links healthy"""
    clock = Clock(dut.clk, CLK_PERIOD_NS, units="ns")
    cocotb.start_soon(clock.start())
    
    await reset_dut(dut)
    
    # Enable with all links up
    dut.fso_link_up.value = 1
    dut.eband_link_up.value = 1
    dut.hf_link_up.value = 1
    dut.fso_packet_loss.value = 5  # 5% loss (healthy)
    dut.eband_packet_loss.value = 10
    dut.hf_packet_loss.value = 15
    dut.enable.value = 1
    
    await ClockCycles(dut.clk, 100)
    
    # FSO should be active (highest priority)
    active = int(dut.active_link.value)
    assert active == LINK_FSO, f"Expected FSO (0b001), got {bin(active)}"
    
    dut._log.info("✅ TC-001 PASSED: FSO correctly selected as primary")


@cocotb.test()
async def test_failover_fso_to_eband(dut):
    """[TC-002] Failover from FSO to E-band on high packet loss"""
    clock = Clock(dut.clk, CLK_PERIOD_NS, units="ns")
    cocotb.start_soon(clock.start())
    
    await reset_dut(dut)
    
    # Start with healthy FSO
    dut.fso_link_up.value = 1
    dut.eband_link_up.value = 1
    dut.hf_link_up.value = 1
    dut.fso_packet_loss.value = 5
    dut.eband_packet_loss.value = 10
    dut.hf_packet_loss.value = 20
    dut.enable.value = 1
    
    await ClockCycles(dut.clk, 100)
    assert int(dut.active_link.value) == LINK_FSO
    
    # Degrade FSO (packet loss > 80%)
    dut.fso_packet_loss.value = 85
    
    # Wait for failover (should be quick)
    await ClockCycles(dut.clk, 50_000)  # 200 µs max
    
    active = int(dut.active_link.value)
    assert active == LINK_EBAND, f"Expected E-band (0b010), got {bin(active)}"
    
    # Check failover reason
    reason = int(dut.failover_reason.value)
    assert reason == 1, f"Expected REASON_PACKET_LOSS (1), got {reason}"
    
    dut._log.info("✅ TC-002 PASSED: FSO → E-band failover on packet loss")


@cocotb.test()
async def test_failover_eband_to_hf(dut):
    """[TC-003] Failover from E-band to HF on link down"""
    clock = Clock(dut.clk, CLK_PERIOD_NS, units="ns")
    cocotb.start_soon(clock.start())
    
    await reset_dut(dut)
    
    # Start with only E-band and HF (FSO down)
    dut.fso_link_up.value = 0
    dut.eband_link_up.value = 1
    dut.hf_link_up.value = 1
    dut.fso_packet_loss.value = 100
    dut.eband_packet_loss.value = 10
    dut.hf_packet_loss.value = 20
    dut.enable.value = 1
    
    await ClockCycles(dut.clk, 100)
    assert int(dut.active_link.value) == LINK_EBAND
    
    # E-band goes down
    dut.eband_link_up.value = 0
    dut.eband_packet_loss.value = 100
    
    # Wait for failover to HF
    await ClockCycles(dut.clk, 10_000_000)  # Up to 40 ms
    
    active = int(dut.active_link.value)
    assert active == LINK_HF, f"Expected HF (0b100), got {bin(active)}"
    
    dut._log.info("✅ TC-003 PASSED: E-band → HF failover on link down")


@cocotb.test()
async def test_automatic_failback(dut):
    """[TC-004] Automatic failback when primary recovers"""
    clock = Clock(dut.clk, CLK_PERIOD_NS, units="ns")
    cocotb.start_soon(clock.start())
    
    await reset_dut(dut)
    
    # Start on E-band (FSO degraded)
    dut.fso_link_up.value = 1
    dut.eband_link_up.value = 1
    dut.hf_link_up.value = 1
    dut.fso_packet_loss.value = 90  # Degraded
    dut.eband_packet_loss.value = 10
    dut.hf_packet_loss.value = 20
    dut.enable.value = 1
    
    await ClockCycles(dut.clk, 50_000)
    
    # FSO recovers (packet loss drops below failback threshold)
    dut.fso_packet_loss.value = 10  # < 20% threshold
    
    # Wait for failback
    await ClockCycles(dut.clk, 100_000)
    
    active = int(dut.active_link.value)
    assert active == LINK_FSO, f"Expected FSO (0b001) after failback, got {bin(active)}"
    
    dut._log.info("✅ TC-004 PASSED: Automatic failback to FSO")


@cocotb.test()
async def test_manual_override(dut):
    """[TC-005] Manual override forces specific link"""
    clock = Clock(dut.clk, CLK_PERIOD_NS, units="ns")
    cocotb.start_soon(clock.start())
    
    await reset_dut(dut)
    
    # All links healthy, FSO should be active
    dut.fso_link_up.value = 1
    dut.eband_link_up.value = 1
    dut.hf_link_up.value = 1
    dut.fso_packet_loss.value = 5
    dut.eband_packet_loss.value = 10
    dut.hf_packet_loss.value = 20
    dut.enable.value = 1
    
    await ClockCycles(dut.clk, 100)
    assert int(dut.active_link.value) == LINK_FSO
    
    # Force to HF
    dut.force_failover.value = 1
    dut.force_link_sel.value = LINK_HF
    
    await ClockCycles(dut.clk, 10)
    
    active = int(dut.active_link.value)
    assert active == LINK_HF, f"Expected HF (0b100) on manual override, got {bin(active)}"
    
    reason = int(dut.failover_reason.value)
    assert reason == 4, f"Expected REASON_MANUAL (4), got {reason}"
    
    # Release override
    dut.force_failover.value = 0
    await ClockCycles(dut.clk, 1000)
    
    # Should return to FSO
    active = int(dut.active_link.value)
    assert active == LINK_FSO, f"Expected FSO after override release, got {bin(active)}"
    
    dut._log.info("✅ TC-005 PASSED: Manual override and release")


@cocotb.test()
async def test_all_links_down(dut):
    """[TC-006] All links down handling"""
    clock = Clock(dut.clk, CLK_PERIOD_NS, units="ns")
    cocotb.start_soon(clock.start())
    
    await reset_dut(dut)
    
    # All links down
    dut.fso_link_up.value = 0
    dut.eband_link_up.value = 0
    dut.hf_link_up.value = 0
    dut.fso_packet_loss.value = 100
    dut.eband_packet_loss.value = 100
    dut.hf_packet_loss.value = 100
    dut.enable.value = 1
    
    await ClockCycles(dut.clk, 1000)
    
    # all_links_down flag should be set
    assert int(dut.all_links_down.value) == 1, "all_links_down should be asserted"
    
    # Bring up HF
    dut.hf_link_up.value = 1
    dut.hf_packet_loss.value = 20
    
    await ClockCycles(dut.clk, 1000)
    
    active = int(dut.active_link.value)
    assert active == LINK_HF, f"Expected HF when only link available, got {bin(active)}"
    
    dut._log.info("✅ TC-006 PASSED: All links down recovery")


@cocotb.test()
async def test_failover_timing(dut):
    """[TC-007] Verify failover completes within 100ms"""
    clock = Clock(dut.clk, CLK_PERIOD_NS, units="ns")
    cocotb.start_soon(clock.start())
    
    await reset_dut(dut)
    
    # Start with healthy FSO
    dut.fso_link_up.value = 1
    dut.eband_link_up.value = 1
    dut.hf_link_up.value = 1
    dut.fso_packet_loss.value = 5
    dut.eband_packet_loss.value = 10
    dut.hf_packet_loss.value = 20
    dut.enable.value = 1
    
    await ClockCycles(dut.clk, 100)
    
    # Record start time and trigger failover
    start_cycle = 0
    dut.fso_link_up.value = 0  # FSO link down
    
    # Wait for failover, counting cycles
    cycles = 0
    max_cycles = MONITOR_INTERVAL_CYCLES  # 100 ms
    
    while cycles < max_cycles:
        await RisingEdge(dut.clk)
        cycles += 1
        if int(dut.active_link.value) == LINK_EBAND:
            break
    
    failover_time_us = (cycles * CLK_PERIOD_NS) / 1000
    
    assert int(dut.active_link.value) == LINK_EBAND, "Failover did not complete"
    assert failover_time_us < 100_000, f"Failover took {failover_time_us} µs (>100 ms limit)"
    
    dut._log.info(f"✅ TC-007 PASSED: Failover completed in {failover_time_us:.0f} µs")
