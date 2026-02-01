# QEDMMA - Quantum-Enhanced Distributed Multi-Mode Array

[![Unified CI](https://github.com/mladen1312/QEDMMA-Radar-System/actions/workflows/qedmma_unified_ci.yml/badge.svg)](https://github.com/mladen1312/QEDMMA-Radar-System/actions)
[![License](https://img.shields.io/badge/License-Proprietary-red.svg)](LICENSE)
[![Version](https://img.shields.io/badge/Version-3.0.0-blue.svg)](CHANGELOG.md)

> **Revolutionary anti-stealth radar system leveraging Rydberg quantum receivers and spread-spectrum waveforms for detection of 5th-generation stealth aircraft at unprecedented ranges.**

**Author:** Dr. Mladen Mešter  
**Copyright © 2026** - All Rights Reserved

---

## 🎯 Performance Summary

| Parameter | QEDMMA v3.0 | Competitors (JY-27V, Rezonans-NE) |
|-----------|-------------|-----------------------------------|
| **Detection Range** | **380+ km @ 0.0001 m² RCS** | ~150-200 km |
| **Range Resolution** | **0.75 m** | 15-50 m |
| **Processing Gain** | **45-60 dB** (PRBS-15/20) | 30-40 dB (LFM) |
| **Quantum SNR Advantage** | **+15-25 dB** | N/A (classical) |
| **ECCM Gain** | **+7 dB** (validated) | +2-3 dB |
| **Geolocation CEP** | **<500 m @ 300 km** | >2 km |
| **Unit Cost** | **~€1.8M** | €15-30M |

---

## 🏗️ System Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         QEDMMA v3.0 SYSTEM ARCHITECTURE                      │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐  │
│  │  QUANTUM    │    │   200M      │    │   MULTI-    │    │    ECCM     │  │
│  │  RECEIVER   │───▶│  CORRELATOR │───▶│   SENSOR    │───▶│   ENGINE    │  │
│  │  (Rydberg)  │    │  (8-lane)   │    │   FUSION    │    │  (+7 dB)    │  │
│  └─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘  │
│        │                  │                  │                  │           │
│        │                  │                  │                  │           │
│        ▼                  ▼                  ▼                  ▼           │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                        TRI-MODAL COMMUNICATION                       │   │
│  │            Link-16 (Primary) │ HF (Backup) │ SATCOM (Tertiary)      │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                      FPGA SUBSYSTEM (ZU47DR)                         │   │
│  │  ┌───────────┐  ┌───────────┐  ┌───────────┐  ┌───────────┐        │   │
│  │  │   PRBS    │  │ PARALLEL  │  │   TRACK   │  │    ML     │        │   │
│  │  │ GENERATOR │  │ CORRELATOR│  │  DATABASE │  │   CFAR    │        │   │
│  │  │ (8-lane)  │  │ (48-bit)  │  │  (1024)   │  │  ENGINE   │        │   │
│  │  └───────────┘  └───────────┘  └───────────┘  └───────────┘        │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 📁 Repository Structure

```
QEDMMA-Radar-System/
├── README.md                          # This file
├── CHANGELOG.md                       # Version history
├── .github/workflows/                 # CI/CD pipelines
│   ├── qedmma_unified_ci.yml         # Main unified pipeline
│   ├── correlator_ci.yml             # Correlator-specific
│   └── physics_validation.yml        # Link budget checks
├── sim/                               # Simulation & validation
│   ├── link_budget.py                # Radar equation simulator
│   ├── fixed_point_twin.py           # Q-format validation
│   └── rydberg_noise_model.py        # Quantum RX noise (NEW)
├── scripts/
│   └── gen_regs.py                   # SSOT register generator
└── v2/
    ├── rtl/
    │   ├── fusion/                   # Multi-sensor fusion (5 modules)
    │   │   ├── track_fusion_engine.sv
    │   │   ├── track_database.sv
    │   │   ├── external_track_adapter.sv
    │   │   ├── link16_interface.sv
    │   │   └── asterix_parser.sv
    │   ├── eccm/                     # Electronic protection (4 modules)
    │   │   ├── eccm_controller.sv
    │   │   ├── ml_cfar_engine.sv
    │   │   ├── jammer_localizer.sv
    │   │   └── integration_controller.sv
    │   ├── comm/                     # Tri-modal comms (3 modules)
    │   │   ├── comm_controller_top.sv
    │   │   ├── failover_fsm.sv
    │   │   └── link_monitor.sv
    │   └── correlator/               # v3.0 200 Mchip/s (3 modules)
    │       ├── correlator_top_200m.sv
    │       ├── parallel_correlator_engine.sv
    │       └── prbs_generator_parallel.sv
    ├── regs/                         # YAML register maps (SSOT)
    │   ├── fusion_engine_regs.yaml
    │   ├── comm_controller_regs.yaml
    │   └── qedmma_v3_regs.yaml       # Quantum + waveform
    ├── tb/                           # Testbenches
    │   ├── test_track_fusion.py
    │   ├── test_failover_fsm.py
    │   └── correlator/
    │       ├── test_correlator_200m.py
    │       └── test_correlator_standalone.py
    └── docs/                         # Documentation
        ├── CORRELATOR_v3_SPECIFICATION.md
        ├── MULTI_SENSOR_FUSION_ARCHITECTURE.md
        ├── COMPETITIVE_ANALYSIS.md
        └── eccm/
            └── ECCM_ARCHITECTURE.md
```

---

## 🔬 Key Technologies

### 1. Quantum Receiver (Rydberg Atoms)
- **Sensitivity:** 200 nV/m/√Hz (vs 1 µV/m/√Hz classical)
- **Advantage:** +15-25 dB SNR improvement
- **States:** Cesium 60S₁/₂ → 60P₃/₂ transition @ 75 MHz

### 2. 200 Mchip/s PRBS Correlator
- **Architecture:** 8-lane parallel @ 25 MHz clock
- **Processing Gain:** 33-60 dB (PRBS-11 to PRBS-20)
- **Range Resolution:** 0.75 m
- **Fixed-Point:** Q16.16 (48-bit accumulator)

### 3. AI-Enhanced ECCM
- **ML-CFAR:** Adaptive threshold based on clutter statistics
- **Jammer Localization:** TDOA/FDOA triangulation
- **Validated Gain:** +7 dB against 50 kW barrage jammer

### 4. Multi-Sensor Fusion (JDL Model)
- **Inputs:** ASTERIX Cat-048/062, Link-16 J3.2/J7.2, ESM, IRST
- **Algorithms:** IMM (CV/CA/CT), MHT for tracking
- **Track Capacity:** 1,024 simultaneous targets

---

## 📊 RTL Statistics

| Subsystem | Modules | Lines | DSP48 | BRAM |
|-----------|---------|-------|-------|------|
| Fusion | 5 | 2,276 | 8 | 32 |
| ECCM | 4 | 1,750 | 24 | 16 |
| Comm | 3 | 1,050 | 4 | 8 |
| Correlator | 3 | 788 | 32 | 24 |
| **TOTAL** | **15** | **5,864** | **68** | **80** |

**Target FPGA:** Xilinx Zynq UltraScale+ ZU47DR  
**Utilization:** <5% (room for v4.0 neural ATR)

---

## 🔧 Quick Start

```bash
# Clone repository
git clone https://github.com/mladen1312/QEDMMA-Radar-System.git
cd QEDMMA-Radar-System

# Run physics validation
python sim/link_budget.py --validate

# Run correlator tests
cd v2/tb/correlator
python test_correlator_standalone.py

# Lint RTL (requires Verilator)
verilator --lint-only -Wall v2/rtl/correlator/*.sv
```

---

## 🗺️ Roadmap

| Version | Status | Key Features |
|---------|--------|--------------|
| **v2.1** | ✅ Complete | Multi-sensor fusion, ECCM (+7 dB), tri-modal comm |
| **v3.0** | 🔄 In Progress | 200 Mchip/s PRBS, quantum RX integration, Q16.16 |
| **v3.1** | 📋 Planned | White Rabbit PTP sync (<100 ps), bit-true twin |
| **v4.0** | 📋 Planned | Neural ATR (micro-Doppler), DRFM rejection |

---

## 📜 References

1. Sedlacek, J. A., et al. "Microwave electrometry with Rydberg atoms." *Nature Physics* 8, 819–824 (2012)
2. Meyer, D. H., et al. "Digital communication with Rydberg atoms." *Physical Review Applied* 15, 014053 (2021)
3. Skolnik, M. I. *Radar Handbook*, 3rd Ed. McGraw-Hill (2008)

---

## 📄 License

**Proprietary** - Copyright © 2026 Dr. Mladen Mešter. All rights reserved.

This software is proprietary and confidential. Unauthorized copying, distribution, or use is strictly prohibited.

---

## 📧 Contact

**Dr. Mladen Mešter**  
Zagreb, Croatia

*"Defeating stealth through quantum physics."*
