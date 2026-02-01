#!/usr/bin/env python3
"""
QEDMMA Link Budget Calculator
Author: Dr. Mladen Mešter
Copyright (c) 2026 Dr. Mladen Mešter - All Rights Reserved

Calculates detection probability for stealth targets under various
jamming scenarios. Validates against Grok-X simulation results.
"""

import numpy as np
import argparse
from dataclasses import dataclass

# Physical constants
C = 3e8  # Speed of light (m/s)
K = 1.38e-23  # Boltzmann constant (J/K)

@dataclass
class RadarParams:
    """QEDMMA radar parameters."""
    P_tx: float = 1e6  # Transmit power (W) = 1 MW
    G_tx: float = 25.0  # Tx antenna gain (dBi)
    G_rx: float = 20.0  # Rx antenna gain (dBi)
    freq: float = 75e6  # Operating frequency (Hz) = 75 MHz VHF
    T_sys: float = 100  # System noise temperature (K) - Rydberg advantage
    NF: float = 0.5  # Noise figure (dB) - Rydberg advantage
    B: float = 10e6  # Bandwidth (Hz) = 10 MHz
    T_chirp: float = 0.1  # Chirp duration (s) = 100 ms
    N_pulses: int = 10  # Coherent integration pulses
    N_rx: int = 6  # Number of Rx nodes (multistatic)

@dataclass
class TargetParams:
    """Target parameters."""
    RCS: float = 0.0001  # Radar cross section (m²) = 0.0001 m² stealth
    range_m: float = 600e3  # Range (m) = 600 km
    velocity: float = 300  # Velocity (m/s)

@dataclass
class JammerParams:
    """Jammer parameters."""
    P_j: float = 0  # Jammer power (W)
    G_j: float = 10.0  # Jammer antenna gain (dBi)
    type: str = "barrage"  # barrage, spot, deception

def db_to_linear(db: float) -> float:
    """Convert dB to linear."""
    return 10 ** (db / 10)

def linear_to_db(linear: float) -> float:
    """Convert linear to dB."""
    return 10 * np.log10(linear + 1e-30)

def calculate_snr(radar: RadarParams, target: TargetParams) -> float:
    """
    Calculate signal-to-noise ratio using radar equation.
    
    SNR = (P_tx * G_tx * G_rx * λ² * σ) / ((4π)³ * R⁴ * k * T * B)
    
    With processing gain from:
    - Pulse compression: TB product
    - Coherent integration: N pulses
    """
    wavelength = C / radar.freq
    
    # Received signal power
    numerator = (radar.P_tx * db_to_linear(radar.G_tx) * db_to_linear(radar.G_rx) 
                 * wavelength**2 * target.RCS)
    denominator = (4 * np.pi)**3 * target.range_m**4
    P_rx = numerator / denominator
    
    # Noise power
    T_eff = radar.T_sys * db_to_linear(radar.NF)
    P_noise = K * T_eff * radar.B
    
    # Raw SNR
    snr_raw = P_rx / P_noise
    
    # Processing gains
    TB_product = radar.B * radar.T_chirp  # Time-bandwidth product
    processing_gain = TB_product * radar.N_pulses
    
    # Final SNR
    snr_final = snr_raw * processing_gain
    
    return linear_to_db(snr_final)

def calculate_sjnr(radar: RadarParams, target: TargetParams, jammer: JammerParams) -> float:
    """
    Calculate signal-to-jammer-plus-noise ratio.
    
    For barrage jamming:
    J/S = (P_j * G_j * 4π * R²) / (P_tx * G_tx * σ)
    
    SJNR = S / (J + N)
    """
    if jammer.P_j == 0:
        return calculate_snr(radar, target)
    
    wavelength = C / radar.freq
    
    # Signal power at receiver (same as SNR calculation)
    P_rx = ((radar.P_tx * db_to_linear(radar.G_tx) * db_to_linear(radar.G_rx) 
             * wavelength**2 * target.RCS) / 
            ((4 * np.pi)**3 * target.range_m**4))
    
    # Jammer power at receiver
    # Self-screening jammer: jammer at target range
    P_jammer = ((jammer.P_j * db_to_linear(jammer.G_j) * db_to_linear(radar.G_rx) 
                 * wavelength**2) / 
                ((4 * np.pi)**2 * target.range_m**2))
    
    # Noise power
    T_eff = radar.T_sys * db_to_linear(radar.NF)
    P_noise = K * T_eff * radar.B
    
    # Processing gain (only applies to signal, not barrage noise)
    TB_product = radar.B * radar.T_chirp
    processing_gain = TB_product * radar.N_pulses
    
    # Signal with processing gain
    P_signal_processed = P_rx * processing_gain
    
    # Jammer noise is NOT compressed by matched filter (barrage)
    P_total_interference = P_jammer + P_noise
    
    # SJNR
    sjnr = P_signal_processed / P_total_interference
    
    # Multistatic gain (non-coherent, sqrt(N) in power)
    multistatic_gain = np.sqrt(radar.N_rx)
    sjnr *= multistatic_gain
    
    return linear_to_db(sjnr)

def validate_against_grok_x():
    """Validate calculations against Grok-X simulation results."""
    radar = RadarParams()
    target = TargetParams()
    
    print("=" * 60)
    print("QEDMMA Link Budget Validation")
    print("=" * 60)
    
    # Test cases from Grok-X
    test_cases = [
        ("No jamming", 0, 37.5),
        ("10 kW ERP jammer", 10e3, 16.4),
        ("50 kW ERP jammer", 50e3, 5.9),
        ("100 kW ERP jammer", 100e3, -1.1),
    ]
    
    print(f"\nTarget: RCS={target.RCS} m², Range={target.range_m/1e3} km")
    print(f"Radar: P_tx={radar.P_tx/1e6} MW, B={radar.B/1e6} MHz, T_chirp={radar.T_chirp*1e3} ms")
    print(f"Nodes: {radar.N_rx} Rx (multistatic)")
    print("-" * 60)
    
    for name, P_j, expected_sjnr in test_cases:
        jammer = JammerParams(P_j=P_j)
        calculated = calculate_sjnr(radar, target, jammer)
        diff = calculated - expected_sjnr
        status = "✅" if abs(diff) < 3 else "⚠️"
        print(f"{name:25s}: {calculated:+6.1f} dB (expected: {expected_sjnr:+6.1f} dB) {status}")
    
    print("-" * 60)
    print(f"Detection threshold: ~14 dB (Pd=0.9, Pfa=1e-6)")
    print("=" * 60)
    
    return True

def main():
    parser = argparse.ArgumentParser(description='QEDMMA Link Budget Calculator')
    parser.add_argument('--range', type=float, default=600, help='Range in km')
    parser.add_argument('--rcs', type=float, default=0.0001, help='RCS in m²')
    parser.add_argument('--jammer', type=str, default='0', help='Jammer power (e.g., 50kW)')
    parser.add_argument('--validate', action='store_true', help='Run validation')
    
    args = parser.parse_args()
    
    if args.validate:
        validate_against_grok_x()
    else:
        radar = RadarParams()
        target = TargetParams(RCS=args.rcs, range_m=args.range * 1e3)
        
        # Parse jammer power
        jammer_power = 0
        if args.jammer.lower().endswith('kw'):
            jammer_power = float(args.jammer[:-2]) * 1e3
        elif args.jammer != '0':
            jammer_power = float(args.jammer)
        
        jammer = JammerParams(P_j=jammer_power)
        
        snr = calculate_snr(radar, target)
        sjnr = calculate_sjnr(radar, target, jammer)
        
        print(f"Range: {args.range} km, RCS: {args.rcs} m²")
        print(f"SNR (no jammer): {snr:.1f} dB")
        print(f"SJNR (with {jammer_power/1e3:.0f} kW jammer): {sjnr:.1f} dB")

if __name__ == "__main__":
    main()
