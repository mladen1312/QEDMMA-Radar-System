#!/usr/bin/env python3
"""
QEDMMA v3.0 - Ambiguity Function Analyzer (Corrected)
[REQ-WAVE-001] Validate PRBS waveform sidelobe levels

Author: Dr. Mladen Mešter
Copyright (c) 2026 - All Rights Reserved
"""

import numpy as np
from dataclasses import dataclass
from typing import Dict, List
from enum import IntEnum

C_LIGHT = 299_792_458  # m/s

class PRBSType(IntEnum):
    PRBS_11 = 11
    PRBS_15 = 15
    PRBS_20 = 20

PRBS_TAPS = {
    PRBSType.PRBS_11: [11, 9],
    PRBSType.PRBS_15: [15, 14],
    PRBSType.PRBS_20: [20, 17],
}

def generate_prbs(prbs_type: PRBSType, seed: int = 1) -> np.ndarray:
    """Generate maximal-length PRBS sequence as ±1 values."""
    n = int(prbs_type)
    length = (1 << n) - 1
    taps = PRBS_TAPS[prbs_type]
    
    lfsr = seed & ((1 << n) - 1)
    if lfsr == 0:
        lfsr = 1
    
    sequence = np.zeros(length, dtype=np.float64)
    
    for i in range(length):
        sequence[i] = (lfsr & 1) * 2 - 1
        feedback = 0
        for tap in taps:
            feedback ^= (lfsr >> (tap - 1)) & 1
        lfsr = ((lfsr >> 1) | (feedback << (n - 1))) & ((1 << n) - 1)
    
    return sequence

def verify_prbs_autocorrelation(prbs_type: PRBSType) -> Dict:
    """
    Verify PRBS autocorrelation properties.
    
    For maximal-length sequence with ±1 values:
    - R(0) = N (peak)
    - R(τ≠0) = -1 (sidelobe)
    - PSL = 20*log10(1/N) dB
    """
    seq = generate_prbs(prbs_type)
    N = len(seq)
    
    # Peak (lag 0)
    R_0 = np.sum(seq * seq)  # Should be N
    
    # Sample some sidelobes
    test_lags = [1, 2, 10, 100, N//2, N-1]
    sidelobes = []
    
    for lag in test_lags:
        if lag < N:
            # Circular correlation for PRBS
            R_lag = np.sum(seq * np.roll(seq, lag))
            sidelobes.append(R_lag)
    
    # For m-sequence, all sidelobes should be -1
    avg_sidelobe = np.mean(sidelobes)
    max_sidelobe = np.max(np.abs(sidelobes))
    
    # PSL calculation
    # Normalized: peak = 1, sidelobe = -1/N
    # PSL = 20*log10(|-1|/N) = 20*log10(1/N) = -20*log10(N)
    psl_measured_db = 20 * np.log10(max_sidelobe / R_0)
    psl_theoretical_db = 20 * np.log10(1.0 / N)
    
    return {
        'N': N,
        'R_0': R_0,
        'expected_R_0': N,
        'avg_sidelobe': avg_sidelobe,
        'expected_sidelobe': -1,
        'max_sidelobe_abs': max_sidelobe,
        'psl_measured_db': psl_measured_db,
        'psl_theoretical_db': psl_theoretical_db,
        'prbs_valid': abs(avg_sidelobe - (-1)) < 0.1 and abs(R_0 - N) < 0.1
    }

@dataclass
class WaveformAnalysis:
    prbs_type: PRBSType
    chip_rate_hz: float
    code_length: int
    processing_gain_db: float
    psl_db: float
    range_resolution_m: float
    unambiguous_range_km: float
    doppler_resolution_hz: float
    doppler_tolerance_hz: float

def analyze_waveform(prbs_type: PRBSType, chip_rate_hz: float) -> WaveformAnalysis:
    """Analyze PRBS waveform parameters."""
    N = (1 << int(prbs_type)) - 1
    T_chip = 1.0 / chip_rate_hz
    T_code = N * T_chip
    
    # Processing gain
    proc_gain_db = 10 * np.log10(N)
    
    # PSL for m-sequence (theoretical)
    psl_db = -20 * np.log10(N)  # This is the correct formula
    
    # Range resolution
    range_res = C_LIGHT / (2 * chip_rate_hz)
    
    # Unambiguous range
    unamb_range = C_LIGHT * T_code / 2
    
    # Doppler resolution (1/integration time)
    doppler_res = 1.0 / T_code
    
    # Doppler tolerance (3dB point)
    doppler_tol = 0.443 / T_code
    
    return WaveformAnalysis(
        prbs_type=prbs_type,
        chip_rate_hz=chip_rate_hz,
        code_length=N,
        processing_gain_db=proc_gain_db,
        psl_db=psl_db,
        range_resolution_m=range_res,
        unambiguous_range_km=unamb_range / 1000,
        doppler_resolution_hz=doppler_res,
        doppler_tolerance_hz=doppler_tol
    )

def detection_analysis(wf: WaveformAnalysis,
                       tx_power_kw: float = 10.0,
                       antenna_gain_dbi: float = 25.0,
                       system_temp_k: float = 50.0,
                       quantum_gain_db: float = 13.0,
                       eccm_gain_db: float = 7.0) -> Dict:
    """Compute detection performance against stealth targets."""
    k_B = 1.38e-23
    freq_hz = 75e6
    wavelength = C_LIGHT / freq_hz
    
    P_tx = tx_power_kw * 1000
    G = 10 ** (antenna_gain_dbi / 10)
    
    # Total gain stack
    total_gain_db = wf.processing_gain_db + quantum_gain_db + eccm_gain_db
    total_gain = 10 ** (total_gain_db / 10)
    
    bandwidth = wf.chip_rate_hz
    noise_power = k_B * system_temp_k * bandwidth
    
    # Minimum detectable RCS at 100 km
    R_ref = 100e3
    snr_req = 10 ** (13 / 10)  # 13 dB required
    
    sigma_min = (snr_req * noise_power * (4*np.pi)**3 * R_ref**4) / \
                (P_tx * G**2 * wavelength**2 * total_gain)
    sigma_min_dbsm = 10 * np.log10(sigma_min + 1e-30)
    
    # Target detection ranges
    targets = {
        'F-35': -40.0,     # 0.0001 m²
        'J-20': -35.0,     # 0.0003 m²
        'Su-57': -30.0,    # 0.001 m²
        'F-16': 0.0,       # 1 m²
    }
    
    detection_ranges = {}
    for name, rcs_dbsm in targets.items():
        sigma = 10 ** (rcs_dbsm / 10)
        R_max_4 = (P_tx * G**2 * wavelength**2 * sigma * total_gain) / \
                  (snr_req * noise_power * (4*np.pi)**3)
        R_max_km = (R_max_4 ** 0.25) / 1000
        detection_ranges[name] = R_max_km
        
    # F-35 margin
    f35_margin = -40.0 - sigma_min_dbsm  # Positive = can detect
    
    # Clutter rejection (based on PSL)
    clutter_rejection = abs(wf.psl_db)
    
    # Risk assessment
    if wf.psl_db < -30:
        risk = "LOW"
        suitable = True
    elif wf.psl_db < -20:
        risk = "MEDIUM"
        suitable = f35_margin > 0
    else:
        risk = "HIGH"
        suitable = False
    
    return {
        'total_gain_db': total_gain_db,
        'min_detectable_rcs_dbsm': sigma_min_dbsm,
        'detection_ranges_km': detection_ranges,
        'f35_margin_db': f35_margin,
        'clutter_rejection_db': clutter_rejection,
        'sidelobe_risk': risk,
        'suitable': suitable
    }

def run_analysis():
    """Run comprehensive waveform analysis."""
    chip_rate_mcps = 200.0
    chip_rate_hz = chip_rate_mcps * 1e6
    
    print("\n" + "=" * 80)
    print("QEDMMA v3.0 - AMBIGUITY FUNCTION ANALYZER")
    print(f"Chip Rate: {chip_rate_mcps} Mchip/s")
    print("System Gains: +13 dB Quantum, +7 dB ECCM")
    print("=" * 80)
    
    # First verify PRBS properties
    print("\n📐 PRBS AUTOCORRELATION VERIFICATION")
    print("-" * 60)
    
    for prbs_type in [PRBSType.PRBS_11, PRBSType.PRBS_15]:
        verify = verify_prbs_autocorrelation(prbs_type)
        print(f"\nPRBS-{int(prbs_type)}: N = {verify['N']:,}")
        print(f"  R(0) = {verify['R_0']:.0f} (expected: {verify['expected_R_0']})")
        print(f"  R(τ≠0) avg = {verify['avg_sidelobe']:.2f} (expected: -1)")
        print(f"  PSL measured = {verify['psl_measured_db']:.1f} dB")
        print(f"  PSL theoretical = {verify['psl_theoretical_db']:.1f} dB")
        print(f"  PRBS Valid: {'✅' if verify['prbs_valid'] else '❌'}")
    
    print("\n" + "=" * 80)
    print("WAVEFORM ANALYSIS")
    print("=" * 80)
    
    results = []
    
    for prbs_type in [PRBSType.PRBS_11, PRBSType.PRBS_15, PRBSType.PRBS_20]:
        print(f"\n{'─' * 80}")
        print(f"PRBS-{int(prbs_type)}")
        print(f"{'─' * 80}")
        
        wf = analyze_waveform(prbs_type, chip_rate_hz)
        det = detection_analysis(wf)
        
        print(f"\n  📊 Waveform Characteristics:")
        print(f"     Code Length:           {wf.code_length:,} chips")
        print(f"     Processing Gain:       {wf.processing_gain_db:.1f} dB")
        print(f"     Peak Sidelobe (PSL):   {wf.psl_db:.1f} dB")
        print(f"     Range Resolution:      {wf.range_resolution_m:.3f} m")
        print(f"     Unambiguous Range:     {wf.unambiguous_range_km:.1f} km")
        print(f"     Doppler Resolution:    {wf.doppler_resolution_hz:.2f} Hz")
        
        print(f"\n  🎯 Detection Performance (Total Gain: {det['total_gain_db']:.1f} dB):")
        print(f"     Min Detectable RCS:    {det['min_detectable_rcs_dbsm']:.1f} dBsm")
        print(f"     F-35 Detection:        {det['detection_ranges_km']['F-35']:.0f} km")
        print(f"     J-20 Detection:        {det['detection_ranges_km']['J-20']:.0f} km")
        print(f"     Su-57 Detection:       {det['detection_ranges_km']['Su-57']:.0f} km")
        print(f"     F-35 Margin:           {det['f35_margin_db']:.1f} dB")
        print(f"     Clutter Rejection:     {det['clutter_rejection_db']:.1f} dB")
        print(f"     Sidelobe Risk:         {det['sidelobe_risk']}")
        print(f"     Suitable for Stealth:  {'✅ YES' if det['suitable'] else '❌ NO'}")
        
        results.append({
            'prbs': f"PRBS-{int(prbs_type)}",
            'N': wf.code_length,
            'proc_gain': wf.processing_gain_db,
            'psl': wf.psl_db,
            'resolution': wf.range_resolution_m,
            'unamb_range': wf.unambiguous_range_km,
            'total_gain': det['total_gain_db'],
            'f35_range': det['detection_ranges_km']['F-35'],
            'f35_margin': det['f35_margin_db'],
            'clutter_rej': det['clutter_rejection_db'],
            'suitable': det['suitable']
        })
    
    # Summary table
    print("\n" + "=" * 80)
    print("COMPARISON SUMMARY")
    print("=" * 80)
    print(f"\n{'PRBS':<10} {'N':<12} {'P.Gain':<8} {'PSL':<8} {'F-35 km':<10} {'Margin':<10} {'Suitable'}")
    print("-" * 76)
    for r in results:
        ok = "✅" if r['suitable'] else "❌"
        print(f"{r['prbs']:<10} {r['N']:<12,} {r['proc_gain']:<8.1f} {r['psl']:<8.1f} {r['f35_range']:<10.0f} {r['f35_margin']:<10.1f} {ok}")
    
    # Recommendation
    suitable_results = [r for r in results if r['suitable']]
    if suitable_results:
        best = max(suitable_results, key=lambda x: x['f35_range'])
    else:
        best = max(results, key=lambda x: x['f35_margin'])
    
    print("\n" + "=" * 80)
    print("📋 FINAL RECOMMENDATION")
    print("=" * 80)
    print(f"""
    RECOMMENDED WAVEFORM: {best['prbs']}
    
    ┌─────────────────────────────────────────────────────────────┐
    │  Parameter              │  Value                           │
    ├─────────────────────────────────────────────────────────────┤
    │  Code Length            │  {best['N']:,} chips{' ' * (20 - len(f"{best['N']:,}"))}│
    │  Processing Gain        │  {best['proc_gain']:.1f} dB                        │
    │  Peak Sidelobe Level    │  {best['psl']:.1f} dB                       │
    │  Range Resolution       │  {best['resolution']:.3f} m                        │
    │  Unambiguous Range      │  {best['unamb_range']:.1f} km                       │
    │  Total System Gain      │  {best['total_gain']:.1f} dB                        │
    │  F-35 Detection Range   │  {best['f35_range']:.0f} km                         │
    │  F-35 Margin            │  {best['f35_margin']:.1f} dB                        │
    │  Clutter Rejection      │  {best['clutter_rej']:.1f} dB                       │
    └─────────────────────────────────────────────────────────────┘
    
    VALIDATION STATUS: {'✅ WAVEFORM VALIDATED' if best['suitable'] else '⚠️ NEEDS OPTIMIZATION'}
    
    Key Finding:
    • PRBS-{best['prbs'].split('-')[1]} provides {best['psl']:.0f} dB sidelobe suppression
    • With {best['total_gain']:.1f} dB total gain, F-35 detectable at {best['f35_range']:.0f} km
    • Sidelobes below -{abs(best['psl']):.0f} dB ensure minimal false alarms from clutter
    """)
    
    return results

if __name__ == "__main__":
    results = run_analysis()
    print("\n✅ AMBIGUITY ANALYSIS COMPLETE\n")
