`ifndef HVSYNC_GENERATOR_H
`define HVSYNC_GENERATOR_H

/*
Video sync generator, used to drive a VGA monitor.
Timing from: https://en.wikipedia.org/wiki/Video_Graphics_Array
To use:
- Wire the hsync and vsync signals to top level outputs
- Add a 3-bit (or more) "rgb" output to the top level
*/

module hvsync_generator(
  input  logic        clk,
  input  logic        reset,
  output logic        hsync,
  output logic        vsync,
  output logic        display_on,
  output logic  [9:0] hpos,
  output logic  [9:0] vpos
);

  // declarations for TV-simulator sync parameters
  // horizontal constants
  localparam H_DISPLAY       = 640; // horizontal display width
  localparam H_BACK          =  48; // horizontal left border (back porch)
  localparam H_FRONT         =  16; // horizontal right border (front porch)
  localparam H_SYNC          =  96; // horizontal sync width
  // vertical constants
  localparam V_DISPLAY       = 480; // vertical display height
  localparam V_TOP           =  33; // vertical top border
  localparam V_BOTTOM        =  10; // vertical bottom border
  localparam V_SYNC          =   2; // vertical sync # lines
  // derived constants
  localparam H_SYNC_START    = H_DISPLAY + H_FRONT;
  localparam H_SYNC_END      = H_DISPLAY + H_FRONT + H_SYNC - 1;
  localparam H_MAX           = H_DISPLAY + H_BACK + H_FRONT + H_SYNC - 1;
  localparam V_SYNC_START    = V_DISPLAY + V_BOTTOM;
  localparam V_SYNC_END      = V_DISPLAY + V_BOTTOM + V_SYNC - 1;
  localparam V_MAX           = V_DISPLAY + V_TOP + V_BOTTOM + V_SYNC - 1;

  // ff signals
  logic hsync_d, hsync_q;
  logic vsync_d, vsync_q;
  logic [9:0] hpos_d, hpos_q;
  logic [9:0] vpos_d, vpos_q;


  // pos signals
  always_comb begin
    hpos_d = '0;
    vpos_d = '0;
    if (hpos_q == H_MAX) begin
      if (vpos_q != V_MAX) begin
        vpos_d = vpos_q + 1;
      end
    end else begin
      hpos_d = hpos_q + 1;
      vpos_d = vpos_q;
    end
  end

  // sync signals
  // we could probably get by with not buffering these
  // but this matches the original implementation more closely
  assign hsync_d = ~(hpos_q>=H_SYNC_START && hpos_q<=H_SYNC_END);
  assign vsync_d = ~(vpos_q>=H_SYNC_START && vpos_q<=H_SYNC_END);

  // flip flap flop
  always_ff @(posedge clk) begin
    if (reset) begin
      hpos_q <= '0;
    end else begin
      hpos_q <= hpos_d;
    end
  end
  always_ff @(posedge clk) begin
    if (reset) begin
      vpos_q <= '0;
    end else begin
      vpos_q <= vpos_d;
    end
  end
  // flubidubap
  always_ff @(posedge clk) begin
    if (reset) begin
      hsync_q <= '0;
    end else begin
      hsync_q <= hsync_d;
    end
  end
  always_ff @(posedge clk) begin
    if (reset) begin
      vsync_q <= '0;
    end else begin
      vsync_q <= vsync_d;
    end
  end
  
  // assign outputs
  assign hpos = hpos_q;
  assign vpos = vpos_q;

  // sync signals
  assign hsync = hsync_q;
  assign vsync = vsync_q;

  // display_on is set when beam is in "safe" visible frame
  assign display_on = (hpos_q<H_DISPLAY) && (vpos_q<V_DISPLAY);

endmodule

`endif
