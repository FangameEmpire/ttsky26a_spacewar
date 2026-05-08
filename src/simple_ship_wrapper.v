module simple_ship_wrapper #(
  parameter WIDTH = 32,
  parameter HEIGHT = 32
) (
  input wire clk_i,
  input wire rst_i,
  input wire en_i,

  input wire [9:0] pix_x_i,
  input wire [9:0] pix_y_i,
  input wire [3:0] cardinal_i,

  input wire [9:0] load_x_i,
  input wire [9:0] load_y_i,
  input wire [2:0] load_angle_i,
  input wire       load_movement_settings_i,
  
  input wire [3:0] x_vel_i,
  input wire [3:0] y_vel_i,
  input wire       allow_angle_upd_i,
  input wire       update_movement_settings_i,

  output wire [9:0] x_o,
  output wire [9:0] y_o,
  output wire [2:0] angle_o,

  output wire draw_ship_line_o,
  output wire in_ship_hitbox_o
);

  // VGA manager signals
  wire ship_vga_man_en;
  wire [5:0] ship_vga_man_x, ship_vga_man_y;

  // VGA Graphics
  vga_offset_manager #(.XMAX(WIDTH - 1), .YMAX(HEIGHT - 1)) ship_offset (.en_i, .pix_x_i, .pix_y_i, .object_x_i(x_o), .object_y_i(y_o),
    .object_en_o(ship_vga_man_en), .object_x_o(ship_vga_man_x), .object_y_o(ship_vga_man_y));

  simple_ship_vga_manager #(.XMAX(WIDTH - 1), .YMAX(HEIGHT - 1)) ship_vga_man (.en_i(ship_vga_man_en), .pix_x_i(ship_vga_man_x), .pix_y_i(ship_vga_man_y),
    .angle_i(angle_o), .draw_ship_line_o, .in_ship_hitbox_o);

  // Movement
  simple_ship_movement_manager #(.WIDTH, .HEIGHT) ship_movement_man (.clk_i, .rst_i, .en_i, .load_x_i, .load_y_i, .load_angle_i,
    .load_movement_settings_i, .cardinal_i, .x_vel_i, .y_vel_i, .allow_angle_upd_i,
    .update_movement_settings_i, .x_o, .y_o, .angle_o);

  // Gravity and Velocity

  // Death

  // Gun

  // Audio

endmodule // simple_ship_wrapper
