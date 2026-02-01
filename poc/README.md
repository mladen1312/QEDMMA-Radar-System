# QEDMMA PoC - "Garažni Pobunjenik" v3.4

[![Budget](https://img.shields.io/badge/Budget-€495-green.svg)](hardware/BOM_GARAZNI_POBUNJENIK.csv)
[![Range](https://img.shields.io/badge/Test_Range-10--100_km-blue.svg)](docs/QEDMMA_POC_BUILD_GUIDE.md)
[![License](https://img.shields.io/badge/License-Proprietary-red.svg)](LICENSE)

> **Proof-of-Concept VHF radar demonstrating QEDMMA core physics for <€500**

**Author:** Dr. Mladen Mešter  
**Copyright © 2026** - All Rights Reserved

---

## 🎯 What This Proves

| Concept | How It's Demonstrated |
|---------|----------------------|
| **Zero-DSP Correlation** | Python implementation matches FPGA logic |
| **PRBS Processing Gain** | 45-60 dB demonstrated in software |
| **VHF Anti-Stealth** | 155 MHz defeats RAM coatings |
| **Low-Cost LNA** | SPF5189Z (€12) achieves 0.6 dB NF |
| **Bistatic Geometry** | Separate Tx/Rx antennas |

---

## 💰 Budget Summary

| Category | Cost |
|----------|------|
| SDR (ADALM-PLUTO) | €230 |
| RF (PA + LNA + Cables) | €127 |
| Antenna (DIY Yagi) | €34 |
| Power & Thermal | €51 |
| Misc | €33 |
| **TOTAL** | **€495** |

[📋 Full BOM (CSV)](hardware/BOM_GARAZNI_POBUNJENIK.csv)

---

## 📡 System Specs

```
┌────────────────────────────────────────────┐
│        GARAŽNI POBUNJENIK SPECS            │
├────────────────────────────────────────────┤
│ Frequency:      155 MHz (VHF)              │
│ Tx Power:       30 W (RA30H1317M)          │
│ Rx NF:          0.6 dB (SPF5189Z)          │
│ PRBS:           PRBS-15 (32767 chips)      │
│ Chip Rate:      1 Mchip/s                  │
│ Processing Gain: 45 dB                     │
│ Range Resolution: 150 m                    │
│ Max Range:      ~100 km (aircraft)         │
│ Antenna Gain:   ~10 dBi (5-elem Yagi)      │
└────────────────────────────────────────────┘
```

---

## 📁 Repository Structure

```
qedmma_poc/
├── README.md                    # This file
├── docs/
│   └── QEDMMA_POC_BUILD_GUIDE.md  # Complete build guide
├── software/
│   ├── pluto_radar.py           # Main radar application
│   ├── zero_dsp_correlator.py   # Core correlator
│   └── radar_display.py         # Real-time display
├── hardware/
│   └── BOM_GARAZNI_POBUNJENIK.csv # Bill of materials
└── test/
    └── loopback_test.py         # Self-test suite
```

---

## 🚀 Quick Start

### 1. Install Dependencies

```bash
pip install pyadi-iio numpy scipy matplotlib numba
```

### 2. Connect PlutoSDR

```bash
# Test connection
python3 -c "import adi; sdr = adi.Pluto(); print('OK!')"
```

### 3. Run Self-Test

```bash
cd test
python3 loopback_test.py
```

### 4. Run Radar

```bash
cd software
python3 pluto_radar.py --mode sim       # Simulation
python3 pluto_radar.py --mode loopback  # With hardware
```

---

## 🔧 Hardware Assembly

### Block Diagram

```
LAPTOP
   │ USB
   ▼
┌──────────┐
│  PLUTO   │
│  SDR     │
└──┬───┬───┘
   │   │
  Tx  Rx
   │   │
   ▼   ▼
┌──────┐ ┌─────────┐
│10dB  │ │Bias Tee │
│Atten │ │  +5V    │
└──┬───┘ └────┬────┘
   │          │
   ▼          ▼
┌─────────┐ ┌─────────┐
│RA30H1317│ │SPF5189Z │
│  30W PA │ │  LNA    │
└────┬────┘ └────┬────┘
     │           │
     ▼           ▼
  Tx Yagi     Rx Yagi
```

### DIY Yagi Antenna (155 MHz)

```
Element      Length    Position
─────────────────────────────────
Reflector    1010 mm   0 mm
Driven       940 mm    350 mm
Director 1   910 mm    650 mm
Director 2   890 mm    1000 mm
Director 3   870 mm    1450 mm
─────────────────────────────────
Gain: ~10.5 dBi
```

---

## 📊 Expected Results

### Loopback Test
- SNR: >50 dB
- Peak at bin 0 ±2
- Sidelobes: <-40 dB

### Field Test (Aircraft)
- Detection range: 50-100 km
- SNR after processing: >30 dB
- Range accuracy: <150 m

---

## ⚠️ Legal Notice

- **Amateur radio license required** for VHF transmission
- Test in shielded environment or obtain HAKOM permit
- For **educational and research purposes only**

---

## 📈 Upgrade Path

| Stage | Addition | New Capability |
|-------|----------|----------------|
| PoC | This build | Prove physics |
| V2 | Second Pluto | TDOA localization |
| V3 | GPS + PPS | Precise timing |
| Full | Rydberg receiver | Quantum sensitivity |

---

**Garažni Pobunjenik v3.4** - *Dokaz fizike za cijenu SUV servisa!* 🚀
