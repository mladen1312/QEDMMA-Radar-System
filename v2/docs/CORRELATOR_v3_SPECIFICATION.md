# QEDMMA v3.0 Correlator Specification
## 200 Mchip/s PRBS Waveform Engine

**Document:** QEDMMA-CORR-SPEC-001  
**Version:** 3.0.0  
**Date:** 1 February 2026  
**Author:** Dr. Mladen Mešter

---

## 1. Requirements [REQ-CORRELATOR-*]

### 1.1 Performance Requirements

| REQ-ID | Requirement | Value | Rationale |
|--------|-------------|-------|-----------|
| REQ-CORR-001 | Chip rate | 200 Mchip/s | Max processing gain |
| REQ-CORR-002 | Code length | 2047-65535 chips | Range resolution vs ambiguity |
| REQ-CORR-003 | Processing gain | 33-48 dB | 10×log₁₀(code_length) |
| REQ-CORR-004 | Correlation latency | <100 µs | Real-time tracking |
| REQ-CORR-005 | Peak sidelobe ratio | <-13 dB (BPSK), <-21 dB (Gold) | False target rejection |
| REQ-CORR-006 | Doppler tolerance | ±50 kHz | High-speed target support |
| REQ-CORR-007 | Fixed-point format | Q1.15 (16-bit) | Per twin validation |

### 1.2 Interface Requirements

| REQ-ID | Requirement | Description |
|--------|-------------|-------------|
| REQ-CORR-010 | ADC interface | 16-bit @ 250 MSPS (JESD204B) |
| REQ-CORR-011 | PRBS output | 1-bit @ 200 MHz to DAC |
| REQ-CORR-012 | Correlation output | 32-bit magnitude² per range bin |
| REQ-CORR-013 | AXI-Lite control | Register interface @ 100 MHz |
| REQ-CORR-014 | AXI-Stream data | 256-bit wide @ 200 MHz |

### 1.3 Resource Requirements

| REQ-ID | Requirement | Target (ZU47DR) |
|--------|-------------|-----------------|
| REQ-CORR-020 | DSP48E2 usage | <256 (15% of 1728) |
| REQ-CORR-021 | BRAM usage | <64 (6% of 1080) |
| REQ-CORR-022 | LUT usage | <50,000 (12% of 425k) |
| REQ-CORR-023 | Timing closure | 200 MHz (5 ns period) |

---

## 2. Mathematical Foundation

### 2.1 PRBS Generation

Maximum Length Sequence (m-sequence) from LFSR:

$$a_n = a_{n-p_1} \oplus a_{n-p_2} \oplus ... \oplus a_{n-p_k}$$

Where $p_i$ are feedback tap positions.

**Supported sequences:**

| Type | Length | Polynomial | Taps |
|------|--------|------------|------|
| PRBS-11 | 2047 | $x^{11} + x^2 + 1$ | [11, 2] |
| PRBS-15 | 32767 | $x^{15} + x^{14} + 1$ | [15, 14] |
| PRBS-20 | 1048575 | $x^{20} + x^3 + 1$ | [20, 3] |
| Gold-11 | 2047 | Two PRBS-11 XOR'd | Configurable |

### 2.2 Correlation

Sliding window correlation:

$$R_{xy}[n] = \sum_{k=0}^{N-1} x[k] \cdot y^*[k-n]$$

For BPSK (+1/-1), this simplifies to:

$$R[n] = \sum_{k=0}^{N-1} x[k] \cdot c[k-n]$$

Where $c[k] \in \{-1, +1\}$ is the reference code.

### 2.3 Processing Gain

$$G_p = 10 \cdot \log_{10}(N_{chips})$$

| Code Length | Processing Gain |
|-------------|-----------------|
| 2047 | 33.1 dB |
| 8191 | 39.1 dB |
| 32767 | 45.2 dB |
| 65535 | 48.2 dB |

### 2.4 Range Resolution

$$\Delta R = \frac{c}{2 \cdot f_{chip}} = \frac{3 \times 10^8}{2 \times 200 \times 10^6} = 0.75 \text{ m}$$

### 2.5 Unambiguous Range

$$R_{max} = \frac{c \cdot N_{chips}}{2 \cdot f_{chip}} = \frac{3 \times 10^8 \times 2047}{2 \times 200 \times 10^6} = 1535 \text{ km}$$

---

## 3. Architecture

### 3.1 Block Diagram

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    CORRELATOR ENGINE (200 Mchip/s)                       │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐              │
│  │    PRBS      │    │   PARALLEL   │    │    PEAK     │              │
│  │  GENERATOR   │───▶│  CORRELATOR  │───▶│  DETECTOR   │──▶ Detections│
│  │  (LFSR×8)    │    │   (8 lanes)  │    │  (CFAR)     │              │
│  └──────────────┘    └──────────────┘    └──────────────┘              │
│         │                   ▲                                           │
│         ▼                   │                                           │
│  ┌──────────────┐    ┌──────────────┐                                  │
│  │     DAC      │    │     ADC      │                                  │
│  │   OUTPUT     │    │    INPUT     │◀── RF Signal                     │
│  │  (1-bit TX)  │    │  (16-bit RX) │                                  │
│  └──────────────┘    └──────────────┘                                  │
│                                                                          │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │                     CONTROL & REGISTERS                           │  │
│  │  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐             │  │
│  │  │ PRBS    │  │ TIMING  │  │ DOPPLER │  │ STATS   │             │  │
│  │  │ CONFIG  │  │ CONTROL │  │ COMP    │  │ COUNTERS│             │  │
│  │  └─────────┘  └─────────┘  └─────────┘  └─────────┘             │  │
│  └──────────────────────────────────────────────────────────────────┘  │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### 3.2 Parallel Processing Strategy

At 200 Mchip/s with 200 MHz FPGA clock:
- **8 parallel lanes** process 8 chips per clock cycle
- Each lane: 16-bit × 16-bit MAC → 32-bit accumulator
- DSP48E2 cascade for efficient accumulation

```
Lane 0: chips[0], chips[8], chips[16], ...
Lane 1: chips[1], chips[9], chips[17], ...
...
Lane 7: chips[7], chips[15], chips[23], ...
```

### 3.3 Memory Architecture

| Memory | Size | Purpose |
|--------|------|---------|
| Code BRAM | 8K × 8-bit | PRBS reference storage |
| Sample BRAM | 64K × 16-bit | ADC sample buffer (circular) |
| Correlation BRAM | 4K × 32-bit | Output magnitude² |

---

## 4. Fixed-Point Analysis

### 4.1 Q-Format Selection

Per /twin simulation results:

| Stage | Format | Bits | Dynamic Range |
|-------|--------|------|---------------|
| ADC input | Q1.15 | 16 | 90 dB |
| PRBS code | Q1.0 | 1 | N/A (±1) |
| Multiply | Q2.30 | 32 | 180 dB |
| Accumulator | Q16.32 | 48 | DSP48 native |
| Output | Q16.16 | 32 | 96 dB |

### 4.2 Overflow Protection

- Accumulator guard bits: 16 (for 65535 chip codes)
- Saturation logic on final output
- Overflow counter for diagnostics

---

## 5. Implementation Plan

| Module | Lines (est.) | Priority |
|--------|--------------|----------|
| prbs_generator.sv | 200 | P1 |
| parallel_correlator.sv | 400 | P1 |
| correlation_accumulator.sv | 250 | P1 |
| peak_detector.sv | 200 | P2 |
| doppler_compensator.sv | 300 | P2 |
| correlator_top.sv | 350 | P1 |
| **Total** | **~1700** | |

---

## 6. Verification Plan

| Test | Description | Coverage |
|------|-------------|----------|
| PRBS autocorrelation | Verify peak = N, sidelobes = -1 | Functional |
| Processing gain | Measure SNR improvement | Performance |
| Timing | 200 MHz closure | Timing |
| Resource | DSP48/BRAM utilization | Resource |

---

*Document Control: QEDMMA-CORR-SPEC-001 Rev A*
