# QEDMMA v3.0 SoC Architecture

## Block Diagram

```
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│                           QEDMMA v3.0 TOP-LEVEL SoC                                     │
│                           (qedmma_v3_top.sv - 673 lines)                                │
├─────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                         │
│   ┌─────────────────────────────────────────────────────────────────────────────────┐   │
│   │                            CLOCK INFRASTRUCTURE                                  │   │
│   │   ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐          │   │
│   │   │ clk_sys  │  │ clk_eth  │  │ clk_prbs │  │ clk_ref  │  │ eth_rx   │          │   │
│   │   │ 200 MHz  │  │ 125 MHz  │  │  25 MHz  │  │ 10 MHz   │  │  _clk    │          │   │
│   │   └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘          │   │
│   └────────┼─────────────┼─────────────┼─────────────┼─────────────┼────────────────┘   │
│            │             │             │             │             │                     │
│   ┌────────▼─────────────▼─────────────▼─────────────▼─────────────▼────────────────┐   │
│   │                        AXI INTERCONNECT (Address Decoder)                        │   │
│   │  ┌─────────────────────────────────────────────────────────────────────────┐    │   │
│   │  │  0x50000: CORRELATOR │ 0x60000: FUSION │ 0x70000: ECCM │ 0x80000: COMM  │    │   │
│   │  │  0x90000: WR_PTP │ 0xA0000: QUANTUM_RX │ 0xF0000: SYSTEM                │    │   │
│   │  └─────────────────────────────────────────────────────────────────────────┘    │   │
│   └──────────────────────────────────────────────────────────────────────────────────┘   │
│            │             │             │             │             │                     │
│   ┌────────▼─────────┐ ┌─▼───────────┐ ┌──────▼─────┐ ┌──────▼─────┐ ┌────────▼────┐   │
│   │   CORRELATOR     │ │   FUSION    │ │    ECCM    │ │    COMM    │ │WHITE RABBIT │   │
│   │   200 Mchip/s    │ │  Multi-Sensorr│ │ AI-Enhanced│ │  Tri-Modal │ │    PTP      │   │
│   │   ┌───────────┐  │ │  ┌────────┐ │ │ ┌────────┐ │ │ ┌────────┐ │ │ ┌────────┐ │   │
│   │   │ PRBS Gen  │  │ │  │IMM Filt│ │ │ │ML CFAR │ │ │ │Link-16 │ │ │ │ Servo  │ │   │
│   │   │ 11/15/20  │  │ │  │CV/CA/CT│ │ │ │ Engine │ │ │ │ Parser │ │ │ │  Loop  │ │   │
│   │   └─────┬─────┘  │ │  └───┬────┘ │ │ └───┬────┘ │ │ └───┬────┘ │ │ └───┬────┘ │   │
│   │   ┌─────▼─────┐  │ │  ┌───▼────┐ │ │ ┌───▼────┐ │ │ ┌───▼────┐ │ │ ┌───▼────┐ │   │
│   │   │8-Lane Corr│  │ │  │ Track  │ │ │ │ DRFM   │ │ │ │  HF    │ │ │ │ DMTD   │ │   │
│   │   │  Engine   │  │ │  │Database│ │ │ │Detector│ │ │ │ ALE    │ │ │ │ Phase  │ │   │
│   │   └─────┬─────┘  │ │  └───┬────┘ │ │ └───┬────┘ │ │ └───┬────┘ │ │ └───┬────┘ │   │
│   │   ┌─────▼─────┐  │ │  ┌───▼────┐ │ │ ┌───▼────┐ │ │ ┌───▼────┐ │ │ ┌───▼────┐ │   │
│   │   │ Detection │  │ │  │ Output │ │ │ │Jammer  │ │ │ │SATCOM  │ │ │ │  ToA   │ │   │
│   │   │ Threshold │  │ │  │Formatter│ │ │ │Localiz │ │ │ │ Bridge │ │ │ │Capture │ │   │
│   │   └───────────┘  │ │  └────────┘ │ │ └────────┘ │ │ └────────┘ │ │ └────────┘ │   │
│   │                  │ │             │ │            │ │            │ │            │   │
│   │  788 lines RTL   │ │ 2276 lines  │ │1750 lines  │ │1050 lines  │ │ 780 lines  │   │
│   │  +45 dB gain     │ │1024 tracks  │ │ +7 dB ECCM │ │ <100ms     │ │ <100 ps    │   │
│   └──────────────────┘ └─────────────┘ └────────────┘ └────────────┘ └────────────┘   │
│            │                  │               │               │              │         │
│            │                  │               │               │              │         │
│            ▼                  ▼               ▼               ▼              ▼         │
│   ┌─────────────────────────────────────────────────────────────────────────────────┐   │
│   │                         EXTERNAL INTERFACES                                      │   │
│   │  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐        │   │
│   │  │ AXI-S   │ │ AXI-S   │ │ AXI-S   │ │ Link-16 │ │ HF/     │ │ Ethernet│        │   │
│   │  │ ADC IN  │ │ DAC OUT │ │ Track   │ │ JTIDS   │ │ SATCOM  │ │ WR PTP  │        │   │
│   │  │ 256-bit │ │ 64-bit  │ │ 128-bit │ │ 16-bit  │ │ 32-bit  │ │ GMII    │        │   │
│   │  └─────────┘ └─────────┘ └─────────┘ └─────────┘ └─────────┘ └─────────┘        │   │
│   └─────────────────────────────────────────────────────────────────────────────────┘   │
│                                                                                         │
│   ┌─────────────────────────────────────────────────────────────────────────────────┐   │
│   │                              STATUS & DEBUG                                      │   │
│   │    led_status[7:0] │ debug_port[31:0] │ irq_detection │ irq_track │ irq_wr      │   │
│   └─────────────────────────────────────────────────────────────────────────────────┘   │
│                                                                                         │
└─────────────────────────────────────────────────────────────────────────────────────────┘
```

## Address Map

| Base Address | Size | Subsystem | Description |
|--------------|------|-----------|-------------|
| 0x0005_0000 | 64KB | Correlator | 200 Mchip/s PRBS correlator |
| 0x0006_0000 | 64KB | Fusion | Multi-sensor track fusion |
| 0x0007_0000 | 64KB | ECCM | AI-enhanced ECCM controller |
| 0x0008_0000 | 64KB | Comm | Tri-modal communication |
| 0x0009_0000 | 64KB | White Rabbit | PTP synchronization |
| 0x000A_0000 | 64KB | Quantum RX | Rydberg receiver interface |
| 0x000F_0000 | 64KB | System | System control & status |

## Clock Domains

| Clock | Frequency | Domain | Purpose |
|-------|-----------|--------|---------|
| clk_sys | 200 MHz | Processing | Main signal processing |
| clk_eth | 125 MHz | Ethernet | White Rabbit PTP |
| clk_prbs | 25 MHz | Correlator | ×8 = 200 Mchip/s |
| clk_ref | 10 MHz | Reference | VCXO reference |
| eth_rx_clk | 125 MHz | RX | Recovered Ethernet clock |

## Resource Utilization (ZU47DR)

| Resource | Used | Available | % |
|----------|------|-----------|---|
| LUT | ~42,000 | 425,280 | 9.9% |
| FF | ~35,000 | 850,560 | 4.1% |
| BRAM | ~92 | 1,080 | 8.5% |
| DSP48E2 | ~86 | 1,728 | 5.0% |
| URAM | ~8 | 80 | 10.0% |

## Interrupt Sources

| IRQ | Source | Description |
|-----|--------|-------------|
| irq_detection | Correlator | New radar detection |
| irq_track_update | Fusion | Track state update |
| irq_comm_event | Comm | Link status change |
| irq_wr_lock | White Rabbit | Sync lock acquired |

## Data Flow

1. **ADC → Correlator**: 256-bit AXI-Stream (8×32-bit I/Q @ 200 MSPS)
2. **Correlator → Fusion**: Detection reports (range, azimuth, magnitude)
3. **External → Fusion**: Link-16, ASTERIX, ESM, IRST tracks
4. **Fusion → ECCM**: Validated tracks for classification
5. **ECCM → Track Output**: Filtered tracks with ECCM status
6. **Track → Comm**: Tracks for dissemination via Link-16/HF/SATCOM

