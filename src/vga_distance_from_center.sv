module vga_distance_from_center #(
  RESOLUTION = 5,
  VGA_WIDTH = 10
) (
  input en_i,
  input [VGA_WIDTH-1:0] pix_x_i,
  input [VGA_WIDTH-1:0] pix_y_i,
  output [RESOLUTION-1:0] distance_x_o,
  output [RESOLUTION-1:0] distance_y_o,
  output [RESOLUTION-1:0] max_distance_x_o,
  output [RESOLUTION-1:0] max_distance_y_o
);

// Store midpoint
localparam [VGA_WIDTH-1:0] x_mid = 320;
localparam [VGA_WIDTH-1:0] y_mid = 240;
wire [RESOLUTION-2:0] x_mid_scaled, y_mid_scaled;
assign x_mid_scaled = x_mid[VGA_WIDTH-1:VGA_WIDTH-RESOLUTION+1];
assign y_mid_scaled = y_mid[VGA_WIDTH-1:VGA_WIDTH-RESOLUTION+1];

// Store X and Y distances
wire [RESOLUTION-2:0] x_diff, y_diff;

// Calculate differences
wire [RESOLUTION-2:0] x_reduced, y_reduced;
assign x_reduced = pix_x_i[VGA_WIDTH-1:VGA_WIDTH-RESOLUTION+1];
assign y_reduced = pix_y_i[VGA_WIDTH-1:VGA_WIDTH-RESOLUTION+1];

assign x_diff = (x_reduced > x_mid_scaled) ? (x_reduced - x_mid_scaled) : (x_mid_scaled - x_reduced);
assign y_diff = (y_reduced > y_mid_scaled) ? (y_reduced - y_mid_scaled) : (y_mid_scaled - y_reduced);

// Return differences
assign distance_x_o = en_i ? x_diff : 0;
assign distance_y_o = en_i ? y_diff : 0;
assign max_distance_x_o = en_i ? x_mid_scaled : 0;
assign max_distance_y_o = en_i ? y_mid_scaled : 0;

endmodule // vga_distance_from_center