# 🎯 QEDMMA - Quantum-Enhanced Distributed Metamaterial Multistatic Array

[![CI/CD](https://github.com/mladen1312/QEDMMA-Radar-System/actions/workflows/ci-cd.yml/badge.svg)](https://github.com/mladen1312/QEDMMA-Radar-System/actions)
[![License: Proprietary](https://img.shields.io/badge/License-Proprietary-red.svg)]()
[![FPGA: ZU47DR](https://img.shields.io/badge/FPGA-ZU47DR-blue)](https://www.xilinx.com/products/silicon-devices/soc/rfsoc.html)
[![TRL: 3](https://img.shields.io/badge/TRL-3-yellow)]()

> **Anti-Stealth Detection & Precision Weapon Guidance System**  
> Using Rydberg quantum sensors, VHF bistatic geometry, and TDOA geolocation

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

## 📦 Repository Structure

```
QEDMMA-Radar-System/
├── rtl/                              # RTL Source Files
│   ├── timestamp_capture.sv          # Sub-ns timestamp capture (PPS sync)
│   ├── ddc_core.sv                   # Digital Down Converter (NCO+CIC)
│   ├── cross_correlator.sv           # FFT-based TDOA extraction
│   ├── cs_encoder.sv                 # Compressed Sensing encoder
│   ├── qedmma_rx_top.sv              # Top-level Rx integration
│   └── timestamp_capture_regs_pkg.sv # Register definitions
│
├── tb/                               # Verification
│   ├── test_timestamp_capture.py     # Cocotb testbench
│   ├── test_ddc_core.py              # DDC verification
│   └── Makefile                      # Simulation makefile
│
├── drivers/                          # Software Drivers
│   ├── timestamp_capture_driver.c    # Linux kernel driver
│   ├── timestamp_capture_regs.h      # C header (auto-gen)
│   └── timestamp_capture.dts         # Device Tree overlay
│
├── docs/                             # Documentation
│   ├── QEDMMA_System_Architecture_v1.3.docx
│   ├── QEDMMA_Technical_Appendix_v1.3.md
│   ├── QEDMMA_BOM_v1.3.xlsx
│   └── QEDMMA_Architecture_Diagrams.md
│
├── regs/                             # Register Definitions (SSOT)
│   └── timestamp_capture_regs.yaml
│
├── scripts/                          # Build & Generation Scripts
│   └── gen_regs.py                   # YAML → RTL/C/Python generator
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
                              │  CS Encoder  │ (Optional)
                              │  2-10× compr │
                              └──────────────┘
```

### RTL Modules

| Module | LOC | Function |
|--------|-----|----------|
| `timestamp_capture.sv` | 860 | Sub-ns PPS timestamping |
| `ddc_core.sv` | 282 | NCO + Mixer + CIC filter |
| `cross_correlator.sv` | 376 | FFT correlation + TDOA |
| `cs_encoder.sv` | 263 | Compressed sensing |
| `qedmma_rx_top.sv` | 261 | Top-level integration |
| **Total** | **2,042** | |

---

## 🚀 Quick Start

### Prerequisites

- Vivado 2024.1+ (for synthesis)
- Verilator 5.0+ (for simulation)
- Python 3.10+ with cocotb
- GNU Make

### Build & Test

```bash
# Clone repository
git clone https://github.com/mladen1312/QEDMMA-Radar-System.git
cd QEDMMA-Radar-System

# Run simulation
cd tb
make SIM=verilator

# Run lint check
verilator --lint-only -Wall rtl/*.sv

# Regenerate registers from YAML
python scripts/gen_regs.py
```

### Vivado Synthesis

```bash
cd scripts/vivado
vivado -mode batch -source create_project.tcl
vivado -mode batch -source run_synthesis.tcl
```

---

## 📊 Performance Specifications

| Parameter | Value | Notes |
|-----------|-------|-------|
| Detection Range | >150 km | RCS 0.01 m² (stealth) |
| Localization | <500 m CEP | 4-node TDOA |
| E-field Sensitivity | 500 nV/m/√Hz | Rydberg sensor |
| Timestamp Resolution | <1 ns | White Rabbit sync |
| Processing Latency | <100 ms | Target-to-track |
| Simultaneous Tracks | 50+ | IMM filter |

---

## 💰 Budget Estimate (Phase I Prototype)

| Item | Cost |
|------|------|
| Rx Quantum Node (×2) | €329,000 |
| Tx Illuminator | €60,000 |
| C2 Fusion Server | €25,000 |
| Field Testing | €50,000 |
| R&D Labor (12 mo) | €288,000 |
| **Total** | **€752,000** |

---

## 📋 CI/CD Pipeline

GitHub Actions automatically runs on every push:

1. **Lint** - Verilator `--lint-only` RTL check
2. **Simulation** - Cocotb tests with Verilator
3. **Synthesis Check** - Yosys open-source synth
4. **Driver Build** - CMake compilation

---

## 📚 Documentation

- [System Architecture v1.3](docs/QEDMMA_System_Architecture_v1.3.docx)
- [Technical Appendix](docs/QEDMMA_Technical_Appendix_v1.3.md)
- [BOM v1.3](docs/QEDMMA_BOM_v1.3.xlsx)
- [Architecture Diagrams](docs/QEDMMA_Architecture_Diagrams.md)

---

## 👤 Author

**Dr. Mladen Mešter**  
Zagreb, Croatia

---

## ⚠️ Export Control Notice

This technology may be subject to export control regulations. Contact the author before sharing outside authorized channels.

---

## 📄 License

Proprietary - All Rights Reserved  
© 2026 Dr. Mladen Mešter

---

*QEDMMA Radar System v1.3*  
*January 2026*
