/*
 * Funny bird game
 * ui_in[0] = up
 * ui_in[1] = down
 *
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_michaelstambach_vogal (
    input  logic [7:0] ui_in,    // Dedicated inputs
    output logic [7:0] uo_out,   // Dedicated outputs
    input  logic [7:0] uio_in,   // IOs: Input path
    output logic [7:0] uio_out,  // IOs: Output path
    output logic [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  logic       ena,      // always 1 when the design is powered
    input  logic       clk,      // clock
    input  logic       rst_n     // reset_n - low to reset
);

    // VGA signals from sync generator
    logic hsync, vsync, display_on;
    logic [9:0] hpos, vpos;

    // Instantiate the sync generator
    hvsync_generator hvsync_gen (
        .clk(clk),
        .reset(~rst_n),
        .hsync(hsync),
        .vsync(vsync),
        .display_on(display_on),
        .hpos(hpos),
        .vpos(vpos)
    );

    // level config
    // these numbers only require 6 bits but aligining them to 8 bits allows us to calculate the indices without mults
    //localparam [127:0] level = {8'd25, 8'd44, 8'd30, 8'd3, 8'd3, 8'd44, 8'd22, 8'd10, 8'd13, 8'd12, 8'd51, 8'd28, 8'd44, 8'd13, 8'd6, 8'd0};
    // localparam [127:0] level = {8'd25, 8'd44, 8'd30, 8'd3, 8'd3, 8'd44, 8'd22, 8'd10, 8'd13, 8'd12, 8'd51, 8'd28, 8'd44, 8'd28, 8'd50, 8'd0};
    // localparam [5:0] level = 6'd31;
    localparam [63:0] level = 64'h0e6c5b9b1d40874d;
    localparam [5:0] level_idx1_step = 6'd7;
    localparam [5:0] level_idx2_step = 6'd5;

    // frame counter / level progress
    logic       frame_next;
    logic [9:0] birdpos_d, birdpos_q;
    logic [9:0] birdvel_d, birdvel_q;
    logic [5:0] level_idx1_d, level_idx1_q;
    logic [5:0] level_idx2_d, level_idx2_q;
    logic [5:0] level_offset_d, level_offset_q;
    logic       running_d, running_q;
    logic       collided_d, collided_q;

    // Control inputs
    // logic [1:0] keymap = ui_in[1:0];

    // color index / what is there
    // 00: bg - blue
    // 01: bird - red
    // 10: pipe - green
    logic [1:0] color;

    // Final color outputs
    logic [1:0] r_out;
    logic [1:0] g_out;
    logic [1:0] b_out;

    assign color[0] = ~running_q || (hpos >= 10'd96 && hpos < 10'd128 && vpos[8:0] >= birdpos_q[9:1] && vpos[8:0] < (birdpos_q[9:1] + 9'd32));
    assign color[1] = running_q && (
        (hpos[9:2] + {'0, level_offset_q} >= 8'd32 && hpos[9:2] + {'0, level_offset_q} < 8'd48 && 
            (vpos[8:0] <  (level[level_idx1_q +: 8] + {1'b0, level[level_idx2_q +: 7]}) ||
             vpos[8:0] >= (level[level_idx1_q +: 8] + {1'b0, level[level_idx2_q +: 7]} + 9'd96))) ||
        (hpos[9:2] >= 8'd96 - {'0, level_offset_q} && hpos[9:2] < 8'd112 - {'0, level_offset_q} && 
            (vpos[8:0] <  (level[(level_idx1_q + level_idx1_step) +: 8] + {1'b0, level[(level_idx2_q + level_idx2_step) +: 7]}) ||
             vpos[8:0] >= (level[(level_idx1_q + level_idx1_step) +: 8] + {1'b0, level[(level_idx2_q + level_idx2_step) +: 7]} + 9'd96))) ||
        (hpos[9:2] >= 8'd160 - {'0, level_offset_q} && hpos[9:2] < 8'd176 - {'0, level_offset_q} && 
            (vpos[8:0] <  (level[(level_idx1_q + 6'd14) +: 8] + {1'b0, level[(level_idx2_q + 6'd10) +: 7]}) ||
             vpos[8:0] >= (level[(level_idx1_q + 6'd14) +: 8] + {1'b0, level[(level_idx2_q + 6'd10) +: 7]} + 9'd96)))
    );

    assign r_out = ((color[0] == 1'b1) ? 2'b11 : 2'b00) & {2{display_on}};
    assign g_out = ((color == 2'b10) ? 2'b11 : 2'b00) & {2{display_on}};
    assign b_out = ((color == 2'b00) ? 2'b11 : 2'b00) & {2{display_on}};

    // this will go high once per frame
    assign frame_next = hpos == '0 && vpos == '0;

    // indexes (level advancing)
    always_comb begin
        level_idx1_d = '0;
        level_idx2_d = '0;
        level_offset_d = 6'd32; // start at 32 offset (more playable)
        if (running_q) begin
            if (frame_next) begin
                if (level_offset_q == 6'd63) begin
                    // advance indices
                    level_idx1_d = level_idx1_q + level_idx1_step;
                    level_idx2_d = level_idx2_q + level_idx2_step;
                    level_offset_d = 6'd0;
                end else begin
                    // advance offset
                    level_idx1_d = level_idx1_q;
                    level_idx2_d = level_idx2_q;
                    level_offset_d = level_offset_q + 6'd1;
                end
            end else begin
                // not on frame boundary -> keep values
                level_idx1_d = level_idx1_q;
                level_idx2_d = level_idx2_q;
                level_offset_d = level_offset_q;
            end
        end
    end

    // bird moving logic
    always_comb begin
        // default: reset
        birdpos_d = '0;
        birdvel_d = '0;
        if (running_q) begin
            // if running: keep
            birdpos_d = birdpos_q;
            birdvel_d = birdvel_q;
            if (frame_next) begin
                // on new frame: move bird
                //  update velocity and position
                if (ui_in[0] == 1'b1) begin
                    birdvel_d = birdvel_q - 10'd3;
                    birdpos_d = birdpos_q + birdvel_q - 10'd4;
                end else begin
                    birdvel_d = birdvel_q + 10'd1;
                    birdpos_d = birdpos_q + birdvel_q;
                end
                //  clamp at screen edges
                if (birdpos_d > 10'd896) begin
                    if (birdpos_q > 10'd448) begin
                        birdpos_d = 10'd896;
                    end else begin
                        birdpos_d = 10'd0;
                    end
                end
            end
        end
    end

    // game running logic
    always_comb begin
        running_d = '0;
        if (~running_q && ui_in[1] == 1'b1 && frame_next) begin
            running_d = '1;
        end else if (collided_q && frame_next) begin
            running_d = '0;
        end else begin
            running_d = running_q;
        end
    end

    // collision checking
    always_comb begin
        collided_d = '0;
        if (color == 2'b11) begin
            collided_d = '1;
        end else if (~running_q) begin
            // reset once game stopped
            collided_d = '0;
        end else begin
            collided_d = collided_q;
        end
    end


    // Flipflop
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            birdpos_q <= 0;
        end else begin
            birdpos_q <= birdpos_d;
        end
    end
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            birdvel_q <= 0;
        end else begin
            birdvel_q <= birdvel_d;
        end
    end
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            running_q <= 0;
        end else begin
            running_q <= running_d;
        end
    end
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            collided_q <= 0;
        end else begin
            collided_q <= collided_d;
        end
    end
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            level_idx1_q <= 0;
        end else begin
            level_idx1_q <= level_idx1_d;
        end
    end
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            level_idx2_q <= 0;
        end else begin
            level_idx2_q <= level_idx2_d;
        end
    end
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            level_offset_q <= 0;
        end else begin
            level_offset_q <= level_offset_d;
        end
    end

    // VGA output mapping (RGB222 on Tiny VGA PMOD)
    assign uo_out[0] = r_out[1];  // R1
    assign uo_out[4] = r_out[0];  // R0
    assign uo_out[1] = g_out[1];  // G1
    assign uo_out[5] = g_out[0];  // G0
    assign uo_out[2] = b_out[1];  // B1
    assign uo_out[6] = b_out[0];  // B0
    assign uo_out[3] = vsync;    // VSYNC
    assign uo_out[7] = hsync;    // HSYNC

    // Bidirectional pins unused
    assign uio_out = 8'b0;
    assign uio_oe  = 8'b0;

    // Unused inputs
    wire _unused = &{ena, uio_in, ui_in[7:2], 1'b0};

endmodule
