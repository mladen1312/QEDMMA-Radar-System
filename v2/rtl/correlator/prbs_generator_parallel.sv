//-----------------------------------------------------------------------------
// QEDMMA v3.0 - Parallel PRBS Generator
// Author: Dr. Mladen Mešter
// Copyright (c) 2026 - All Rights Reserved
//
// [REQ-CORR-001] 200 Mchip/s PRBS generation
// [REQ-CORR-002] PRBS-11/15/20 and Gold code support
//
// Description:
//   Generates 8 PRBS chips per clock cycle for 200 Mchip/s @ 25 MHz
//   Uses parallel LFSR architecture for maximum throughput.
//-----------------------------------------------------------------------------

`timescale 1ns / 1ps

module prbs_generator_parallel #(
    parameter int PARALLEL_WIDTH = 8,
    parameter int MAX_LFSR_LEN   = 20,
    parameter int COUNTER_WIDTH  = 20
)(
    input  logic                      clk,
    input  logic                      rst_n,
    
    // Control
    input  logic                      enable,
    input  logic                      sync_reset,
    input  logic [1:0]                code_type,        // 0=PRBS-11, 1=PRBS-15, 2=PRBS-20, 3=Gold
    input  logic [MAX_LFSR_LEN-1:0]   seed_primary,
    input  logic [MAX_LFSR_LEN-1:0]   seed_secondary,
    
    // Output
    output logic [PARALLEL_WIDTH-1:0] prbs_out,
    output logic                      prbs_valid,
    output logic [COUNTER_WIDTH-1:0]  chip_count,
    output logic                      sequence_wrap
);

    //=========================================================================
    // LFSR State Registers
    //=========================================================================
    logic [MAX_LFSR_LEN-1:0] lfsr_a;
    logic [MAX_LFSR_LEN-1:0] lfsr_b;
    logic [MAX_LFSR_LEN-1:0] lfsr_a_next;
    logic [MAX_LFSR_LEN-1:0] lfsr_b_next;
    
    //=========================================================================
    // Code Length Parameters
    //=========================================================================
    logic [COUNTER_WIDTH-1:0] code_length;
    
    always_comb begin
        case (code_type)
            2'b00: code_length = 20'd2047;      // PRBS-11
            2'b01: code_length = 20'd32767;     // PRBS-15
            2'b10: code_length = 20'd1048575;   // PRBS-20
            2'b11: code_length = 20'd2047;      // Gold-11
            default: code_length = 20'd2047;
        endcase
    end
    
    //=========================================================================
    // Feedback Functions
    //=========================================================================
    function automatic logic feedback_a(
        input logic [MAX_LFSR_LEN-1:0] lfsr,
        input logic [1:0] ctype
    );
        case (ctype)
            2'b00: return lfsr[10] ^ lfsr[1];           // PRBS-11
            2'b01: return lfsr[14] ^ lfsr[13];          // PRBS-15
            2'b10: return lfsr[19] ^ lfsr[2];           // PRBS-20
            2'b11: return lfsr[10] ^ lfsr[1];           // Gold primary
            default: return lfsr[10] ^ lfsr[1];
        endcase
    endfunction
    
    function automatic logic feedback_b(
        input logic [MAX_LFSR_LEN-1:0] lfsr
    );
        // Gold secondary: x^11 + x^8 + x^5 + x^2 + 1
        return lfsr[10] ^ lfsr[7] ^ lfsr[4] ^ lfsr[1];
    endfunction
    
    //=========================================================================
    // Parallel LFSR Advance (8 steps at once)
    //=========================================================================
    logic [PARALLEL_WIDTH-1:0] parallel_bits_a;
    logic [PARALLEL_WIDTH-1:0] parallel_bits_b;
    logic [MAX_LFSR_LEN-1:0] lfsr_a_temp [PARALLEL_WIDTH+1];
    logic [MAX_LFSR_LEN-1:0] lfsr_b_temp [PARALLEL_WIDTH+1];
    
    always_comb begin
        lfsr_a_temp[0] = lfsr_a;
        lfsr_b_temp[0] = lfsr_b;
        
        for (int i = 0; i < PARALLEL_WIDTH; i++) begin
            parallel_bits_a[i] = lfsr_a_temp[i][0];
            parallel_bits_b[i] = lfsr_b_temp[i][0];
            
            lfsr_a_temp[i+1] = {feedback_a(lfsr_a_temp[i], code_type), lfsr_a_temp[i][MAX_LFSR_LEN-1:1]};
            lfsr_b_temp[i+1] = {feedback_b(lfsr_b_temp[i]), lfsr_b_temp[i][MAX_LFSR_LEN-1:1]};
        end
        
        lfsr_a_next = lfsr_a_temp[PARALLEL_WIDTH];
        lfsr_b_next = lfsr_b_temp[PARALLEL_WIDTH];
    end
    
    //=========================================================================
    // LFSR State Update
    //=========================================================================
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            lfsr_a <= {MAX_LFSR_LEN{1'b1}};
            lfsr_b <= {MAX_LFSR_LEN{1'b1}};
            chip_count <= '0;
            sequence_wrap <= 1'b0;
        end else if (sync_reset) begin
            lfsr_a <= (seed_primary == '0) ? {MAX_LFSR_LEN{1'b1}} : seed_primary;
            lfsr_b <= (seed_secondary == '0) ? {MAX_LFSR_LEN{1'b1}} : seed_secondary;
            chip_count <= '0;
            sequence_wrap <= 1'b0;
        end else if (enable) begin
            lfsr_a <= lfsr_a_next;
            lfsr_b <= lfsr_b_next;
            
            if (chip_count + PARALLEL_WIDTH >= code_length) begin
                chip_count <= chip_count + PARALLEL_WIDTH - code_length;
                sequence_wrap <= 1'b1;
            end else begin
                chip_count <= chip_count + PARALLEL_WIDTH;
                sequence_wrap <= 1'b0;
            end
        end else begin
            sequence_wrap <= 1'b0;
        end
    end
    
    //=========================================================================
    // Output
    //=========================================================================
    always_comb begin
        if (code_type == 2'b11) begin
            prbs_out = parallel_bits_a ^ parallel_bits_b;  // Gold code
        end else begin
            prbs_out = parallel_bits_a;
        end
    end
    
    assign prbs_valid = enable;

endmodule
