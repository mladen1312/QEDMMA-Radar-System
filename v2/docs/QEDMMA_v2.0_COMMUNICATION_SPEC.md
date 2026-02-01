# 📡 QEDMMA v2.0 - KOMUNIKACIJSKI PODSUSTAV
## Specifikacija Tri-Modalne Otporne Komunikacije

**Autor:** Dr. Mladen Mešter  
**Datum:** 31. siječnja 2026.  
**Verzija:** 2.0-DRAFT

---

# 1. PREGLED SUSTAVA

## 1.1 Arhitektura

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                    QEDMMA v2.0 COMMUNICATION SYSTEM                          │
├──────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│    ╔══════════════╗    ╔══════════════╗    ╔══════════════╗                 │
│    ║   PRIMARY    ║    ║  SECONDARY   ║    ║   TERTIARY   ║                 │
│    ║              ║    ║              ║    ║              ║                 │
│    ║  FREE-SPACE  ║    ║   E-BAND     ║    ║    HF NVIS   ║                 │
│    ║   OPTICAL    ║    ║  MICROWAVE   ║    ║   SKYWAVE    ║                 │
│    ║   (FSO)      ║    ║  (71-86 GHz) ║    ║  (3-10 MHz)  ║                 │
│    ╚══════╤═══════╝    ╚══════╤═══════╝    ╚══════╤═══════╝                 │
│           │                   │                   │                          │
│           │    10 Gbps        │    10 Gbps        │    9.6 kbps             │
│           │    50 km          │    15 km          │    500 km               │
│           │    Clear LOS      │    All-weather    │    BLOS                 │
│           │                   │                   │                          │
│           └───────────────────┴───────────────────┘                          │
│                               │                                              │
│                    ╔══════════╧══════════╗                                  │
│                    ║   COMMUNICATION     ║                                  │
│                    ║    CONTROLLER       ║                                  │
│                    ║                     ║                                  │
│                    ║ • Link monitoring   ║                                  │
│                    ║ • Auto failover     ║                                  │
│                    ║ • AES-256-GCM       ║                                  │
│                    ║ • FHSS/DSSS         ║                                  │
│                    ║ • Protocol bridge   ║                                  │
│                    ╚═════════════════════╝                                  │
│                                                                              │
└──────────────────────────────────────────────────────────────────────────────┘
```

## 1.2 Karakteristike kanala

| Kanal | Kapacitet | Domet | Latencija | Otpornost | Primjena |
|-------|-----------|-------|-----------|-----------|----------|
| **FSO** | 10 Gbps | 20-50 km | <1 ms | LPI/LPD, ne-RF | I/Q streaming, bulk data |
| **E-band** | 10 Gbps | 5-15 km | <1 ms | Uski snop, weather resilient | Backup high-speed |
| **HF NVIS** | 9.6 kbps | 50-500 km | 50-200 ms | BLOS, survivable | Command/control, status |

---

# 2. PRIMARY: FREE-SPACE OPTICAL (FSO)

## 2.1 Princip rada

```
┌─────────────────────────────────────────────────────────────┐
│                    FSO TERMINAL                             │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│   ┌─────────────┐         ┌─────────────┐                  │
│   │   LASER     │         │  TELESCOPE  │                  │
│   │   1550 nm   │────────►│   100 mm    │─────────►        │
│   │   200 mW    │         │  aperture   │    TO            │
│   └─────────────┘         └─────────────┘    REMOTE        │
│                                              NODE          │
│   ┌─────────────┐         ┌─────────────┐                  │
│   │    APD      │◄────────│  TELESCOPE  │◄─────────        │
│   │  RECEIVER   │         │   100 mm    │    FROM          │
│   │  InGaAs     │         │  aperture   │    REMOTE        │
│   └──────┬──────┘         └─────────────┘    NODE          │
│          │                                                  │
│          ▼                                                  │
│   ┌─────────────┐         ┌─────────────┐                  │
│   │   10 GbE    │◄───────►│   GIMBAL    │                  │
│   │  INTERFACE  │         │  TRACKING   │                  │
│   └─────────────┘         │  ±30° Az    │                  │
│                           │  ±15° El    │                  │
│                           └─────────────┘                  │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## 2.2 Specifikacije

| Parametar | Vrijednost | Komentar |
|-----------|------------|----------|
| Valna duljina | 1550 nm | Eye-safe, telekom standard |
| Tx snaga | 200 mW (+23 dBm) | Class 1M laser safety |
| Modulacija | OOK / PAM4 | 10 Gbps / 25 Gbps |
| Rx osjetljivost | -28 dBm @ 10 Gbps | APD receiver |
| Beam divergence | 0.5 mrad | 50 m spot @ 100 km |
| Apertura | 100 mm | Tx i Rx |
| Tracking | 2-axis gimbal | ±0.1 mrad accuracy |
| Acquisition time | <10 s | Initial alignment |

## 2.3 Link Budget (FSO @ 30 km)

```
TRANSMITTER:
  Laser power:           +23 dBm (200 mW)
  Tx optics efficiency:  -1 dB
  
CHANNEL:
  Geometric loss:        -59 dB (30 km, 0.5 mrad div, 100mm Rx)
  Atmospheric:           -3 dB (clear, 23 km visibility)
  Scintillation margin:  -5 dB
  Pointing loss:         -2 dB
  
RECEIVER:
  Rx optics efficiency:  -1 dB
  
LINK MARGIN:
  Received power:        -48 dBm
  Rx sensitivity:        -28 dBm
  Margin:                +20 dB (AMPLE)
```

## 2.4 Vremenski uvjeti

| Uvjet | Vidljivost | Atenuacija | Status |
|-------|------------|------------|--------|
| Clear | >23 km | 0.1 dB/km | ✅ Full rate |
| Haze | 10-23 km | 0.5 dB/km | ✅ Full rate |
| Light fog | 2-10 km | 3 dB/km | ⚠️ Reduced range |
| Dense fog | <1 km | >20 dB/km | ❌ Failover to E-band |
| Rain (heavy) | - | 3-10 dB/km | ⚠️ Marginal |

## 2.5 Komponente

| Komponenta | Model | Cijena | Dobavljač |
|------------|-------|--------|-----------|
| Laser modul | IPG YLPM-10-1550 | €8,000 | IPG Photonics |
| APD prijemnik | Hamamatsu G8931-20 | €2,500 | Hamamatsu |
| Optika Tx/Rx | Custom 100mm | €3,000 | Edmund Optics |
| Gimbal | FLIR PTU-D48E | €12,000 | FLIR |
| PHY/MAC | Custom FPGA | €3,000 | In-house |
| **TOTAL per terminal** | | **€28,500** | |

---

# 3. SECONDARY: E-BAND MICROWAVE (71-86 GHz)

## 3.1 Princip rada

```
┌─────────────────────────────────────────────────────────────┐
│                 E-BAND TERMINAL                             │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│   ┌─────────────────────────────────────────┐              │
│   │         INTEGRATED UNIT                  │              │
│   │                                          │              │
│   │   ┌─────────┐    ┌─────────┐            │              │
│   │   │  E-band │    │  0.6m   │            │              │
│   │   │  Radio  │───►│  Dish   │─────────►  │              │
│   │   │ 71-86GHz│    │ 50 dBi  │            │              │
│   │   └────┬────┘    └─────────┘            │              │
│   │        │                                 │              │
│   │   ┌────┴────┐                           │              │
│   │   │  Modem  │                           │              │
│   │   │ 256-QAM │                           │              │
│   │   │ 10 Gbps │                           │              │
│   │   └────┬────┘                           │              │
│   │        │                                 │              │
│   └────────┼────────────────────────────────┘              │
│            │                                                │
│            ▼                                                │
│      10 GbE SFP+                                           │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## 3.2 Specifikacije

| Parametar | Vrijednost | Komentar |
|-----------|------------|----------|
| Frekvencija | 71-76 / 81-86 GHz | E-band, light licensed |
| Bandwidth | 2 × 5 GHz | Full duplex |
| Modulacija | Up to 256-QAM | Adaptive |
| Kapacitet | 10 Gbps | Full duplex |
| Tx snaga | +23 dBm (200 mW) | Solid-state |
| Antena | 0.6 m dish | 50 dBi gain |
| Beamwidth | 0.3° | Narrow, hard to jam |
| Domet | 5-15 km | Weather dependent |

## 3.3 Link Budget (E-band @ 10 km)

```
TRANSMITTER:
  Tx power:              +23 dBm
  Antenna gain:          +50 dBi
  EIRP:                  +73 dBm
  
CHANNEL (10 km):
  Free space loss:       -140 dB @ 80 GHz
  Rain (25 mm/h):        -50 dB (5 dB/km)
  Atmospheric O2:        -1.5 dB
  
RECEIVER:
  Antenna gain:          +50 dBi
  System noise:          -68 dBm (10 GHz BW)
  
LINK MARGIN:
  Received power:        -68.5 dBm
  Required SNR (256QAM): 27 dB
  Noise floor:           -68 dBm
  Available SNR:         -0.5 dB ❌ (rain degrades)
  
WITH ADAPTIVE MODULATION:
  QPSK @ -68.5 dBm:      SNR = 0 dB → OK for 2 Gbps
```

## 3.4 Vremenski utjecaj

| Kiša (mm/h) | Atenuacija | Max domet @ 10 Gbps | Max domet @ 1 Gbps |
|-------------|------------|---------------------|---------------------|
| 0 (dry) | 0.5 dB/km | 15 km | 25 km |
| 10 | 3 dB/km | 8 km | 15 km |
| 25 | 5 dB/km | 5 km | 10 km |
| 50 | 10 dB/km | 2 km | 5 km |

## 3.5 Komponente

| Komponenta | Model | Cijena | Dobavljač |
|------------|-------|--------|-----------|
| E-band radio | Siklu EH-8010FX | €15,000 | Siklu |
| Dish antenna | 0.6m integrated | €2,000 | Siklu |
| Mounting kit | Heavy duty | €500 | Various |
| **TOTAL per terminal** | | **€17,500** | |

---

# 4. TERTIARY: HF NVIS (Near Vertical Incidence Skywave)

## 4.1 Princip propagacije

```
                    IONOSFERA (F-sloj, 250-400 km)
    ════════════════════════════════════════════════════
              ╱╲              ╱╲              ╱╲
             ╱  ╲            ╱  ╲            ╱  ╲
            ╱    ╲          ╱    ╲          ╱    ╲
           ╱      ╲        ╱      ╲        ╱      ╲
          ╱        ╲      ╱        ╲      ╱        ╲
         ╱          ╲    ╱          ╲    ╱          ╲
    ────────────────────────────────────────────────────
        NODE A                              NODE B
        
    NVIS: Signal ide gotovo vertikalno gore,
          reflektira se od ionosfere,
          i pada gotovo vertikalno dolje.
          
    Domet: 0 - 500 km (skip zone minimal)
    Frekvencija: 3-10 MHz (dan/noć varijacija)
```

## 4.2 Specifikacije

| Parametar | Vrijednost | Komentar |
|-----------|------------|----------|
| Frekvencija | 3-10 MHz | ALE selects optimal |
| Bandwidth | 3 kHz (SSB) | Voice/data channel |
| Modem | MIL-STD-188-110D | 9.6 kbps max |
| Tx snaga | 100 W PEP | Solid-state |
| Antena | AS-2259/GR NVIS | Near-horizontal dipole |
| ALE | MIL-STD-188-141C | Automatic link establishment |
| Domet | 0-500 km | NVIS propagation |
| Encryption | AES-256 | TRANSEC |

## 4.3 Link Budget (HF NVIS @ 200 km)

```
TRANSMITTER:
  Tx power:              +50 dBm (100 W)
  Antenna gain:          +2 dBi (NVIS dipole)
  EIRP:                  +52 dBm
  
CHANNEL (ionospheric reflection):
  Ionospheric loss:      -10 dB (typical F-layer)
  Absorption (D-layer):  -5 dB (daytime)
  Fading margin:         -15 dB
  
RECEIVER:
  Antenna gain:          +2 dBi
  Noise floor:           -120 dBm (rural, 3 kHz BW)
  
RESULT:
  Received power:        +24 dBm
  Required SNR:          15 dB (for 9.6 kbps)
  Available SNR:         +24 - (-120) = 144 dB >> 15 dB ✓
  
MARGIN: Excellent (100+ dB)
```

## 4.4 Propagacija vs. doba dana

| Vrijeme | Optimalna frekv. | MUF | LUF | Status |
|---------|-----------------|-----|-----|--------|
| Dan (ljeto) | 7-10 MHz | 12 MHz | 5 MHz | ✅ |
| Dan (zima) | 5-8 MHz | 10 MHz | 3 MHz | ✅ |
| Noć (ljeto) | 3-5 MHz | 6 MHz | 2 MHz | ✅ |
| Noć (zima) | 3-4 MHz | 5 MHz | 2 MHz | ✅ |

ALE automatski bira optimalnu frekvenciju!

## 4.5 Komponente

| Komponenta | Model | Cijena | Dobavljač |
|------------|-------|--------|-----------|
| HF Transceiver | Harris RF-7800H-MP | €25,000 | L3Harris |
| HF Modem | Harris RF-5710A | €8,000 | L3Harris |
| NVIS Antenna | AS-2259/GR | €1,500 | DLA |
| Antenna tuner | LDG RT-600 | €500 | LDG |
| **TOTAL per node** | | **€35,000** | |

---

# 5. COMMUNICATION CONTROLLER

## 5.1 Arhitektura

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    COMMUNICATION CONTROLLER (FPGA + ARM)                    │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   ┌───────────────────────────────────────────────────────────────────┐    │
│   │                    ZYNQ ULTRASCALE+ (ZU+ 7EV)                      │    │
│   │                                                                    │    │
│   │   ┌─────────────┐  ┌─────────────┐  ┌─────────────┐               │    │
│   │   │ FSO PHY     │  │ E-BAND IF   │  │ HF MODEM IF │               │    │
│   │   │ 10GBASE-R   │  │ 10GBASE-R   │  │ UART 115.2k │               │    │
│   │   └──────┬──────┘  └──────┬──────┘  └──────┬──────┘               │    │
│   │          │                │                │                       │    │
│   │          └────────────────┴────────────────┘                       │    │
│   │                           │                                        │    │
│   │                  ┌────────┴────────┐                               │    │
│   │                  │  LINK ARBITER   │                               │    │
│   │                  │  (Programmable  │                               │    │
│   │                  │   Logic - PL)   │                               │    │
│   │                  └────────┬────────┘                               │    │
│   │                           │                                        │    │
│   │   ┌───────────────────────┴───────────────────────┐               │    │
│   │   │              PROTOCOL STACK (PS - ARM)         │               │    │
│   │   │                                                │               │    │
│   │   │  ┌─────────┐ ┌─────────┐ ┌─────────┐         │               │    │
│   │   │  │  TLS    │ │  QUIC   │ │ Protobuf│         │               │    │
│   │   │  │  1.3    │ │Transport│ │ Encode  │         │               │    │
│   │   │  └─────────┘ └─────────┘ └─────────┘         │               │    │
│   │   │                                                │               │    │
│   │   │  ┌─────────┐ ┌─────────┐ ┌─────────┐         │               │    │
│   │   │  │ AES-256 │ │  Mesh   │ │  Link   │         │               │    │
│   │   │  │   GCM   │ │ Routing │ │ Monitor │         │               │    │
│   │   │  └─────────┘ └─────────┘ └─────────┘         │               │    │
│   │   │                                                │               │    │
│   │   └────────────────────────────────────────────────┘               │    │
│   │                                                                    │    │
│   └────────────────────────────────────────────────────────────────────┘    │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

## 5.2 Failover logika

```python
# Pseudocode for link failover
class CommController:
    def __init__(self):
        self.links = {
            'FSO':    Link(priority=1, capacity=10e9, latency=0.001),
            'E-band': Link(priority=2, capacity=10e9, latency=0.001),
            'HF':     Link(priority=3, capacity=9.6e3, latency=0.1)
        }
        self.active_link = 'FSO'
        self.failover_threshold = 0.8  # 80% packet loss triggers failover
        
    def monitor_loop(self):
        while True:
            for name, link in self.links.items():
                link.check_status()  # Ping, measure BER, latency
                
            # Check if active link is degraded
            if self.links[self.active_link].packet_loss > self.failover_threshold:
                self.failover()
                
            # Check if better link is available
            if self.active_link != 'FSO' and self.links['FSO'].is_healthy():
                self.failback('FSO')
                
            time.sleep(0.1)  # 100 ms monitoring interval
            
    def failover(self):
        current_priority = self.links[self.active_link].priority
        for name, link in sorted(self.links.items(), key=lambda x: x[1].priority):
            if link.priority > current_priority and link.is_healthy():
                log(f"FAILOVER: {self.active_link} → {name}")
                self.active_link = name
                return
        log("WARNING: All links degraded!")
        
    def failback(self, target):
        log(f"FAILBACK: {self.active_link} → {target}")
        self.active_link = target
```

## 5.3 Vremena failovera

| Prijelaz | Tipično vrijeme | Max vrijeme |
|----------|-----------------|-------------|
| FSO → E-band | <100 ms | 500 ms |
| E-band → HF | <5 s | 30 s (ALE handshake) |
| HF → E-band | <500 ms | 2 s |
| E-band → FSO | <100 ms | 1 s (gimbal acquire) |

---

# 6. PROTOKOL STOG

```
┌────────────────────────────────────────────────────────────────┐
│ L7: APPLICATION                                                │
│     • TDOA measurements (Protobuf)                             │
│     • Track reports (Protobuf)                                 │
│     • Commands (JSON-RPC)                                      │
│     • Health/status (MQTT)                                     │
├────────────────────────────────────────────────────────────────┤
│ L6: PRESENTATION                                               │
│     • Protobuf serialization                                   │
│     • LZ4 compression (for bulk data)                          │
├────────────────────────────────────────────────────────────────┤
│ L5: SESSION                                                    │
│     • TLS 1.3 (mutual auth, PFS)                               │
│     • Session key rotation (hourly)                            │
├────────────────────────────────────────────────────────────────┤
│ L4: TRANSPORT                                                  │
│     • QUIC (primary - low latency, reliable)                   │
│     • UDP multicast (broadcast alerts)                         │
│     • TCP fallback (HF link)                                   │
├────────────────────────────────────────────────────────────────┤
│ L3: NETWORK                                                    │
│     • IPv6 (unique local addresses)                            │
│     • OSPF-like mesh routing                                   │
│     • Multipath support                                        │
├────────────────────────────────────────────────────────────────┤
│ L2: DATA LINK                                                  │
│     • FSO: Custom framing (10 Gbps)                            │
│     • E-band: Ethernet (10 GbE)                                │
│     • HF: HDLC-like framing (9.6 kbps)                         │
├────────────────────────────────────────────────────────────────┤
│ L1: PHYSICAL                                                   │
│     • FSO: 1550 nm laser, APD rx                               │
│     • E-band: 71-86 GHz, 256-QAM                               │
│     • HF: 3-10 MHz SSB, MIL-STD-188-110D                       │
└────────────────────────────────────────────────────────────────┘
```

---

# 7. SIGURNOST

## 7.1 Enkripcija

| Sloj | Algoritam | Ključ | Rotacija |
|------|-----------|-------|----------|
| Transport | AES-256-GCM | 256-bit | Hourly |
| Session | TLS 1.3 | ECDHE-P384 | Per-session |
| Link (HF) | AES-256-CTR | 256-bit | Daily |

## 7.2 Autentikacija

- **Mutual TLS**: Svaki čvor ima X.509 certifikat
- **Pre-shared keys**: Za HF backup (offline provisioning)
- **Certificate rotation**: Godišnje (s CRL)

## 7.3 Anti-jam mjere

| Kanal | Mjera | Efektivnost |
|-------|-------|-------------|
| FSO | LPI/LPD (narrow beam) | Excellent |
| E-band | Narrow beam (0.3°) | Very good |
| E-band | Adaptive power (+10 dB) | Good |
| HF | FHSS (MIL-STD-188-141C) | Good |
| HF | Burst transmission (<100 ms) | Good |

---

# 8. BOM (BILL OF MATERIALS)

## Per Node

| Stavka | Cijena | Komentar |
|--------|--------|----------|
| FSO Terminal | €28,500 | Laser + optics + gimbal |
| E-band Terminal | €17,500 | Siklu radio + dish |
| HF System | €35,000 | Harris radio + modem + antenna |
| Comm Controller | €8,000 | Zynq + carrier board |
| Cabling & misc | €3,000 | Fiber, coax, power |
| **TOTAL per node** | **€92,000** | |

## Full System (6 nodes)

| Stavka | Qty | Unit | Total |
|--------|-----|------|-------|
| FSO Terminals | 6 | €28,500 | €171,000 |
| E-band Terminals | 6 | €17,500 | €105,000 |
| HF Systems | 6 | €35,000 | €210,000 |
| Comm Controllers | 6 | €8,000 | €48,000 |
| Spares (10%) | - | - | €53,400 |
| Integration & test | - | - | €50,000 |
| **TOTAL COMM SYSTEM** | | | **€637,400** |

---

# 9. SAŽETAK

## Prednosti tri-modalne arhitekture

| Aspekt | Prednost |
|--------|----------|
| **Otpornost** | Tri nezavisna puta = visoka dostupnost |
| **LPI/LPD** | FSO ne emitira RF |
| **BLOS** | HF radi bez line-of-sight |
| **Kapacitet** | 10 Gbps omogućuje raw I/Q streaming |
| **Survivability** | Teško uništiti sva tri kanala |

## Matrica failovera

| Scenario | FSO | E-band | HF | Rezultat |
|----------|-----|--------|-----|----------|
| Vedro | ✅ | ✅ | ✅ | Full 10 Gbps |
| Magla | ❌ | ✅ | ✅ | Full 10 Gbps |
| Jaka kiša | ⚠️ | ⚠️ | ✅ | 1-10 Gbps |
| RF jamming | ✅ | ❌ | ❌ | 10 Gbps (FSO only) |
| All-spectrum attack | ⚠️ | ⚠️ | ⚠️ | Degraded |

---

**© 2026 Dr. Mladen Mešter - All Rights Reserved**
