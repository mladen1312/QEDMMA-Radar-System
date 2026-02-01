# QEDMMA v2.0 ECCM (Electronic Counter-Countermeasures) Architecture
## Anti-Jamming & Interference Rejection Subsystem

**Author:** Dr. Mladen Mešter  
**Version:** 2.0.1  
**Date:** 31. January 2026  
**Classification:** PROPRIETARY

---

## 1. Threat Analysis Summary

Based on Grok-X simulation [REQ-JAMMING-001]:

| Threat | ERP | Effect on QEDMMA | Mitigation |
|--------|-----|------------------|------------|
| **Self-screening barrage (stealth)** | 10-20 kW | SJNR +12-16 dB | Baseline ECCM sufficient |
| **High-power barrage (fighter)** | 50 kW | SJNR +2-6 dB | Extended integration + ML-CFAR |
| **Stand-off barrage (EA-18G)** | 100+ kW | SJNR < 0 dB | Jammer localization + home-on-jam |
| **Deception (RGPO/VGPO)** | N/A | False targets | Multistatic TDOA rejection |
| **DRFM repeater** | Variable | Coherent false echoes | Pulse diversity + coding |

---

## 2. ECCM Hierarchy

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        QEDMMA ECCM ARCHITECTURE                              │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  LEVEL 1: INHERENT (Physics-based)                                          │
│  ┌──────────────────────────────────────────────────────────────────────┐  │
│  │ • VHF wavelength → Resonance RCS enhancement (30×)                    │  │
│  │ • Rydberg quantum Rx → Ultra-low noise floor (100 K)                  │  │
│  │ • LFM waveform → 60 dB processing gain (TB = 10⁶)                     │  │
│  │ • Bistatic geometry → Jammer sees only Tx, not Rx                     │  │
│  │ • Multistatic (6 Rx) → Spatial diversity (+4 dB non-coherent)         │  │
│  └──────────────────────────────────────────────────────────────────────┘  │
│                                                                              │
│  LEVEL 2: ADAPTIVE (Signal processing)                                       │
│  ┌──────────────────────────────────────────────────────────────────────┐  │
│  │ • Extended coherent integration (10→50 pulses, +7 dB)                 │  │
│  │ • ML-assisted CFAR (jammer vs clutter classification)                 │  │
│  │ • Adaptive pulse scheduling (avoid jammer time-slots)                 │  │
│  │ • Sidelobe blanking (auxiliary channels)                              │  │
│  └──────────────────────────────────────────────────────────────────────┘  │
│                                                                              │
│  LEVEL 3: ACTIVE (Countermeasures)                                           │
│  ┌──────────────────────────────────────────────────────────────────────┐  │
│  │ • Jammer localization (TDOA/AOA triangulation)                        │  │
│  │ • Home-on-jam mode (passive tracking of jammer)                       │  │
│  │ • Burn-through calculation (optimal Tx power allocation)              │  │
│  │ • Track-through-jam (IMM filter with jam state model)                 │  │
│  └──────────────────────────────────────────────────────────────────────┘  │
│                                                                              │
│  LEVEL 4: COGNITIVE (AI-driven)                                              │
│  ┌──────────────────────────────────────────────────────────────────────┐  │
│  │ • Jammer classification (barrage/deception/DRFM)                      │  │
│  │ • Threat prioritization (ML-based)                                    │  │
│  │ • Waveform adaptation (optimal TB product selection)                  │  │
│  │ • Autonomous ECCM mode selection                                      │  │
│  └──────────────────────────────────────────────────────────────────────┘  │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 3. Key ECCM Modules

### 3.1 ML-Assisted CFAR

**Purpose:** Distinguish jamming from clutter in range-Doppler map.

**Algorithm:**
1. Compute local statistics (mean, variance, kurtosis)
2. Extract features: power ratio, spectral flatness, temporal correlation
3. ML classifier (lightweight CNN or Random Forest on FPGA)
4. Adaptive threshold: $T = \alpha \cdot \mu + \beta \cdot \sigma$

**Implementation:**
- FPGA: Feature extraction + inference
- Edge AI: Model training/update
- Latency: <1 ms per CPI

### 3.2 Extended Integration Controller

**Purpose:** Dynamically adjust integration time based on jamming level.

**Algorithm:**
```
IF J/S > threshold_high THEN
    N_pulses = 50 (max integration)
    T_chirp = 500 ms
ELSE IF J/S > threshold_low THEN
    N_pulses = 20
    T_chirp = 200 ms
ELSE
    N_pulses = 10 (baseline)
    T_chirp = 100 ms
END IF
```

**Gain:** Up to +7 dB additional processing gain.

### 3.3 Jammer Localization Engine

**Purpose:** Triangulate jammer position using TDOA.

**Method:**
- Time difference of arrival at 3+ Rx nodes
- Hyperbolic intersection
- Kalman filter for jammer track

**Precision:** <1 km CEP at 500 km range (with 6 nodes, 100 km baseline).

### 3.4 Deception Rejection Filter

**Purpose:** Reject RGPO/VGPO and DRFM false targets.

**Methods:**
1. **Multistatic consistency:** True target has consistent TDOA across all Rx pairs
2. **Doppler validation:** Verify range rate matches Doppler
3. **Pulse-to-pulse correlation:** DRFM has characteristic signatures
4. **Waveform agility:** Random PRI/frequency defeats repeaters

---

## 4. Performance Targets

| Metric | Baseline | With ECCM | Improvement |
|--------|----------|-----------|-------------|
| **SJNR (50 kW jammer)** | +2.0 dB | +9.0 dB | +7 dB |
| **False target rejection** | 90% | 99.9% | 10× |
| **Jammer localization** | N/A | <1 km CEP | New capability |
| **Track continuity (in jam)** | 60% | 95% | +35% |

---

## 5. RTL Module Summary

| Module | Function | Lines | Status |
|--------|----------|-------|--------|
| `ml_cfar_engine.sv` | ML-assisted CFAR | ~400 | NEW |
| `integration_controller.sv` | Adaptive integration | ~200 | NEW |
| `jammer_localizer.sv` | TDOA-based HOJ | ~350 | NEW |
| `deception_filter.sv` | False target rejection | ~300 | NEW |
| `eccm_controller.sv` | Top-level ECCM FSM | ~250 | NEW |

---

## 6. Register Map Extension

Base: `0x00030000` (ECCM subsystem)

| Offset | Name | Description |
|--------|------|-------------|
| 0x0000 | ECCM_CTRL | Enable bits for each ECCM function |
| 0x0004 | ECCM_STATUS | Jamming detected, HOJ active, etc. |
| 0x0008 | JAM_THRESHOLD_HIGH | J/S threshold for max integration |
| 0x000C | JAM_THRESHOLD_LOW | J/S threshold for baseline |
| 0x0010 | INTEGRATION_CFG | N_pulses, T_chirp settings |
| 0x0020 | JAMMER_POS_X | Estimated jammer position X |
| 0x0024 | JAMMER_POS_Y | Estimated jammer position Y |
| 0x0028 | JAMMER_POWER | Estimated jammer ERP |
| 0x0030 | CFAR_FEATURES | ML feature extraction config |
| 0x0040 | DECEPTION_CFG | False target rejection params |

---

*Document Control: QEDMMA-ECCM-ARCH-001*
