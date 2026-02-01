//=============================================================================
// QEDMMA v3.2 - PISO Serializer + AXI-Stream Interface
// [REQ-PISO-001] Parallel-In Serial-Out for DMA transfer
// [REQ-AXI-001] AXI-Stream master interface
//
// Author: Dr. Mladen Mešter
// Copyright (c) 2026 - All Rights Reserved
//
// Converts 512 × 48-bit parallel results to sequential AXI-Stream
// Total: 512 lanes × 48 bits = 24,576 bits → 384 × 64-bit words
//=============================================================================

`timescale 1ns / 1ps

module qedmma_correlator_piso_axi #(
    parameter int NUM_LANES      = 512,
    parameter int ACC_WIDTH      = 48,
    parameter int AXI_DATA_WIDTH = 64
)(
    input  logic                          clk,
    input  logic                          rst_n,
    
    //=========================================================================
    // Parallel Input (from correlator bank)
    //=========================================================================
    input  logic [NUM_LANES*ACC_WIDTH-1:0] i_results_flat,
    input  logic                          i_results_valid,
    
    //=========================================================================
    // AXI-Stream Master Output
    //=========================================================================
    output logic [AXI_DATA_WIDTH-1:0]     m_axis_tdata,
    output logic                          m_axis_tvalid,
    output logic                          m_axis_tlast,
    output logic [3:0]                    m_axis_tkeep,
    input  logic                          m_axis_tready,
    
    //=========================================================================
    // Status
    //=========================================================================
    output logic                          o_busy,
    output logic [9:0]                    o_word_count
);

    //=========================================================================
    // Local Parameters
    //=========================================================================
    // Pack 48-bit values into 64-bit words
    // Option 1: 1 accumulator per word (48 bits data + 16 bits metadata)
    // Using Option 1 for simplicity
    localparam int TOTAL_WORDS = NUM_LANES;  // 512 words
    
    //=========================================================================
    // State Machine
    //=========================================================================
    typedef enum logic [1:0] {
        IDLE,
        LOAD,
        SERIALIZE,
        DONE
    } state_t;
    
    state_t state;
    
    //=========================================================================
    // Serialization Buffer
    //=========================================================================
    logic [ACC_WIDTH-1:0] buffer [NUM_LANES];
    logic [9:0] word_index;
    
    //=========================================================================
    // FSM
    //=========================================================================
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            word_index <= '0;
            m_axis_tvalid <= 1'b0;
            m_axis_tlast <= 1'b0;
            m_axis_tdata <= '0;
            
            for (int i = 0; i < NUM_LANES; i++) begin
                buffer[i] <= '0;
            end
        end else begin
            case (state)
                IDLE: begin
                    m_axis_tvalid <= 1'b0;
                    m_axis_tlast <= 1'b0;
                    word_index <= '0;
                    
                    if (i_results_valid) begin
                        // Load buffer from flat input
                        for (int i = 0; i < NUM_LANES; i++) begin
                            buffer[i] <= i_results_flat[(i+1)*ACC_WIDTH-1 -: ACC_WIDTH];
                        end
                        state <= LOAD;
                    end
                end
                
                LOAD: begin
                    state <= SERIALIZE;
                end
                
                SERIALIZE: begin
                    if (m_axis_tready || !m_axis_tvalid) begin
                        // Pack: [63:48]=lane_index, [47:0]=accumulator
                        m_axis_tdata <= {6'b0, word_index, buffer[word_index]};
                        m_axis_tvalid <= 1'b1;
                        m_axis_tkeep <= 4'b1111;
                        
                        if (word_index == NUM_LANES - 1) begin
                            m_axis_tlast <= 1'b1;
                            state <= DONE;
                        end else begin
                            m_axis_tlast <= 1'b0;
                            word_index <= word_index + 1;
                        end
                    end
                end
                
                DONE: begin
                    if (m_axis_tready) begin
                        m_axis_tvalid <= 1'b0;
                        m_axis_tlast <= 1'b0;
                        state <= IDLE;
                    end
                end
                
                default: state <= IDLE;
            endcase
        end
    end
    
    assign o_busy = (state != IDLE);
    assign o_word_count = word_index;

endmodule
