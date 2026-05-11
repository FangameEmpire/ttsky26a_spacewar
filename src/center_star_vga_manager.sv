module center_star_vga_manager #(
  XMAX = 5'd31,
  YMAX = 5'd31
) (
  input clk_i,
  input rst_i,
  input en_i,
  input en_vga_i,
  input [5:0] pix_x_i,
  input [5:0] pix_y_i,
  input [2:0] rng_i,
  input frame_upd_i,
  output draw_star_o,
  output in_star_killzone_o
);

// Set octagonal bounds
wire in_bounds;
assign in_bounds = ((pix_x_i + pix_y_i) >= 6'd08) & ((pix_x_i + pix_y_i) < 6'd55) &
                   (pix_x_i < (pix_y_i + 6'd24)) & ((pix_x_i + 6'd23) >= pix_y_i);

// Frame counter and rng sampler
reg [5:0] frame_counter;
reg [2:0] rng_q;
always @(posedge clk_i) begin
  if (rst_i) begin
    frame_counter <= 0;
    rng_q <= 0;
  end else if (en_i & frame_upd_i) begin
    frame_counter <= frame_counter + 1;
    rng_q <= rng_i;
  end else begin
    frame_counter <= frame_counter;
    rng_q <= rng_q;
  end
end

// Line selector
reg do_star_line;
always @(*) begin
    case (rng_q)
      3'h0:    do_star_line = (pix_x_i == pix_y_i);
      3'h1:    do_star_line = (pix_x_i == (YMAX - pix_y_i));
      3'h2:    do_star_line = (pix_x_i == (XMAX >> 1));
      3'h3:    do_star_line = (pix_y_i == (YMAX >> 1));
      3'h4:    do_star_line = ((pix_x_i >> 1) == (pix_y_i - (YMAX >> 2) - 1));
      3'h5:    do_star_line = ((pix_y_i >> 1) == (pix_x_i - (XMAX >> 2) - 1));
      3'h6:    do_star_line = ((pix_x_i >> 1) == (YMAX - pix_y_i - (YMAX >> 2) - 1));
      3'h7:    do_star_line = ((pix_y_i >> 1) == (XMAX - pix_x_i - (XMAX >> 2) - 1));
      default: do_star_line = 1'b0;
    endcase
  end // always @(*)

// Assign outputs (WIP)
assign draw_star_o = in_bounds & do_star_line & frame_counter[0];
assign in_star_killzone_o = (pix_x_i > (XMAX >> 2)) & ((XMAX - pix_x_i) > (XMAX >> 2)) & 
                            (pix_y_i > (YMAX >> 2)) & ((YMAX - pix_y_i) > (YMAX >> 2));

endmodule // center_star_vga_manager