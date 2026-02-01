# QEDMMA System Block Diagram
## Auto-generated from Repository Structure

**Generated:** 31 January 2026  
**Version:** 2.1.0 (v3.0 Ready)

---

## 1. Top-Level System Diagram

```mermaid
flowchart TB
    subgraph TX["🔴 TRANSMITTER NODE"]
        DDS[DDS/NCO<br/>14-bit DAC]
        PA[1 MW PA<br/>VHF 50-100 MHz]
        ANT_TX[Log-Periodic<br/>25 dBi]
        DDS --> PA --> ANT_TX
    end
    
    subgraph TARGETS["🎯 TARGET SPACE"]
        STEALTH[Stealth Aircraft<br/>σ = 0.0001 m²]
        JAMMER[Self-Protection<br/>Jammer 10-50 kW]
    end
    
    subgraph RX["🟢 QUANTUM RX ARRAY (6 nodes)"]
        RYD[Rydberg Vapor Cell<br/>Cs Atoms]
        PROBE[Probe Laser<br/>852 nm]
        COUPLE[Coupling Laser<br/>510 nm]
        LIA[Lock-In Amp<br/>FPGA]
        ADC[14-bit ADC<br/>250 MSPS]
        
        PROBE --> RYD
        COUPLE --> RYD
        RYD --> LIA --> ADC
    end
    
    subgraph FPGA["⚡ RFSoC PROCESSING (ZU47DR)"]
        direction TB
        subgraph DSP["DSP Pipeline"]
            DDC[DDC Core]
            MF[Matched Filter<br/>60 dB gain]
            RD[Range-Doppler<br/>FFT]
        end
        
        subgraph DET["Detection"]
            CFAR[ML-CFAR]
            TDOA[TDOA Engine<br/><100 ps]
        end
        
        subgraph ECCM_SUB["ECCM"]
            JAM_CLASS[Jammer<br/>Classifier]
            INT_CTRL[Adaptive<br/>Integration]
            HOJ[Home-on-Jam]
        end
        
        subgraph FUSION_SUB["Fusion"]
            EXT_ADAPT[External<br/>Adapter]
            FUSE_ENG[Fusion<br/>Engine]
            TRACK_DB[Track DB<br/>1024 tracks]
        end
        
        DDC --> MF --> RD --> CFAR
        CFAR --> TDOA --> FUSE_ENG
        CFAR --> JAM_CLASS --> INT_CTRL
        JAM_CLASS --> HOJ
        EXT_ADAPT --> FUSE_ENG --> TRACK_DB
    end
    
    subgraph COMM["📡 COMMUNICATIONS"]
        SAT[Satcom<br/>Primary]
        RF[LoS RF<br/>Secondary]
        HF[HF<br/>Tertiary]
        FAILOVER[Failover<br/>FSM]
        
        SAT & RF & HF --> FAILOVER
    end
    
    subgraph OUTPUTS["📤 OUTPUTS"]
        L16[Link 16<br/>JREAP-C]
        C2[C2 Interface<br/>gRPC]
        DISPLAY[Track<br/>Display]
    end
    
    ANT_TX -.->|Bistatic| STEALTH
    STEALTH -.->|Echo| RYD
    JAMMER -.->|Noise| RYD
    
    ADC --> DDC
    INT_CTRL -->|CPI Config| MF
    HOJ -->|Passive Track| FUSE_ENG
    
    TRACK_DB --> FAILOVER
    FAILOVER --> L16 & C2 & DISPLAY
    
    style STEALTH fill:#f96,stroke:#333
    style JAMMER fill:#f66,stroke:#333
    style RYD fill:#9f9,stroke:#333
    style CFAR fill:#69f,stroke:#333
    style FUSE_ENG fill:#69f,stroke:#333
```

---

## 2. RTL Module Hierarchy

```mermaid
flowchart TB
    subgraph TOP["qedmma_top.sv (Top Level)"]
        subgraph RX_CHAIN["Receive Chain"]
            timestamp[timestamp_capture.sv<br/>856 lines]
            ddc[ddc_core.sv<br/>~400 lines]
            mf[matched_filter.sv<br/>~350 lines]
        end
        
        subgraph DETECTION["Detection"]
            ml_cfar[ml_cfar_engine.sv<br/>553 lines]
            int_ctrl[integration_controller.sv<br/>309 lines]
        end
        
        subgraph ECCM_CTRL["ECCM Controller"]
            jam_loc[jammer_localizer.sv<br/>402 lines]
            eccm_top[eccm_controller.sv<br/>486 lines]
        end
        
        subgraph FUSION_CTRL["Fusion Controller"]
            ext_adapt[external_track_adapter.sv<br/>403 lines]
            fusion[track_fusion_engine.sv<br/>549 lines]
            track_db[track_database.sv<br/>357 lines]
        end
        
        subgraph EXT_IF["External Interfaces"]
            link16[link16_interface.sv<br/>461 lines]
            asterix[asterix_parser.sv<br/>506 lines]
        end
        
        subgraph COMM_CTRL["Communications"]
            comm_top[comm_controller_top.sv<br/>450 lines]
            failover[failover_fsm.sv<br/>300 lines]
            link_mon[link_monitor.sv<br/>~300 lines]
        end
    end
    
    timestamp --> ddc --> mf --> ml_cfar
    ml_cfar --> int_ctrl
    ml_cfar --> jam_loc --> eccm_top
    int_ctrl --> eccm_top
    
    ml_cfar --> fusion
    ext_adapt --> fusion --> track_db
    link16 --> ext_adapt
    asterix --> ext_adapt
    
    track_db --> comm_top
    link_mon --> failover --> comm_top
    
    style timestamp fill:#ffd,stroke:#333
    style ml_cfar fill:#dff,stroke:#333
    style fusion fill:#dff,stroke:#333
    style eccm_top fill:#fdf,stroke:#333
```

---

## 3. Data Flow Diagram

```mermaid
flowchart LR
    subgraph INPUTS["📥 INPUTS"]
        RF_IN[RF Signal<br/>VHF 50-100 MHz]
        PPS[1 PPS<br/>GPS/Rb]
        L16_IN[Link 16<br/>J2.2/J3.2]
        AST_IN[ASTERIX<br/>CAT048]
        IRST_IN[IRST<br/>AOA/Elevation]
        ESM_IN[ESM<br/>AOA/Frequency]
    end
    
    subgraph PROC["⚙️ PROCESSING"]
        SYNC[Time<br/>Sync]
        DSP[DSP<br/>Pipeline]
        DET[Detection<br/>ML-CFAR]
        ASSOC[Track<br/>Association]
        FUSE[State<br/>Fusion]
        MGMT[Track<br/>Management]
    end
    
    subgraph OUTPUTS["📤 OUTPUTS"]
        TRACKS[Fused<br/>Tracks]
        L16_OUT[Link 16<br/>J2.2 TX]
        HOJ_CUE[HOJ<br/>Cueing]
        STATS[Statistics<br/>Telemetry]
    end
    
    RF_IN --> DSP
    PPS --> SYNC --> DSP
    DSP --> DET --> ASSOC
    
    L16_IN --> ASSOC
    AST_IN --> ASSOC
    IRST_IN --> ASSOC
    ESM_IN --> ASSOC
    
    ASSOC --> FUSE --> MGMT --> TRACKS
    MGMT --> L16_OUT
    DET --> HOJ_CUE
    MGMT --> STATS
```

---

## 4. Register Map Architecture

```mermaid
flowchart TB
    subgraph AXI["AXI-Lite Bus"]
        AXI_M[ARM Cortex-A53<br/>PS Master]
    end
    
    subgraph REGS["Register Spaces"]
        subgraph TS_REGS["0x00010000<br/>Timestamp"]
            TS_CTRL[CTRL]
            TS_STATUS[STATUS]
            TS_FRAC[TIMESTAMP_FRAC]
        end
        
        subgraph FUSION_REGS["0x00020000<br/>Fusion"]
            FUS_CTRL[CTRL]
            FUS_CFG[ASSOC_CFG]
            FUS_STATS[STATISTICS]
        end
        
        subgraph ECCM_REGS["0x00030000<br/>ECCM"]
            ECCM_CTRL[CTRL]
            ECCM_THRESH[THRESHOLDS]
            ECCM_JAM[JAM_STATUS]
        end
        
        subgraph COMM_REGS["0x00040000<br/>Comm"]
            COMM_CTRL[CTRL]
            COMM_STATUS[STATUS]
            COMM_FAIL[FAILOVER]
        end
    end
    
    AXI_M --> TS_REGS & FUSION_REGS & ECCM_REGS & COMM_REGS
```

---

## 5. v3.0 Upgrade Path

```mermaid
flowchart LR
    subgraph V2["v2.1 (Current)"]
        LFM[LFM Waveform<br/>10 MHz BW]
        Q16[Q16.16<br/>Fixed Point]
        CLASS_RX[Classical RX<br/>T=290K]
    end
    
    subgraph V3["v3.0 (Planned)"]
        PRBS[PRBS Waveform<br/>200 Mchip/s]
        Q15[Q1.15 + Block FP<br/>Optimized]
        QUANTUM[Rydberg RX<br/>T=100K]
    end
    
    subgraph GAINS["Performance Gains"]
        BW_GAIN["+13 dB<br/>Process Gain"]
        FP_GAIN["<0.5 dB<br/>FP Loss"]
        Q_GAIN["+15-25 dB<br/>Quantum SNR"]
    end
    
    LFM --> PRBS --> BW_GAIN
    Q16 --> Q15 --> FP_GAIN
    CLASS_RX --> QUANTUM --> Q_GAIN
    
    style V3 fill:#9f9,stroke:#333
    style GAINS fill:#ffd,stroke:#333
```

---

## 6. Testbench Architecture

```mermaid
flowchart TB
    subgraph TB["Cocotb Testbenches"]
        subgraph UNIT["Unit Tests"]
            TB_FAIL[test_failover_fsm.py]
            TB_FUSION[test_track_fusion.py]
            TB_CFAR[test_ml_cfar.py]
        end
        
        subgraph SIM["Simulation"]
            VERILATOR[Verilator<br/>Lint + Sim]
            IVERILOG[Icarus<br/>Backup]
        end
        
        subgraph VALID["Validation"]
            TWIN[Fixed-Point<br/>Twin]
            LINKBUD[Link Budget<br/>Validation]
        end
    end
    
    subgraph CI["CI/CD Pipeline"]
        LINT[RTL Lint]
        COCOTB[Cocotb Run]
        PHYSICS[Physics Check]
        REPORT[Report Gen]
    end
    
    TB_FAIL & TB_FUSION & TB_CFAR --> VERILATOR
    VERILATOR --> COCOTB
    TWIN --> PHYSICS
    LINKBUD --> PHYSICS
    LINT --> COCOTB --> PHYSICS --> REPORT
```

---

## Summary Statistics

| Category | Count | Lines |
|----------|-------|-------|
| RTL Modules | 14 | 5,794 |
| Register YAMLs | 4 | ~1,200 |
| Testbenches | 3 | ~900 |
| Documentation | 8 | ~2,000 |
| **Total** | **29** | **~10,000** |

---

*Auto-generated from QEDMMA-Radar-System repository structure*
