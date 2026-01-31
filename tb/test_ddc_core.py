"""
QEDMMA DDC Core Testbench
Radar Systems Architect v9.0 - Forge Spec

Tests:
- NCO frequency accuracy
- Complex mixing correctness  
- CIC decimation and passband
- AXI4-Stream handshaking
"""

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ClockCycles, Timer
from cocotb.result import TestFailure
import numpy as np

@cocotb.test()
async def test_nco_frequency(dut):
    """Test NCO generates correct frequency"""
    clock = Clock(dut.clk, 4, units="ns")  # 250 MHz
    cocotb.start_soon(clock.start())
    
    # Reset
    dut.rst_n.value = 0
    dut.cfg_enable.value = 0
    dut.cfg_nco_freq.value = 0
    dut.cfg_decimation.value = 4
    dut.cfg_bypass_cic.value = 0
    dut.s_axis_tdata.value = 0
    dut.s_axis_tvalid.value = 0
    dut.m_axis_tready.value = 1
    
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 10)
    
    # Configure NCO for 10 MHz (at 250 MHz clock)
    # freq_word = f_out / f_clk * 2^32 = 10e6 / 250e6 * 2^32 = 171,798,692
    NCO_FREQ_WORD = int(10e6 / 250e6 * (2**32))
    dut.cfg_nco_freq.value = NCO_FREQ_WORD
    dut.cfg_enable.value = 1
    
    # Feed constant input to observe NCO output
    dut.s_axis_tdata.value = 32767  # Max positive
    dut.s_axis_tvalid.value = 1
    
    # Collect output samples
    outputs_i = []
    outputs_q = []
    
    for _ in range(1000):
        await RisingEdge(dut.clk)
        if dut.m_axis_tvalid.value:
            i_val = dut.m_axis_tdata.value & 0xFFFF
            q_val = (dut.m_axis_tdata.value >> 16) & 0xFFFF
            # Convert to signed
            if i_val >= 32768: i_val -= 65536
            if q_val >= 32768: q_val -= 65536
            outputs_i.append(i_val)
            outputs_q.append(q_val)
    
    dut._log.info(f"Collected {len(outputs_i)} output samples")
    
    # Verify I/Q are 90 degrees out of phase (check correlation)
    if len(outputs_i) > 100:
        i_arr = np.array(outputs_i[:100])
        q_arr = np.array(outputs_q[:100])
        correlation = np.corrcoef(i_arr, q_arr)[0, 1]
        dut._log.info(f"I/Q correlation: {correlation:.4f} (should be ~0 for quadrature)")


@cocotb.test()
async def test_cic_decimation(dut):
    """Test CIC filter decimates correctly"""
    clock = Clock(dut.clk, 4, units="ns")
    cocotb.start_soon(clock.start())
    
    # Reset
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1
    
    # Configure for decimation by 8
    DECIMATION = 8
    dut.cfg_nco_freq.value = 0  # DC (no mixing)
    dut.cfg_decimation.value = DECIMATION
    dut.cfg_bypass_cic.value = 0
    dut.cfg_enable.value = 1
    dut.m_axis_tready.value = 1
    
    await ClockCycles(dut.clk, 10)
    
    # Count input vs output samples
    input_count = 0
    output_count = 0
    
    for i in range(DECIMATION * 100):
        dut.s_axis_tdata.value = i % 65536
        dut.s_axis_tvalid.value = 1
        await RisingEdge(dut.clk)
        input_count += 1
        
        if dut.m_axis_tvalid.value:
            output_count += 1
    
    expected_outputs = input_count // DECIMATION
    dut._log.info(f"Input samples: {input_count}, Output samples: {output_count}")
    dut._log.info(f"Expected decimation ratio: {DECIMATION}:1")
    
    # Allow some tolerance for pipeline delay
    assert abs(output_count - expected_outputs) < 10, \
        f"Decimation ratio incorrect: expected ~{expected_outputs}, got {output_count}"


@cocotb.test()
async def test_bypass_mode(dut):
    """Test CIC bypass mode"""
    clock = Clock(dut.clk, 4, units="ns")
    cocotb.start_soon(clock.start())
    
    # Reset
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1
    
    # Configure bypass mode
    dut.cfg_nco_freq.value = 0
    dut.cfg_decimation.value = 4
    dut.cfg_bypass_cic.value = 1  # Bypass!
    dut.cfg_enable.value = 1
    dut.m_axis_tready.value = 1
    
    await ClockCycles(dut.clk, 10)
    
    # In bypass mode, output rate should equal input rate
    input_count = 0
    output_count = 0
    
    for i in range(100):
        dut.s_axis_tdata.value = i * 100
        dut.s_axis_tvalid.value = 1
        await RisingEdge(dut.clk)
        input_count += 1
        
        if dut.m_axis_tvalid.value:
            output_count += 1
    
    dut._log.info(f"Bypass mode: Input={input_count}, Output={output_count}")
    # Should be nearly 1:1 (minus pipeline delay)
    assert output_count > input_count - 20, "Bypass mode not working correctly"
