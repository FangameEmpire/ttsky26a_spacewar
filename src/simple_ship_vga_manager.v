module simple_ship_vga_manager #(
  XMAX = 5'd31,
  YMAX = 5'd31
) (
  input en_i,
  input [9:0] pix_x_i,
  input [9:0] pix_y_i,
  input [9:0] ship_x_i,
  input [9:0] ship_y_i,
  input [2:0] angle_i,
  output draw_ship_line_o,
  output in_ship_hitbox_o
);

// Determine whether the current pixel is within bounds
wire offset_en, within_x, within_y;
assign within_x = (pix_x_i >= ship_x_i) & (pix_x_i < ship_x_i + XMAX + 1);
assign within_y = (pix_y_i >= ship_y_i) & (pix_y_i < ship_y_i + YMAX + 1);
assign offset_en = en_i & within_x & within_y;

// Get offset VGA pixel coordinates
wire [5:0] offset_x, offset_y;
assign offset_x = offset_en ? {(pix_x_i - ship_x_i)}[5:0] : 5'b0;
assign offset_y = offset_en ? {(pix_y_i - ship_y_i)}[5:0] : 5'b0;

// Wrap the main VGA graphics manager after simplifying pixel math
simple_ship_vga_manager_offset #(.XMAX, .YMAX) ship_man_helper (.en_i(offset_en),
  .pix_x_i(offset_x), .pix_y_i(offset_y), .angle_i, .draw_ship_line_o, .in_ship_hitbox_o);

endmodule // simple_ship_vga_manager
