module simple_ship_vga_manager_offset #(
  parameter XMAX = 5'd31,
  parameter YMAX = 5'd31, 
  localparam XW = $clog2(XMAX),
  localparam YW = $clog2(YMAX)
) (
  input en_i,
  input [XW:0] pix_x_i,
  input [YW:0] pix_y_i,
  input [2:0] angle_i,
  output draw_ship_line_o,
  output in_ship_hitbox_o
);

  // Quadrants
  wire in_top_half, in_bottom_half, in_left_half, in_right_half;
  assign in_top_half = ~in_bottom_half;
  assign in_bottom_half = pix_y_i[YW-1];
  assign in_left_half = ~in_right_half;
  assign in_right_half = pix_x_i[XW-1];

  // Boundary lines

  wire [3:0] lines_x, lines_y; // x: Slope of 2, y: slope of 1/2
  assign lines_x[3] = (pix_y_i == (pix_x_i << 1));
  assign lines_x[2] = (pix_y_i == (XMAX - (pix_x_i << 1)));
  assign lines_x[1] = (pix_y_i == ((pix_x_i << 1) - XMAX));
  assign lines_x[0] = (pix_y_i == ((YMAX - pix_x_i) << 1));
  assign lines_y[3] = (pix_y_i == (pix_x_i >> 1));
  assign lines_y[2] = (pix_y_i == ((YMAX >> 1) - (pix_x_i >> 1)));
  assign lines_y[1] = (pix_y_i == ((pix_x_i >> 1) + (YMAX >> 1) + 1));
  assign lines_y[0] = (pix_y_i == (YMAX - (pix_x_i >> 1)));

  wire [3:0] mini_lines_x, mini_lines_y;
  assign mini_lines_x[3] = lines_x[3] & (pix_y_i >= ((pix_x_i >> 1) + (YMAX >> 1) + 1)) & in_left_half; // y1
  assign mini_lines_x[2] = lines_x[2] & (pix_y_i <= ((YMAX >> 1) - (pix_x_i >> 1))) & in_left_half; // y2
  assign mini_lines_x[1] = lines_x[1] & (pix_y_i <= (pix_x_i >> 1)) & in_right_half; // y3
  assign mini_lines_x[0] = lines_x[0] & (pix_y_i >= (YMAX - (pix_x_i >> 1))) & in_right_half; // y0
  assign mini_lines_y[3] = lines_y[3] & (pix_y_i <= ((pix_x_i << 1) - XMAX)) & in_right_half; // x1
  assign mini_lines_y[2] = lines_y[2] & (pix_y_i <= (XMAX - (pix_x_i << 1))) & in_left_half; // x2
  assign mini_lines_y[1] = lines_y[1] & (pix_y_i >= (pix_x_i << 1)) & in_left_half; // x3
  assign mini_lines_y[0] = lines_y[0] & (pix_y_i >= ((YMAX - pix_x_i) << 1)) & in_right_half; // x0

  // Select boundary lines
  reg selected_lines;
  always @(*) begin
    case (angle_i)
      3'h0:    selected_lines = lines_x[2] | lines_x[1] | (lines_y[1] & in_right_half) | (lines_y[0] & in_left_half);
      3'h1:    selected_lines = lines_y[2] | lines_x[0] | mini_lines_y[1] | mini_lines_x[3];
      3'h2:    selected_lines = lines_y[3] | lines_y[0] | (lines_x[3] & in_top_half) | (lines_x[2] & in_bottom_half);
      3'h3:    selected_lines = lines_y[1] | lines_x[1] | mini_lines_y[2] | mini_lines_x[2];
      3'h4:    selected_lines = lines_x[3] | lines_x[0] | (lines_y[3] & in_left_half) | (lines_y[2] & in_right_half);
      3'h5:    selected_lines = lines_x[2] | lines_y[0] | mini_lines_y[3] | mini_lines_x[1];
      3'h6:    selected_lines = lines_y[2] | lines_y[1] | (lines_x[1] & in_bottom_half) | (lines_x[0] & in_top_half);
      3'h7:    selected_lines = lines_y[3] | lines_x[3] | mini_lines_y[0] | mini_lines_x[0];
      default: selected_lines = 1'b0;
    endcase
  end // always @(*)

  // Simple hitbox: Inner half by x and y I.E. Center quarter
  wire in_simple_hitbox;
  assign in_simple_hitbox = (pix_x_i > (XMAX >> 2)) & ((XMAX - pix_x_i) > (XMAX >> 2)) & 
                            (pix_y_i > (YMAX >> 2)) & ((YMAX - pix_y_i) > (YMAX >> 2));

  // Assign outputs (WIP)
  //assign draw_ship_line_o = en_i & (1'b0);
  assign draw_ship_line_o = en_i & |{lines_x, lines_y};
  assign in_ship_hitbox_o = en_i & selected_lines;
  //assign in_ship_hitbox_o = en_i & lines_y[3] * (1'b0);
  //assign in_ship_hitbox_o = in_simple_hitbox;
  //assign in_ship_hitbox_o = en_i;

endmodule // simple_ship_vga_manager_offset
