module vga_offset_manager #(
  XMAX = 5'd31,
  YMAX = 5'd31
) (
  input en_i,
  input [9:0] pix_x_i,
  input [9:0] pix_y_i,
  input [9:0] object_x_i,
  input [9:0] object_y_i,
  output object_en_o,
  output [5:0] object_x_o,
  output [5:0] object_y_o
);

// Determine whether the current pixel is within bounds
wire within_x, within_y;
assign within_x = (pix_x_i >= object_x_i) & (pix_x_i < object_x_i + XMAX + 1);
assign within_y = (pix_y_i >= object_y_i) & (pix_y_i < object_y_i + YMAX + 1);
assign object_en_o = en_i & within_x & within_y;

// Get offset VGA pixel coordinates
assign object_x_o = object_en_o ? {(pix_x_i - object_x_i)}[5:0] : 5'b0;
assign object_y_o = object_en_o ? {(pix_y_i - object_y_i)}[5:0] : 5'b0;

endmodule // vga_offset_manager