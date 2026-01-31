//-----------------------------------------------------------------------------
// QEDMMA v2.0 - Multi-Source Fusion Engine
// Author: Dr. Mladen Mešter
// Copyright (c) 2026 Dr. Mladen Mešter - All Rights Reserved
//
// Description:
//   Top-level fusion engine integrating data from multiple sources:
//   - QEDMMA TDOA solver (organic)
//   - Link-16 (cooperative)
//   - ADS-B (non-cooperative)
//   - ESM/ELINT (passive)
//
// [REQ-FUSION-001] Multi-source track correlation
// [REQ-FUSION-002] <100 ms processing latency
// [REQ-FUSION-003] Weapon-grade output (<500m CEP)
//-----------------------------------------------------------------------------

`timescale 1ns / 1ps

module fusion_engine_top #(
    parameter int MAX_TRACKS      = 1024,
    parameter int TRACK_ID_WIDTH  = 16,
    parameter int POSITION_WIDTH  = 32,
    parameter int VELOCITY_WIDTH  = 16
)(
    input  logic        clk,
    input  logic        rst_n,
    
    // QEDMMA TDOA Input
    input  logic [POSITION_WIDTH-1:0]  qedmma_lat,
    input  logic [POSITION_WIDTH-1:0]  qedmma_lon,
    input  logic [POSITION_WIDTH-1:0]  qedmma_alt,
    input  logic [VELOCITY_WIDTH-1:0]  qedmma_vx,
    input  logic [VELOCITY_WIDTH-1:0]  qedmma_vy,
    input  logic [VELOCITY_WIDTH-1:0]  qedmma_vz,
    input  logic [15:0]                qedmma_cep,
    input  logic [TRACK_ID_WIDTH-1:0]  qedmma_track_id,
    input  logic                       qedmma_valid,
    output logic                       qedmma_ready,
    
    // ADS-B Input
    input  logic [23:0]                adsb_icao,
    input  logic [POSITION_WIDTH-1:0]  adsb_lat,
    input  logic [POSITION_WIDTH-1:0]  adsb_lon,
    input  logic [15:0]                adsb_alt,
    input  logic [15:0]                adsb_velocity,
    input  logic                       adsb_valid,
    output logic                       adsb_ready,
    
    // ESM Input
    input  logic [15:0]                esm_azimuth,
    input  logic [31:0]                esm_frequency,
    input  logic [7:0]                 esm_emitter_id,
    input  logic                       esm_valid,
    output logic                       esm_ready,
    
    // Fire Control Output
    output logic [TRACK_ID_WIDTH-1:0]  fc_track_id,
    output logic [POSITION_WIDTH-1:0]  fc_lat,
    output logic [POSITION_WIDTH-1:0]  fc_lon,
    output logic [POSITION_WIDTH-1:0]  fc_alt,
    output logic [VELOCITY_WIDTH-1:0]  fc_vx,
    output logic [VELOCITY_WIDTH-1:0]  fc_vy,
    output logic [VELOCITY_WIDTH-1:0]  fc_vz,
    output logic [7:0]                 fc_quality,
    output logic [7:0]                 fc_classification,
    output logic [7:0]                 fc_threat_level,
    output logic [7:0]                 fc_source_bitmap,
    output logic [15:0]                fc_cep,
    output logic [31:0]                fc_timestamp,
    output logic                       fc_valid,
    input  logic                       fc_ready,
    
    // Configuration
    input  logic                       ctrl_enable,
    input  logic [7:0]                 ctrl_source_enable,
    input  logic [15:0]                cfg_gate_position,
    input  logic [7:0]                 cfg_qedmma_weight,
    
    // Status
    output logic [15:0]                active_tracks,
    output logic                       fusion_busy
);

    // Track structure
    typedef struct packed {
        logic [TRACK_ID_WIDTH-1:0]  track_id;
        logic [POSITION_WIDTH-1:0]  lat;
        logic [POSITION_WIDTH-1:0]  lon;
        logic [POSITION_WIDTH-1:0]  alt;
        logic [VELOCITY_WIDTH-1:0]  vx;
        logic [VELOCITY_WIDTH-1:0]  vy;
        logic [VELOCITY_WIDTH-1:0]  vz;
        logic [15:0]                cep;
        logic [7:0]                 quality;
        logic [7:0]                 classification;
        logic [7:0]                 threat_level;
        logic [7:0]                 source_bitmap;
        logic [31:0]                timestamp;
        logic                       active;
    } track_t;

    // Classification codes
    localparam logic [7:0] CLASS_UNKNOWN = 8'd0;
    localparam logic [7:0] CLASS_FRIEND  = 8'd1;
    localparam logic [7:0] CLASS_FOE     = 8'd2;
    
    // Source bitmap
    localparam logic [7:0] SRC_QEDMMA = 8'b00000001;
    localparam logic [7:0] SRC_ADSB   = 8'b00001000;
    localparam logic [7:0] SRC_ESM    = 8'b00010000;

    // State machine
    typedef enum logic [3:0] {
        ST_IDLE,
        ST_QEDMMA,
        ST_ADSB,
        ST_ESM,
        ST_ASSOCIATE,
        ST_FUSE,
        ST_OUTPUT
    } state_t;
    
    state_t state;
    
    // Track database (simplified for synthesis)
    track_t track_db [0:255];  // Reduced for example
    logic [7:0] next_free_slot;
    logic [15:0] track_count;
    
    // Pending input
    track_t pending_track;
    logic [7:0] pending_source;
    
    // Association
    logic [7:0] assoc_idx;
    logic [7:0] best_match_idx;
    logic [31:0] best_match_dist;
    logic assoc_found;
    
    // Timestamp
    logic [31:0] timestamp_cnt;
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            timestamp_cnt <= '0;
        else
            timestamp_cnt <= timestamp_cnt + 1;
    end

    // Ready signals
    assign qedmma_ready = (state == ST_IDLE) && ctrl_enable && ctrl_source_enable[0];
    assign adsb_ready   = (state == ST_IDLE) && ctrl_enable && ctrl_source_enable[3];
    assign esm_ready    = (state == ST_IDLE) && ctrl_enable && ctrl_source_enable[4];

    // Main FSM
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= ST_IDLE;
            fc_valid <= 1'b0;
            pending_track <= '0;
            pending_source <= '0;
            assoc_idx <= '0;
            best_match_idx <= '0;
            best_match_dist <= 32'hFFFFFFFF;
            assoc_found <= 1'b0;
            next_free_slot <= '0;
            
            for (int i = 0; i < 256; i++)
                track_db[i].active <= 1'b0;
                
        end else begin
            case (state)
                ST_IDLE: begin
                    fc_valid <= 1'b0;
                    
                    if (qedmma_valid && ctrl_source_enable[0]) begin
                        pending_track.lat <= qedmma_lat;
                        pending_track.lon <= qedmma_lon;
                        pending_track.alt <= qedmma_alt;
                        pending_track.vx  <= qedmma_vx;
                        pending_track.vy  <= qedmma_vy;
                        pending_track.vz  <= qedmma_vz;
                        pending_track.cep <= qedmma_cep;
                        pending_source <= SRC_QEDMMA;
                        state <= ST_QEDMMA;
                    end else if (adsb_valid && ctrl_source_enable[3]) begin
                        pending_track.lat <= adsb_lat;
                        pending_track.lon <= adsb_lon;
                        pending_track.alt <= {16'b0, adsb_alt};
                        pending_track.cep <= 16'd50;
                        pending_source <= SRC_ADSB;
                        state <= ST_ADSB;
                    end else if (esm_valid && ctrl_source_enable[4]) begin
                        pending_source <= SRC_ESM;
                        state <= ST_ESM;
                    end
                end
                
                ST_QEDMMA, ST_ADSB: begin
                    assoc_idx <= '0;
                    best_match_dist <= 32'hFFFFFFFF;
                    assoc_found <= 1'b0;
                    state <= ST_ASSOCIATE;
                end
                
                ST_ESM: begin
                    // ESM provides bearing only - correlate with existing tracks
                    state <= ST_IDLE;  // Simplified
                end
                
                ST_ASSOCIATE: begin
                    if (assoc_idx < 256) begin
                        if (track_db[assoc_idx].active) begin
                            // Simple distance calculation
                            automatic logic [31:0] d_lat, d_lon, dist;
                            d_lat = (pending_track.lat > track_db[assoc_idx].lat) ?
                                    (pending_track.lat - track_db[assoc_idx].lat) :
                                    (track_db[assoc_idx].lat - pending_track.lat);
                            d_lon = (pending_track.lon > track_db[assoc_idx].lon) ?
                                    (pending_track.lon - track_db[assoc_idx].lon) :
                                    (track_db[assoc_idx].lon - pending_track.lon);
                            dist = d_lat + d_lon;
                            
                            if (dist < cfg_gate_position && dist < best_match_dist) begin
                                best_match_dist <= dist;
                                best_match_idx <= assoc_idx;
                                assoc_found <= 1'b1;
                            end
                        end
                        assoc_idx <= assoc_idx + 1;
                    end else begin
                        state <= ST_FUSE;
                    end
                end
                
                ST_FUSE: begin
                    if (assoc_found) begin
                        // Fuse with existing track (weighted average)
                        automatic logic [7:0] w1 = cfg_qedmma_weight;
                        automatic logic [7:0] w2 = 100 - w1;
                        
                        track_db[best_match_idx].lat <= 
                            (pending_track.lat * w1 + track_db[best_match_idx].lat * w2) / 100;
                        track_db[best_match_idx].lon <= 
                            (pending_track.lon * w1 + track_db[best_match_idx].lon * w2) / 100;
                        
                        if (pending_source == SRC_QEDMMA) begin
                            track_db[best_match_idx].vx <= pending_track.vx;
                            track_db[best_match_idx].vy <= pending_track.vy;
                            track_db[best_match_idx].vz <= pending_track.vz;
                        end
                        
                        // Better CEP
                        track_db[best_match_idx].cep <= 
                            (pending_track.cep < track_db[best_match_idx].cep) ?
                            pending_track.cep : track_db[best_match_idx].cep;
                        
                        // Update sources
                        track_db[best_match_idx].source_bitmap <= 
                            track_db[best_match_idx].source_bitmap | pending_source;
                        
                        // Classification
                        if (pending_source == SRC_ADSB)
                            track_db[best_match_idx].classification <= CLASS_FRIEND;
                        
                        track_db[best_match_idx].timestamp <= timestamp_cnt;
                        track_db[best_match_idx].quality <= 
                            track_db[best_match_idx].quality + 10;
                        
                        // Output
                        fc_track_id       <= track_db[best_match_idx].track_id;
                        fc_lat            <= track_db[best_match_idx].lat;
                        fc_lon            <= track_db[best_match_idx].lon;
                        fc_alt            <= track_db[best_match_idx].alt;
                        fc_vx             <= track_db[best_match_idx].vx;
                        fc_vy             <= track_db[best_match_idx].vy;
                        fc_vz             <= track_db[best_match_idx].vz;
                        fc_quality        <= track_db[best_match_idx].quality;
                        fc_classification <= track_db[best_match_idx].classification;
                        fc_threat_level   <= track_db[best_match_idx].threat_level;
                        fc_source_bitmap  <= track_db[best_match_idx].source_bitmap;
                        fc_cep            <= track_db[best_match_idx].cep;
                        fc_timestamp      <= timestamp_cnt;
                        
                    end else begin
                        // Create new track
                        track_db[next_free_slot].track_id <= {8'b0, next_free_slot};
                        track_db[next_free_slot].lat <= pending_track.lat;
                        track_db[next_free_slot].lon <= pending_track.lon;
                        track_db[next_free_slot].alt <= pending_track.alt;
                        track_db[next_free_slot].vx  <= pending_track.vx;
                        track_db[next_free_slot].vy  <= pending_track.vy;
                        track_db[next_free_slot].vz  <= pending_track.vz;
                        track_db[next_free_slot].cep <= pending_track.cep;
                        track_db[next_free_slot].source_bitmap <= pending_source;
                        track_db[next_free_slot].timestamp <= timestamp_cnt;
                        track_db[next_free_slot].active <= 1'b1;
                        track_db[next_free_slot].quality <= 8'd50;
                        
                        // QEDMMA-only = potential threat
                        if (pending_source == SRC_QEDMMA) begin
                            track_db[next_free_slot].classification <= CLASS_UNKNOWN;
                            track_db[next_free_slot].threat_level <= 8'd5;
                        end else begin
                            track_db[next_free_slot].classification <= CLASS_FRIEND;
                            track_db[next_free_slot].threat_level <= 8'd0;
                        end
                        
                        fc_track_id       <= {8'b0, next_free_slot};
                        fc_lat            <= pending_track.lat;
                        fc_lon            <= pending_track.lon;
                        fc_alt            <= pending_track.alt;
                        fc_vx             <= pending_track.vx;
                        fc_vy             <= pending_track.vy;
                        fc_vz             <= pending_track.vz;
                        fc_quality        <= 8'd50;
                        fc_classification <= track_db[next_free_slot].classification;
                        fc_threat_level   <= track_db[next_free_slot].threat_level;
                        fc_source_bitmap  <= pending_source;
                        fc_cep            <= pending_track.cep;
                        fc_timestamp      <= timestamp_cnt;
                        
                        next_free_slot <= next_free_slot + 1;
                    end
                    
                    state <= ST_OUTPUT;
                end
                
                ST_OUTPUT: begin
                    fc_valid <= 1'b1;
                    if (fc_ready || !fc_valid)
                        state <= ST_IDLE;
                end
                
                default: state <= ST_IDLE;
            endcase
        end
    end
    
    // Track count
    always_comb begin
        automatic logic [15:0] cnt = 0;
        for (int i = 0; i < 256; i++)
            if (track_db[i].active) cnt = cnt + 1;
        track_count = cnt;
    end
    
    assign active_tracks = track_count;
    assign fusion_busy = (state != ST_IDLE);

endmodule
