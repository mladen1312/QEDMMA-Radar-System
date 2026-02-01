# QEDMMA v2.0 Multi-Sensor Fusion Subsystem

## Overview

The Multi-Sensor Fusion subsystem enables QEDMMA to integrate data from **any external sensor** to enhance situational awareness and targeting capability. This is a key competitive differentiator.

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    FUSION SUBSYSTEM                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌───────────┐  ┌───────────┐  ┌───────────┐  ┌───────────┐   │
│  │  Link 16  │  │  ASTERIX  │  │   IRST    │  │   ESM     │   │
│  │  Adapter  │  │  Parser   │  │  Adapter  │  │  Adapter  │   │
│  └─────┬─────┘  └─────┬─────┘  └─────┬─────┘  └─────┬─────┘   │
│        │              │              │              │          │
│        └──────────────┴──────┬───────┴──────────────┘          │
│                              │                                  │
│                    ┌─────────┴─────────┐                       │
│                    │  TRACK ADAPTER    │                       │
│                    │  (Unified Format) │                       │
│                    └─────────┬─────────┘                       │
│                              │                                  │
│                    ┌─────────┴─────────┐                       │
│                    │  FUSION ENGINE    │                       │
│                    │  • Association    │                       │
│                    │  • Covariance CI  │                       │
│                    │  • IMM Tracking   │                       │
│                    └─────────┬─────────┘                       │
│                              │                                  │
│                    ┌─────────┴─────────┐                       │
│                    │  TRACK DATABASE   │                       │
│                    │  (1024 tracks)    │                       │
│                    └─────────┬─────────┘                       │
│                              │                                  │
│                    ┌─────────┴─────────┐                       │
│                    │  OUTPUT MUX       │                       │
│                    │  • Link 16 TX     │                       │
│                    │  • C2 Interface   │                       │
│                    │  • Weapon Cueing  │                       │
│                    └───────────────────┘                       │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

## Supported Interfaces

| Interface | Standard | Direction | Data Rate |
|-----------|----------|-----------|-----------|
| Link 16 | STANAG 5516 / JREAP-C | RX/TX | 115.2 kbps |
| ASTERIX CAT048 | EUROCONTROL | RX | Variable |
| IRST | Custom (angle-only) | RX | 10 Hz |
| ESM/ELINT | Custom (AOA/freq) | RX | Variable |
| ADS-B | Mode-S ES | RX | 1090 MHz |
| Generic Radar | UDP | RX | Variable |

## Key Algorithms

### Track-to-Track Association
- **Method:** Global Nearest Neighbor (GNN) with Mahalanobis distance
- **Threshold:** Configurable (default: d² < 1000)
- **Fallback:** Multi-Hypothesis Tracking (MHT)

### State Fusion
- **Method:** Covariance Intersection (CI)
- **Formula:** P_fused = (P₁ × P₂) / (P₁ + P₂)
- **Benefit:** Optimal fusion without cross-correlation knowledge

### Track Management
- **Initiation:** 2-of-3 detections
- **Deletion:** Timeout (default 30s) or manual
- **Update:** Kalman filter with IMM

## RTL Modules

| Module | Lines | Description |
|--------|-------|-------------|
| `external_track_adapter.sv` | 403 | Universal input adapter |
| `track_fusion_engine.sv` | 549 | Main fusion logic |
| `track_database.sv` | 357 | BRAM track storage |
| `link16_interface.sv` | 461 | Link 16 RX/TX |
| `asterix_parser.sv` | 506 | ASTERIX CAT048 decoder |

## Register Map

Base address: `0x00020000`

| Offset | Name | Access | Description |
|--------|------|--------|-------------|
| 0x0000 | CTRL | RW | Enable bits for each adapter |
| 0x0004 | STATUS | RO | Active tracks, busy, errors |
| 0x0008 | ASSOC_CFG | RW | Association threshold |
| 0x000C | TIMEOUT_CFG | RW | Track timeout (ms) |
| 0x0010 | LINK16_CFG | RW | STN, exercise indicator |
| 0x0020 | ASTERIX_CFG | RW | SAC/SIC filter |
| 0x0030 | ORIGIN_LAT | RW | WGS84 origin |
| 0x0040 | FUSIONS_PERFORMED | RO | Statistics |

See `fusion_engine_regs.yaml` for complete SSOT.

## Performance

| Metric | Target | Achieved |
|--------|--------|----------|
| Association latency | <10 ms | <100 µs |
| Tracks capacity | 1024 | 1024 |
| Fusion rate | 100 Hz | 1000 Hz |
| Link 16 encode/decode | <20 ms | <5 ms |

## Testing

```bash
cd tb
make -f Makefile.fusion
```

Test cases:
- TC-001: Single source track creation
- TC-002: Track-to-track association
- TC-003: Covariance intersection verification
- TC-005: Multi-source fusion
- TC-007: Latency verification

## Competitive Advantage

**QEDMMA is the ONLY anti-stealth radar with open fusion architecture.**

| Competitor | Fusion Capability |
|------------|-------------------|
| JY-27V (China) | Proprietary, closed |
| Surya (India) | Limited integration |
| Rezonans-NE (Russia) | Fixed protocols |
| **QEDMMA** | **Universal, open** |

This allows NATO customers to leverage existing infrastructure investments.

---

*Document Control: QEDMMA-FUSION-README-001*
