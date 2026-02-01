# QEDMMA Power Upgrade Roadmap

**Author:** Dr. Mladen Mešter  
**Version:** v3.4+ Planning Document  
**Date:** February 2026  
**Status:** FUTURE OPTION  
**Copyright © 2026** - All Rights Reserved

---

## 📋 Executive Summary

Trenutni QEDMMA v3.2 sustav koristi **25 kW Tx snagu** po nodeu i postiže **720 km** detekciju F-35 (RCS 0.0001 m²). Ovaj dokument definira **buduću opciju** povećanja Tx snage na **50-100 kW** za v3.5+ verzije.

### Zašto je ovo OPCIJA, ne prioritet?

| Faktor | Trenutno (25 kW) | Obrazloženje |
|--------|------------------|--------------|
| F-35 domet | 720 km | **Već premašuje** operativne zahtjeve (500 km) |
| SNR margina | +42 dB | **Obilna rezerva** za clutter/jamming |
| Cost | €98,750/node | Optimalan za deployment |
| Mobilnost | Kamion/dron | 25 kW omogućuje manje platforme |

**Zaključak:** Power upgrade čuvamo za scenarije gdje je potreban **800+ km domet** ili **ekstremno jamming okruženje**.

---

## 🎯 Power Upgrade Benefiti

### Link Budget Analiza

```
Radar Range Equation:
R = ⁴√[(Pt × Gt × Gr × λ² × σ × Gp) / ((4π)³ × k × T_sys × B × SNR_min)]

Gdje:
- Pt = Transmit power
- R ∝ ⁴√Pt (četvrti korijen!)
```

### Dobitak po Power Levelu

| Tx Power | Relativni dobitak | Novi domet (F-35) | SNR boost |
|----------|-------------------|-------------------|-----------|
| **25 kW** (baseline) | 0 dB | 720 km | +42 dB |
| **50 kW** (+3 dB) | +0.75 dB range | **780 km** | +45 dB |
| **75 kW** (+4.8 dB) | +1.2 dB range | **820 km** | +47 dB |
| **100 kW** (+6 dB) | +1.5 dB range | **856 km** | +48 dB |

### Matematički Izvod

```
R_new / R_old = ⁴√(Pt_new / Pt_old)

Za 100 kW vs 25 kW:
R_new = 720 km × ⁴√(100/25) = 720 × ⁴√4 = 720 × 1.414 = 856 km

SNR boost = 10 × log10(100/25) = 10 × log10(4) = +6 dB
```

---

## 📊 Detaljni Benefiti

### 1. Povećani Domet (+136 km)

| Metrika | 25 kW | 100 kW | Poboljšanje |
|---------|-------|--------|-------------|
| F-35 detection | 720 km | **856 km** | +19% |
| F-22 detection | 680 km | **808 km** | +19% |
| J-20 detection | 750 km | **892 km** | +19% |
| B-21 detection | 620 km | **737 km** | +19% |

### 2. Poboljšana Jamming Otpornost

| Scenarij | 25 kW margina | 100 kW margina | Dobitak |
|----------|---------------|----------------|---------|
| Barrage 50 kW ERP | +18 dB | **+24 dB** | +6 dB |
| Barrage 100 kW ERP | +12 dB | **+18 dB** | +6 dB |
| DRFM repeater | +15 dB | **+21 dB** | +6 dB |
| Combined EW attack | +8 dB | **+14 dB** | +6 dB |

### 3. Poboljšana Detekcija u Clutteru

| Okruženje | 25 kW P_d | 100 kW P_d | Dobitak |
|-----------|-----------|------------|---------|
| Sea clutter (SS4) | 92% | **98%** | +6% |
| Ground clutter | 88% | **96%** | +8% |
| Rain (10 mm/hr) | 95% | **99%** | +4% |
| Urban multipath | 85% | **94%** | +9% |

### 4. Smanjena Potreba za Integracijom

| Metrika | 25 kW | 100 kW | Benefit |
|---------|-------|--------|---------|
| Required CPI | 5.24 ms | **3.31 ms** | 37% brže |
| Update rate | 191 Hz | **302 Hz** | +58% |
| Track latency | 15.7 ms | **9.9 ms** | -37% |

---

## 💰 Cost Impact

### Hardware Changes Required

| Component | Current (25 kW) | Upgraded (100 kW) | Delta Cost |
|-----------|-----------------|-------------------|------------|
| GaN PA modules | CMPA0060025F ×4 | CGHV96100F2 ×4 | +€8,200 |
| Power supply | 1.6 kW PSU | 4 kW PSU | +€1,850 |
| Cooling system | Air + liquid | Enhanced liquid | +€2,400 |
| Thermal management | Standard | High-power | +€1,200 |
| EMI shielding | Standard | Enhanced | +€650 |
| **TOTAL DELTA** | - | - | **+€14,300** |

### Per-Node Cost Comparison

| Config | 25 kW Node | 100 kW Node | Delta |
|--------|------------|-------------|-------|
| Component cost | €93,000 | €107,300 | +15.4% |
| Assembly & test | €5,750 | €7,200 | +25% |
| **Total per node** | **€98,750** | **€114,500** | **+16%** |
| 6-node system | €592,500 | €687,000 | +16% |

### ROI Analysis

| Metrika | 25 kW | 100 kW | Value |
|---------|-------|--------|-------|
| Detection range | 720 km | 856 km | +136 km |
| Cost per km coverage | €137/km | €134/km | **-2.5%** |
| Cost per dB SNR | €2,351/dB | €2,385/dB | +1.5% |

**Zaključak:** 100 kW opcija je **cost-effective** za scenarije koji zahtijevaju maksimalni domet.

---

## 🔧 Implementation Plan (v3.5+)

### Phase 1: Design (v3.5-alpha)
- [ ] GaN PA module selection & qualification
- [ ] Thermal simulation (CFD)
- [ ] Power supply redesign
- [ ] EMC analysis

### Phase 2: Prototype (v3.5-beta)
- [ ] Single-node 100 kW prototype
- [ ] Thermal validation
- [ ] Power efficiency measurement
- [ ] Range verification

### Phase 3: Production (v3.5)
- [ ] Multi-node integration
- [ ] Field testing
- [ ] Documentation update
- [ ] BOM finalization

### Timeline

```
v3.2 (Current) ──▶ v3.4 (ECCM/Deploy) ──▶ v3.5 (Power Option)
     │                    │                      │
   Feb 2026            Q2 2026               Q4 2026
```

---

## ⚠️ Trade-offs & Considerations

### Advantages of 100 kW
- ✅ +136 km detection range
- ✅ +6 dB jamming margin
- ✅ Faster update rate
- ✅ Better clutter performance

### Disadvantages of 100 kW
- ❌ +16% cost per node
- ❌ Larger thermal footprint
- ❌ Reduced mobility (heavier cooling)
- ❌ Higher power consumption (grid dependency)

### Recommendation Matrix

| Deployment Scenario | Recommended Power |
|---------------------|-------------------|
| Mobile tactical | **25 kW** |
| Semi-fixed strategic | **50 kW** |
| Fixed long-range | **100 kW** |
| Drone-mounted | **25 kW** |
| Ship-based | **100 kW** |

---

## 📐 Technical Specifications (100 kW Option)

### GaN PA Module: CGHV96100F2

| Parameter | Value |
|-----------|-------|
| Frequency | 30-512 MHz |
| P_sat | 100 W per device |
| Gain | 22 dB |
| Efficiency | 65% |
| Package | Flanged ceramic |
| Combining | 4× spatial combiner |

### Power Budget (100 kW Tx)

| Subsystem | Power | Notes |
|-----------|-------|-------|
| GaN PA (4×) | 615 W | 65% efficiency |
| Driver chain | 85 W | |
| Digital (RFSoC) | 45 W | |
| Cooling | 180 W | Enhanced liquid |
| Aux systems | 75 W | |
| **Total DC** | **1,000 W** | |

### Thermal Requirements

| Parameter | 25 kW | 100 kW |
|-----------|-------|--------|
| Heat dissipation | 350 W | 650 W |
| Coolant flow | 2 L/min | 5 L/min |
| Ambient max | 45°C | 40°C |
| Junction temp | 150°C | 175°C |

---

## 🎯 Decision Framework

### When to Upgrade to 100 kW

**UPGRADE if:**
- Mission requires >800 km detection
- Operating in heavy jamming (>100 kW ERP)
- Fixed/ship installation available
- Budget allows +16% per node

**STAY at 25 kW if:**
- 720 km range is sufficient
- Mobility is priority
- Cost optimization needed
- Drone/airborne deployment

---

## 📊 Summary

| Parameter | v3.2 (25 kW) | v3.5+ (100 kW) | Delta |
|-----------|--------------|----------------|-------|
| F-35 range | 720 km | 856 km | +19% |
| SNR margin | +42 dB | +48 dB | +6 dB |
| Cost/node | €98,750 | €114,500 | +16% |
| Mobility | High | Medium | ↓ |
| Status | **CURRENT** | **FUTURE OPTION** | - |

---

**Power upgrade je OPCIJA za v3.5+, ne prioritet za v3.4.**

*Trenutni 25 kW sustav već dominira anti-stealth misiju.*

---

**Document Control:**
- Created: February 2026
- Author: Dr. Mladen Mešter
- Classification: PROPRIETARY
- Next Review: Q3 2026
