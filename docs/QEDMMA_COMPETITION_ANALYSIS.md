# QEDMMA v2.0 - Konkurentska Analiza i Multi-Source Fusion Arhitektura

**Autor:** Dr. Mladen Mešter  
**Datum:** 31. siječnja 2026.  
**Verzija:** 1.0  
**Klasifikacija:** PROPRIETARY

---

## 1. ANALIZA KONKURENCIJE

### 1.1 Tržište Anti-Stealth Radara

| Metrika | Vrijednost |
|---------|------------|
| Globalno tržište (2025) | $2.162 milijarde |
| CAGR (2025-2033) | 7-9% |
| Tržište pasivnih radara (2024) | $1.12 milijardi |
| Projekcija pasivnih radara (2033) | $4.38 milijardi |
| CAGR pasivnih radara | 17.6% |

**Ključni igrači:** Lockheed Martin, Raytheon, Thales, Saab, L3Harris, Elbit Systems

### 1.2 Konkurentski Sustavi

#### 1.2.1 Ruski Sustavi

| Sustav | Tip | Frekvencija | Domet | Karakteristike |
|--------|-----|-------------|-------|----------------|
| **Rezonans-NE** | VHF PESA | VHF (30-300 MHz) | >400 km vs F-35/B-2 | 500+ simultanih ciljeva, bistatic mode |
| **Nebo-M** | Multi-band | VHF/L/S/X | 600 km (high alt), 50 km (low alt) | Mobilni, 3 antene, AESA |
| **Kolchuga** | Pasivni ELINT | 130 MHz - 18 GHz | 800 km | Detekcija RF emisija, trilateration |
| **Tamara** | Pasivni | 0.82-18 GHz | 400 km | PCL tehnologija |

#### 1.2.2 Kineski Sustavi

| Sustav | Tip | Frekvencija | Domet | Karakteristike |
|--------|-----|-------------|-------|----------------|
| **YLC-8B** | UHF AESA | UHF (300-1000 MHz) | 200+ km vs stealth | Mobilni, anti-stealth |
| **JY-27A** | VHF | VHF | 500+ km | Sparse array, synthetic aperture |
| **"Photon Catcher"** | Quantum | Single-photon | TBD | Single-photon detektor, 2025 mass production |
| **Yaogan-41** | Optički satelit | Visible/IR | Geostationary | 2.5m rezolucija, AI analiza |

#### 1.2.3 Zapadni Sustavi

| Sustav | Proizvođač | Tip | Karakteristike |
|--------|-----------|-----|----------------|
| **Silent Sentry** | Lockheed Martin | Pasivni PCL | FM/TV illuminators |
| **VERA-NG** | ERA (Czech) | Pasivni | TDOA, 450 km range |
| **Celldar** | Roke Manor | Pasivni | GSM illuminators |
| **PRP (Passive Radar)** | Thales | Pasivni | DAB/DVB-T |
| **SAAB Giraffe** | Saab | Active AESA | Multi-function |

### 1.3 SWOT Analiza QEDMMA vs Konkurencija

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           SWOT ANALIZA QEDMMA                               │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  STRENGTHS (Prednosti)                │  WEAKNESSES (Slabosti)              │
│  ─────────────────────────────────────│──────────────────────────────────── │
│  ✓ Rydberg kvantni senzori            │  ✗ Složena kalibracija              │
│    (-190 dBm noise floor)             │  ✗ Ovisnost o atomskom referencama  │
│  ✓ VHF bistatic geometrija            │  ✗ Visoka cijena razvoja            │
│    (30× RCS vs monostatic)            │  ✗ Nedostatak field-proven statusa  │
│  ✓ TDOA geolokacija                   │  ✗ Potrebna višestruka sinkronizacija│
│    (<500m CEP)                        │                                     │
│  ✓ Kompaktna antena (1×1m)            │                                     │
│  ✓ Tri-modalna komunikacija           │                                     │
│  ✓ N+2 redundancija                   │                                     │
│                                       │                                     │
│  OPPORTUNITIES (Prilike)              │  THREATS (Prijetnje)                │
│  ─────────────────────────────────────│──────────────────────────────────── │
│  ✓ Rastući anti-stealth market        │  ✗ Kineski quantum radar napredak   │
│  ✓ NATO modernizacija                 │  ✗ Ruski integrirani AD sustavi     │
│  ✓ Multi-sensor fusion potražnja      │  ✗ Export kontrole                  │
│  ✓ A2/AD zone zahtijevaju pasivne     │  ✗ Brzi razvoj stealth tehnologije  │
│    senzore                            │  ✗ Visoki R&D troškovi konkurenata  │
│  ✓ Integracija s postojećim AD        │                                     │
│                                       │                                     │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 1.4 Competitive Positioning Matrix

```
                          HIGH RESOLUTION
                               ▲
                               │
              X-band AESA      │      QEDMMA v2.0
              (F-22 APG-77)    │      (Rydberg + TDOA)
                    ●          │          ●
                               │
    LOW ───────────────────────┼───────────────────────► HIGH
    STEALTH                    │                      STEALTH
    DETECTION                  │                      DETECTION
                               │
         Conventional          │      VHF Bistatic
         S-band                │      (Rezonans-NE)
              ●                │          ●
                               │
                               ▼
                          LOW RESOLUTION
```

---

## 2. QEDMMA KOMPETITIVNE PREDNOSTI

### 2.1 Tehnološke Prednosti

| Parametar | QEDMMA v2.0 | Rezonans-NE | VERA-NG | YLC-8B |
|-----------|-------------|-------------|---------|--------|
| Detekcija F-22 | 380 km | 400 km | 450 km | 200 km |
| Točnost lokalizacije | <500m CEP | ~5 km | <1 km | ~1 km |
| Pasivan (LPI) | ✓ Rx pasivan | ✗ Aktivan | ✓ Pasivan | ✗ Aktivan |
| Mobilnost | ✓ | ✗ Fiksni | ✓ | ✓ |
| Weapon-grade track | ✓ | ✗ | ✗ | ✗ |
| Multi-sensor fusion | ✓ v2.0 | ✗ | ✗ | Limited |
| Cijena (6-node) | ~€1.8M | ~€50M | ~€30M | ~€20M |

### 2.2 Jedinstvena Prodajna Točka (USP)

**QEDMMA je jedini sustav koji kombinira:**

1. **Kvantnu osjetljivost** - Rydberg senzori s -190 dBm noise floor
2. **Weapon-grade precision** - <500m CEP za vođenje oružja
3. **Pasivnu detekciju** - LPI/LPD Rx čvorovi
4. **Multi-source fusion** - Integracija svih dostupnih senzora
5. **Pristupačnu cijenu** - 10-30× jeftinije od konkurencije

---

## 3. MULTI-SOURCE FUSION ARHITEKTURA

### 3.1 Pregled Senzora za Integraciju

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    QEDMMA MULTI-SOURCE FUSION                               │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐            │
│  │  ORGANIC        │  │  COOPERATIVE    │  │  NON-COOPERATIVE│            │
│  │  SENSORS        │  │  SENSORS        │  │  SOURCES        │            │
│  ├─────────────────┤  ├─────────────────┤  ├─────────────────┤            │
│  │ • Rydberg Rx    │  │ • Link-16       │  │ • ADS-B         │            │
│  │ • VHF Tx        │  │ • Link-22       │  │ • MLAT          │            │
│  │ • TDOA solver   │  │ • AWACS feed    │  │ • FR24/OGN      │            │
│  │ • IMM tracker   │  │ • Ground radar  │  │ • Satellite IR  │            │
│  │                 │  │ • Naval radar   │  │ • Social media  │            │
│  │                 │  │ • IRST          │  │ • Weather radar │            │
│  └────────┬────────┘  └────────┬────────┘  └────────┬────────┘            │
│           │                    │                    │                      │
│           └────────────────────┼────────────────────┘                      │
│                                ▼                                           │
│  ┌─────────────────────────────────────────────────────────────────────┐  │
│  │                      FUSION ENGINE                                   │  │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐│  │
│  │  │ Track       │  │ Data        │  │ Multi-      │  │ AI/ML       ││  │
│  │  │ Association │→ │ Alignment   │→ │ Hypothesis  │→ │ Classifier  ││  │
│  │  │ (Gating)    │  │ (Spatial/   │  │ Tracker     │  │             ││  │
│  │  │             │  │  Temporal)  │  │ (MHT/JPDA)  │  │             ││  │
│  │  └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘│  │
│  └─────────────────────────────────────────────────────────────────────┘  │
│                                │                                           │
│                                ▼                                           │
│  ┌─────────────────────────────────────────────────────────────────────┐  │
│  │                    FUSED TRACK OUTPUT                                │  │
│  │  • Position (WGS84)         • Velocity (3D)                         │  │
│  │  • Classification (Friend/Foe/Unknown)                              │  │
│  │  • Threat level (1-10)      • Engagement recommendation             │  │
│  │  • Fire control quality track (weapon-grade)                        │  │
│  └─────────────────────────────────────────────────────────────────────┘  │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 3.2 Podržani Senzori i Sučelja

| Senzor/Izvor | Protokol | Data Rate | Latency | Sadržaj |
|--------------|----------|-----------|---------|---------|
| **Link-16** | STANAG 5516 | 115.2 kbps | <100 ms | J-series messages, tracks |
| **Link-22** | STANAG 5522 | 1.3 Mbps | <100 ms | FJ-series, IP routing |
| **ASTERIX** | EUROCONTROL | Variable | <500 ms | CAT-001/021/034/048 |
| **ADS-B** | Mode-S ES | 1090 MHz | <1 s | Position, velocity, ID |
| **ESM/ELINT** | STANAG 4607 | Variable | <500 ms | Emitter params, DF |
| **GMTI** | STANAG 4607 | Variable | <1 s | Moving target tracks |
| **IFF** | Mode-5 | Interrogation | <100 ms | Friend/Foe status |
| **IRST** | Custom | 10 Mbps | <100 ms | IR bearing, intensity |
| **Satellite** | SatCom | Variable | 1-5 s | EO/IR imagery, tracks |
| **AWACS** | Link-16 | 115.2 kbps | <1 s | Air picture |
| **Weather** | NEXRAD | UDP | 5 min | Precipitation, winds |

### 3.3 JDL Fusion Model

```
                    JDL DATA FUSION MODEL
                    ═════════════════════
                    
Level 0: Source Pre-Processing
├── Signal conditioning
├── A/D conversion  
├── Time stamping (GPS/atomic)
└── Format conversion

Level 1: Object Refinement (QEDMMA TDOA Solver)
├── Track association (gating, nearest-neighbor)
├── State estimation (Kalman/IMM)
├── Track maintenance (initiation, update, deletion)
└── Attribute estimation (RCS, velocity, maneuver)

Level 2: Situation Refinement (Fusion Engine)
├── Object aggregation
├── Event detection
├── Threat assessment
└── Prediction (intent estimation)

Level 3: Threat Refinement
├── Threat evaluation
├── Target prioritization
├── Engagement recommendation
└── Weapon-target pairing

Level 4: Process Refinement
├── Sensor management
├── Resource allocation
├── Performance monitoring
└── System adaptation
```

---

## 4. FUSION ENGINE RTL ARHITEKTURA

### 4.1 Block Dijagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        FUSION ENGINE TOP                                     │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌──────────────┐   ┌──────────────┐   ┌──────────────┐   ┌──────────────┐│
│  │  LINK-16     │   │   ASTERIX    │   │   ADS-B      │   │    ESM       ││
│  │  INTERFACE   │   │   DECODER    │   │   DECODER    │   │  INTERFACE   ││
│  │  (J-Series)  │   │  (CAT-048)   │   │  (Mode-S ES) │   │  (STANAG)    ││
│  └──────┬───────┘   └──────┬───────┘   └──────┬───────┘   └──────┬───────┘│
│         │                  │                  │                  │         │
│         └──────────────────┼──────────────────┼──────────────────┘         │
│                            ▼                                               │
│  ┌─────────────────────────────────────────────────────────────────────┐  │
│  │                    TRACK INTERFACE BUFFER                            │  │
│  │  • Standardized track format (internal)                              │  │
│  │  • Timestamp normalization (UTC)                                     │  │
│  │  • Coordinate transform (WGS84/ECEF/ENU)                            │  │
│  └─────────────────────────────────────────────────────────────────────┘  │
│                            │                                               │
│                            ▼                                               │
│  ┌─────────────────────────────────────────────────────────────────────┐  │
│  │                    TRACK ASSOCIATOR                                  │  │
│  │  • Statistical gating (chi-square)                                   │  │
│  │  • Nearest-neighbor / Global nearest-neighbor                        │  │
│  │  • Multi-hypothesis tracking (MHT)                                   │  │
│  │  • Probabilistic data association (JPDA)                            │  │
│  └─────────────────────────────────────────────────────────────────────┘  │
│                            │                                               │
│  ┌────────────────────────┼────────────────────────┐                     │
│  │                        ▼                        │                     │
│  │  ┌──────────────────────────────────────────┐  │                     │
│  │  │           FUSED STATE ESTIMATOR          │  │  ← From QEDMMA      │
│  │  │  • Covariance intersection              │  │     TDOA Solver     │
│  │  │  • Federated Kalman filter              │  │                     │
│  │  │  • Bar-Shalom-Campo fusion              │  │                     │
│  │  └──────────────────────────────────────────┘  │                     │
│  │                        │                        │                     │
│  │  ┌────────────────────┐│┌────────────────────┐ │                     │
│  │  │  IMM Bank          │││  Classification    │ │                     │
│  │  │  • CV model        │││  • RCS estimate    │ │                     │
│  │  │  • CT model        │││  • Maneuver class  │ │                     │
│  │  │  • CA model        │││  • Threat level    │ │                     │
│  │  └────────────────────┘│└────────────────────┘ │                     │
│  │                        │                        │                     │
│  └────────────────────────┼────────────────────────┘                     │
│                            ▼                                               │
│  ┌─────────────────────────────────────────────────────────────────────┐  │
│  │                    TRACK DATABASE                                    │  │
│  │  • 1024 simultaneous tracks                                          │  │
│  │  • Track history (60 min)                                            │  │
│  │  • Covariance storage                                                │  │
│  │  • Source attribution                                                │  │
│  └─────────────────────────────────────────────────────────────────────┘  │
│                            │                                               │
│                            ▼                                               │
│  ┌─────────────────────────────────────────────────────────────────────┐  │
│  │                    OUTPUT FORMATTER                                  │  │
│  │  • Link-16 J-series encoder                                          │  │
│  │  • ASTERIX CAT-062 encoder                                           │  │
│  │  • Fire control interface                                            │  │
│  │  • Display interface (JSON/Protocol Buffers)                         │  │
│  └─────────────────────────────────────────────────────────────────────┘  │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 4.2 Register Map (Fusion Engine)

| Offset | Ime | Opis |
|--------|-----|------|
| 0x00 | FUSION_CTRL | Enable, mode, gate size |
| 0x04 | FUSION_STATUS | Active tracks, associations/sec |
| 0x08 | GATE_PARAMS | Chi-square threshold, velocity gate |
| 0x0C | SOURCE_ENABLE | Bitmask za enabled izvore |
| 0x10 | LINK16_CFG | JTIDS config, NPG assignment |
| 0x14 | ASTERIX_CFG | CAT selection, SIC/SAC |
| 0x18 | ADSB_CFG | ICAO filter, decode options |
| 0x1C | ESM_CFG | Frequency range, DF mode |
| 0x20 | QEDMMA_CFG | TDOA weight, priority |
| 0x30 | TRACK_COUNT | Current active tracks |
| 0x34 | ASSOC_COUNT | Associations this second |
| 0x38 | FALSE_TRACK_CNT | Deleted false tracks |
| 0x40-0x7F | TRACK_TABLE | Direct track access (read) |
| 0xFC | VERSION | IP version |

---

## 5. SUČELJA PREMA VANJSKIM SUSTAVIMA

### 5.1 Link-16 Integracija

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                       LINK-16 INTEGRATION                                    │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  QEDMMA → Link-16 (Transmit)            Link-16 → QEDMMA (Receive)         │
│  ─────────────────────────────          ─────────────────────────────      │
│                                                                             │
│  J2.2 Air Track                         J2.2 Air Track                     │
│  • Track number                         • Correlate with TDOA tracks       │
│  • Position (lat/lon/alt)               • Fuse state vectors               │
│  • Velocity (speed/heading)             • Update classification            │
│  • IFF status                                                              │
│  • Track quality                        J2.6 EW Track                      │
│                                         • ESM data for emitter ID          │
│  J3.2 Air PPLI                                                             │
│  • QEDMMA node position                 J7.2 Air C2                        │
│  • Status/health                        • Tasking messages                 │
│  • Capability                           • Engagement orders                │
│                                                                             │
│  J2.6 EW Track (from ESM)               J12.6 Mission Assignment           │
│  • Emitter location                     • Sensor cueing                    │
│  • Frequency/PRF                        • Track priority                   │
│  • Threat type                                                             │
│                                                                             │
│  Message Rates:                                                            │
│  • Air tracks: 12 sec nominal                                              │
│  • PPLI: 12 sec nominal                                                    │
│  • EW: On detection                                                        │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 5.2 STANAG 4607 (GMTI) Integracija

```yaml
# GMTI Integration
protocol: STANAG_4607
version: Ed3
content:
  - Segment 10: Job Definition
  - Segment 11: Dwell
  - Segment 12: Target Report
  - Segment 13: Free Text
  
mapping:
  gmti_target:
    lat_lon: direct_mapping
    velocity: radial_only → need_triangulation
    rcs: direct_use_for_classification
    snr: quality_indicator
    
fusion_method:
  - Correlate GMTI with QEDMMA tracks
  - Use GMTI for moving targets confirmation
  - GMTI provides velocity validation
```

### 5.3 ADS-B/Mode-S Integracija

```
ADS-B Integration (1090ES)
─────────────────────────────

Message Types:
  DF17: Extended Squitter
    TC 1-4:   Aircraft ID
    TC 5-8:   Surface Position
    TC 9-18:  Airborne Position (Baro/GNSS)
    TC 19:    Airborne Velocity
    TC 28:    Aircraft Status
    TC 29:    Target State
    TC 31:    Operational Status

QEDMMA Usage:
  ┌──────────────────────────────────────────────────────┐
  │  Cooperative Track                                   │
  │  ├── If ADS-B present → Use for ID, augment track   │
  │  ├── Compare ADS-B position with TDOA               │
  │  │   └── Large discrepancy → Possible spoofing      │
  │  └── ADS-B velocity validates IMM estimate          │
  │                                                      │
  │  Non-Cooperative Track (Stealth)                    │
  │  ├── No ADS-B → Flag as potential threat            │
  │  ├── Use TDOA-only tracking                         │
  │  └── ESM correlation for emitter ID                 │
  └──────────────────────────────────────────────────────┘

Anti-Spoofing:
  • Compare ADS-B position with TDOA triangulation
  • Velocity consistency check (ADS-B vs Doppler)
  • MLAT validation if available
  • Signal strength plausibility
```

### 5.4 ESM/ELINT Integracija

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          ESM INTEGRATION                                     │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ESM Input Parameters:                                                      │
│  ─────────────────────                                                      │
│  • AOA (Angle of Arrival)     ±2° accuracy                                 │
│  • Frequency                  100 MHz - 18 GHz                             │
│  • PRI (Pulse Repetition)     1 µs - 10 ms                                 │
│  • PW (Pulse Width)           0.1 - 100 µs                                 │
│  • Scan pattern               Circular, sector, TWS                        │
│  • Emitter ID                 Library match confidence                      │
│                                                                             │
│  Fusion with QEDMMA:                                                        │
│  ──────────────────                                                         │
│                                                                             │
│     ESM (AOA only)          QEDMMA (TDOA)         FUSED OUTPUT             │
│     ┌───────────┐           ┌───────────┐         ┌───────────┐            │
│     │ Bearing:  │           │ Position: │         │ Position: │            │
│     │ 045° ±2°  │    +      │ ±500m CEP │    =    │ ±200m CEP │            │
│     │           │           │           │         │           │            │
│     │ Emitter:  │           │ RCS:      │         │ ID:       │            │
│     │ SA-20     │           │ -15 dBsm  │         │ SA-20 TEL │            │
│     │ (70% conf)│           │           │         │ (95% conf)│            │
│     └───────────┘           └───────────┘         └───────────┘            │
│                                                                             │
│  Threat Database Integration:                                               │
│  ────────────────────────────                                               │
│  • Emitter → Platform mapping (e.g., 9S18M1 → SA-11 Buk)                   │
│  • Engagement envelope lookup                                               │
│  • Threat prioritization (SAM > AAA > EW)                                  │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 5.5 IRST (Infrared Search & Track) Integracija

```
IRST Integration
─────────────────

Input Data:
  • Azimuth bearing (±0.1°)
  • Elevation bearing (±0.1°)
  • IR intensity (W/sr)
  • Wavelength band (MWIR 3-5µm / LWIR 8-12µm)
  • Track ID

Fusion Method:
  ┌───────────────────────────────────────────────────────────────┐
  │                                                               │
  │   IRST provides:              QEDMMA provides:                │
  │   • High-precision bearing    • Range (via TDOA)             │
  │   • Afterburner detection     • Velocity                     │
  │   • Passive (no emission)     • Multiple targets             │
  │                                                               │
  │   Combined:                                                   │
  │   • IRST bearing + QEDMMA range = 3D position               │
  │   • IRST thermal → Engine state → Threat assessment         │
  │   • IRST + QEDMMA = Fully passive detection                 │
  │                                                               │
  └───────────────────────────────────────────────────────────────┘

Key Advantage:
  IRST + QEDMMA = Completely passive detection of stealth aircraft
  (No emissions from defender, stealth has no warning)
```

---

## 6. FIRE CONTROL INTEGRACIJA

### 6.1 Weapon-Grade Track Requirements

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    FIRE CONTROL INTERFACE                                    │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  Track Quality Levels:                                                      │
│  ─────────────────────                                                      │
│                                                                             │
│  Level 1: SURVEILLANCE (Warning)                                           │
│  • Position accuracy: <5 km                                                │
│  • Update rate: 10-60 sec                                                  │
│  • Use: Early warning, situation awareness                                 │
│                                                                             │
│  Level 2: ACQUISITION (Cueing)                                             │
│  • Position accuracy: <1 km                                                │
│  • Update rate: 2-10 sec                                                   │
│  • Use: Cue fire control radar                                             │
│                                                                             │
│  Level 3: TRACK (Fire Control)                   ← QEDMMA TARGET           │
│  • Position accuracy: <500 m                                               │
│  • Velocity accuracy: <10 m/s                                              │
│  • Update rate: 1 sec                                                      │
│  • Use: Direct weapon guidance                                             │
│                                                                             │
│  Level 4: ENGAGEMENT (Weapon Guidance)                                     │
│  • Position accuracy: <100 m                                               │
│  • Update rate: 100 ms                                                     │
│  • Use: Terminal guidance                                                  │
│  • Note: QEDMMA can achieve via sensor fusion                             │
│                                                                             │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  Fire Control Interface Protocol:                                          │
│  ────────────────────────────────                                          │
│                                                                             │
│  struct fc_track_t {                                                       │
│      uint32_t track_id;           // Unique track identifier              │
│      int32_t  lat;                // Latitude (μdeg)                      │
│      int32_t  lon;                // Longitude (μdeg)                     │
│      int32_t  alt;                // Altitude (m MSL)                     │
│      int16_t  vx, vy, vz;         // Velocity (m/s × 10)                  │
│      uint16_t heading;            // True heading (0.01°)                 │
│      uint16_t speed;              // Ground speed (m/s)                   │
│      uint8_t  quality;            // 0-100 (100=best)                     │
│      uint8_t  classification;     // Friend/Foe/Unknown                   │
│      uint8_t  threat_level;       // 0-10 (10=highest)                    │
│      uint8_t  source_bitmap;      // Contributing sensors                 │
│      uint32_t timestamp;          // GPS time (ms of day)                 │
│      uint16_t cep_m;              // Position uncertainty (m)            │
│      uint16_t vel_err;            // Velocity uncertainty (m/s × 10)     │
│  };                                                                        │
│                                                                             │
│  Update Rate: 1 Hz minimum, 10 Hz for engagement tracks                   │
│  Latency: <100 ms from detection to output                                │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 6.2 Weapon System Compatibility

| Weapon System | Interface | QEDMMA Compatibility |
|---------------|-----------|---------------------|
| **NASAMS** | Link-16 J3.3/J12.6 | ✓ Cue AMRAAM/ESSM |
| **Patriot** | Link-16 / FAAD | ✓ Acquisition cue |
| **IRIS-T SLM** | SAMOC/Link-16 | ✓ Direct track feed |
| **S-300/400** | Proprietarni | ⚠ Gateway required |
| **Naval AEGIS** | Link-16 / CEC | ✓ Full integration |
| **F-16/F-35** | Link-16 | ✓ PPLI + Track |

---

## 7. IMPLEMENTACIJSKI PLAN

### 7.1 Razvojni Prioriteti

```
Phase 1: Core Fusion (3 mjeseca)
├── Track association algorithm (GNN/MHT)
├── Covariance intersection fusion
├── Internal track database
└── AXI interface to QEDMMA TDOA solver

Phase 2: External Interfaces (3 mjeseca)
├── Link-16 gateway (Rx/Tx)
├── ASTERIX decoder/encoder
├── ADS-B receiver integration
└── ESM interface

Phase 3: Advanced Fusion (2 mjeseca)
├── IRST integration
├── Satellite track feed
├── GMTI fusion
└── AI-assisted classification

Phase 4: Fire Control (2 mjeseca)
├── Weapon system interfaces
├── Engagement recommendation
├── Latency optimization
└── Certification testing
```

### 7.2 BOM za Fusion Module

| Komponenta | Opis | Količina | Cijena |
|------------|------|----------|--------|
| Link-16 Terminal | MIDS-LVT ili compatible | 1 | €150,000 |
| ASTERIX Processor | COTS ili custom FPGA | 1 | €5,000 |
| ADS-B Receiver | 1090 MHz SDR | 1 | €500 |
| ESM Interface | RS-422/Ethernet bridge | 1 | €2,000 |
| FPGA Fusion | Additional ZU47DR resources | - | Included |
| Software | Fusion algorithms | - | Development |
| **TOTAL per node** | | | **~€160,000** |

---

## 8. ZAKLJUČAK

### 8.1 Konkurentska Pozicija

QEDMMA v2.0 s multi-source fusion postaje **jedini sustav na tržištu** koji kombinira:

1. **Kvantnu osjetljivost** za detekciju ultra-low RCS ciljeva
2. **Weapon-grade preciznost** za direktno vođenje oružja
3. **Multi-sensor fusion** za potpunu situacijsku svijest
4. **Tri-modalnu komunikaciju** za survivabilnost
5. **Pristupačnu cijenu** (10-30× jeftinije od konkurencije)

### 8.2 Tržišna Diferencijacija

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    QEDMMA MARKET POSITIONING                                 │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│                        DETECTION CAPABILITY                                 │
│                               ▲                                             │
│                               │                                             │
│              Quantum          │                                             │
│              Radar       ●────┼────● QEDMMA v2.0                           │
│              (Lab)            │      (Operational)                          │
│                               │                                             │
│         VHF Passive      ●────┼────● VHF Active                            │
│         (VERA-NG)             │      (Rezonans)                             │
│                               │                                             │
│         X-band AESA      ●────┼                                            │
│         (APG-77)              │                                             │
│                               │                                             │
│  ─────────────────────────────┼─────────────────────────► COST             │
│        €50M                   │        €2M                                  │
│                               │                                             │
│  QEDMMA Unique Value:                                                      │
│  • Only system with quantum sensitivity + fusion + weapon-grade           │
│  • 10× cost advantage over comparable capability                           │
│  • Passive Rx = Survivable in A2/AD environment                           │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 8.3 Preporuke

1. **Prioritet 1:** Implementirati Link-16 sučelje za NATO interoperabilnost
2. **Prioritet 2:** Dodati ESM integraciju za ELINT fusion
3. **Prioritet 3:** IRST integracija za potpuno pasivnu detekciju
4. **Prioritet 4:** Fire control interface za weapon-grade tracks

---

**Dr. Mladen Mešter**  
Radar Systems Architect  
© 2026 - All Rights Reserved
