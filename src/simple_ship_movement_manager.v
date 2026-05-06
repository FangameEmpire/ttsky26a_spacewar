module simple_ship_movement_manager #(
  parameter WIDTH = 32,
  parameter HEIGHT = 32, 
  localparam XW = $clog2(WIDTH-1),
  localparam YW = $clog2(HEIGHT-1)
) (
  input wire clk_i,
  input wire rst_i,
  input wire en_i,
  input wire [9:0] load_x_i,
  input wire [9:0] load_y_i,
  input wire [2:0] load_angle_i,
  input wire load_movement_settings_i,
  input wire [3:0] cardinal_i,
  input wire [3:0] x_vel_i,
  input wire [3:0] y_vel_i,
  input wire update_movement_settings_i,
  output wire [9:0] x_o,
  output wire [9:0] y_o,
  output wire [2:0] angle_o
);
  // Store parameters
  parameter X_MAX = (640 - 1);
  parameter Y_MAX = (480 - 1);

  // Store internal copies of position and angle
  reg [9:0] x, y;
  reg [2:0] angle;

  // Calculate potential moves
  wire [9:0] y_up, y_down, x_left, x_right;

  always @(*) begin
    if (x < WIDTH) begin
      x_left = 0;
      x_right = x + x_vel_i;
    end else if (x + WIDTH > X_MAX - WIDTH) begin
      x_left = x - x_vel_i;
      x_right = X_MAX - WIDTH;
    end else begin
      x_left = x - x_vel_i;
      x_right = x + x_vel_i;
    end

    if (y < HEIGHT) begin
      x_left = 0;
      x_right = x + x_vel_i;
    end else if (x > Y_MAX - HEIGHT) begin
      x_left = x - x_vel_i;
      x_right = X_MAX;
    end else begin
      x_left = x - x_vel_i;
      x_right = x + x_vel_i;
    end
  end // always @(*)

  // Movement counters
  always @(posedge clk) begin
    if (rst_i) begin
      x <= 0;
      y <= 0;
      angle <= 0;
    end else begin
      if (update_movement_settings_i) begin
        // Square 0 X
        if (inp_left && inp_right) begin
          square_x_0 <= square_x_0;
        end else if (inp_left & (square_x_0 > 0)) begin
          square_x_0 <= square_x_0 - 1;
        end else if (inp_right & (square_x_0 < (X_MAX - WIDTH + 1))) begin
          square_x_0 <= square_x_0 + 1;
        end else begin
          square_x_0 <= square_x_0;
        end
        
        // Square 0 Y
        if (inp_up && inp_down) begin
          square_y_0 <= square_y_0;
        end else if (inp_up & (square_y_0 > 0)) begin
          square_y_0 <= square_y_0 - 1;
        end else if (inp_down & (square_y_0 < Y_MAX - HEIGHT + 1)) begin
          square_y_0 <= square_y_0 + 1;
        end else begin
          square_y_0 <= square_y_0;
        end
      end else begin
        square_x_0 <= square_x_0;
        square_y_0 <= square_y_0;
        square_x_1 <= square_x_1;
        square_y_1 <= square_y_1;
      end
    end
  end // always @(posedge clk)

endmodule // simple_ship_movement_manager

module cardinal_directions_cleaner (
  input wire [3:0] cardinal_i,
  output wire [3:0] cardinal_o
);

  // Up, down, left, right. Set up/down or left/right to 0 if both are 1.
  assign cardinal_o = cardinal_i ^ {{2{&cardinal_i[3:2]}}, {2{&cardinal_i[1:0]}}};

endmodule // cardinal_directions_cleaner

// Assumes clean cardinal inputs
module cardinal_to_spaceship_controls (
  input wire thrust_i,
  input wire [2:0] angle_i,
  output wire [3:0] cardinal_o // udlr
);

// Store movement if movement is requested
wire cardinal_thrust;

// Convert angle to direction of forward movement for this angle
always @(*) begin
  case (angle_i)
    3'h0:    cardinal_thrust = 4'b1000;
    3'h1:    cardinal_thrust = 4'b1001;
    3'h2:    cardinal_thrust = 4'b0001;
    3'h3:    cardinal_thrust = 4'b0101;
    3'h4:    cardinal_thrust = 4'b0100;
    3'h5:    cardinal_thrust = 4'b0110;
    3'h6:    cardinal_thrust = 4'b0010;
    3'h7:    cardinal_thrust = 4'b1010;
    default: cardinal_thrust = 4'b0000;
  endcase
end // always @(*)

// Output movement
assign cardinal_o = thrust_i ? cardinal_thrust : 4'b0;

endmodule // cardinal_to_spaceship_controls
