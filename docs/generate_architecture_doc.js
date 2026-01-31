const { Document, Packer, Paragraph, TextRun, Table, TableRow, TableCell, 
        Header, Footer, AlignmentType, LevelFormat, HeadingLevel, 
        BorderStyle, WidthType, ShadingType, PageNumber, PageBreak,
        TableOfContents } = require('docx');
const fs = require('fs');

// Styles and helpers
const border = { style: BorderStyle.SINGLE, size: 1, color: "CCCCCC" };
const borders = { top: border, bottom: border, left: border, right: border };
const headerBorder = { style: BorderStyle.SINGLE, size: 1, color: "1F4E79" };
const headerBorders = { top: headerBorder, bottom: headerBorder, left: headerBorder, right: headerBorder };

function createParagraph(text, options = {}) {
    return new Paragraph({
        ...options,
        children: [new TextRun({ text, ...options.textOptions })]
    });
}

function createHeaderCell(text, width = 2000) {
    return new TableCell({
        borders: headerBorders,
        width: { size: width, type: WidthType.DXA },
        shading: { fill: "1F4E79", type: ShadingType.CLEAR },
        margins: { top: 80, bottom: 80, left: 120, right: 120 },
        children: [new Paragraph({ 
            children: [new TextRun({ text, bold: true, color: "FFFFFF", font: "Arial", size: 20 })]
        })]
    });
}

function createDataCell(text, width = 2000) {
    return new TableCell({
        borders,
        width: { size: width, type: WidthType.DXA },
        margins: { top: 60, bottom: 60, left: 100, right: 100 },
        children: [new Paragraph({ 
            children: [new TextRun({ text, font: "Arial", size: 20 })]
        })]
    });
}

// Document creation
const doc = new Document({
    styles: {
        default: { document: { run: { font: "Arial", size: 22 } } },
        paragraphStyles: [
            { id: "Heading1", name: "Heading 1", basedOn: "Normal", next: "Normal", quickFormat: true,
              run: { size: 32, bold: true, font: "Arial", color: "1F4E79" },
              paragraph: { spacing: { before: 400, after: 200 }, outlineLevel: 0 } },
            { id: "Heading2", name: "Heading 2", basedOn: "Normal", next: "Normal", quickFormat: true,
              run: { size: 26, bold: true, font: "Arial", color: "2E75B6" },
              paragraph: { spacing: { before: 300, after: 150 }, outlineLevel: 1 } },
            { id: "Heading3", name: "Heading 3", basedOn: "Normal", next: "Normal", quickFormat: true,
              run: { size: 24, bold: true, font: "Arial", color: "5B9BD5" },
              paragraph: { spacing: { before: 200, after: 100 }, outlineLevel: 2 } },
        ]
    },
    numbering: {
        config: [
            { reference: "bullets",
              levels: [{ level: 0, format: LevelFormat.BULLET, text: "•", alignment: AlignmentType.LEFT,
                style: { paragraph: { indent: { left: 720, hanging: 360 } } } }] },
        ]
    },
    sections: [{
        properties: {
            page: {
                size: { width: 11906, height: 16838 }, // A4
                margin: { top: 1440, right: 1080, bottom: 1440, left: 1080 }
            }
        },
        headers: {
            default: new Header({
                children: [new Paragraph({
                    alignment: AlignmentType.RIGHT,
                    children: [new TextRun({ text: "QEDMMA System Architecture v1.3 | PROPRIETARY", size: 18, color: "666666", font: "Arial" })]
                })]
            })
        },
        footers: {
            default: new Footer({
                children: [new Paragraph({
                    alignment: AlignmentType.CENTER,
                    children: [
                        new TextRun({ text: "Page ", size: 18, font: "Arial" }),
                        new TextRun({ children: [PageNumber.CURRENT], size: 18, font: "Arial" }),
                        new TextRun({ text: " of ", size: 18, font: "Arial" }),
                        new TextRun({ children: [PageNumber.TOTAL_PAGES], size: 18, font: "Arial" })
                    ]
                })]
            })
        },
        children: [
            // Title Page
            new Paragraph({ spacing: { after: 400 } }),
            new Paragraph({ spacing: { after: 400 } }),
            new Paragraph({
                alignment: AlignmentType.CENTER,
                children: [new TextRun({ text: "QEDMMA", size: 72, bold: true, color: "1F4E79", font: "Arial" })]
            }),
            new Paragraph({
                alignment: AlignmentType.CENTER,
                spacing: { after: 200 },
                children: [new TextRun({ text: "System Architecture Document", size: 36, color: "2E75B6", font: "Arial" })]
            }),
            new Paragraph({
                alignment: AlignmentType.CENTER,
                spacing: { after: 400 },
                children: [new TextRun({ text: "Version 1.3 \"Reality Check\"", size: 28, italics: true, font: "Arial" })]
            }),
            new Paragraph({
                alignment: AlignmentType.CENTER,
                children: [new TextRun({ text: "Quantum-Enhanced Distributed Metamaterial Multistatic Array", size: 24, font: "Arial" })]
            }),
            new Paragraph({
                alignment: AlignmentType.CENTER,
                spacing: { before: 100 },
                children: [new TextRun({ text: "Anti-Stealth Detection & Precision Weapon Guidance System", size: 22, italics: true, font: "Arial" })]
            }),
            new Paragraph({ spacing: { after: 800 } }),
            new Paragraph({
                alignment: AlignmentType.CENTER,
                children: [new TextRun({ text: "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━", size: 24, color: "1F4E79" })]
            }),
            new Paragraph({ spacing: { after: 400 } }),
            new Paragraph({
                alignment: AlignmentType.CENTER,
                children: [new TextRun({ text: "Document Classification: PROPRIETARY - EXPORT CONTROLLED", size: 20, bold: true, color: "C00000", font: "Arial" })]
            }),
            new Paragraph({
                alignment: AlignmentType.CENTER,
                spacing: { after: 200 },
                children: [new TextRun({ text: "Date: 31 January 2026", size: 20, font: "Arial" })]
            }),
            new Paragraph({
                alignment: AlignmentType.CENTER,
                children: [new TextRun({ text: "Prepared for: Dr. Mladen Mešter, Principal Investigator", size: 20, font: "Arial" })]
            }),
            new Paragraph({
                alignment: AlignmentType.CENTER,
                spacing: { after: 200 },
                children: [new TextRun({ text: "Author: Radar Systems Architect v9.0 - Forge Spec", size: 20, font: "Arial" })]
            }),
            
            // Page break
            new Paragraph({ children: [new PageBreak()] }),
            
            // Table of Contents
            new Paragraph({ heading: HeadingLevel.HEADING_1, children: [new TextRun("Table of Contents")] }),
            new TableOfContents("Table of Contents", { hyperlink: true, headingStyleRange: "1-3" }),
            
            new Paragraph({ children: [new PageBreak()] }),
            
            // Section 1: Executive Summary
            new Paragraph({ heading: HeadingLevel.HEADING_1, children: [new TextRun("1. Executive Summary")] }),
            
            new Paragraph({ heading: HeadingLevel.HEADING_2, children: [new TextRun("1.1 Mission Statement")] }),
            new Paragraph({
                spacing: { after: 200 },
                children: [new TextRun({ 
                    text: "QEDMMA is a revolutionary radar system designed for detection and tracking of \"invisible\" stealth platforms (aircraft, cruise missiles, drones) and precision guidance of defensive missiles to targets at long ranges (>150 km).",
                    font: "Arial", size: 22
                })]
            }),
            
            new Paragraph({ heading: HeadingLevel.HEADING_2, children: [new TextRun("1.2 Core Innovation")] }),
            new Paragraph({
                spacing: { after: 200 },
                children: [new TextRun({ 
                    text: "QEDMMA combines three disruptive technologies to defeat stealth:",
                    font: "Arial", size: 22
                })]
            }),
            
            // Innovation table
            new Table({
                width: { size: 100, type: WidthType.PERCENTAGE },
                columnWidths: [2500, 3000, 4000],
                rows: [
                    new TableRow({
                        children: [
                            createHeaderCell("Technology", 2500),
                            createHeaderCell("Advantage", 3000),
                            createHeaderCell("Why It Works Against Stealth", 4000)
                        ]
                    }),
                    new TableRow({
                        children: [
                            createDataCell("Bistatic VHF Radar", 2500),
                            createDataCell("RCS enhancement 10-30 dB", 3000),
                            createDataCell("Stealth is optimized for monostatic X-band, not VHF", 4000)
                        ]
                    }),
                    new TableRow({
                        children: [
                            createDataCell("Rydberg Quantum Sensor", 2500),
                            createDataCell("Sensitivity <500 nV/m/√Hz", 3000),
                            createDataCell("Detects signals below thermal noise floor", 4000)
                        ]
                    }),
                    new TableRow({
                        children: [
                            createDataCell("Distributed TDOA Network", 2500),
                            createDataCell("Precision <500 m", 3000),
                            createDataCell("No return signal to reveal position", 4000)
                        ]
                    })
                ]
            }),
            
            new Paragraph({ spacing: { after: 300 } }),
            
            new Paragraph({ heading: HeadingLevel.HEADING_2, children: [new TextRun("1.3 Key Performance Indicators")] }),
            
            new Table({
                width: { size: 100, type: WidthType.PERCENTAGE },
                columnWidths: [3500, 3000, 3000],
                rows: [
                    new TableRow({
                        children: [
                            createHeaderCell("Parameter", 3500),
                            createHeaderCell("Specification v1.3", 3000),
                            createHeaderCell("Notes", 3000)
                        ]
                    }),
                    new TableRow({ children: [createDataCell("Detection Range", 3500), createDataCell(">150 km (RCS 0.01 m²)", 3000), createDataCell("Bistatic link", 3000)] }),
                    new TableRow({ children: [createDataCell("Localization Accuracy", 3500), createDataCell("<500 m CEP", 3000), createDataCell("TDOA with 4+ nodes", 3000)] }),
                    new TableRow({ children: [createDataCell("Position Update Rate", 3500), createDataCell("1-5 Hz", 3000), createDataCell("SNR dependent", 3000)] }),
                    new TableRow({ children: [createDataCell("Track-While-Scan", 3500), createDataCell("50+ simultaneous targets", 3000), createDataCell("AI-enhanced tracker", 3000)] }),
                    new TableRow({ children: [createDataCell("Weapon Datalink Latency", 3500), createDataCell("<100 ms", 3000), createDataCell("UDP over tactical network", 3000)] }),
                ]
            }),
            
            new Paragraph({ children: [new PageBreak()] }),
            
            // Section 2: The Stealth Problem
            new Paragraph({ heading: HeadingLevel.HEADING_1, children: [new TextRun("2. The Stealth Problem: Why Current Radars Fail")] }),
            
            new Paragraph({ heading: HeadingLevel.HEADING_2, children: [new TextRun("2.1 How Stealth Technology Works")] }),
            new Paragraph({
                spacing: { after: 200 },
                children: [new TextRun({ 
                    text: "Stealth aircraft (F-22, F-35, Su-57, B-21) use a combination of techniques to reduce their Radar Cross Section (RCS):",
                    font: "Arial", size: 22
                })]
            }),
            
            new Paragraph({ numbering: { reference: "bullets", level: 0 }, children: [new TextRun({ text: "SHAPE: Flat surfaces at angles deflect radar away from transmitter", font: "Arial", size: 22 })] }),
            new Paragraph({ numbering: { reference: "bullets", level: 0 }, children: [new TextRun({ text: "RAM: Radar Absorbing Material converts RF energy to heat", font: "Arial", size: 22 })] }),
            new Paragraph({ numbering: { reference: "bullets", level: 0 }, children: [new TextRun({ text: "EDGE ALIGNMENT: All edges parallel to minimize scattering directions", font: "Arial", size: 22 })] }),
            new Paragraph({ numbering: { reference: "bullets", level: 0 }, children: [new TextRun({ text: "INTERNAL WEAPONS: No external stores for smooth surface", font: "Arial", size: 22 })] }),
            
            new Paragraph({
                spacing: { before: 200, after: 200 },
                children: [new TextRun({ 
                    text: "Result: F-22 has frontal RCS of ~0.0001-0.001 m² at X-band (10 GHz), equivalent to a metal sphere ~1 cm in diameter.",
                    font: "Arial", size: 22, bold: true
                })]
            }),
            
            new Paragraph({ heading: HeadingLevel.HEADING_2, children: [new TextRun("2.2 Why Conventional Radars Cannot See Stealth")] }),
            new Paragraph({
                spacing: { after: 200 },
                children: [new TextRun({ 
                    text: "The Radar Range Equation shows the fundamental problem. Range scales as RCS to the 1/4 power. If RCS drops 40 dB (stealth vs conventional), range drops by factor of 100×. A radar detecting conventional aircraft at 400 km will only see stealth at 4 km - when it's too late.",
                    font: "Arial", size: 22
                })]
            }),
            
            new Paragraph({ heading: HeadingLevel.HEADING_2, children: [new TextRun("2.3 Stealth's Achilles Heel")] }),
            new Paragraph({
                spacing: { after: 200 },
                children: [new TextRun({ 
                    text: "Stealth design has fundamental physical limitations that QEDMMA exploits:",
                    font: "Arial", size: 22
                })]
            }),
            
            new Table({
                width: { size: 100, type: WidthType.PERCENTAGE },
                columnWidths: [2500, 3500, 3500],
                rows: [
                    new TableRow({
                        children: [
                            createHeaderCell("Weakness", 2500),
                            createHeaderCell("Physical Reason", 3500),
                            createHeaderCell("QEDMMA Exploitation", 3500)
                        ]
                    }),
                    new TableRow({ children: [createDataCell("Frequency", 2500), createDataCell("RAM doesn't work at VHF (<300 MHz)", 3500), createDataCell("We use 100-200 MHz", 3500)] }),
                    new TableRow({ children: [createDataCell("Angle", 2500), createDataCell("Optimized only for frontal aspect", 3500), createDataCell("Bistatic angles expose weakness", 3500)] }),
                    new TableRow({ children: [createDataCell("Monostatic", 2500), createDataCell("Shaped for return to transmitter", 3500), createDataCell("Receiver is elsewhere", 3500)] }),
                ]
            }),
            
            new Paragraph({ children: [new PageBreak()] }),
            
            // Section 3: QEDMMA Solution
            new Paragraph({ heading: HeadingLevel.HEADING_1, children: [new TextRun("3. QEDMMA Solution: The Physics of \"Lighting Up\" Stealth")] }),
            
            new Paragraph({ heading: HeadingLevel.HEADING_2, children: [new TextRun("3.1 VHF Resonance Effect")] }),
            new Paragraph({
                spacing: { after: 200 },
                children: [new TextRun({ 
                    text: "When radar wavelength is comparable to aircraft dimensions, resonant scattering occurs. At VHF (100-200 MHz, λ=1.5-3 m), structural elements become resonant scatterers even with RAM coating. RCS enhancement factor: σ_VHF ≈ 30× σ_X-band (+15 dB).",
                    font: "Arial", size: 22
                })]
            }),
            
            new Paragraph({ heading: HeadingLevel.HEADING_2, children: [new TextRun("3.2 Bistatic RCS Advantage")] }),
            new Paragraph({
                spacing: { after: 200 },
                children: [new TextRun({ 
                    text: "In bistatic geometry, transmitter (Tx) and receiver (Rx) are at different locations. The bistatic RCS can be 10-20 dB higher than monostatic RCS at certain angles. Combined with VHF resonance: σ_bistatic,VHF ≈ 0.3-3 m² for stealth aircraft - comparable to conventional aircraft!",
                    font: "Arial", size: 22
                })]
            }),
            
            new Paragraph({ heading: HeadingLevel.HEADING_2, children: [new TextRun("3.3 Rydberg Quantum Sensing")] }),
            new Paragraph({
                spacing: { after: 200 },
                children: [new TextRun({ 
                    text: "Conventional RF receivers are limited by thermal noise at -174 dBm/Hz @ 290K. The Rydberg atomic sensor uses Electromagnetically Induced Transparency (EIT) in rubidium atoms for direct RF electric field measurement without antenna thermal noise. Sensitivity: 300-700 nV/m/√Hz - enabling detection of signals below classical noise floor.",
                    font: "Arial", size: 22
                })]
            }),
            
            new Table({
                width: { size: 100, type: WidthType.PERCENTAGE },
                columnWidths: [3200, 3200, 3100],
                rows: [
                    new TableRow({
                        children: [
                            createHeaderCell("Parameter", 3200),
                            createHeaderCell("Conventional Receiver", 3200),
                            createHeaderCell("Rydberg Sensor", 3100)
                        ]
                    }),
                    new TableRow({ children: [createDataCell("Noise Floor", 3200), createDataCell("-174 dBm/Hz", 3200), createDataCell("-190 dBm/Hz equivalent", 3100)] }),
                    new TableRow({ children: [createDataCell("Dynamic Range", 3200), createDataCell("60-80 dB", 3200), createDataCell("70+ dB", 3100)] }),
                    new TableRow({ children: [createDataCell("Self-Jamming", 3200), createDataCell("Yes (LNA saturation)", 3200), createDataCell("No (linear response)", 3100)] }),
                    new TableRow({ children: [createDataCell("Broadband", 3200), createDataCell("Limited by filters", 3200), createDataCell("1 MHz - 100 GHz", 3100)] }),
                ]
            }),
            
            new Paragraph({ children: [new PageBreak()] }),
            
            // Section 4: System Architecture
            new Paragraph({ heading: HeadingLevel.HEADING_1, children: [new TextRun("4. System Architecture Overview")] }),
            
            new Paragraph({
                spacing: { after: 200 },
                children: [new TextRun({ 
                    text: "The QEDMMA system consists of three major subsystems working in coordination:",
                    font: "Arial", size: 22
                })]
            }),
            
            new Paragraph({ numbering: { reference: "bullets", level: 0 }, children: [new TextRun({ text: "Rx Nodes (Quantum Receivers): 4+ distributed receivers with Rydberg sensors, metamaterial antennas, RFSoC processing, and precision timing", font: "Arial", size: 22 })] }),
            new Paragraph({ numbering: { reference: "bullets", level: 0 }, children: [new TextRun({ text: "Tx Node (VHF Illuminator): 5-10 kW transmitter with PRBS waveform, log-periodic antenna, and White Rabbit master timing", font: "Arial", size: 22 })] }),
            new Paragraph({ numbering: { reference: "bullets", level: 0 }, children: [new TextRun({ text: "C2 Fusion Center: GPU cluster for correlation, TDOA solving, tracking (EKF/IMM), and weapon guidance datalink", font: "Arial", size: 22 })] }),
            
            new Paragraph({ heading: HeadingLevel.HEADING_2, children: [new TextRun("4.1 Data Flow")] }),
            new Paragraph({
                spacing: { after: 200 },
                children: [new TextRun({ 
                    text: "1) Tx illuminates airspace with PRBS waveform at 100-200 MHz. 2) Target reflects signal toward distributed Rx nodes. 3) Each Rx captures timestamped samples via Rydberg sensor. 4) C2 center cross-correlates signals, extracts TDOA. 5) TDOA solver computes target position via hyperbolic intersection. 6) Kalman filter tracks target state. 7) Weapon datalink transmits guidance updates.",
                    font: "Arial", size: 22
                })]
            }),
            
            new Paragraph({ children: [new PageBreak()] }),
            
            // Section 5: Quantum Receiver
            new Paragraph({ heading: HeadingLevel.HEADING_1, children: [new TextRun("5. Subsystem Deep Dive: Quantum Receiver (Rx Node)")] }),
            
            new Paragraph({ heading: HeadingLevel.HEADING_2, children: [new TextRun("5.1 Rx Node Architecture")] }),
            new Paragraph({
                spacing: { after: 200 },
                children: [new TextRun({ 
                    text: "Each Rx node contains the following integrated subsystems:",
                    font: "Arial", size: 22
                })]
            }),
            
            new Table({
                width: { size: 100, type: WidthType.PERCENTAGE },
                columnWidths: [2500, 4000, 3000],
                rows: [
                    new TableRow({
                        children: [
                            createHeaderCell("Subsystem", 2500),
                            createHeaderCell("Key Components", 4000),
                            createHeaderCell("Function", 3000)
                        ]
                    }),
                    new TableRow({ children: [createDataCell("RF Front-End", 2500), createDataCell("Metamaterial array, BPF, LNA", 4000), createDataCell("Signal capture & amplification", 3000)] }),
                    new TableRow({ children: [createDataCell("Rydberg Sensor", 2500), createDataCell("780nm + 480nm lasers, Rb vapor cell, APD", 4000), createDataCell("Quantum RF detection", 3000)] }),
                    new TableRow({ children: [createDataCell("Signal Processing", 2500), createDataCell("Xilinx ZU47DR RFSoC, 5 GSPS ADC", 4000), createDataCell("Digitization & timestamp", 3000)] }),
                    new TableRow({ children: [createDataCell("Timing", 2500), createDataCell("White Rabbit LEN, CSAC SA.35m", 4000), createDataCell("Sub-ns synchronization", 3000)] }),
                    new TableRow({ children: [createDataCell("Edge AI", 2500), createDataCell("NVIDIA Jetson Orin AGX 64GB", 4000), createDataCell("Local detection & pre-track", 3000)] }),
                    new TableRow({ children: [createDataCell("Power/Enclosure", 2500), createDataCell("1500W MIL-spec PSU, 4U rugged case", 4000), createDataCell("Ruggedization & thermal", 3000)] }),
                ]
            }),
            
            new Paragraph({ heading: HeadingLevel.HEADING_2, children: [new TextRun("5.2 Rydberg Sensor Physics")] }),
            new Paragraph({
                spacing: { after: 200 },
                children: [new TextRun({ 
                    text: "The Rydberg EIT sensor uses a three-level atomic ladder in Rb-85. A 780nm probe laser couples the ground state (5S₁/₂) to intermediate state (5P₃/₂). A 480nm coupling laser excites atoms to a Rydberg state (nD₅/₂, n≈70). The RF field at VHF frequencies couples adjacent Rydberg states, creating measurable Autler-Townes splitting proportional to |E_RF|. Sensitivity at 150 MHz: ~500 nV/m/√Hz.",
                    font: "Arial", size: 22
                })]
            }),
            
            new Paragraph({ children: [new PageBreak()] }),
            
            // Section 9: TDOA Geolocation
            new Paragraph({ heading: HeadingLevel.HEADING_1, children: [new TextRun("9. TDOA Geolocation Algorithm")] }),
            
            new Paragraph({ heading: HeadingLevel.HEADING_2, children: [new TextRun("9.1 Geometry of the Problem")] }),
            new Paragraph({
                spacing: { after: 200 },
                children: [new TextRun({ 
                    text: "Time Difference of Arrival (TDOA) measurements define hyperbolic surfaces. Each receiver pair (i,j) produces one TDOA measurement: Δt_ij = (r_ti - r_tj) / c. This equation describes a hyperboloid with foci at receivers i and j. The intersection of multiple hyperboloids gives the target position. Minimum 3 receivers for 2D, 4+ for 3D localization.",
                    font: "Arial", size: 22
                })]
            }),
            
            new Paragraph({ heading: HeadingLevel.HEADING_2, children: [new TextRun("9.2 Chan-Ho Algorithm")] }),
            new Paragraph({
                spacing: { after: 200 },
                children: [new TextRun({ 
                    text: "QEDMMA uses the Chan-Ho closed-form TDOA solver followed by Gauss-Newton refinement. The algorithm linearizes the measurement equations, forms a geometry matrix G, and solves via weighted least squares. Covariance propagation provides uncertainty estimates. Typical computation time: <1 ms per solution on GPU.",
                    font: "Arial", size: 22
                })]
            }),
            
            new Paragraph({ heading: HeadingLevel.HEADING_2, children: [new TextRun("9.3 GDOP (Geometric Dilution of Precision)")] }),
            new Paragraph({
                spacing: { after: 200 },
                children: [new TextRun({ 
                    text: "Position accuracy depends on receiver geometry. GDOP = √(trace((H'H)⁻¹)). Optimal configuration: receivers form equilateral triangle/tetrahedron around target area. GDOP < 2: Ideal. GDOP 2-5: Good. GDOP 5-10: Moderate. GDOP > 10: Poor geometry, needs improvement.",
                    font: "Arial", size: 22
                })]
            }),
            
            new Paragraph({ children: [new PageBreak()] }),
            
            // Section 11: Weapon Guidance Interface
            new Paragraph({ heading: HeadingLevel.HEADING_1, children: [new TextRun("11. Weapon Guidance Interface")] }),
            
            new Paragraph({ heading: HeadingLevel.HEADING_2, children: [new TextRun("11.1 Track-to-Weapon Handoff Protocol")] }),
            new Paragraph({
                spacing: { after: 200 },
                children: [new TextRun({ 
                    text: "QEDMMA provides continuous target state updates to weapon systems via low-latency datalink. The track output message (MIL-STD-6016 compatible) includes: track_id, timestamp (ns), position_ecef (m), velocity_ecef (m/s), acceleration_ecef (m/s²), covariance matrix, track_quality (%), classification, and threat_level.",
                    font: "Arial", size: 22
                })]
            }),
            
            new Paragraph({ heading: HeadingLevel.HEADING_2, children: [new TextRun("11.2 Guidance Update Modes")] }),
            
            new Table({
                width: { size: 100, type: WidthType.PERCENTAGE },
                columnWidths: [3000, 3000, 3500],
                rows: [
                    new TableRow({
                        children: [
                            createHeaderCell("Mode", 3000),
                            createHeaderCell("Update Rate", 3000),
                            createHeaderCell("Accuracy Required", 3500)
                        ]
                    }),
                    new TableRow({ children: [createDataCell("ACQUISITION", 3000), createDataCell("1 Hz", 3000), createDataCell("< 5 km CEP", 3500)] }),
                    new TableRow({ children: [createDataCell("MIDCOURSE", 3000), createDataCell("5 Hz", 3000), createDataCell("< 1 km CEP", 3500)] }),
                    new TableRow({ children: [createDataCell("TERMINAL", 3000), createDataCell("10 Hz", 3000), createDataCell("< 100 m CEP", 3500)] }),
                ]
            }),
            
            new Paragraph({ heading: HeadingLevel.HEADING_2, children: [new TextRun("11.3 Engagement Sequence")] }),
            new Paragraph({
                spacing: { after: 200 },
                children: [new TextRun({ 
                    text: "T+0s: QEDMMA detects and establishes track. T+5s: Weapon receives initial target cue. T+10s: Missile launch. T+10s to T+120s: Midcourse guidance via QEDMMA datalink (5 Hz updates). T+120s: Terminal phase - missile seeker takes over (if lock achieved) OR QEDMMA continues guidance. T+150s: Intercept.",
                    font: "Arial", size: 22
                })]
            }),
            
            new Paragraph({ children: [new PageBreak()] }),
            
            // Section 12: Performance Specifications
            new Paragraph({ heading: HeadingLevel.HEADING_1, children: [new TextRun("12. Performance Specifications")] }),
            
            new Table({
                width: { size: 100, type: WidthType.PERCENTAGE },
                columnWidths: [3500, 3000, 3000],
                rows: [
                    new TableRow({
                        children: [
                            createHeaderCell("Parameter", 3500),
                            createHeaderCell("Specification", 3000),
                            createHeaderCell("Notes", 3000)
                        ]
                    }),
                    new TableRow({ children: [createDataCell("Frequency Band", 3500), createDataCell("100-200 MHz (VHF)", 3000), createDataCell("Optimized for Rydberg n≈70", 3000)] }),
                    new TableRow({ children: [createDataCell("Detection Range (RCS 1m²)", 3500), createDataCell(">150 km", 3000), createDataCell("Bistatic link budget", 3000)] }),
                    new TableRow({ children: [createDataCell("Detection Range (RCS 0.01m²)", 3500), createDataCell(">80 km", 3000), createDataCell("Stealth target", 3000)] }),
                    new TableRow({ children: [createDataCell("Localization Accuracy", 3500), createDataCell("<500 m CEP", 3000), createDataCell("4+ Rx nodes, GDOP<5", 3000)] }),
                    new TableRow({ children: [createDataCell("Time Synchronization", 3500), createDataCell("<1 ns", 3000), createDataCell("White Rabbit + CSAC", 3000)] }),
                    new TableRow({ children: [createDataCell("Track Update Rate", 3500), createDataCell("1-10 Hz", 3000), createDataCell("SNR dependent", 3000)] }),
                    new TableRow({ children: [createDataCell("Simultaneous Tracks", 3500), createDataCell("50+", 3000), createDataCell("GPU processing", 3000)] }),
                    new TableRow({ children: [createDataCell("Datalink Latency", 3500), createDataCell("<100 ms", 3000), createDataCell("Track to weapon", 3000)] }),
                    new TableRow({ children: [createDataCell("Dynamic Range", 3500), createDataCell(">70 dB", 3000), createDataCell("Rydberg linear response", 3000)] }),
                    new TableRow({ children: [createDataCell("Holdover Accuracy", 3500), createDataCell("<5 µs / 4h", 3000), createDataCell("Rb CSAC upgrade", 3000)] }),
                ]
            }),
            
            new Paragraph({ children: [new PageBreak()] }),
            
            // Section 14: Requirements Traceability
            new Paragraph({ heading: HeadingLevel.HEADING_1, children: [new TextRun("14. Requirements Traceability Matrix")] }),
            
            new Table({
                width: { size: 100, type: WidthType.PERCENTAGE },
                columnWidths: [1800, 3000, 2500, 2200],
                rows: [
                    new TableRow({
                        children: [
                            createHeaderCell("REQ-ID", 1800),
                            createHeaderCell("Requirement", 3000),
                            createHeaderCell("Design Element", 2500),
                            createHeaderCell("Verification", 2200)
                        ]
                    }),
                    new TableRow({ children: [createDataCell("REQ-DET-001", 1800), createDataCell("Detect RCS 0.01m² at >50km", 3000), createDataCell("VHF + Rydberg + Bistatic", 2500), createDataCell("Link budget analysis", 2200)] }),
                    new TableRow({ children: [createDataCell("REQ-DET-002", 1800), createDataCell("Pd>90% for RCS 1m² at 150km", 3000), createDataCell("5kW Tx, 1s integration", 2500), createDataCell("Monte Carlo sim", 2200)] }),
                    new TableRow({ children: [createDataCell("REQ-LOC-001", 1800), createDataCell("Position accuracy <500m CEP", 3000), createDataCell("TDOA with 4+ nodes", 2500), createDataCell("CRLB + field test", 2200)] }),
                    new TableRow({ children: [createDataCell("REQ-TRK-001", 1800), createDataCell("Track update 1-10 Hz", 3000), createDataCell("GPU processing, EKF/IMM", 2500), createDataCell("Benchmark", 2200)] }),
                    new TableRow({ children: [createDataCell("REQ-TIM-001", 1800), createDataCell("Time sync <1ns networked", 3000), createDataCell("White Rabbit protocol", 2500), createDataCell("PTP measurement", 2200)] }),
                    new TableRow({ children: [createDataCell("REQ-WPN-001", 1800), createDataCell("Datalink latency <100ms", 3000), createDataCell("UDP protocol, 25GbE", 2500), createDataCell("Network test", 2200)] }),
                    new TableRow({ children: [createDataCell("REQ-MOB-001", 1800), createDataCell("Setup time <30 minutes", 3000), createDataCell("Containerized design", 2500), createDataCell("Field exercise", 2200)] }),
                ]
            }),
            
            new Paragraph({ children: [new PageBreak()] }),
            
            // Final page - Document Control
            new Paragraph({ heading: HeadingLevel.HEADING_1, children: [new TextRun("Document Control")] }),
            
            new Table({
                width: { size: 100, type: WidthType.PERCENTAGE },
                columnWidths: [3000, 6500],
                rows: [
                    new TableRow({ children: [createDataCell("Version", 3000), createDataCell("1.3", 6500)] }),
                    new TableRow({ children: [createDataCell("Status", 3000), createDataCell("DRAFT - FOR INTERNAL REVIEW", 6500)] }),
                    new TableRow({ children: [createDataCell("Classification", 3000), createDataCell("PROPRIETARY - EXPORT CONTROLLED", 6500)] }),
                    new TableRow({ children: [createDataCell("Distribution", 3000), createDataCell("LIMITED - Principal Investigator & Authorized Personnel", 6500)] }),
                    new TableRow({ children: [createDataCell("Author", 3000), createDataCell("Radar Systems Architect v9.0 - Forge Spec", 6500)] }),
                    new TableRow({ children: [createDataCell("Date", 3000), createDataCell("31 January 2026", 6500)] }),
                ]
            }),
            
            new Paragraph({ spacing: { before: 400 } }),
            new Paragraph({
                alignment: AlignmentType.CENTER,
                children: [new TextRun({ text: "— END OF DOCUMENT —", size: 24, bold: true, color: "1F4E79", font: "Arial" })]
            }),
        ]
    }]
});

// Generate document
Packer.toBuffer(doc).then(buffer => {
    fs.writeFileSync('/home/claude/qedmma_forge/docs/QEDMMA_System_Architecture_v1.3.docx', buffer);
    console.log('QEDMMA System Architecture Document generated successfully!');
});
