`ifndef HVSYNC_GENERATOR_H
`define HVSYNC_GENERATOR_H

/*
Video sync generator, used to drive a VGA monitor.
Timing from: https://en.wikipedia.org/wiki/Video_Graphics_Array
To use:
- Wire the hsync and vsync signals to top level outputs
- Add a 3-bit (or more) "rgb" output to the top level
*/

module hvsync_generator(clk, reset, hsync, vsync, display_on, hpos, vpos);

  input clk;
  input reset;
  output reg hsync, vsync;
  output display_on;
  output reg [9:0] hpos;
  output reg [9:0] vpos;

  // declarations for TV-simulator sync parameters
  // horizontal constants
  parameter H_DISPLAY       = 640; // horizontal display width
  parameter H_BACK          =  48; // horizontal left border (back porch)
  parameter H_FRONT         =  16; // horizontal right border (front porch)
  parameter H_SYNC          =  96; // horizontal sync width
  // vertical constants
  parameter V_DISPLAY       = 480; // vertical display height
  parameter V_TOP           =  33; // vertical top border
  parameter V_BOTTOM        =  10; // vertical bottom border
  parameter V_SYNC          =   2; // vertical sync # lines
  // derived constants
  parameter H_SYNC_START    = H_DISPLAY + H_FRONT;
  parameter H_SYNC_END      = H_DISPLAY + H_FRONT + H_SYNC - 1;
  parameter H_MAX           = H_DISPLAY + H_BACK + H_FRONT + H_SYNC - 1;
  parameter V_SYNC_START    = V_DISPLAY + V_BOTTOM;
  parameter V_SYNC_END      = V_DISPLAY + V_BOTTOM + V_SYNC - 1;
  parameter V_MAX           = V_DISPLAY + V_TOP + V_BOTTOM + V_SYNC - 1;

  wire hmaxxed = (hpos == H_MAX) || reset;	// set when hpos is maximum
  wire vmaxxed = (vpos == V_MAX) || reset;	// set when vpos is maximum
  
  // horizontal position counter
  always @(posedge clk)
  begin
    hsync <= (hpos>=H_SYNC_START && hpos<=H_SYNC_END);
    if(hmaxxed)
      hpos <= 0;
    else
      hpos <= hpos + 1;
  end

  // vertical position counter
  always @(posedge clk)
  begin
    vsync <= (vpos>=V_SYNC_START && vpos<=V_SYNC_END);
    if(hmaxxed)
      if (vmaxxed)
        vpos <= 0;
      else
        vpos <= vpos + 1;
  end
  
  // display_on is set when beam is in "safe" visible frame
  assign display_on = (hpos<H_DISPLAY) && (vpos<V_DISPLAY);

endmodule

`endif

// Supports use with a clock frequency higher than the desired VGA frequency
module hvsync_generator_enabled(clk, reset, en, hsync, vsync, display_on, hpos, vpos);

  input clk;
  input reset;
  input en;
  output reg hsync, vsync;
  output display_on;
  output reg [9:0] hpos;
  output reg [9:0] vpos;

  // declarations for TV-simulator sync parameters
  // horizontal constants
  parameter H_DISPLAY       = 640; // horizontal display width
  parameter H_BACK          =  48; // horizontal left border (back porch)
  parameter H_FRONT         =  16; // horizontal right border (front porch)
  parameter H_SYNC          =  96; // horizontal sync width
  // vertical constants
  parameter V_DISPLAY       = 480; // vertical display height
  parameter V_TOP           =  33; // vertical top border
  parameter V_BOTTOM        =  10; // vertical bottom border
  parameter V_SYNC          =   2; // vertical sync # lines
  // derived constants
  parameter H_SYNC_START    = H_DISPLAY + H_FRONT;
  parameter H_SYNC_END      = H_DISPLAY + H_FRONT + H_SYNC - 1;
  parameter H_MAX           = H_DISPLAY + H_BACK + H_FRONT + H_SYNC - 1;
  parameter V_SYNC_START    = V_DISPLAY + V_BOTTOM;
  parameter V_SYNC_END      = V_DISPLAY + V_BOTTOM + V_SYNC - 1;
  parameter V_MAX           = V_DISPLAY + V_TOP + V_BOTTOM + V_SYNC - 1;

  wire hmaxxed = (hpos == H_MAX);	// set when hpos is maximum
  wire vmaxxed = (vpos == V_MAX);	// set when vpos is maximum
  
  // horizontal position counter
  always @(posedge clk)
  begin
	// hsync
	if (reset) begin
		hsync <= 1'b0;
	end else if (~en) begin
		hsync <= hsync;
	end else begin
		hsync <= (hpos>=H_SYNC_START && hpos<=H_SYNC_END);
	end // if
	
	// hpos
	if (reset) begin
		hpos <= 1'b0;
	end else if (~en) begin
		hpos <= hpos;
	end else begin
		if (hmaxxed)	hpos <= 0;
		else			hpos <= hpos + 1;
	end // if
  end // always @(posedge clk)

	// vertical position counter
	always @(posedge clk)
	begin
		// vsync
		if (reset) begin
			vsync <= 1'b0;
		end else if (~en) begin
			vsync <= vsync;
		end else begin
			vsync <= (vpos>=V_SYNC_START && vpos<=V_SYNC_END);
		end // if
		
		// vpos
		if (reset) begin
			vpos <= 0;
		end else if (~en) begin
			vpos <= vpos;
		end else begin
			if (hmaxxed) begin
				if (vmaxxed)	vpos <= 0;
				else			vpos <= vpos + 1;
			end else begin
				vpos <= vpos;
			end // if
		end // if
		
	end // always @(posedge clk)
  
  // display_on is set when beam is in "safe" visible frame
  assign display_on = (hpos<H_DISPLAY) && (vpos<V_DISPLAY);

endmodule

// Determine where in the VGA frame a given (X, Y) coordinate is
// State[3:2]: 2'b11 = VSYNC, 2'b10 = V_FP, 2'b01 = V_Active, 2'b00 = V_BP
// State[1:0]: 2'b11 = HSYNC, 2'b10 = H_FP, 2'b01 = H_Active, 2'b00 = H_BP
// Flags[3:0]: [3] = VMAX, [2] = VMIN, [1] = HMAX, [0] = HMIN
module hvsync_generator_decoder(hpos, vpos, state, flags);
	// Declarations for TV-simulator sync parameters
	// Horizontal constants
	parameter H_DISPLAY       = 640; // horizontal display width
	parameter H_BACK          =  48; // horizontal left border (back porch)
	parameter H_FRONT         =  16; // horizontal right border (front porch)
	parameter H_SYNC          =  96; // horizontal sync width
	// Vertical constants
	parameter V_DISPLAY       = 480; // vertical display height
	parameter V_TOP           =  33; // vertical top border
	parameter V_BOTTOM        =  10; // vertical bottom border
	parameter V_SYNC          =   2; // vertical sync # lines
	// Derived constants
	parameter H_SYNC_START    = H_DISPLAY + H_FRONT;
	parameter H_SYNC_END      = H_DISPLAY + H_FRONT + H_SYNC - 1;
	parameter H_MAX           = H_DISPLAY + H_BACK + H_FRONT + H_SYNC - 1;
	parameter V_SYNC_START    = V_DISPLAY + V_BOTTOM;
	parameter V_SYNC_END      = V_DISPLAY + V_BOTTOM + V_SYNC - 1;
	parameter V_MAX           = V_DISPLAY + V_TOP + V_BOTTOM + V_SYNC - 1;
	
	// Module ports
	input wire [9:0] hpos, vpos;
	output wire [3:0] state, flags;
	
	// Intermediate values
	wire vSYNC, v_FP, v_Active, hSYNC, h_FP, h_Active;
	assign v_Active = (vpos < V_DISPLAY);
	assign v_fp = (vpos < V_SYNC_START);
	assign vSYNC = (vpos < V_SYNC_END + 1);
	assign h_Active = (hpos < H_DISPLAY);
	assign h_fp = (hpos < H_SYNC_START);
	assign hSYNC = (hpos < H_SYNC_END + 1);
	
	// Find region of VGA frame
	assign state[3] = vSYNC & ~v_Active; // V_FP or VSYNC
	assign state[2] = v_fp ? v_Active : vSYNC; // V_BP or V_Active
	assign state[1] = hSYNC & ~h_Active; // H_FP or HSYNC
	assign state[0] = h_fp ? h_Active : hSYNC; // H_BP or H_Active
	
	// Check X, Y bounds
	assign flags[3] = (vpos == V_MAX);
	assign flags[2] = (vpos == 10'b0);
	assign flags[1] = (hpos == H_MAX);
	assign flags[0] = (hpos == 10'b0);
	
endmodule // hvsync_generator_decoder
