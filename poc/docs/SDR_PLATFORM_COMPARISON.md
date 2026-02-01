# SDR Platform Comparison for QEDMMA PoC

## 🎯 Executive Summary: Which SDR for Radar PoC?

**Author:** Dr. Mladen Mešter  
**Date:** February 2026  
**Purpose:** Select optimal SDR platform for "Garažni Pobunjenik" VHF radar PoC

---

## 📊 Head-to-Head Comparison

| Parameter | PlutoSDR | bladeRF xA9 | RFNM + Lime | RFNM + Granita |
|-----------|----------|-------------|-------------|----------------|
| **Price** | €230 | €860 | €478 | €548 |
| **VHF Coverage** | 70-6000 MHz* | 47-6000 MHz | 5-3500 MHz | 600-7200 MHz |
| **155 MHz Support** | ✅ (hack) | ✅ Native | ✅ Native | ❌ Min 600 MHz |
| **ADC Resolution** | 12-bit | 12-bit | 12-bit | 12-bit |
| **Max Bandwidth** | 56 MHz | 122 MHz | 153 MHz | 153 MHz |
| **TX Power** | 7 dBm | 10 dBm | ~20 dBm | ~20 dBm |
| **MIMO** | 2T2R | 2T2R | 2RX/1TX | 2RX/2TX |
| **On-board FPGA** | Xilinx Zynq | Cyclone V 301K | ❌ (LA9310 DSP) | ❌ |
| **USB** | 2.0 | 3.0 SS | 3.0 | 3.0 |
| **Software Maturity** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐ | ⭐⭐ |
| **Radar Examples** | Many | Some | Few | Few |
| **libiio Support** | ✅ Native | Via SoapySDR | Custom | Custom |

*PlutoSDR requires firmware hack for VHF

---

## 🔬 Detailed Analysis

### 1. ADALM-PLUTO (Current Choice)

```
┌─────────────────────────────────────────────────────────────┐
│                    ADALM-PLUTO                              │
├─────────────────────────────────────────────────────────────┤
│  Chip:        AD9363 (hackable to AD9361 mode)              │
│  Frequency:   325 MHz - 3.8 GHz (stock)                     │
│               70 MHz - 6 GHz (hacked)                       │
│  Bandwidth:   20 MHz (stock), 56 MHz (hacked)               │
│  ADC:         12-bit @ 61.44 MSPS                           │
│  FPGA:        Xilinx Zynq 7010 (28K LUTs)                   │
│  Price:       €230                                          │
└─────────────────────────────────────────────────────────────┘

PROS:
  ✅ Cheapest option with decent specs
  ✅ Excellent software ecosystem (libiio, pyadi-iio)
  ✅ Many radar project examples online
  ✅ On-board Zynq FPGA for future correlator offload
  ✅ Well documented firmware hacks
  ✅ AD9361 proven in professional radar systems

CONS:
  ❌ USB 2.0 limits sustained bandwidth to ~5 MB/s
  ❌ VHF requires firmware hack (works but unofficial)
  ❌ Lower TX power (7 dBm, needs external PA anyway)
  ❌ Small FPGA (28K LUTs) limits on-board processing

RADAR SUITABILITY: ⭐⭐⭐⭐ (4/5)
Best for: Budget PoC, learning, proven reliability
```

### 2. bladeRF 2.0 micro xA9

```
┌─────────────────────────────────────────────────────────────┐
│                 bladeRF 2.0 micro xA9                       │
├─────────────────────────────────────────────────────────────┤
│  Chip:        AD9361                                        │
│  Frequency:   47 MHz - 6 GHz (native!)                      │
│  Bandwidth:   56 MHz (standard), 122 MHz (extended)         │
│  ADC:         12-bit @ 61.44 MSPS (up to 122.88 MSPS)       │
│  FPGA:        Intel Cyclone V 301KLE (292K usable)          │
│  Price:       €860                                          │
└─────────────────────────────────────────────────────────────┘

PROS:
  ✅ Native VHF support (47 MHz!) - no hacks needed
  ✅ MASSIVE FPGA (301K LEs vs 28K on Pluto)
  ✅ USB 3.0 SuperSpeed - full bandwidth to host
  ✅ Higher TX power (10 dBm)
  ✅ Better oscillator stability (VCTCXO + 10 MHz ref in)
  ✅ Headless operation possible
  ✅ Active development (2025.10 major release)
  ✅ Open-source VHDL available

CONS:
  ❌ 3.7× more expensive than PlutoSDR
  ❌ Different API (libbladeRF vs libiio)
  ❌ Heavier, needs external power for full performance
  ❌ Fewer radar examples compared to Pluto

RADAR SUITABILITY: ⭐⭐⭐⭐⭐ (5/5)
Best for: Serious development, on-board FPGA processing
```

### 3. RFNM + Lime Daughterboard

```
┌─────────────────────────────────────────────────────────────┐
│                   RFNM + Lime DB                            │
├─────────────────────────────────────────────────────────────┤
│  Chip:        LA9310 + LMS7002M                             │
│  Frequency:   5 MHz - 3.5 GHz                               │
│  Bandwidth:   Up to 153.6 MHz (!!)                          │
│  ADC:         12-bit @ 153.6 MSPS                           │
│  Processor:   VSPA DSP + ARM Cortex-A53 + 16 GFLOPS GPU     │
│  Price:       €299 (MB) + €179 (Lime) = €478                │
└─────────────────────────────────────────────────────────────┘

PROS:
  ✅ WIDEST bandwidth (153 MHz vs 56 MHz on Pluto)
  ✅ Native VHF support down to 5 MHz
  ✅ On-board DSP processor for correlation
  ✅ ARM + GPU for edge processing
  ✅ Modular (can upgrade daughterboard later)
  ✅ Good price/bandwidth ratio

CONS:
  ❌ Immature software ecosystem (early stage)
  ❌ No FPGA for custom HDL
  ❌ USB connection issues reported
  ❌ Limited gain control in current software
  ❌ Few radar examples
  ❌ New product - less community support

RADAR SUITABILITY: ⭐⭐⭐ (3/5)
Best for: Wideband applications, future potential
```

### 4. RFNM + Granita Daughterboard

```
┌─────────────────────────────────────────────────────────────┐
│                 RFNM + Granita DB                           │
├─────────────────────────────────────────────────────────────┤
│  Chip:        LA9310 + Arctic Semi Granita                  │
│  Frequency:   600 MHz - 7.2 GHz (NO VHF!)                   │
│  Bandwidth:   Up to 153.6 MHz                               │
│  ADC:         12-bit @ 153.6 MSPS                           │
│  Price:       €299 (MB) + €249 (Granita) = €548             │
└─────────────────────────────────────────────────────────────┘

PROS:
  ✅ Excellent for UHF/microwave radar
  ✅ Wide bandwidth
  ✅ Low noise PLL

CONS:
  ❌ NO VHF SUPPORT (min 600 MHz)
  ❌ Cannot do 155 MHz radar!
  ❌ Same software immaturity as Lime version

RADAR SUITABILITY FOR VHF: ❌ (0/5 - NOT SUITABLE)
Best for: UHF/microwave applications only
```

---

## 🎯 RECOMMENDATION FOR QEDMMA PoC

### Budget Constrained (<€500): **ADALM-PLUTO** ✅

```
Razlog:
• Dokazana platforma za radar projekte
• Odličan software ekosistem
• VHF hack pouzdan
• €230 ostavlja budget za PA, LNA, antene
• Brzi start - fokus na fiziku, ne na debugging SDR-a
```

### Best Technical Choice: **bladeRF 2.0 micro xA9** ⭐

```
Razlog:
• Native 47 MHz - idealno za VHF bez hackova
• 301K FPGA - može hostati Zero-DSP correlator na FPGA!
• USB 3.0 - nema bandwidth bottleneck
• Bolji oscillator = bolja koherencija
• Upgrade path za full QEDMMA sustav
```

### NOT Recommended for VHF Radar: **RFNM + Granita** ❌

```
Razlog:
• Granita NE PODRŽAVA VHF (min 600 MHz)
• Za 155 MHz radar MORATE koristiti Lime daughterboard
```

---

## 💰 Cost-Benefit Analysis

| Scenario | SDR Cost | Total PoC Cost | Processing Location | VHF Native |
|----------|----------|----------------|---------------------|------------|
| **Budget PoC** | Pluto €230 | €495 | Host (Python) | No (hack) |
| **Mid-range** | RFNM+Lime €478 | €743 | On-board DSP | Yes |
| **Professional** | bladeRF xA9 €860 | €1,125 | On-board FPGA | Yes |

---

## 🔧 Upgrade Path Recommendation

```
PHASE 1: Garažni Pobunjenik PoC (NOW)
├── Hardware: ADALM-PLUTO (€230)
├── Processing: Python on laptop
├── Goal: Prove physics
└── Budget: €495

PHASE 2: Intermediate System (3-6 months)
├── Hardware: bladeRF xA9 (€860)
├── Processing: FPGA correlator (VHDL)
├── Goal: Real-time processing
└── Budget: €1,500

PHASE 3: Full QEDMMA Node (12+ months)
├── Hardware: Custom RF front-end
├── Processing: Zynq UltraScale+
├── Receiver: Rydberg cell
└── Budget: €50,000+
```

---

## 📋 Final Verdict

### Za "Garažni Pobunjenik" v3.4 PoC:

| Kriterij | Winner |
|----------|--------|
| Best Value | **PlutoSDR** |
| Best Technical | **bladeRF xA9** |
| Best Bandwidth | RFNM + Lime |
| VHF Native | bladeRF xA9 |
| Software Ecosystem | **PlutoSDR** |
| FPGA Resources | **bladeRF xA9** |
| On-board Processing | RFNM |

### **PREPORUKA:**

1. **Za brzi PoC (<€500):** Ostani na **PlutoSDR**
   - Dokazano radi
   - Sav kod već napisan
   - Fokus na fiziku, ne na platformu

2. **Za ozbiljniji razvoj:** Nadogradi na **bladeRF xA9**
   - Native VHF
   - FPGA za correlator
   - USB 3.0 bandwidth
   - €860 je fer cijena za 301K FPGA + AD9361

3. **Izbjegavaj RFNM za VHF radar:**
   - Granita ne podržava VHF
   - Lime radi, ali software je nezreo
   - Čekaj 6-12 mjeseci da software sazrije

---

**Document Version:** 1.0  
**Last Updated:** February 2026
