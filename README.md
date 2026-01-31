# 🎯 QEDMMA - Quantum-Enhanced Distributed Metamaterial Multistatic Array

[![CI/CD](https://github.com/mladen1312/QEDMMA-Radar-System/actions/workflows/ci-cd.yml/badge.svg)](https://github.com/mladen1312/QEDMMA-Radar-System/actions)
[![License: Proprietary](https://img.shields.io/badge/License-Proprietary-red.svg)]()
[![FPGA: ZU47DR](https://img.shields.io/badge/FPGA-ZU47DR-blue)](https://www.xilinx.com/products/silicon-devices/soc/rfsoc.html)
[![TRL: 3](https://img.shields.io/badge/TRL-3-yellow)]()

> **Anti-Stealth Detection & Precision Weapon Guidance System**  
> Using Rydberg quantum sensors, VHF bistatic geometry, and TDOA geolocation

**Author:** Dr. Mladen Mešter  
**Copyright:** © 2026 Dr. Mladen Mešter - All Rights Reserved

---

## 🔬 System Overview

QEDMMA is a revolutionary distributed radar system designed to detect and track modern stealth aircraft (F-22, F-35, B-21) that are invisible to conventional X-band radars.

### Key Innovations

| Technology | Benefit |
|------------|---------|
| **VHF Bistatic** | 30× RCS enhancement vs X-band monostatic |
| **Rydberg Sensors** | 500 nV/m/√Hz sensitivity (-190 dBm noise floor) |
| **TDOA Geolocation** | <500m CEP at 150+ km range |
| **Metamaterial Array** | Compact 1×1m antenna with 10 dBi gain |

---

## 🆕 Version 2.0 Enhancements

### Tri-Modal Communication System

| Mode | Capacity | Range | Failover Time |
|------|----------|-------|---------------|
| **FSO** (1550 nm) | 10 Gbps | 50 km | - |
| **E-band** (71-86 GHz) | 10 Gbps | 15 km | <100 ms |
| **HF NVIS** (3-10 MHz) | 9.6 kbps | 500 km | <30 s |

### Extended Range
- **v1.3:** 150 km detection range
- **v2.0:** 380 km detection range (+27.8 dB link budget)

### N+2 Redundancy
- 6 nodes (4 required for operation)
- Hot standby C2 server
- Mesh network topology

---

## 📦 Repository Structure

```
QEDMMA-Radar-System/
├── rtl/                              # RTL Source Files
│   ├── timestamp_capture.sv          # Sub-ns timestamp capture (PPS sync)
│   ├── ddc_core.sv                   # Digital Down Converter (NCO+CIC)
│   ├── cross_correlator.sv           # FFT-based TDOA extraction
│   ├── cs_encoder.sv                 # Compressed Sensing encoder
│   ├── qedmma_rx_top.sv              # Top-level Rx integration
│   ├── imm_tracker.sv                # IMM target tracker
│   ├── tdoa_solver.sv                # TDOA geolocation solver
│   │
│   │   # v2.0 Communication Modules
│   ├── failover_fsm.sv               # ⭐ NEW: Auto-failover FSM
│   ├── link_monitor.sv               # ⭐ NEW: Per-link health monitor
│   └── comm_controller_top.sv        # ⭐ NEW: Communication controller
│
├── tb/                               # Verification
│   ├── test_timestamp_capture.py     # Cocotb testbench
│   ├── test_ddc_core.py              # DDC verification
│   ├── test_failover_fsm.py          # ⭐ NEW: Failover FSM tests
│   └── Makefile                      # Simulation makefile
│
├── drivers/                          # Software Drivers
│   ├── timestamp_capture_driver.c    # Linux kernel driver
│   └── timestamp_capture_regs.h      # C header (auto-gen)
│
├── docs/                             # Documentation
│   ├── QEDMMA_System_Architecture_v1.3.docx
│   ├── QEDMMA_Technical_Appendix_v1.3.md
│   ├── QEDMMA_BOM_v1.3.xlsx
│   ├── QEDMMA_v2.0_COMMUNICATION_SPEC.md  # ⭐ NEW
│   └── QEDMMA_v2.0_UPGRADE_PROPOSAL.md    # ⭐ NEW
│
├── regs/                             # Register Definitions (SSOT)
│   ├── timestamp_capture_regs.yaml
│   ├── ddc_core_regs.yaml
│   ├── correlator_regs.yaml
│   └── comm_controller_regs.yaml     # ⭐ NEW
│
├── scripts/                          # Build & Generation Scripts
│   ├── gen_regs.py                   # YAML → RTL/C/Python generator
│   └── vivado/                       # Vivado TCL scripts
│
├── constraints/                      # FPGA Constraints
│   └── timing_zu47dr.xdc             # Timing for ZU47DR RFSoC
│
└── .github/workflows/                # GitHub Actions
    └── ci-cd.yml                     # Lint → Sim → Synth pipeline
```

---

## 🔧 Signal Processing Chain

```
┌─────────┐    ┌─────────┐    ┌──────────────┐    ┌─────────────┐    ┌────────┐
│ Rydberg │───►│   ADC   │───►│  DDC Core    │───►│ Correlator  │───►│  TDOA  │
│ Sensor  │    │ 5 GSPS  │    │ NCO+Mixer+CIC│    │ FFT-based   │    │ Output │
└─────────┘    └─────────┘    └──────────────┘    └─────────────┘    └────────┘
                                     │
                                     ▼
                              ┌──────────────┐
                              │ CS Encoder   │
                              │ (Compressed) │
                              └──────────────┘
```

## 📡 v2.0 Communication Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    TRI-MODAL COMMUNICATION                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   ┌───────────┐     ┌───────────┐     ┌───────────┐            │
│   │    FSO    │     │  E-BAND   │     │  HF NVIS  │            │
│   │  1550 nm  │     │ 71-86 GHz │     │  3-10 MHz │            │
│   │  10 Gbps  │     │  10 Gbps  │     │  9.6 kbps │            │
│   │   LPI/D   │     │   narrow  │     │   BLOS    │            │
│   └─────┬─────┘     └─────┬─────┘     └─────┬─────┘            │
│         │                 │                 │                   │
│         └─────────────────┴─────────────────┘                   │
│                           │                                     │
│                  ┌────────┴────────┐                           │
│                  │ COMM CONTROLLER │                           │
│                  │ • Auto failover │                           │
│                  │ • AES-256-GCM   │                           │
│                  │ • Mesh routing  │                           │
│                  └─────────────────┘                           │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🔨 Build Instructions

### Prerequisites
- Vivado 2024.1+ (for ZU47DR RFSoC)
- Python 3.10+ with cocotb
- Verilator 5.0+

### Simulation
```bash
cd tb
make                          # Run all tests
make test_link_monitor        # Test link monitor
make test_comm_top            # Test full controller
```

### Synthesis
```bash
cd scripts/vivado
vivado -mode batch -source create_project.tcl
vivado -mode batch -source run_synthesis.tcl
```

---

## 📊 Performance Comparison

| Metric | v1.3 | v2.0 | Improvement |
|--------|------|------|-------------|
| Detection Range | 150 km | 380 km | +2.5× |
| Tx Power | 5 kW | 25 kW | +7 dB |
| Rydberg Sensitivity | 500 nV/m | 200 nV/m | +8 dB |
| Communication | None | Tri-modal | ∞ |
| Redundancy | N/A | N+2 | Full |
| Anti-Jam | None | LPI/LPD + FHSS | Military-grade |
| Failover Time | N/A | <100 ms | Spec |

---

## 📄 License

**PROPRIETARY - ALL RIGHTS RESERVED**

© 2026 Dr. Mladen Mešter

This repository contains proprietary technology. Unauthorized copying, distribution, or use is strictly prohibited.

---

## 📞 Contact

**Dr. Mladen Mešter**  
Radar Systems Architect

---

*Last updated: January 31, 2026*
