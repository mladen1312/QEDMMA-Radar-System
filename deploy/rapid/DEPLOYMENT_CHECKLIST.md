# QEDMMA v3.4 - Rapid Deployment Checklist

**Target:** <10 minutes from arrival to operational  
**Author:** Dr. Mladen Mešter  
**Version:** 3.4.0

---

## ⏱️ Timeline Overview

| Phase | Duration | Cumulative | Description |
|-------|----------|------------|-------------|
| 1. Site Arrival | 0:00 | 0:00 | Vehicle positioned |
| 2. Power On | 0:30 | 0:30 | 48V DC or generator |
| 3. FPGA Boot | 1:00 | 1:30 | Bitstream load |
| 4. WR Sync | 2:00 | 3:30 | <100ps accuracy |
| 5. Self-Test | 0:30 | 4:00 | BIT complete |
| 6. Antenna Deploy | 4:00 | 8:00 | LPDA erected |
| 7. First Track | 2:00 | **10:00** | Operational |

---

## 📋 Pre-Deployment (Before Mission)

### Hardware
- [ ] SD cards flashed with latest Yocto image
- [ ] Bitstream verified on all nodes
- [ ] CSAC batteries charged (>90%)
- [ ] WR fiber cables tested
- [ ] Antenna elements secured

### Software
- [ ] Configuration files updated
- [ ] Node IPs assigned
- [ ] Encryption keys loaded
- [ ] Fusion geometry calibrated

### Logistics
- [ ] Site coordinates entered
- [ ] Communication links tested
- [ ] Power source confirmed
- [ ] Weather checked

---

## 🚀 Rapid Deployment Sequence

### Phase 1: Site Setup (0:00 - 0:30)
```
□ Position vehicle/container
□ Deploy power cables
□ Connect 48V DC (or start generator)
□ Verify green power LED on all nodes
```

### Phase 2: System Boot (0:30 - 1:30)
```
□ Power on all nodes simultaneously
□ Wait for boot complete LED (solid green)
□ Verify FPGA loaded (blue LED)
□ Check serial console if needed
```

### Phase 3: Network & Sync (1:30 - 3:30)
```
□ Connect WR fiber daisy-chain
□ Verify WR master lock (node1)
□ Wait for slave nodes to lock
□ Verify <100ps sync on all nodes
□ If WR fails: enable CSAC holdover
```

### Phase 4: Self-Test (3:30 - 4:00)
```
□ Run: ./rapid_deploy.sh --mode tactical
□ Verify all subsystems green
□ Check ADC noise floor
□ Verify DMA transfers
□ Confirm ECCM enabled
```

### Phase 5: Antenna Deployment (4:00 - 8:00)
```
□ Extend LPDA mast
□ Connect RF cables
□ Verify VSWR < 2:1
□ Set azimuth reference
□ Lock antenna position
```

### Phase 6: Operational (8:00 - 10:00)
```
□ Start radar daemon
□ Verify first detections
□ Confirm fusion data flow
□ Check Link-16/ASTERIX output
□ Report "OPERATIONAL" to C2
```

---

## 🔧 Troubleshooting

### WR Sync Failure
```bash
# Check WR status
wr_mon -g

# Force holdover mode
echo "holdover" > /sys/class/qedmma/csac/mode

# Restart WR daemon
systemctl restart wr-core
```

### FPGA Load Failure
```bash
# Check FPGA state
cat /sys/class/fpga_manager/fpga0/state

# Manual reload
echo "qedmma_v34.bit" > /sys/class/fpga_manager/fpga0/firmware
```

### No Detections
```bash
# Check ADC
cat /sys/class/qedmma/adc/status

# Check correlator
cat /sys/class/qedmma/correlator/chip_count

# Check threshold
cat /sys/class/qedmma/eccm/noise_estimate
```

---

## 📊 Success Criteria

| Metric | Target | Verification |
|--------|--------|--------------|
| Deployment time | <10 min | Stopwatch |
| WR sync | <100 ps | `wr_mon -g` |
| All nodes operational | 6/6 | Status LEDs |
| First track | <10 min | Fusion output |
| P_fa | <1e-4 | CFAR monitor |

---

## 🚨 Emergency Procedures

### Power Loss
1. CSAC maintains timing for 30 min
2. Critical data saved to eMMC
3. Auto-resume on power restore

### Node Failure
1. Fusion continues with N-1 nodes
2. Alert sent to C2
3. Hot spare activation (if available)

### Jamming Detected
1. Auto-switch to HOJ mode
2. Frequency agility enabled
3. Report jammer location

---

**QEDMMA v3.4 - Ready in <10 Minutes** 🚀
