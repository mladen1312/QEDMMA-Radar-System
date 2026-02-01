# Changelog

All notable changes to QEDMMA Radar System will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.1.0] - 2026-01-31

### Added
- **ECCM Subsystem** (1,750 lines RTL)
  - `ml_cfar_engine.sv` - ML-assisted CFAR with jammer/clutter classification
  - `integration_controller.sv` - Adaptive coherent integration (10/20/50 pulses)
  - `jammer_localizer.sv` - TDOA-based Home-on-Jam capability
  - `eccm_controller.sv` - Top-level ECCM orchestrator with AXI-Lite interface
- ECCM register map at base address 0x00030000
- Comprehensive ECCM architecture documentation

### Changed
- Fusion engine now outputs to ECCM controller
- Updated competitive analysis with 2024-2025 anti-stealth systems

### Performance
- +7 dB ECCM gain against 50 kW jammer
- Transforms MARGINAL detection to CONFIRMED detection

## [2.0.0] - 2026-01-31

### Added
- **Multi-Sensor Fusion Subsystem** (2,276 lines RTL)
  - `external_track_adapter.sv` - Universal adapter for 6+ external formats
  - `track_fusion_engine.sv` - GNN association + Covariance Intersection
  - `track_database.sv` - 1024-track BRAM storage
  - `link16_interface.sv` - STANAG 5516 / JREAP-C encode/decode
  - `asterix_parser.sv` - EUROCONTROL CAT048 parser
- Fusion engine register map (YAML SSOT)
- Competitive analysis document (vs. JY-27V, Surya, Rezonans-NE)
- Complete fusion architecture specification

### Added (Communications)
- **Tri-Modal Communications**
  - `comm_controller_top.sv` - Top-level with auto-failover
  - `failover_fsm.sv` - N+2 redundancy state machine
  - `link_monitor.sv` - Health monitoring and quality metrics
- Satellite, LoS RF, and HF fallback modes
- 99.999% uplink availability target

### Added (Core)
- `timestamp_capture.sv` - Sub-100ps TDOA precision
- Register map generator (`gen_regs.py`)
- Cocotb testbenches for all major modules

### Changed
- Restructured repository for v2 development
- SSOT register definitions in YAML format

## [1.0.0] - 2026-01-15

### Added
- Initial QEDMMA system architecture
- Basic RTL modules (DDC, NCO, matched filter)
- Link budget calculations
- System specification documents

---

## Roadmap

### [2.2.0] - Planned Q2 2026
- Deception rejection filter (RGPO/VGPO/DRFM)
- Space track integration (TLE/SP)
- Hardware-in-loop testing

### [3.0.0] - Planned Q4 2026
- 200 Mchip/s PRBS waveform
- 800 km detection range
- Quantum noise model
- Fixed-point twin validation
