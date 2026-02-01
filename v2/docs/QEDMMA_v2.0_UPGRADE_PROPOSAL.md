# 🎯 QEDMMA v2.0 - ENHANCED RESILIENT ARCHITECTURE
## Upgrade Proposal: Extended Range, Redundancy & Secure Communications

**Author:** Dr. Mladen Mešter  
**Date:** January 31, 2026  
**Classification:** PROPRIETARY

---

# 1. EXECUTIVE SUMMARY

## Upgrade Goals

| Goal | v1.3 | v2.0 Target | Improvement |
|------|------|-------------|-------------|
| Detection Range | 150 km | **300+ km** | 2× |
| Communication | None | **Tri-modal** | ∞ |
| Redundancy | 0% | **N+2** | Full |
| Anti-Jam | None | **LPI/LPD** | Military-grade |
| Graceful Degradation | No | **Yes** | Survivable |

---

# 2. RANGE EXTENSION ANALYSIS

## 2.1 Current Limitation

From radar range equation, range scales as:
$$R \propto \sqrt[4]{P_t \cdot G_t \cdot G_r \cdot T_{int}}$$

To **double range** (150 → 300 km), we need **16× improvement** in link budget.

## 2.2 Proposed Improvements

| Parameter | v1.3 | v2.0 | Gain |
|-----------|------|------|------|
| Tx Power | 5 kW | 25 kW | +7 dB |
| Tx Antenna | 10 dBi | 15 dBi | +5 dB |
| Rx Antenna | 10 dBi | 13 dBi | +3 dB |
| Integration Time | 10 s | 30 s | +4.8 dB |
| Rydberg Gen-2 | 500 nV/m/√Hz | 200 nV/m/√Hz | +8 dB |
| **Total Gain** | | | **+27.8 dB** |

**Result:** 27.8 dB gain → **4.3× range increase** → **650 km theoretical**

## 2.3 Practical Range Budget (v2.0)

```
TRANSMITTER (Enhanced):
  Tx Power:              +44 dBm (25 kW)
  Tx Antenna Gain:       +15 dBi (2×2m phased array)
  EIRP:                  +59 dBm (800 kW equivalent)

RECEIVER (Rydberg Gen-2):
  Rx Antenna Gain:       +13 dBi (1.5×1.5m metamaterial)
  Rydberg Sensitivity:   200 nV/m/√Hz (-198 dBm/Hz)
  Noise Floor (100 MHz): -118 dBm

PATH (300 km each leg):
  Tx→Target (300 km):    -126 dB
  Target→Rx (300 km):    -126 dB
  Atmospheric (VHF):     -1 dB
  System Losses:         -6 dB

TARGET:
  Bistatic RCS (F-22):   +3 dBsm (β=120°)

LINK BUDGET:
  Pr = 59 + 13 + 3 - 126 - 126 - 1 - 6 - 11 = -195 dBm

SNR CALCULATION:
  Pre-integration SNR:   -195 - (-118) = -77 dB
  Integration (30s):     +95 dB
  Post-integration SNR:  +18 dB ✓ DETECTABLE @ 300 km

MAXIMUM RANGE (SNR=13 dB):
  Available margin:      +5 dB → R_max ≈ 380 km
```

---

# 3. RESILIENT COMMUNICATION ARCHITECTURE

## 3.1 Tri-Modal Communication System

```
┌─────────────────────────────────────────────────────────────────┐
│                    QEDMMA NODE COMMUNICATION                     │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐         │
│  │   PRIMARY   │    │  SECONDARY  │    │  TERTIARY   │         │
│  │             │    │             │    │             │         │
│  │  FREE-SPACE │    │  E-BAND     │    │  HF NVIS    │         │
│  │  OPTICAL    │    │  MICROWAVE  │    │  SKYWAVE    │         │
│  │  (FSO)      │    │  (71-86GHz) │    │  (3-10MHz)  │         │
│  └──────┬──────┘    └──────┬──────┘    └──────┬──────┘         │
│         │                  │                  │                 │
│         ▼                  ▼                  ▼                 │
│  ┌─────────────────────────────────────────────────────┐       │
│  │              COMMUNICATION CONTROLLER               │       │
│  │  • Automatic failover (FSO→E-band→HF)              │       │
│  │  • Link quality monitoring                          │       │
│  │  │  • Encryption (AES-256-GCM)                        │       │
│  │  • Anti-jam: FHSS + DSSS                            │       │
│  └─────────────────────────────────────────────────────┘       │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## 3.2 Primary: Free-Space Optical (FSO)

### Specifications

| Parameter | Value | Notes |
|-----------|-------|-------|
| Wavelength | 1550 nm | Eye-safe, low absorption |
| Data Rate | 10 Gbps | Full I/Q streaming |
| Range | 20-50 km | Node-to-node |
| Beam Divergence | 0.5 mrad | Narrow, LPI |
| Tx Power | 200 mW | Class 1M safe |
| Rx Aperture | 100 mm | Avalanche photodiode |
| Tracking | 2-axis gimbal | ±30° azimuth, ±15° elevation |

### Advantages
- **LPI/LPD**: Narrow beam nearly impossible to intercept
- **No RF signature**: Invisible to electronic warfare
- **High bandwidth**: Supports raw I/Q data
- **Immune to RF jamming**: Different spectrum

### Limitations
- **Weather dependent**: Fog, rain, snow degrade link
- **Line-of-sight required**: No terrain penetration
- **Acquisition time**: Needs initial alignment

### Hardware
- **Tx**: IPG Photonics YLPM-10-1550 fiber laser
- **Rx**: Hamamatsu G8931-20 InGaAs APD
- **Gimbal**: FLIR PTU-D48E precision positioner
- **Controller**: Xilinx ZU+ with optical PHY

## 3.3 Secondary: E-Band Microwave (71-86 GHz)

### Specifications

| Parameter | Value | Notes |
|-----------|-------|-------|
| Frequency | 71-76 / 81-86 GHz | Licensed E-band |
| Bandwidth | 2×5 GHz | 10 Gbps capacity |
| Data Rate | 10 Gbps | Full-duplex |
| Range | 5-15 km | Weather dependent |
| Antenna | 0.6m dish | 50 dBi gain |
| Tx Power | +23 dBm | 200 mW |
| Modulation | 256-QAM | Adaptive |

### Advantages
- **All-weather**: Works in fog (unlike FSO)
- **High capacity**: Multi-gigabit rates
- **Narrow beam**: 0.3° beamwidth = hard to jam
- **Mature technology**: Commercial availability

### Limitations
- **Rain fade**: 10-30 dB/km in heavy rain
- **Oxygen absorption**: 15 dB/km @ 60 GHz (not E-band)
- **Shorter range than FSO**: In clear weather

### Hardware
- **Transceiver**: Siklu EH-8010FX (10 Gbps E-band)
- **Antenna**: 0.6m integrated dish
- **Modem**: Built-in adaptive modulation

## 3.4 Tertiary: HF NVIS (Near Vertical Incidence Skywave)

### Specifications

| Parameter | Value | Notes |
|-----------|-------|-------|
| Frequency | 3-10 MHz | Ionospheric reflection |
| Bandwidth | 3 kHz (SSB) | Limited data rate |
| Data Rate | 9.6 kbps (MIL-STD-188-110D) | HF modem |
| Range | 0-500 km | NVIS propagation |
| Antenna | NVIS dipole | Near-horizontal |
| Tx Power | 100 W PEP | |
| ALE | MIL-STD-188-141C | Auto link establishment |

### Advantages
- **Beyond line-of-sight**: Ionospheric skip
- **No infrastructure**: Peer-to-peer
- **Survivable**: Hard to destroy ionosphere
- **Anti-jam**: Frequency hopping (ALE 3G)

### Limitations
- **Low bandwidth**: Only control/status data
- **Propagation varies**: Day/night, solar activity
- **Long acquisition**: ALE handshake ~10s

### Use Cases
- Emergency command & control
- Node status/heartbeat
- Minimal TDOA data (compressed)
- System reconfiguration commands

### Hardware
- **Transceiver**: Harris Falcon III RF-7800H
- **Modem**: Harris RF-5710A (MIL-STD-188-110D)
- **Antenna**: AS-2259/GR NVIS antenna
- **Controller**: Embedded Linux + serial interface

---

# 4. NETWORK TOPOLOGY & REDUNDANCY

## 4.1 Mesh Network Architecture

```
                          ┌─────────┐
                          │   C2    │
                          │ FUSION  │
                          │ SERVER  │
                          └────┬────┘
                               │
          ┌────────────────────┼────────────────────┐
          │                    │                    │
     ┌────┴────┐          ┌────┴────┐          ┌────┴────┐
     │  NODE   │◄────────►│  NODE   │◄────────►│  NODE   │
     │   A     │   FSO    │   B     │   FSO    │   C     │
     │  (Tx)   │          │  (Rx)   │          │  (Rx)   │
     └────┬────┘          └────┬────┘          └────┬────┘
          │                    │                    │
          │      E-band        │      E-band        │
          └────────────────────┴────────────────────┘
                               │
                          HF NVIS (backup)
                               │
     ┌─────────┐          ┌────┴────┐          ┌─────────┐
     │  NODE   │◄────────►│  NODE   │◄────────►│  NODE   │
     │   D     │   FSO    │   E     │   FSO    │   F     │
     │  (Rx)   │          │  (Tx)   │          │  (Rx)   │
     └─────────┘          └─────────┘          └─────────┘
```

## 4.2 Redundancy Levels

| Component | Redundancy | Failover Time |
|-----------|------------|---------------|
| Tx Illuminator | N+1 (2 Tx nodes) | 0 ms (simultaneous) |
| Rx Sensor | N+2 (6 Rx, need 4) | 0 ms (continuous) |
| FSO Link | N+1 per link | <100 ms |
| E-band Link | N+1 per link | <500 ms |
| HF Link | 1 per node | <30 s |
| Fusion Server | 2× hot standby | <1 s |
| Power | UPS + Generator | 0 ms / 30 s |
| Clock | WR + CSAC + GPS | 0 ms cascade |

## 4.3 Graceful Degradation Matrix

| Nodes Lost | Capability | TDOA Accuracy | Range |
|------------|------------|---------------|-------|
| 0 | 100% | <500 m | 300 km |
| 1 Rx | 90% | <600 m | 300 km |
| 2 Rx | 75% | <800 m | 300 km |
| 1 Tx | 50% | <1000 m | 200 km |
| 3 Rx | 40% (2D only) | <2000 m | 300 km |
| Both Tx | 0% (passive only) | N/A | N/A |

---

# 5. ANTI-JAM & ELECTRONIC PROTECTION

## 5.1 Communication Protection

### FSO (Inherent LPI)
- Beam divergence: 0.5 mrad → 50m spot @ 100km
- Interception requires being in beam path
- No RF emissions to detect

### E-band Protection
- **FHSS**: 500 hops/second across 10 GHz
- **DSSS**: 100 Mchip/s spreading
- **Adaptive power**: +20 dB margin
- **Null steering**: Antenna pattern control

### HF Protection
- **ALE 3G**: MIL-STD-188-141C hopping
- **ECCM**: Burst transmission <100 ms
- **Backup frequencies**: 10 pre-programmed channels

## 5.2 Radar Protection

### Tx Waveform Diversity
- **LFM chirp**: Standard detection
- **PRBS spreading**: Low probability of intercept
- **Noise radar**: Truly random waveform
- **Frequency agility**: Pulse-to-pulse hopping

### Rx Hardening
- **Rydberg advantage**: Inherently wideband, hard to saturate
- **Spatial filtering**: Digital beamforming nulls
- **Temporal blanking**: Excise known jamming
- **Multi-baseline**: Jammer localization via TDOA

---

# 6. UPGRADED SYSTEM ARCHITECTURE

## 6.1 Node Block Diagram (v2.0)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         QEDMMA v2.0 RX NODE                                 │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────────────────────┐  │
│  │   RYDBERG    │    │   TIMING     │    │      COMMUNICATION           │  │
│  │   SENSOR     │    │   SYSTEM     │    │         SUITE                │  │
│  │   (Gen-2)    │    │              │    │                              │  │
│  │              │    │ ┌──────────┐ │    │  ┌─────┐ ┌─────┐ ┌─────┐    │  │
│  │ • 200 nV/m   │    │ │White     │ │    │  │ FSO │ │E-bnd│ │ HF  │    │  │
│  │ • 100 MHz BW │    │ │Rabbit    │ │    │  │10Gb │ │10Gb │ │9.6kb│    │  │
│  │ • 150 MHz    │    │ └────┬─────┘ │    │  └──┬──┘ └──┬──┘ └──┬──┘    │  │
│  └──────┬───────┘    │      │       │    │     │       │       │        │  │
│         │            │ ┌────┴─────┐ │    │     └───────┴───────┘        │  │
│         │            │ │  CSAC    │ │    │             │                │  │
│         │            │ │ (backup) │ │    │    ┌────────┴────────┐       │  │
│         │            │ └──────────┘ │    │    │   COMM SWITCH   │       │  │
│         │            └──────┬───────┘    │    │   (auto failover)│       │  │
│         │                   │            │    └────────┬────────┘       │  │
│         │                   │            └─────────────┼────────────────┘  │
│         ▼                   ▼                          │                   │
│  ┌──────────────────────────────────────────────────────────────────────┐  │
│  │                    PROCESSING UNIT (ZU47DR RFSoC)                    │  │
│  │                                                                      │  │
│  │  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐   │  │
│  │  │  ADC    │  │  DDC    │  │ CORREL  │  │  TDOA   │  │  IMM    │   │  │
│  │  │ 5 GSPS  │─►│  Core   │─►│  FFT    │─►│ Solver  │─►│ Tracker │   │  │
│  │  └─────────┘  └─────────┘  └─────────┘  └─────────┘  └─────────┘   │  │
│  │       │                                                     │       │  │
│  │       │           ┌─────────────────────────────┐          │       │  │
│  │       └──────────►│    EMBEDDED LINUX (PS)      │◄─────────┘       │  │
│  │                   │  • Node management          │                   │  │
│  │                   │  • Comm stack               │                   │  │
│  │                   │  • Crypto (AES-256)         │                   │  │
│  │                   │  • Health monitoring        │                   │  │
│  │                   └─────────────────────────────┘                   │  │
│  └──────────────────────────────────────────────────────────────────────┘  │
│                                                                             │
│  ┌──────────────────────────────────────────────────────────────────────┐  │
│  │                         POWER SYSTEM                                 │  │
│  │  • Primary: 48 VDC (solar/grid)                                      │  │
│  │  • UPS: LiFePO4 10 kWh (4h backup)                                   │  │
│  │  • Generator: 5 kW diesel (auto-start)                               │  │
│  └──────────────────────────────────────────────────────────────────────┘  │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

## 6.2 Communication Protocol Stack

```
┌────────────────────────────────────────────────┐
│ Layer 7: Application                           │
│   • TDOA data exchange                         │
│   • Track reports                              │
│   • System commands                            │
├────────────────────────────────────────────────┤
│ Layer 6: Presentation                          │
│   • Protocol Buffers (efficient serialization) │
│   • Compression (LZ4)                          │
├────────────────────────────────────────────────┤
│ Layer 5: Session                               │
│   • TLS 1.3 (mutual authentication)            │
│   • Session key rotation (hourly)              │
├────────────────────────────────────────────────┤
│ Layer 4: Transport                             │
│   • QUIC (low-latency, reliable)               │
│   • UDP multicast (broadcast)                  │
├────────────────────────────────────────────────┤
│ Layer 3: Network                               │
│   • IPv6 mesh routing                          │
│   • OSPF-like link state                       │
├────────────────────────────────────────────────┤
│ Layer 2: Data Link                             │
│   • FSO: Custom framing (10 Gbps)              │
│   • E-band: Ethernet (10 GbE)                  │
│   • HF: MIL-STD-188-110D                       │
├────────────────────────────────────────────────┤
│ Layer 1: Physical                              │
│   • FSO: 1550 nm laser                         │
│   • E-band: 71-86 GHz                          │
│   • HF: 3-10 MHz                               │
└────────────────────────────────────────────────┘
```

---

# 7. BILL OF MATERIALS DELTA (v2.0 vs v1.3)

## 7.1 New Components per Node

| Component | Qty | Unit Cost | Total | Supplier |
|-----------|-----|-----------|-------|----------|
| **FSO Terminal** | | | | |
| IPG YLPM-10 Laser | 1 | €8,000 | €8,000 | IPG Photonics |
| Hamamatsu APD | 1 | €2,500 | €2,500 | Hamamatsu |
| FLIR PTU-D48E Gimbal | 1 | €12,000 | €12,000 | FLIR |
| FSO Controller Board | 1 | €3,000 | €3,000 | Custom |
| **Subtotal FSO** | | | **€25,500** | |
| | | | | |
| **E-band Terminal** | | | | |
| Siklu EH-8010FX | 1 | €15,000 | €15,000 | Siklu |
| 0.6m Dish Antenna | 1 | €2,000 | €2,000 | Siklu |
| **Subtotal E-band** | | | **€17,000** | |
| | | | | |
| **HF System** | | | | |
| Harris RF-7800H | 1 | €25,000 | €25,000 | L3Harris |
| RF-5710A Modem | 1 | €8,000 | €8,000 | L3Harris |
| AS-2259 NVIS Antenna | 1 | €1,500 | €1,500 | Military surplus |
| **Subtotal HF** | | | **€34,500** | |
| | | | | |
| **Tx Upgrade (25 kW)** | | | | |
| 25 kW Solid-State PA | 1 | €45,000 | €45,000 | Prana GN |
| 2×2m Phased Array | 1 | €35,000 | €35,000 | Custom |
| **Subtotal Tx** | | | **€80,000** | |
| | | | | |
| **Rydberg Gen-2 Sensor** | | | | |
| Enhanced vapor cell | 1 | €15,000 | €15,000 | ColdQuanta |
| Narrow-line lasers | 2 | €12,000 | €24,000 | Toptica |
| **Subtotal Rydberg** | | | **€39,000** | |
| | | | | |
| **Power System** | | | | |
| LiFePO4 10 kWh | 1 | €8,000 | €8,000 | SimpliPhi |
| 5 kW Diesel Gen | 1 | €5,000 | €5,000 | Kubota |
| **Subtotal Power** | | | **€13,000** | |

## 7.2 Cost Summary

| Configuration | v1.3 Cost | v2.0 Delta | v2.0 Total |
|---------------|-----------|------------|------------|
| Rx Node | €164,500 | +€129,000 | €293,500 |
| Tx Node | €225,000 | +€80,000 | €305,000 |
| 4-Node System | €658,000 | +€516,000 | €1,174,000 |
| 6-Node System (N+2) | €987,000 | +€774,000 | €1,761,000 |

---

# 8. IMPLEMENTATION ROADMAP

## Phase 1: Communication Subsystem (3 months)
- [ ] FSO terminal design & prototyping
- [ ] E-band integration
- [ ] HF modem integration
- [ ] Comm controller firmware
- [ ] Failover testing

## Phase 2: Range Extension (3 months)
- [ ] 25 kW PA procurement
- [ ] Phased array design
- [ ] Rydberg Gen-2 integration
- [ ] Link budget validation

## Phase 3: Network Integration (2 months)
- [ ] Mesh routing implementation
- [ ] Encryption integration
- [ ] Multi-node testing
- [ ] Redundancy validation

## Phase 4: Field Testing (4 months)
- [ ] Jamming resistance tests
- [ ] Weather effects characterization
- [ ] Extended range validation
- [ ] Graceful degradation verification

---

# 9. SUMMARY

## Key Upgrades v1.3 → v2.0

| Feature | v1.3 | v2.0 |
|---------|------|------|
| Detection Range | 150 km | **300+ km** |
| Tx Power | 5 kW | **25 kW** |
| Rydberg Sensitivity | 500 nV/m/√Hz | **200 nV/m/√Hz** |
| Primary Comm | None | **FSO 10 Gbps** |
| Secondary Comm | None | **E-band 10 Gbps** |
| Backup Comm | None | **HF NVIS 9.6 kbps** |
| Redundancy | None | **N+2** |
| Anti-Jam | None | **FHSS/DSSS/LPI** |
| Graceful Degradation | No | **Yes** |
| Cost (6-node) | €987k | **€1,761k** |

**ROI**: 2× range, full redundancy, military-grade resilience for 78% cost increase.

---

**© 2026 Dr. Mladen Mešter - All Rights Reserved**
