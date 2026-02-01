# QEDMMA v2.0 Competitive Analysis
## Anti-Stealth Radar Market Intelligence

**Author:** Dr. Mladen Mešter  
**Date:** 31. January 2026  
**Classification:** PROPRIETARY

---

## 1. Executive Summary

QEDMMA se pozicionira kao **jedini** sustav koji kombinira:
- **Rydberg kvantne senzore** (500→200 nV/m/√Hz) - najosjetljiviji na tržištu
- **VHF bistatičku geometriju** - 30× RCS enhancement
- **TDOA geolokaciju** - <500m CEP preciznost
- **Multi-sensor fuzija** - integracija bilo kojeg vanjskog izvora

### Ključna prednost vs. konkurencija:

| Parametar | QEDMMA v2.0 | JY-27V (Kina) | Surya (Indija) | Rezonans-NE (Rusija) |
|-----------|-------------|---------------|----------------|----------------------|
| **Tehnologija** | Rydberg + VHF bistatic | VHF AESA | VHF AESA | VHF passive phased |
| **Domet** | 380 km | 500 km (tvrdnja) | 350-400 km | 400+ km |
| **RCS detekcija** | 0.0001 m² | 0.01 m² | 0.001 m² | ~0.01 m² |
| **Preciznost** | <500m CEP | ~1-2 km | ~1 km | ~2-3 km |
| **Pasivnost** | Semi-pasivni Rx | Aktivan | Aktivan | Pasivan Rx |
| **Fusion inputs** | ∞ (open arch.) | Proprietary | Limited | Limited |
| **AI/ML** | Embedded IMM | Basic | Some AI | None |
| **Cost** | ~€1.8M (6-node) | ~$15-20M | ~€24M (6 units) | ~$30M+ |
| **Mobility** | Full mobile | Truck-mounted | TATRA mobile | Fixed + mobile |

---

## 2. Competitor Deep Dive

### 2.1 China: JY-27V / YLC-8E

**Proizvođač:** CETC (38th Research Institute)

**Karakteristike:**
- VHF AESA (30-300 MHz)
- Tvrdnja: F-22/F-35 detekcija do 500 km
- AI-driven signal processing
- 3D tracking
- Truck-mounted (mobile)

**Slabosti:**
- Niska prostorna rezolucija (10-30m)
- Ne može voditi raketu do završne faze
- Ovisi o X-band handoff za engagement
- Export restricted

**QEDMMA prednost:**
- 10× bolja osjetljivost (Rydberg vs GaN AESA)
- TDOA daje bolju preciznost bez handoff-a
- Open architecture za NATO integraciju

---

### 2.2 India: Surya VHF + DRDO Anti-Stealth

**Proizvođač:** Alpha Design Technologies / DRDO-BEL

**Karakteristike:**
- VHF solid-state 3D radar
- 360 km range (2 m² RCS)
- GaN T/R modules
- Adaptive nulling (anti-jam)
- Frequency hopping
- 100 simultaneous tracks

**Slabosti:**
- Samo monostatički rad
- Nema TDOA geolokaciju
- Limited sensor fusion

**QEDMMA prednost:**
- Bistatička geometrija = veći RCS
- Distribuirani senzori = redundancy
- Superior sensor fusion

---

### 2.3 Russia: Rezonans-NE / Container-S (29B6)

**Karakteristike:**
- VHF passive phased array
- 400+ km detection
- Bistatic mode
- 500+ simultaneous tracks
- OTH capability (Container-S: 3000+ km)

**Slabosti:**
- Fixed installations (Rezonans)
- Low precision (early warning only)
- Zastarjela elektronika
- Export embargo (djelomično)

**QEDMMA prednost:**
- Full mobility
- Weapon-grade precision
- Modern FPGA processing
- Western supply chain

---

### 2.4 Passive Bistatic Radar (PBR) Systems

**Tržište:** $1.14B (2024) → $3.39B (2033), CAGR 15.2%

**Ključni igrači:**
- Thales (Silent Sentry successor)
- Lockheed Martin (PCL systems)
- Leonardo (Aulos)
- Hensoldt (TwInvis)

**Karakteristike PBR-a:**
- Koriste "illuminators of opportunity" (FM, DVB-T, GSM, WiFi)
- Potpuno pasivni (covert)
- Jeftini

**Slabosti PBR:**
- Ovisnost o vanjskim odašiljačima
- Nepredvidiva pokrivenost
- Loša performance u ruralnim područjima

**QEDMMA prednost:**
- Kontrolirani odašiljač = predvidiva pokrivenost
- Rydberg osjetljivost nadmašuje PBR
- Može koristiti i illuminators of opportunity kao dodatak

---

## 3. QEDMMA Unique Selling Points (USP)

### 3.1 Rydberg Quantum Sensing
- **Fizika:** Elektromagnetski inducirani transparentnost (EIT) u Rb/Cs atomima
- **Osjetljivost:** 200 nV/m/√Hz (Gen-2) vs ~1 µV/m za konvencionalne
- **Prednost:** 1000× bolji SNR = detekcija manjih RCS na većim udaljenostima

### 3.2 Bistatic RCS Enhancement
- **Fizika:** Forward scatter + resonance region
- **Enhancement:** 30× za F-22 tip geometrije vs monostatic
- **Prednost:** Stealth dizajn optimiziran za monostatic X-band - neučinkovit protiv VHF bistatic

### 3.3 TDOA Precision Geolocation
- **Tehnologija:** 4+ node multilateration
- **Preciznost:** <500m CEP @ 300 km
- **Prednost:** Weapon-grade coordinates bez X-band handoff

### 3.4 Open Fusion Architecture
- **Novost:** Sposobnost integracije BILO KOJEG vanjskog senzora
- **Prednost:** Koristi postojeću infrastrukturu kupca
- **Lock-in avoidance:** NATO-compatible interfaces

---

## 4. Market Positioning

```
                    HIGH PRECISION
                         ▲
                         │
    QEDMMA v2.0 ●────────┼───────────────
                         │              │
                         │   Targeting  │
    IRST/ESM ○           │    Zone      │
    Fusion   │           │              │
             │           │              │
             ├───────────┼──────────────┤
             │           │              │
  LOW        │  Early    │              │  HIGH
  SENSITIVITY│  Warning  │              │  SENSITIVITY
             │  Zone     │              │
             │           │              │
    Passive  │    VHF    │    Quantum   │
    Radar ○──┼────○──────┼───────●──────│
             │  (JY-27V) │   (QEDMMA)   │
             │           │              │
                         ▼
                    LOW PRECISION
```

**QEDMMA zauzima jedinstvenu poziciju:**
- HIGH Sensitivity (Rydberg)
- HIGH Precision (TDOA)
- OPEN Architecture (Fusion)

---

## 5. Competitive Response Strategy

### 5.1 vs. Chinese Systems
- **Argument:** NATO interoperability, no backdoors
- **Technical:** Superior precision for kill chain
- **Commercial:** Lower cost, European supply chain

### 5.2 vs. Russian Systems
- **Argument:** No export restrictions, modern tech
- **Technical:** Full mobility, better EW resistance
- **Commercial:** NATO funding eligible

### 5.3 vs. Indian Systems
- **Argument:** Technology transfer potential
- **Technical:** Quantum advantage
- **Commercial:** Partnership opportunity (Croatian-Indian defence ties)

### 5.4 vs. Western PBR
- **Argument:** Controlled illumination = reliability
- **Technical:** Rydberg sensitivity >> PBR
- **Commercial:** Complement existing PBR deployments

---

## 6. Key Differentiator: Multi-Sensor Fusion

**QEDMMA v2.0 može integrirati:**

| Izvor | Interface | Data Type | Fusion Benefit |
|-------|-----------|-----------|----------------|
| Link 16 | STANAG 5516 | J-series tracks | NATO COP integration |
| IRST | Angle-only | Az/El/Time | Silent detection |
| ESM/ELINT | AOA/TOA | Emitter tracks | Classification |
| ADS-B | Mode-S | Transponder | Civil deconfliction |
| Satellite | TLE/CCSDS | Space tracks | Strategic cueing |
| Other radars | ASTERIX | Plot/track | Multi-radar fusion |
| External C2 | NATO formats | Commands | Kill chain integration |
| Drones/UAS | MAVLink | Sensor data | Distributed sensing |

**Ovo je KLJUČNA prednost** - nijedan konkurent ne nudi ovako otvorenu arhitekturu!

---

## 7. Conclusion

QEDMMA v2.0 je pozicioniran kao:

1. **Tehnološki lider** - Rydberg quantum + bistatic + TDOA
2. **Cenovno konkurentan** - €1.8M vs $15-30M konkurencija
3. **NATO-kompatibilan** - Open architecture, western supply
4. **Fusion-enabled** - Integrira bilo koji senzor

**Preporučena strategija:**
- Pozicioniraj kao "Swiss Army knife" anti-stealth sustava
- Naglasi sensor fusion kao force multiplier
- Target: NATO small/medium states (Baltics, Balkans, Nordics)
- Secondary: Export to non-aligned (UAE, Singapore, Brazil)

---

*Document Control: QEDMMA-CA-2026-001*
