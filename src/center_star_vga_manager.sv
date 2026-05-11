module center_star_vga_manager #(
  XMAX = 5'd31,
  YMAX = 5'd31
) (
  input clk_i,
  input rst_i,
  input en_i,
  input [5:0] pix_x_i,
  input [5:0] pix_y_i,
  input [9:0] rng_i,
  input frame_upd_i,
  output draw_star_o,
  output in_star_killzone_o
);

// Set octagonal bounds
wire in_bounds;
assign in_bounds = ((pix_x_i + pix_y_i) >= 6'd08) & ((pix_x_i + pix_y_i) < 6'd55) &
                   (pix_x_i < (pix_y_i + 6'd24)) & ((pix_x_i + 6'd23) >= pix_y_i);

// Assign outputs (WIP)
assign draw_star_o = in_bounds;
assign in_star_killzone_o = (pix_x_i > (XMAX >> 2)) & ((XMAX - pix_x_i) > (XMAX >> 2)) & 
                            (pix_y_i > (YMAX >> 2)) & ((YMAX - pix_y_i) > (YMAX >> 2));

endmodule // center_star_vga_manager