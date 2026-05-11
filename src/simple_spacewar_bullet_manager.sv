`default_nettype none

module simple_spacewar_bullet_manager #(
  XMAX = 5'd31,
  YMAX = 5'd31,
  parameter X_VEL = 4'h7,
  parameter Y_VEL = 4'h7
) (
  input wire clk_i,
  input wire rst_i,
  input wire en_i,
  input wire [9:0] pix_x_i,
  input wire [9:0] pix_y_i,
  input wire [9:0] ship_x_i,
  input wire [9:0] ship_y_i,
  input wire [2:0] ship_angle_i,
  input wire update_movement_settings_i,
  input wire bullet_request_i,
  input wire destroy_bullet_i,
  output wire do_bullet_o
);

// Output bullet at requested location
assign do_bullet_o = 1'b0;

endmodule // simple_spacewar_bullet_manager