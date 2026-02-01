# QEDMMA v2.0 Multi-Sensor Fusion Architecture
## Open Integration Platform for Universal Sensor Data

**Author:** Dr. Mladen Mešter  
**Version:** 2.0  
**Date:** 31. January 2026  
**Classification:** PROPRIETARY

---

## 1. Architecture Overview

QEDMMA v2.0 implementira **JDL Data Fusion Model** s potpunom podrškom za integraciju vanjskih senzora.

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                       QEDMMA FUSION ARCHITECTURE                            │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │
│  │   QEDMMA    │  │  External   │  │   IRST/EO   │  │  ESM/ELINT  │        │
│  │   Rydberg   │  │   Radars    │  │   Sensors   │  │   Sensors   │        │
│  │   Nodes     │  │  (ASTERIX)  │  │ (Angle-only)│  │ (AOA/TDOA)  │        │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘        │
│         │                │                │                │               │
│  ┌──────┴────────────────┴────────────────┴────────────────┴──────┐        │
│  │                    LEVEL 0: SOURCE PREPROCESSING                │        │
│  │  • Coordinate transformation (WGS84, ECEF, ENU)                │        │
│  │  • Time alignment (UTC, GPS time)                              │        │
│  │  • Format conversion (ASTERIX → internal)                      │        │
│  └────────────────────────────────┬───────────────────────────────┘        │
│                                   │                                        │
│  ┌────────────────────────────────┴───────────────────────────────┐        │
│  │                    LEVEL 1: OBJECT ASSESSMENT                   │        │
│  │  • Track-to-Track Association (GNN, MHT)                       │        │
│  │  • State Estimation (IMM-EKF)                                  │        │
│  │  • Track fusion (Covariance Intersection)                      │        │
│  └────────────────────────────────┬───────────────────────────────┘        │
│                                   │                                        │
│  ┌────────────────────────────────┴───────────────────────────────┐        │
│  │                    LEVEL 2: SITUATION ASSESSMENT                │        │
│  │  • Formation detection                                         │        │
│  │  • Threat correlation                                          │        │
│  │  • Pattern recognition (ML-based)                              │        │
│  └────────────────────────────────┬───────────────────────────────┘        │
│                                   │                                        │
│  ┌────────────────────────────────┴───────────────────────────────┐        │
│  │                    LEVEL 3: THREAT ASSESSMENT                   │        │
│  │  • Intent estimation                                           │        │
│  │  • Vulnerability analysis                                      │        │
│  │  • Kill chain integration                                      │        │
│  └────────────────────────────────┬───────────────────────────────┘        │
│                                   │                                        │
│  ┌────────────────────────────────┴───────────────────────────────┐        │
│  │                         FUSED OUTPUT                            │        │
│  │  • Link 16 J-series messages                                   │        │
│  │  • Weapon cueing data                                          │        │
│  │  • C2 integration (NATO formats)                               │        │
│  └────────────────────────────────────────────────────────────────┘        │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Supported External Interfaces

### 2.1 Tactical Data Links

| Interface | Standard | Data Rate | Content |
|-----------|----------|-----------|---------|
| **Link 16** | STANAG 5516 / MIL-STD-6016 | 31.6-115.2 kbps | J-series messages |
| **Link 22** | STANAG 5522 | 3.2 kbps | NATO tracks |
| **Link 11** | STANAG 5511 | 1.8-2.25 kbps | Legacy tracks |
| **VMF** | MIL-STD-2045-47001 | Variable | Ground forces |
| **JREAP-C** | MIL-STD-3011 | IP-based | Link 16 over TCP/IP |

### 2.2 Radar Data Exchange

| Interface | Standard | Format | Use Case |
|-----------|----------|--------|----------|
| **ASTERIX** | EUROCONTROL | CAT 001/002/034/048 | Civil/Military radar |
| **SAPIENT** | DSTL | JSON/Protobuf | UK sensor network |
| **NMEA** | IEC 61162 | ASCII | Marine radar |
| **Custom UDP** | Proprietary | Configurable | OEM radar integration |

### 2.3 Passive Sensor Data

| Sensor Type | Interface | Data Format | QEDMMA Fusion |
|-------------|-----------|-------------|---------------|
| **IRST** | RS-422 / Ethernet | Az/El/Time | Angle-only triangulation |
| **ESM/ELINT** | Ethernet | AOA/Freq/PRI | Emitter correlation |
| **Acoustic** | AES/EBU | Bearing/Time | Ground target cueing |
| **Seismic** | SEED | Vibration data | Vehicle detection |

### 2.4 Space Situational Awareness

| Source | Interface | Data | Update Rate |
|--------|-----------|------|-------------|
| **TLE (NORAD)** | HTTP/FTP | Orbital elements | Daily |
| **SP (Space-Track)** | REST API | Precision ephemeris | Hourly |
| **CCSDS** | TCP/IP | Real-time tracks | Real-time |

### 2.5 Civil Aviation

| Source | Interface | Data | Coverage |
|--------|-----------|------|----------|
| **ADS-B** | 1090 MHz Mode-S | Position/velocity/ID | Line-of-sight |
| **MLAT** | Distributed Rx | Multilateration | Regional |
| **Flight radar** | API | Global tracks | Global |

---

## 3. Track Fusion Algorithm

### 3.1 Track-to-Track Association

QEDMMA koristi **Global Nearest Neighbor (GNN)** s **Multi-Hypothesis Tracking (MHT)** fallback:

```
Algorithm: GNN Track Association
Input: Local tracks T_local, External tracks T_ext
Output: Association matrix A

1. FOR each t_local in T_local:
2.   FOR each t_ext in T_ext:
3.     d = Mahalanobis_distance(t_local, t_ext)
4.     IF d < threshold:
5.       Add (t_local, t_ext, d) to candidates
6. A = Hungarian_algorithm(candidates)
7. RETURN A
```

**Mahalanobis Distance:**

$$d_M = \sqrt{(\mathbf{x}_1 - \mathbf{x}_2)^T \mathbf{S}^{-1} (\mathbf{x}_1 - \mathbf{x}_2)}$$

gdje je $\mathbf{S} = \mathbf{P}_1 + \mathbf{P}_2$ kombinirana kovarijanca.

### 3.2 State Fusion (Covariance Intersection)

Za fuziju dva tracka s kovarijancama $\mathbf{P}_1, \mathbf{P}_2$:

$$\mathbf{P}_{fused}^{-1} = \omega \mathbf{P}_1^{-1} + (1-\omega) \mathbf{P}_2^{-1}$$

$$\mathbf{x}_{fused} = \mathbf{P}_{fused} \left[ \omega \mathbf{P}_1^{-1} \mathbf{x}_1 + (1-\omega) \mathbf{P}_2^{-1} \mathbf{x}_2 \right]$$

gdje je $\omega \in [0,1]$ optimiziran da minimizira $\det(\mathbf{P}_{fused})$.

### 3.3 IMM Filter for Maneuvering Targets

QEDMMA koristi **Interacting Multiple Model (IMM)** filter s 3 modela:
- **CV (Constant Velocity)** - straight flight
- **CT (Coordinated Turn)** - maneuvering
- **CA (Constant Acceleration)** - aggressive maneuver

```
IMM Cycle:
1. Model interaction (mixing)
2. Per-model Kalman filtering
3. Model probability update
4. State combination
```

---

## 4. Data Flow Architecture

### 4.1 Input Adapters

Svaki vanjski izvor ima dedicirani adapter koji normalizira podatke:

```
┌─────────────────────────────────────────────────────────────────┐
│                     INPUT ADAPTER LAYER                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌───────────┐  ┌───────────┐  ┌───────────┐  ┌───────────┐   │
│  │ Link 16   │  │  ASTERIX  │  │   IRST    │  │   ESM     │   │
│  │ Adapter   │  │  Adapter  │  │  Adapter  │  │  Adapter  │   │
│  │           │  │           │  │           │  │           │   │
│  │ J-series  │  │ CAT048    │  │ Az/El     │  │ AOA/Freq  │   │
│  │ decode    │  │ decode    │  │ normalize │  │ correlate │   │
│  └─────┬─────┘  └─────┬─────┘  └─────┬─────┘  └─────┬─────┘   │
│        │              │              │              │          │
│        └──────────────┴──────────────┴──────────────┘          │
│                              │                                  │
│                    ┌─────────┴─────────┐                       │
│                    │ UNIFIED TRACK BUS │                       │
│                    │ (Internal format) │                       │
│                    └───────────────────┘                       │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 4.2 Unified Track Format

```c
typedef struct {
    // Identity
    uint32_t track_id;           // Unique fused track ID
    uint32_t source_bitmap;      // Which sensors contributed
    uint8_t  classification;     // Aircraft type (NATO STANAG)
    uint8_t  iff_code;           // IFF Mode 1/2/3A/C/S
    
    // Kinematics (ENU coordinates, WGS84 origin)
    double   pos_east;           // meters
    double   pos_north;          // meters
    double   pos_up;             // meters (altitude)
    double   vel_east;           // m/s
    double   vel_north;          // m/s
    double   vel_up;             // m/s
    
    // Covariance (6x6 position/velocity)
    double   covariance[36];
    
    // Metadata
    uint64_t time_stamp;         // GPS microseconds
    uint32_t update_count;
    float    quality;            // 0-1 confidence
    
    // Source-specific
    float    rcs_estimate;       // dBsm (from QEDMMA)
    float    emitter_freq;       // MHz (from ESM)
    float    ir_intensity;       // W/sr (from IRST)
    
} fused_track_t;
```

---

## 5. External Interface Specifications

### 5.1 Link 16 Interface

**Supported J-series Messages:**

| Message | Description | Direction |
|---------|-------------|-----------|
| J2.0 | Indirect Track | Rx |
| J2.2 | Air Track | Rx/Tx |
| J2.3 | Surface Track | Rx |
| J2.5 | Space Track | Rx |
| J3.0 | Track Platform | Tx |
| J3.2 | Point Track | Tx |
| J3.5 | Track Management | Rx/Tx |
| J7.0 | Track Quality | Tx |
| J7.2 | Track Drop | Tx |
| J12.6 | Targeting Data | Tx |

**Implementation:**
- JREAP-C gateway (Link 16 over IP)
- SIMPLE (STANAG 5602) encapsulation
- Crypto: KG-175 TACLANE compatible

### 5.2 ASTERIX Interface

**Supported Categories:**

| CAT | Description | Use |
|-----|-------------|-----|
| 001 | Monoradar plot/track | Legacy radar |
| 002 | Monoradar service | Status |
| 034 | Transmission of status | Health |
| 048 | Monoradar target | Modern radar |
| 062 | Track data | Fused tracks |
| 065 | SDPS service | Messages |

**Parser:** Libasterix-compatible, FPGA-accelerated

### 5.3 IRST/EO Adapter

**Input Format:**
```
IRST_REPORT {
    timestamp:    uint64  // GPS microseconds
    azimuth:      float32 // degrees (0-360)
    elevation:    float32 // degrees (-90 to +90)
    az_sigma:     float32 // degrees (1-sigma)
    el_sigma:     float32 // degrees (1-sigma)
    intensity:    float32 // arbitrary units
    wavelength:   uint8   // 0=SWIR, 1=MWIR, 2=LWIR
    track_id:     uint32  // sensor-local ID
}
```

**Fusion:** Angle-only tracking s range estimation iz QEDMMA radar-a

### 5.4 ESM/ELINT Adapter

**Input Format:**
```
ESM_REPORT {
    timestamp:    uint64  // GPS microseconds
    frequency:    float64 // Hz
    bandwidth:    float32 // Hz
    pri:          float32 // Pulse repetition interval (s)
    pulse_width:  float32 // seconds
    aoa:          float32 // Angle of arrival (degrees)
    aoa_sigma:    float32 // degrees
    signal_type:  uint8   // CW, pulsed, etc.
    emitter_id:   uint32  // From ESM database
}
```

**Fusion:** Emitter-to-track correlation using spatial and temporal gating

### 5.5 ADS-B Receiver

**Input:** 1090 MHz Mode-S Extended Squitter

**Decoded Fields:**
- ICAO 24-bit address
- Position (CPR encoded)
- Altitude (barometric/geometric)
- Velocity (ground speed, track, vertical rate)
- Aircraft identification (callsign)
- Category (aircraft type)

**Use:** Civil traffic deconfliction, transponder correlation

---

## 6. Real-Time Performance Requirements

| Function | Latency | Throughput | Notes |
|----------|---------|------------|-------|
| Track association | <10 ms | 1000 tracks | Per fusion cycle |
| State fusion | <5 ms | 1000 tracks | Covariance intersection |
| Link 16 encode | <20 ms | 200 msg/s | J-series generation |
| ASTERIX decode | <2 ms | 500 plots/s | CAT048 parsing |
| Total pipeline | <50 ms | - | End-to-end |

---

## 7. Hardware Implementation

### 7.1 Fusion Engine (FPGA)

**Target:** ZU47DR RFSoC (shared with signal chain)

**Resource Allocation:**
- Track database: 1024 entries × 256 bytes = 256 KB BRAM
- Association matrix: 1024×1024 × 4 bytes = 4 MB (external DDR)
- Kalman filter: DSP48 blocks for matrix ops
- Adapters: Soft cores (MicroBlaze) for protocol handling

### 7.2 Block Diagram

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        FUSION ENGINE (ZU47DR)                           │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐                 │
│  │  Ethernet   │    │   Serial    │    │   RF/IF     │                 │
│  │  10GbE MAC  │    │  RS-422 ×4  │    │ (from DDC)  │                 │
│  └──────┬──────┘    └──────┬──────┘    └──────┬──────┘                 │
│         │                  │                  │                         │
│  ┌──────┴──────────────────┴──────────────────┴──────┐                 │
│  │              INPUT ADAPTER ARRAY                   │                 │
│  │  ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐     │                 │
│  │  │Link 16 │ │ASTERIX │ │  IRST  │ │  ESM   │     │                 │
│  │  └────────┘ └────────┘ └────────┘ └────────┘     │                 │
│  └────────────────────────┬──────────────────────────┘                 │
│                           │                                             │
│  ┌────────────────────────┴──────────────────────────┐                 │
│  │              TRACK DATABASE (BRAM)                 │                 │
│  │  • 1024 tracks × 256 bytes                        │                 │
│  │  • Dual-port access (read/write)                  │                 │
│  └────────────────────────┬──────────────────────────┘                 │
│                           │                                             │
│  ┌────────────────────────┴──────────────────────────┐                 │
│  │              ASSOCIATION ENGINE                    │                 │
│  │  • Mahalanobis distance (parallel)                │                 │
│  │  • Hungarian algorithm (sequential)               │                 │
│  │  • MHT hypothesis management                      │                 │
│  └────────────────────────┬──────────────────────────┘                 │
│                           │                                             │
│  ┌────────────────────────┴──────────────────────────┐                 │
│  │              FUSION CORE                           │                 │
│  │  • Covariance intersection                        │                 │
│  │  • IMM filter bank (3 models)                     │                 │
│  │  • Track quality estimation                       │                 │
│  └────────────────────────┬──────────────────────────┘                 │
│                           │                                             │
│  ┌────────────────────────┴──────────────────────────┐                 │
│  │              OUTPUT FORMATTER                      │                 │
│  │  • Link 16 J-series encoder                       │                 │
│  │  • ASTERIX CAT062 generator                       │                 │
│  │  • Weapon cueing interface                        │                 │
│  └───────────────────────────────────────────────────┘                 │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 8. Software Stack

### 8.1 Embedded Linux (PetaLinux)

**Components:**
- Kernel: Linux 5.15 LTS (Xilinx fork)
- Root filesystem: Yocto-based
- Device drivers: UIO for FPGA access
- Middleware: DDS (RTI Connext or eProsima Fast DDS)

### 8.2 Application Layer

```
┌─────────────────────────────────────────────────────┐
│                   APPLICATION LAYER                  │
├─────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐ │
│  │   Fusion    │  │   Track     │  │   C2        │ │
│  │   Manager   │  │   Database  │  │   Interface │ │
│  │   (Python)  │  │   (SQLite)  │  │   (gRPC)    │ │
│  └─────────────┘  └─────────────┘  └─────────────┘ │
│                                                     │
│  ┌─────────────────────────────────────────────────┐│
│  │          DDS Middleware (Fast DDS)              ││
│  └─────────────────────────────────────────────────┘│
│                                                     │
│  ┌─────────────────────────────────────────────────┐│
│  │          Linux Kernel + UIO Drivers             ││
│  └─────────────────────────────────────────────────┘│
│                                                     │
│  ┌─────────────────────────────────────────────────┐│
│  │          FPGA Fabric (Fusion Engine)            ││
│  └─────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────┘
```

---

## 9. Security Considerations

### 9.1 Data Classification

| Source | Classification | Handling |
|--------|---------------|----------|
| QEDMMA internal | SECRET | Encrypted storage |
| Link 16 | SECRET | KG-175 crypto |
| ASTERIX | UNCLASSIFIED | No encryption |
| ADS-B | PUBLIC | No encryption |

### 9.2 Crypto Implementation

- **Link 16:** Type 1 crypto (NSA approved)
- **Internal:** AES-256-GCM
- **Key management:** EKMS compatible

---

## 10. Integration Roadmap

### Phase 1: Core Fusion (Month 1-3)
- [ ] Track database RTL
- [ ] Association engine
- [ ] Covariance intersection
- [ ] Internal track format

### Phase 2: Link 16 Integration (Month 4-6)
- [ ] JREAP-C gateway
- [ ] J-series encoder/decoder
- [ ] Time synchronization

### Phase 3: Additional Adapters (Month 7-9)
- [ ] ASTERIX parser
- [ ] IRST interface
- [ ] ESM interface
- [ ] ADS-B receiver

### Phase 4: Testing & Certification (Month 10-12)
- [ ] NATO interoperability testing
- [ ] Link 16 certification
- [ ] Field trials

---

*Document Control: QEDMMA-FUSION-2026-001*
