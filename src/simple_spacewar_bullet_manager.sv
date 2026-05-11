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

// Bullet details
reg bullet_active;
reg [9:0] bullet_x, bullet_y;

// Get bullet spawn points and velocities
reg [9:0] bullet_spawn_x, bullet_spawn_y;
reg [3:0] bullet_cardinal, bullet_cardinal_q;

always @(*) begin
    case (bullet_cardinal[3:2])
      2'b10:    bullet_spawn_y = ship_y_i;
      2'b01:    bullet_spawn_y = ship_y_i + YMAX;
      default:  bullet_spawn_y = ship_y_i + (YMAX >> 1);
    endcase

    case (bullet_cardinal[1:0])
      2'b10:    bullet_spawn_x = ship_x_i;
      2'b01:    bullet_spawn_x = ship_x_i + XMAX;
      default:  bullet_spawn_x = ship_x_i + (XMAX >> 1);
    endcase
  end // always @(*)

cardinal_to_spaceship_controls bullet_cardinal_gen (.thrust_i(1'b1), .angle_i(ship_angle_i), .cardinal_o(bullet_cardinal));

// Bullet FSM
wire destroy_bullet, destroy_bullet_bounds;
assign destroy_bullet = destroy_bullet_i | destroy_bullet_bounds;
always @(posedge clk_i) begin
  if (rst_i) begin
    bullet_active <= 1'b0;
    bullet_cardinal_q <= 4'b0;
  end else if (en_i & update_movement_settings_i) begin
    if (bullet_request_i & ~bullet_active) begin
      bullet_active <= 1'b1;
      bullet_cardinal_q <= bullet_cardinal;
    end else if (destroy_bullet) begin
      bullet_active <= 1'b0;
      bullet_cardinal_q <= bullet_cardinal_q;
    end else begin
      bullet_active <= bullet_active;
      bullet_cardinal_q <= bullet_cardinal_q;
    end
  end else begin
    bullet_active <= bullet_active;
    bullet_cardinal_q <= bullet_cardinal_q;
  end
end // always @(posedge clk_i)

// Bullet movement
always @(posedge clk_i) begin
  if (rst_i) begin
    bullet_x <= 10'b0;
    bullet_y <= 10'b0;
  end else if (en_i & update_movement_settings_i) begin
    if (bullet_request_i & ~bullet_active) begin
      bullet_x <= bullet_spawn_x;
      bullet_y <= bullet_spawn_y;
    end else if (bullet_active) begin
      bullet_x <= bullet_x + (bullet_cardinal_q[0] ? X_VEL : 0) - (bullet_cardinal_q[1] ? X_VEL : 0);
      bullet_y <= bullet_y + (bullet_cardinal_q[2] ? Y_VEL : 0) - (bullet_cardinal_q[3] ? Y_VEL : 0);
    end else begin
      bullet_x <= bullet_x;
      bullet_y <= bullet_y;
    end
  end else begin
    bullet_x <= bullet_x;
    bullet_y <= bullet_y;
  end
end // always @(posedge clk_i)

// Bullet out of bounds detector
assign destroy_bullet_bounds = (bullet_x == 10'd0) | (bullet_y == 10'd0) |
  (bullet_x >= (10'd640 - 10'd1)) | (bullet_y >= (10'd480 - 10'd1));

// Output bullet at requested location
assign do_bullet_o = bullet_active & (pix_x_i == bullet_x) & (pix_y_i == bullet_y);

endmodule // simple_spacewar_bullet_manager