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
    localparam [127:0] level = {8'd25, 8'd44, 8'd30, 8'd3, 8'd3, 8'd44, 8'd22, 8'd10, 8'd13, 8'd12, 8'd51, 8'd28, 8'd44, 8'd28, 8'd50, 8'd0};
    // localparam [5:0] level = 6'd31;

    // frame counter / level progress
    logic       frame_next;
    logic [9:0] frame_d, frame_q;
    logic [5:0] birdpos_d, birdpos_q;
    logic [3:0] level_idx;
    logic [5:0] level_offset;
    logic       running_d, running_q;

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

    assign level_idx = frame_q[9:6];
    assign level_offset = frame_q[5:0];

    assign color[0] = ~running_q || (hpos >= 10'd96 && hpos < 10'd128 && vpos[8:3] >= birdpos_q && vpos[8:3] < (birdpos_q + 6'd4));
    assign color[1] = running_q && (
        (hpos[9:2] >= 8'd32 - {'0, level_offset} && hpos[9:2] < 8'd48 - {'0, level_offset} && (vpos[8:3] < level[{level_idx, 3'd0} +: 6] || vpos[8:3] >= (level[{level_idx, 3'd0} +: 6] + 6'd8))) ||
        (hpos[9:2] >= 8'd96 - {'0, level_offset} && hpos[9:2] < 8'd112 - {'0, level_offset} && (vpos[8:3] < level[{level_idx+4'd1, 3'd0} +: 6] || vpos[8:3] >= level[{level_idx+4'd1, 3'd0} +: 6] + 6'd8)) ||
        (hpos[9:2] >= 8'd160 - {'0, level_offset} && hpos[9:2] < 8'd176 - {'0, level_offset} && (vpos[8:3] < level[{level_idx+4'd2, 3'd0} +: 6] || vpos[8:3] >= level[{level_idx+4'd2, 3'd0} +: 6] + 6'd8))
    );

    assign r_out = ((color == 2'b01) ? 2'b11 : 2'b00) & {2{display_on}};
    assign g_out = ((color == 2'b10) ? 2'b11 : 2'b00) & {2{display_on}};
    assign b_out = ((color == 2'b00) ? 2'b11 : 2'b00) & {2{display_on}};

    // this will go high once per frame
    assign frame_next = hpos == '0 && vpos == '0;

    // frame advancing
    assign frame_d = running_q ? (frame_next ? frame_q + 10'b1 : frame_q) : '0;

    // bird moving logic
    always_comb begin
        // default: reset
        birdpos_d = '0;
        if (running_q) begin
            // if running: keep
            birdpos_d = birdpos_q;
            if (frame_next) begin
                // on new frame: move bird
                if (ui_in[1:0] == 2'b10) begin
                    birdpos_d = (birdpos_q == '0) ? 6'd0 : (birdpos_q - 1'b1);
                end else if (ui_in[1:0] == 2'b01) begin
                    birdpos_d = (birdpos_q == 6'd56) ? 6'd56 : (birdpos_q + 1'b1);
                end
            end
        end
    end

    // game running logic
    always_comb begin
        running_d = '0;
        if (~running_q && ui_in[2] == 1'b1 && frame_next) begin
            running_d = '1;
        end else begin
            running_d = running_q;
        end
    end


    // Flipflop
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            frame_q <= 0;
        end else begin
            frame_q <= frame_d;
        end
    end
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            birdpos_q <= 0;
        end else begin
            birdpos_q <= birdpos_d;
        end
    end
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            running_q <= 0;
        end else begin
            running_q <= running_d;
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
