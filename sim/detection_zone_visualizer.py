#!/usr/bin/env python3
"""
QEDMMA v3.0 - Detection Zone Visualization
[REQ-VIS-001] Visualize QEDMMA vs competitor detection zones
[REQ-VIS-002] F-35/J-20 stealth aircraft scenarios

Author: Dr. Mladen Mešter
Copyright (c) 2026 - All Rights Reserved

Generates detection zone plots comparing QEDMMA v3.0 against:
- Competitor systems (JY-27V, Rezonans-NE, Nebo-M)
- Different target RCS (F-35, J-20, Su-57, conventional)
- Various operational scenarios (clear, jamming, clutter)
"""

import numpy as np
from dataclasses import dataclass
from typing import List, Tuple, Dict, Optional
import sys

# =============================================================================
# RADAR SYSTEM DEFINITIONS
# =============================================================================

@dataclass
class RadarSystem:
    """Radar system parameters for detection calculation."""
    name: str
    
    # Transmitter
    P_tx_kW: float              # Peak TX power
    G_tx_dBi: float             # TX antenna gain
    freq_MHz: float             # Operating frequency
    
    # Receiver
    G_rx_dBi: float             # RX antenna gain
    T_sys_K: float              # System noise temperature
    NF_dB: float                # Noise figure
    
    # Processing
    bandwidth_MHz: float        # Processing bandwidth
    integration_time_ms: float  # Coherent integration time
    processing_gain_dB: float   # Waveform processing gain
    
    # Detection
    Pd: float                   # Probability of detection
    Pfa: float                  # Probability of false alarm
    SNR_req_dB: float          # Required SNR for detection
    
    # ECCM
    eccm_gain_dB: float = 0    # ECCM improvement factor
    quantum_gain_dB: float = 0  # Quantum receiver advantage
    
    # Display
    color: str = 'blue'
    linestyle: str = '-'


# QEDMMA v3.0 Configuration
QEDMMA_V3 = RadarSystem(
    name="QEDMMA v3.0",
    P_tx_kW=10.0,
    G_tx_dBi=25.0,
    freq_MHz=75.0,
    G_rx_dBi=25.0,
    T_sys_K=50.0,           # Quantum RX
    NF_dB=1.0,
    bandwidth_MHz=200.0,
    integration_time_ms=163.8,  # PRBS-15 period
    processing_gain_dB=45.2,    # PRBS-15
    Pd=0.9,
    Pfa=1e-6,
    SNR_req_dB=13.0,
    eccm_gain_dB=7.0,
    quantum_gain_dB=13.0,
    color='green',
    linestyle='-'
)

# Competitor systems
JY_27V = RadarSystem(
    name="JY-27V (China)",
    P_tx_kW=25.0,
    G_tx_dBi=22.0,
    freq_MHz=150.0,
    G_rx_dBi=22.0,
    T_sys_K=800.0,
    NF_dB=4.0,
    bandwidth_MHz=10.0,
    integration_time_ms=100.0,
    processing_gain_dB=30.0,
    Pd=0.9,
    Pfa=1e-6,
    SNR_req_dB=15.0,
    eccm_gain_dB=3.0,
    color='red',
    linestyle='--'
)

REZONANS_NE = RadarSystem(
    name="Rezonans-NE (Russia)",
    P_tx_kW=100.0,
    G_tx_dBi=20.0,
    freq_MHz=50.0,
    G_rx_dBi=20.0,
    T_sys_K=1000.0,
    NF_dB=5.0,
    bandwidth_MHz=5.0,
    integration_time_ms=200.0,
    processing_gain_dB=25.0,
    Pd=0.9,
    Pfa=1e-6,
    SNR_req_dB=15.0,
    eccm_gain_dB=2.0,
    color='orange',
    linestyle='--'
)

NEBO_M = RadarSystem(
    name="Nebo-M (Russia)",
    P_tx_kW=50.0,
    G_tx_dBi=24.0,
    freq_MHz=100.0,
    G_rx_dBi=24.0,
    T_sys_K=600.0,
    NF_dB=3.5,
    bandwidth_MHz=20.0,
    integration_time_ms=150.0,
    processing_gain_dB=35.0,
    Pd=0.9,
    Pfa=1e-6,
    SNR_req_dB=14.0,
    eccm_gain_dB=4.0,
    color='purple',
    linestyle='--'
)


# =============================================================================
# TARGET RCS DEFINITIONS
# =============================================================================

@dataclass
class TargetRCS:
    """Target RCS characteristics."""
    name: str
    rcs_vhf_dBsm: float        # RCS at VHF (50-150 MHz)
    rcs_uhf_dBsm: float        # RCS at UHF (300-1000 MHz)
    rcs_xband_dBsm: float      # RCS at X-band (8-12 GHz)
    speed_mach: float          # Typical speed
    altitude_km: float         # Typical altitude
    symbol: str


# Target definitions (VHF RCS estimates from open sources)
F35_LIGHTNING = TargetRCS(
    name="F-35 Lightning II",
    rcs_vhf_dBsm=-40.0,        # 0.0001 m² @ VHF
    rcs_uhf_dBsm=-25.0,        # 0.003 m²
    rcs_xband_dBsm=-30.0,      # 0.001 m² (optimized)
    speed_mach=1.6,
    altitude_km=10.0,
    symbol='v'
)

J20_MIGHTY_DRAGON = TargetRCS(
    name="J-20 Mighty Dragon",
    rcs_vhf_dBsm=-35.0,        # 0.0003 m²
    rcs_uhf_dBsm=-20.0,
    rcs_xband_dBsm=-25.0,
    speed_mach=2.0,
    altitude_km=12.0,
    symbol='^'
)

SU57_FELON = TargetRCS(
    name="Su-57 Felon",
    rcs_vhf_dBsm=-30.0,        # 0.001 m²
    rcs_uhf_dBsm=-15.0,
    rcs_xband_dBsm=-20.0,
    speed_mach=2.0,
    altitude_km=11.0,
    symbol='s'
)

F16_FALCON = TargetRCS(
    name="F-16 Fighting Falcon",
    rcs_vhf_dBsm=0.0,          # 1 m² (conventional)
    rcs_uhf_dBsm=5.0,
    rcs_xband_dBsm=3.0,
    speed_mach=2.0,
    altitude_km=10.0,
    symbol='o'
)

B2_SPIRIT = TargetRCS(
    name="B-2 Spirit",
    rcs_vhf_dBsm=-35.0,
    rcs_uhf_dBsm=-30.0,
    rcs_xband_dBsm=-40.0,      # Extremely low
    speed_mach=0.9,
    altitude_km=15.0,
    symbol='D'
)

CRUISE_MISSILE = TargetRCS(
    name="Cruise Missile",
    rcs_vhf_dBsm=-20.0,
    rcs_uhf_dBsm=-25.0,
    rcs_xband_dBsm=-30.0,
    speed_mach=0.8,
    altitude_km=0.1,           # Low altitude
    symbol='*'
)


# =============================================================================
# RADAR EQUATION
# =============================================================================

def calc_detection_range(radar: RadarSystem, rcs_dBsm: float, 
                         jamming_power_kW: float = 0,
                         jammer_range_km: float = 100) -> float:
    """
    Calculate detection range using radar equation.
    
    R^4 = (Pt × Gt × Gr × λ² × σ × Gp × Geccm × Gq) / ((4π)³ × k × Tsys × B × SNRreq)
    
    Args:
        radar: Radar system parameters
        rcs_dBsm: Target RCS in dBsm
        jamming_power_kW: Jammer power (0 for no jamming)
        jammer_range_km: Distance to jammer
        
    Returns:
        Detection range in km
    """
    # Physical constants
    c = 3e8
    k_B = 1.38e-23
    
    # Wavelength
    wavelength = c / (radar.freq_MHz * 1e6)
    
    # Convert to linear
    P_tx = radar.P_tx_kW * 1000  # W
    G_tx = 10 ** (radar.G_tx_dBi / 10)
    G_rx = 10 ** (radar.G_rx_dBi / 10)
    sigma = 10 ** (rcs_dBsm / 10)
    B = radar.bandwidth_MHz * 1e6
    proc_gain = 10 ** (radar.processing_gain_dB / 10)
    eccm_gain = 10 ** (radar.eccm_gain_dB / 10)
    quantum_gain = 10 ** (radar.quantum_gain_dB / 10)
    SNR_req = 10 ** (radar.SNR_req_dB / 10)
    
    # Noise power
    noise_power = k_B * radar.T_sys_K * B
    
    # Effective noise (after processing and quantum advantage)
    effective_noise = noise_power / (proc_gain * eccm_gain * quantum_gain)
    
    # Add jamming if present
    if jamming_power_kW > 0:
        # J/S calculation
        P_jam = jamming_power_kW * 1000
        G_jam = 10  # Assume 10 dBi jammer antenna
        R_jam = jammer_range_km * 1000
        
        # Jamming power at receiver (one-way)
        P_jam_rx = (P_jam * G_jam * G_rx * wavelength**2) / ((4*np.pi)**2 * R_jam**2)
        
        # Reduce effective noise by jamming
        effective_noise += P_jam_rx / eccm_gain
    
    # Minimum required received power
    P_rx_min = SNR_req * effective_noise
    
    # Radar equation numerator
    numerator = P_tx * G_tx * G_rx * wavelength**2 * sigma
    
    # Radar equation denominator
    denominator = (4 * np.pi)**3 * P_rx_min
    
    # Solve for range
    R_m = (numerator / denominator) ** 0.25
    R_km = R_m / 1000
    
    return R_km


def generate_detection_envelope(radar: RadarSystem, target: TargetRCS,
                                azimuth_deg: np.ndarray,
                                jamming_power_kW: float = 0) -> np.ndarray:
    """
    Generate detection range envelope vs azimuth.
    
    Simple model with antenna pattern consideration.
    """
    # Get VHF RCS (most relevant for anti-stealth)
    rcs = target.rcs_vhf_dBsm
    
    # Base detection range
    R_max = calc_detection_range(radar, rcs, jamming_power_kW)
    
    # Apply simple antenna pattern (cosine approximation)
    # Real radar would have actual pattern
    pattern = np.cos(np.radians(azimuth_deg / 2)) ** 2
    pattern = np.maximum(pattern, 0.1)  # Sidelobe floor
    
    # Range scales as pattern^0.25 (4th root from radar equation)
    R_envelope = R_max * (pattern ** 0.25)
    
    return R_envelope


# =============================================================================
# VISUALIZATION (ASCII + Data Export)
# =============================================================================

def create_ascii_detection_plot(radars: List[RadarSystem], 
                                target: TargetRCS,
                                width: int = 80,
                                height: int = 40) -> str:
    """
    Create ASCII art detection zone plot.
    """
    # Calculate ranges
    ranges = {}
    max_range = 0
    for radar in radars:
        R = calc_detection_range(radar, target.rcs_vhf_dBsm)
        ranges[radar.name] = R
        max_range = max(max_range, R)
    
    # Scale factor
    scale = (width // 2 - 5) / max_range
    
    # Create plot
    lines = []
    
    # Title
    lines.append("=" * width)
    lines.append(f"  DETECTION ZONE: {target.name}".center(width))
    lines.append(f"  RCS @ VHF: {target.rcs_vhf_dBsm:.0f} dBsm ({10**(target.rcs_vhf_dBsm/10):.4f} m²)".center(width))
    lines.append("=" * width)
    lines.append("")
    
    # Plot area
    center_x = width // 2
    
    for y in range(height, -height-1, -2):
        line = [' '] * width
        
        # Axis
        if y == 0:
            line = list('-' * width)
            line[center_x] = '+'
        else:
            line[center_x] = '|'
        
        # Draw detection ranges
        for radar in radars:
            R = ranges[radar.name]
            # Calculate x position for this y
            y_km = y * max_range / height
            if abs(y_km) <= R:
                x_km = np.sqrt(R**2 - y_km**2)
                x_pos_r = int(center_x + x_km * scale)
                x_pos_l = int(center_x - x_km * scale)
                
                char = radar.name[0]  # First letter
                if 0 <= x_pos_r < width:
                    line[x_pos_r] = char
                if 0 <= x_pos_l < width:
                    line[x_pos_l] = char
        
        lines.append(''.join(line))
    
    # Legend
    lines.append("")
    lines.append("-" * width)
    lines.append("LEGEND:".center(width))
    for radar in radars:
        R = ranges[radar.name]
        lines.append(f"  [{radar.name[0]}] {radar.name}: {R:.0f} km".ljust(width))
    
    return '\n'.join(lines)


def create_comparison_table(radars: List[RadarSystem], 
                           targets: List[TargetRCS]) -> str:
    """
    Create comparison table of detection ranges.
    """
    # Header
    col_width = 18
    header = f"{'Target':<20}"
    for radar in radars:
        header += f"{radar.name[:col_width]:<{col_width}}"
    
    lines = []
    lines.append("=" * len(header))
    lines.append("DETECTION RANGE COMPARISON (km)")
    lines.append("=" * len(header))
    lines.append(header)
    lines.append("-" * len(header))
    
    for target in targets:
        row = f"{target.name:<20}"
        for radar in radars:
            R = calc_detection_range(radar, target.rcs_vhf_dBsm)
            row += f"{R:>10.0f} km      "
        lines.append(row)
    
    lines.append("-" * len(header))
    
    # QEDMMA advantage
    lines.append("")
    lines.append("QEDMMA v3.0 ADVANTAGE:")
    qedmma = radars[0]  # Assume first is QEDMMA
    for target in targets:
        R_qedmma = calc_detection_range(qedmma, target.rcs_vhf_dBsm)
        advantages = []
        for radar in radars[1:]:
            R_comp = calc_detection_range(radar, target.rcs_vhf_dBsm)
            adv = R_qedmma / R_comp if R_comp > 0 else float('inf')
            advantages.append(f"{radar.name[:10]}: {adv:.1f}×")
        lines.append(f"  vs {target.name}: {', '.join(advantages)}")
    
    return '\n'.join(lines)


def create_jamming_analysis(radar: RadarSystem, target: TargetRCS) -> str:
    """
    Analyze detection performance under jamming.
    """
    lines = []
    lines.append("=" * 70)
    lines.append(f"JAMMING ANALYSIS: {radar.name} vs {target.name}")
    lines.append("=" * 70)
    lines.append("")
    
    # Base range (no jamming)
    R_clear = calc_detection_range(radar, target.rcs_vhf_dBsm)
    lines.append(f"Clear conditions:      {R_clear:.0f} km")
    lines.append("")
    
    # Various jamming levels
    lines.append(f"{'Jammer Power':<20} {'Jammer Range':<15} {'Detection Range':<20} {'Degradation':<15}")
    lines.append("-" * 70)
    
    for P_jam in [1, 5, 10, 20, 50, 100]:
        for R_jam in [50, 100, 150]:
            R = calc_detection_range(radar, target.rcs_vhf_dBsm, P_jam, R_jam)
            degradation = (1 - R/R_clear) * 100
            lines.append(f"{P_jam:>10} kW       {R_jam:>8} km      {R:>10.0f} km          {degradation:>8.1f}%")
    
    lines.append("")
    lines.append(f"ECCM Gain: +{radar.eccm_gain_dB:.1f} dB")
    lines.append(f"Quantum Advantage: +{radar.quantum_gain_dB:.1f} dB")
    
    return '\n'.join(lines)


def export_for_plotting(radars: List[RadarSystem], 
                       targets: List[TargetRCS],
                       filename: str) -> Dict:
    """
    Export data in format suitable for external plotting tools.
    """
    data = {
        'metadata': {
            'title': 'QEDMMA v3.0 Detection Zone Analysis',
            'author': 'Dr. Mladen Mešter',
            'date': '2026-02-01',
        },
        'radars': [],
        'targets': [],
        'detection_ranges': {},
        'azimuth_data': {},
    }
    
    # Radar parameters
    for radar in radars:
        data['radars'].append({
            'name': radar.name,
            'P_tx_kW': radar.P_tx_kW,
            'freq_MHz': radar.freq_MHz,
            'processing_gain_dB': radar.processing_gain_dB,
            'quantum_gain_dB': radar.quantum_gain_dB,
            'color': radar.color,
        })
    
    # Target parameters
    for target in targets:
        data['targets'].append({
            'name': target.name,
            'rcs_vhf_dBsm': target.rcs_vhf_dBsm,
            'rcs_m2': 10 ** (target.rcs_vhf_dBsm / 10),
            'symbol': target.symbol,
        })
    
    # Detection ranges matrix
    for target in targets:
        data['detection_ranges'][target.name] = {}
        for radar in radars:
            R = calc_detection_range(radar, target.rcs_vhf_dBsm)
            data['detection_ranges'][target.name][radar.name] = R
    
    # Azimuth envelope data (for polar plots)
    azimuth = np.linspace(-180, 180, 361)
    for target in targets:
        data['azimuth_data'][target.name] = {'azimuth_deg': azimuth.tolist()}
        for radar in radars:
            envelope = generate_detection_envelope(radar, target, azimuth)
            data['azimuth_data'][target.name][radar.name] = envelope.tolist()
    
    # Save to JSON
    import json
    with open(filename, 'w') as f:
        json.dump(data, f, indent=2)
    
    return data


# =============================================================================
# MAIN
# =============================================================================

if __name__ == "__main__":
    print("\n" + "=" * 80)
    print("   QEDMMA v3.0 - DETECTION ZONE VISUALIZATION")
    print("   Anti-Stealth Radar Performance Analysis")
    print("=" * 80)
    
    # Define systems and targets
    radars = [QEDMMA_V3, JY_27V, REZONANS_NE, NEBO_M]
    targets = [F35_LIGHTNING, J20_MIGHTY_DRAGON, SU57_FELON, F16_FALCON, B2_SPIRIT, CRUISE_MISSILE]
    
    # Comparison table
    print("\n" + create_comparison_table(radars, targets))
    
    # F-35 Detection Zone (ASCII)
    print("\n")
    print(create_ascii_detection_plot(radars, F35_LIGHTNING, width=78, height=15))
    
    # Jamming analysis for QEDMMA vs F-35
    print("\n")
    print(create_jamming_analysis(QEDMMA_V3, F35_LIGHTNING))
    
    # Performance summary
    print("\n" + "=" * 80)
    print("   QEDMMA v3.0 PERFORMANCE SUMMARY")
    print("=" * 80)
    
    print("""
    ┌─────────────────────────────────────────────────────────────────────────┐
    │                     DETECTION RANGE COMPARISON                          │
    ├─────────────────────────────────────────────────────────────────────────┤
    │                                                                         │
    │   Target          QEDMMA v3.0    JY-27V    Rezonans-NE    Nebo-M       │
    │   ─────────────────────────────────────────────────────────────────────│
    """)
    
    for target in targets[:4]:
        ranges = [calc_detection_range(r, target.rcs_vhf_dBsm) for r in radars]
        print(f"    │   {target.name:<14}    {ranges[0]:>6.0f} km    {ranges[1]:>5.0f} km    {ranges[2]:>7.0f} km    {ranges[3]:>5.0f} km   │")
    
    print("""    │                                                                         │
    ├─────────────────────────────────────────────────────────────────────────┤
    │                                                                         │
    │   KEY ADVANTAGES:                                                       │
    │                                                                         │
    │   ✓ Quantum receiver: +13 dB sensitivity                               │
    │   ✓ 200 Mchip/s PRBS: +45 dB processing gain                           │
    │   ✓ AI ECCM: +7 dB jamming rejection                                   │
    │   ✓ Sub-meter range resolution (0.75 m)                                │
    │                                                                         │
    │   TOTAL SYSTEM ADVANTAGE: +65 dB over conventional radar               │
    │                                                                         │
    └─────────────────────────────────────────────────────────────────────────┘
    """)
    
    # Export data for external plotting
    export_for_plotting(radars, targets, '/home/claude/qedmma_v2/sim/detection_zones_data.json')
    print("📊 Data exported to: detection_zones_data.json")
    
    print("\n" + "=" * 80)
    print("✅ DETECTION ZONE VISUALIZATION COMPLETE")
    print("=" * 80)
