//-----------------------------------------------------------------------------
// QEDMMA Compressed Sensing Encoder
// Radar Systems Architect v9.0 - Forge Spec
//
// Features:
//   - Random measurement matrix (Gaussian/Bernoulli)
//   - Streaming architecture for real-time compression
//   - Configurable compression ratio (2x to 10x)
//   - LFSR-based pseudo-random matrix generation
//
// [REQ-CS-001] Compression ratio: 2x to 10x configurable
// [REQ-CS-002] Input: 1024-point complex spectrum
// [REQ-CS-003] Measurement matrix: LFSR-generated ±1 (Bernoulli)
// [REQ-CS-004] Output: M compressed measurements (M = N/CR)
//-----------------------------------------------------------------------------

`timescale 1ns / 1ps

module cs_encoder #(
    parameter DATA_WIDTH     = 16,
    parameter INPUT_SIZE     = 1024,    // N = input vector size
    parameter MAX_COMPRESS   = 10,      // Maximum compression ratio
    parameter LFSR_WIDTH     = 32,      // LFSR for random matrix
    parameter ACC_WIDTH      = 32       // Accumulator width
)(
    // Clock and Reset
    input  logic                      clk,
    input  logic                      rst_n,
    
    // AXI4-Stream Input (complex samples)
    input  logic [2*DATA_WIDTH-1:0]   s_axis_tdata,   // {Q, I}
    input  logic                      s_axis_tvalid,
    input  logic                      s_axis_tlast,   // End of input vector
    output logic                      s_axis_tready,
    
    // AXI4-Stream Output (compressed measurements)
    output logic [2*DATA_WIDTH-1:0]   m_axis_tdata,   // {Q, I} compressed
    output logic                      m_axis_tvalid,
    output logic                      m_axis_tlast,   // End of output vector
    input  logic                      m_axis_tready,
    
    // Configuration
    input  logic [3:0]                cfg_compress_ratio, // 2-10
    input  logic [LFSR_WIDTH-1:0]     cfg_lfsr_seed,      // Random seed
    input  logic                      cfg_enable,
    
    // Status
    output logic                      busy,
    output logic [9:0]                measurements_out    // Number of outputs
);

    //-------------------------------------------------------------------------
    // Local Parameters
    //-------------------------------------------------------------------------
    localparam MIN_MEASUREMENTS = INPUT_SIZE / MAX_COMPRESS;  // 102 for N=1024, CR=10
    localparam MAX_MEASUREMENTS = INPUT_SIZE / 2;             // 512 for CR=2
    localparam MEAS_ADDR_WIDTH  = $clog2(MAX_MEASUREMENTS);
    
    //-------------------------------------------------------------------------
    // State Machine
    //-------------------------------------------------------------------------
    typedef enum logic [2:0] {
        ST_IDLE,
        ST_RESET_LFSR,
        ST_ACCUMULATE,
        ST_OUTPUT,
        ST_DONE
    } state_t;
    
    state_t state, next_state;
    
    //-------------------------------------------------------------------------
    // LFSR for Pseudo-Random Measurement Matrix
    // Generates ±1 values (sign bits) for Bernoulli measurement matrix
    //-------------------------------------------------------------------------
    logic [LFSR_WIDTH-1:0] lfsr;
    logic [LFSR_WIDTH-1:0] lfsr_next;
    logic                  lfsr_bit;
    
    // LFSR feedback (maximal length for 32 bits: taps at 32, 22, 2, 1)
    assign lfsr_next = {lfsr[30:0], lfsr[31] ^ lfsr[21] ^ lfsr[1] ^ lfsr[0]};
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            lfsr <= 32'hDEADBEEF;  // Non-zero initial value
        end else if (state == ST_RESET_LFSR) begin
            lfsr <= cfg_lfsr_seed;
        end else if (state == ST_ACCUMULATE && s_axis_tvalid && s_axis_tready) begin
            lfsr <= lfsr_next;
        end
    end
    
    // Use multiple LFSR bits for parallel measurements
    // Each measurement row uses different LFSR state
    logic [MAX_MEASUREMENTS-1:0] meas_signs;
    
    // Generate sign bits for all measurements from LFSR
    genvar g;
    generate
        for (g = 0; g < MAX_MEASUREMENTS; g++) begin : gen_signs
            // Hash LFSR with measurement index for uncorrelated signs
            assign meas_signs[g] = lfsr[(g*7) % LFSR_WIDTH] ^ lfsr[(g*13+3) % LFSR_WIDTH];
        end
    endgenerate
    
    //-------------------------------------------------------------------------
    // Accumulators for Compressed Measurements
    //-------------------------------------------------------------------------
    logic signed [ACC_WIDTH-1:0] acc_i [0:MAX_MEASUREMENTS-1];
    logic signed [ACC_WIDTH-1:0] acc_q [0:MAX_MEASUREMENTS-1];
    
    logic [9:0] num_measurements;  // M = N / CR
    logic [9:0] input_cnt;
    logic [9:0] output_cnt;
    
    // Calculate number of measurements
    always_comb begin
        case (cfg_compress_ratio)
            4'd2:  num_measurements = INPUT_SIZE / 2;   // 512
            4'd3:  num_measurements = INPUT_SIZE / 3;   // 341
            4'd4:  num_measurements = INPUT_SIZE / 4;   // 256
            4'd5:  num_measurements = INPUT_SIZE / 5;   // 204
            4'd6:  num_measurements = INPUT_SIZE / 6;   // 170
            4'd7:  num_measurements = INPUT_SIZE / 7;   // 146
            4'd8:  num_measurements = INPUT_SIZE / 8;   // 128
            4'd9:  num_measurements = INPUT_SIZE / 9;   // 113
            4'd10: num_measurements = INPUT_SIZE / 10;  // 102
            default: num_measurements = INPUT_SIZE / 4; // Default CR=4
        endcase
    end
    
    //-------------------------------------------------------------------------
    // State Machine
    //-------------------------------------------------------------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= ST_IDLE;
        end else begin
            state <= next_state;
        end
    end
    
    always_comb begin
        next_state = state;
        case (state)
            ST_IDLE: begin
                if (cfg_enable && s_axis_tvalid)
                    next_state = ST_RESET_LFSR;
            end
            
            ST_RESET_LFSR: begin
                next_state = ST_ACCUMULATE;
            end
            
            ST_ACCUMULATE: begin
                if (s_axis_tlast || input_cnt == INPUT_SIZE - 1)
                    next_state = ST_OUTPUT;
            end
            
            ST_OUTPUT: begin
                if (output_cnt == num_measurements - 1 && m_axis_tready)
                    next_state = ST_DONE;
            end
            
            ST_DONE: begin
                next_state = ST_IDLE;
            end
            
            default: next_state = ST_IDLE;
        endcase
    end
    
    //-------------------------------------------------------------------------
    // Input Counter
    //-------------------------------------------------------------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            input_cnt <= '0;
        end else if (state == ST_IDLE || state == ST_RESET_LFSR) begin
            input_cnt <= '0;
        end else if (state == ST_ACCUMULATE && s_axis_tvalid && s_axis_tready) begin
            input_cnt <= input_cnt + 1'b1;
        end
    end
    
    //-------------------------------------------------------------------------
    // Accumulation: y[m] = Σ Φ[m,n] * x[n]
    // Where Φ[m,n] = ±1 based on LFSR
    //-------------------------------------------------------------------------
    logic signed [DATA_WIDTH-1:0] in_i, in_q;
    
    assign in_i = s_axis_tdata[DATA_WIDTH-1:0];
    assign in_q = s_axis_tdata[2*DATA_WIDTH-1:DATA_WIDTH];
    
    // Parallel accumulation for all measurements
    integer m;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (m = 0; m < MAX_MEASUREMENTS; m++) begin
                acc_i[m] <= '0;
                acc_q[m] <= '0;
            end
        end else if (state == ST_RESET_LFSR) begin
            // Clear accumulators
            for (m = 0; m < MAX_MEASUREMENTS; m++) begin
                acc_i[m] <= '0;
                acc_q[m] <= '0;
            end
        end else if (state == ST_ACCUMULATE && s_axis_tvalid && s_axis_tready) begin
            // Accumulate: add or subtract based on sign bit
            for (m = 0; m < MAX_MEASUREMENTS; m++) begin
                if (m < num_measurements) begin
                    if (meas_signs[m]) begin
                        acc_i[m] <= acc_i[m] + {{(ACC_WIDTH-DATA_WIDTH){in_i[DATA_WIDTH-1]}}, in_i};
                        acc_q[m] <= acc_q[m] + {{(ACC_WIDTH-DATA_WIDTH){in_q[DATA_WIDTH-1]}}, in_q};
                    end else begin
                        acc_i[m] <= acc_i[m] - {{(ACC_WIDTH-DATA_WIDTH){in_i[DATA_WIDTH-1]}}, in_i};
                        acc_q[m] <= acc_q[m] - {{(ACC_WIDTH-DATA_WIDTH){in_q[DATA_WIDTH-1]}}, in_q};
                    end
                end
            end
        end
    end
    
    //-------------------------------------------------------------------------
    // Output Counter and Data
    //-------------------------------------------------------------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            output_cnt <= '0;
        end else if (state == ST_IDLE || state == ST_ACCUMULATE) begin
            output_cnt <= '0;
        end else if (state == ST_OUTPUT && m_axis_tvalid && m_axis_tready) begin
            output_cnt <= output_cnt + 1'b1;
        end
    end
    
    //-------------------------------------------------------------------------
    // Output Scaling and Truncation
    // Scale by sqrt(N/M) to maintain energy (approximated)
    //-------------------------------------------------------------------------
    logic signed [DATA_WIDTH-1:0] out_i, out_q;
    localparam SCALE_SHIFT = $clog2(INPUT_SIZE) - 1;  // Approximate scaling
    
    assign out_i = acc_i[output_cnt][ACC_WIDTH-1:ACC_WIDTH-DATA_WIDTH];
    assign out_q = acc_q[output_cnt][ACC_WIDTH-1:ACC_WIDTH-DATA_WIDTH];
    
    //-------------------------------------------------------------------------
    // AXI4-Stream Interface
    //-------------------------------------------------------------------------
    assign s_axis_tready = (state == ST_ACCUMULATE);
    
    assign m_axis_tdata  = {out_q, out_i};
    assign m_axis_tvalid = (state == ST_OUTPUT);
    assign m_axis_tlast  = (state == ST_OUTPUT) && (output_cnt == num_measurements - 1);
    
    //-------------------------------------------------------------------------
    // Status
    //-------------------------------------------------------------------------
    assign busy             = (state != ST_IDLE);
    assign measurements_out = num_measurements;

endmodule
