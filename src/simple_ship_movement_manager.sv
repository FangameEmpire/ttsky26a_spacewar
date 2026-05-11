module simple_ship_movement_manager #(
  parameter WIDTH = 32,
  parameter HEIGHT = 32,
  parameter X_VEL = 4'h7,
  parameter Y_VEL = 4'h7
) (
  input wire clk_i,
  input wire rst_i,
  input wire en_i,
  input wire [9:0] load_x_i,
  input wire [9:0] load_y_i,
  input wire [2:0] load_angle_i,
  input wire load_movement_settings_i,
  input wire [3:0] cardinal_i,
  input wire allow_angle_upd_i,
  input wire update_movement_settings_i,
  output wire [9:0] x_o,
  output wire [9:0] y_o,
  output wire [2:0] angle_o
);
  // Store parameters
  localparam X_MAX = (640 - 1);
  localparam Y_MAX = (480 - 1);

  // Store internal copies of position and angle
  reg [9:0] x, y;
  reg [2:0] angle;

  // Clean up inputs
  wire [3:0] cardinal_nodown, cardinal, cardinal_ship;
  cardinal_down_remover down_remover (.cardinal_i, .cardinal_o(cardinal_nodown));
  cardinal_directions_cleaner udlr_overlap_cleaner (.cardinal_i(cardinal_nodown), .cardinal_o(cardinal));
  cardinal_to_spaceship_controls udlr_ship (.thrust_i(cardinal[3]), .angle_i(angle), .cardinal_o(cardinal_ship));

  // Calculate potential moves
  reg [9:0] y_up, y_down, x_left, x_right;

  always @(*) begin
    if (x < X_VEL) begin
      x_left = 0;
      x_right = x + X_VEL;
    end else if (x > (X_MAX - WIDTH - X_VEL + 1)) begin
      x_left = x - X_VEL;
      x_right = X_MAX - WIDTH;
    end else begin
      x_left = x - X_VEL;
      x_right = x + X_VEL;
    end

    if (y < Y_VEL) begin
      y_up = 0;
      y_down = y + Y_VEL;
    end else if (y > (Y_MAX - HEIGHT - Y_VEL + 1)) begin
      y_up = y - Y_VEL;
      y_down = Y_MAX - HEIGHT;
    end else begin
      y_up = y - Y_VEL;
      y_down = y + Y_VEL;
    end
  end // always @(*)

  // Movement counters
  always @(posedge clk_i) begin
    if (rst_i) begin
      x <= 0;
      y <= 0;
      angle <= 0;
    end else begin
      if (en_i & update_movement_settings_i) begin
        // X Coordinate
        if (load_movement_settings_i) begin
          x <= load_x_i;
        end else if (cardinal_ship[1] & (x > 0)) begin
          x <= x_left;
        end else if (cardinal_ship[0] & (x < (X_MAX - WIDTH + 1))) begin
          x <= x_right;
        end else begin
          x <= x;
        end
        
        // Y Position
        if (load_movement_settings_i) begin
          y <= load_y_i;
        end else if (cardinal_ship[3] & (y > 0)) begin
          y <= y_up;
        end else if (cardinal_ship[2] & (y < Y_MAX - HEIGHT + 1)) begin
          y <= y_down;
        end else begin
          y <= y;
        end

        // Angle
        if (load_movement_settings_i) begin
          angle <= load_angle_i;
        end else if (allow_angle_upd_i & cardinal[1]) begin
          angle <= angle - 1;
        end else if (allow_angle_upd_i & cardinal[0]) begin
          angle <= angle + 1;
        end else begin
          angle <= angle;
        end
        
      end else begin
        x <= x;
        y <= y;
        angle <= angle;
      end
    end
  end // always @(posedge clk)

  // Outputs
  assign x_o = x;
  assign y_o = y;
  assign angle_o = angle;

endmodule // simple_ship_movement_manager

module cardinal_down_remover (
  input wire [3:0] cardinal_i,
  output wire [3:0] cardinal_o
);

  assign cardinal_o = {cardinal_i[3], 1'b0, cardinal_i[1:0]};

endmodule // cardinal_down_remover

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
reg [3:0] cardinal_thrust;

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
