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
    localparam [95:0] level = {6'd0, 6'd44, 6'd30, 6'd3, 6'd3, 6'd44, 6'd22, 6'd10, 6'd13, 6'd12, 6'd51, 6'd28, 6'd44, 6'd13, 6'd6, 6'd25};
    // localparam [5:0] level = 6'd31;

    // frame counter / level progress
    logic [9:0] frame_d, frame_q;
    logic [5:0] birdpos_d, birdpos_q;
    logic [3:0] level_idx;
    logic [5:0] level_offset;
    // logic       running_d, running_q;

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

    assign color[0] = (hpos >= 96 && hpos < 128 && vpos >= (birdpos_q<<3) && vpos < ((birdpos_q<<3) + 32));
    assign color[1] = (
        (hpos >= 10'd128 - (level_offset<<2) && hpos < 10'd192 - (level_offset<<2) && (vpos>>2 < level[level_idx +: 6] || vpos>>2 > level[level_idx +: 6] + 16)) ||
        (hpos >= 10'd384 - (level_offset<<2) && hpos < 10'd448 - (level_offset<<2) && (vpos>>2 < level[level_idx+4'd6 +: 6] || vpos>>2 > level[level_idx+4'd6 +: 6] + 16)) ||
        (hpos >= 10'd640 - (level_offset<<2) && hpos < 10'd704 - (level_offset<<2) && (vpos>>2 < level[level_idx+4'd12 +: 6] || vpos>>2 > level[level_idx+4'd12 +: 6] + 16))
    );

    assign r_out = ((color == 2'b01) ? 2'b11 : 2'b00) & {2{display_on}};
    assign g_out = ((color == 2'b10) ? 2'b11 : 2'b00) & {2{display_on}};
    assign b_out = ((color == 2'b00) ? 2'b11 : 2'b00) & {2{display_on}};


    // main logic
    always_comb begin
        frame_d = '0;
        birdpos_d = '0;
        if (hpos == 0 && vpos == 0) begin
            frame_d = frame_q + 10'b1;
            if (ui_in[1:0] == 2'b10) begin
                birdpos_d = (birdpos_q == '0) ? 6'd0 : (birdpos_q - 1'b1);
            end else if (ui_in[1:0] == 2'b01) begin
                birdpos_d = (birdpos_q == 6'd56) ? 6'd56 : (birdpos_q + 1'b1);
            end
        end else begin
            frame_d = frame_q;
            birdpos_d = birdpos_q;
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
    // always_ff @(posedge clk or negedge rst_n) begin
    //     if (!rst_n) begin
    //         running_q <= 0;
    //     end else begin
    //         running_q <= running_d;
    //     end
    // end

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
