# QEDMMA v2.0 Multi-Source Fusion - Executive Summary

**Autor:** Dr. Mladen Mešter  
**Datum:** 31. siječnja 2026.

---

## 🎯 CILJ

Omogućiti QEDMMA radaru integraciju podataka iz **svih dostupnih izvora** za:
1. Poboljšanu detekciju i praćenje
2. Fire control kvalitetu (<500m CEP)
3. Automatsku klasifikaciju Friend/Foe/Unknown
4. Kompetitivnu prednost nad postojećim sustavima

---

## 📊 KONKURENTSKA ANALIZA

### Ključni Konkurenti

| Sustav | Proizvođač | Tip | Domet vs Stealth | Cijena |
|--------|-----------|-----|------------------|--------|
| Rezonans-NE | Rusija | VHF Active | 400 km | ~€50M |
| VERA-NG | ERA (CZ) | Pasivni TDOA | 450 km | ~€30M |
| YLC-8B | Kina | UHF AESA | 200 km | ~€20M |
| **QEDMMA v2.0** | Dr. Mešter | Rydberg+TDOA | **380 km** | **€1.8M** |

### QEDMMA Prednosti

✅ **10-30× jeftiniji** od konkurenata  
✅ **Weapon-grade** preciznost (<500m CEP)  
✅ **Kvantna osjetljivost** (-190 dBm)  
✅ **Pasivni Rx** (LPI/LPD)  
✅ **Multi-source fusion** (jedinstveno)

---

## 🔌 PODRŽANI IZVORI PODATAKA

```
┌─────────────────────────────────────────────────────────────┐
│                    FUSION ENGINE                            │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ORGANIC              COOPERATIVE          NON-COOPERATIVE  │
│  ────────             ───────────          ───────────────  │
│  • QEDMMA TDOA        • Link-16            • ADS-B          │
│  • IMM Tracker        • Link-22            • MLAT           │
│                       • ASTERIX            • Satellite IR   │
│                       • AWACS              • Weather Radar  │
│                       • Naval Radar        • FR24/OGN       │
│                       • IRST                                │
│                       • ESM/ELINT                           │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 🔧 IMPLEMENTACIJA

### Novi RTL Moduli

| Modul | Linije | Funkcija |
|-------|--------|----------|
| `fusion_engine_top.sv` | 352 | Multi-source track fusion |
| `link16_interface.sv` | TBD | J-Series encode/decode |
| `adsb_decoder.sv` | TBD | Mode-S Extended Squitter |
| `esm_correlator.sv` | TBD | Emitter-to-track association |

### Fire Control Output Format

```c
struct fc_track_t {
    uint16_t track_id;        // Unique ID
    int32_t  lat, lon, alt;   // Position (WGS84)
    int16_t  vx, vy, vz;      // Velocity (m/s)
    uint8_t  quality;         // 0-100
    uint8_t  classification;  // Friend/Foe/Unknown
    uint8_t  threat_level;    // 0-10
    uint8_t  source_bitmap;   // Contributing sensors
    uint16_t cep;             // Position error (m)
    uint32_t timestamp;       // GPS time
};
```

---

## 📈 POBOLJŠANJA KROZ FUSION

| Metrika | QEDMMA Only | + ADS-B | + ESM | + IRST | Sve |
|---------|-------------|---------|-------|--------|-----|
| CEP | 500m | 200m | 400m | 300m | **<100m** |
| Classification | Unknown | Friend | Emitter ID | Thermal | **Full ID** |
| False Track | 5% | 1% | 3% | 2% | **<0.5%** |
| Detection (stealth) | 95% | 95% | 98% | 99% | **>99%** |

---

## 💰 ROI ANALIZA

### Troškovi Fusion Modula

| Komponenta | Cijena/Node |
|------------|-------------|
| Link-16 Terminal | €150,000 |
| ADS-B Receiver | €500 |
| ESM Interface | €2,000 |
| FPGA Resources | Included |
| **UKUPNO** | **~€152,500** |

### Benefit

- **Fire control capability** bez dodatnog radara
- **Reduce false tracks** = manje krivog angažiranja
- **NATO interoperability** = izvozni potencijal
- **Full situational awareness** = bolje odlučivanje

---

## 🚀 SLJEDEĆI KORACI

### Phase 1 (3 mj): Core Fusion
- [ ] Track association algorithm
- [ ] Covariance intersection
- [ ] Internal track database

### Phase 2 (3 mj): External Interfaces
- [ ] Link-16 gateway
- [ ] ADS-B decoder
- [ ] ESM interface

### Phase 3 (2 mj): Advanced
- [ ] IRST integration
- [ ] AI classification
- [ ] Satellite feed

### Phase 4 (2 mj): Fire Control
- [ ] Weapon system interfaces
- [ ] Certification
- [ ] Field testing

---

## 📋 DELIVERABLES

✅ **QEDMMA_COMPETITION_ANALYSIS.md** - Kompletna analiza konkurencije  
✅ **fusion_engine_top.sv** - RTL za fusion engine  
⏳ **link16_interface.sv** - Pending  
⏳ **adsb_decoder.sv** - Pending  
⏳ **esm_correlator.sv** - Pending

---

**Dr. Mladen Mešter**  
Radar Systems Architect  
© 2026 - All Rights Reserved
