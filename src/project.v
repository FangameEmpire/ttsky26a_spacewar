/*
 * Copyright (c) 2026 Nicklaus Thompson
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_spacewar_top (
  input  wire [7:0] ui_in,    // Dedicated inputs
  output wire [7:0] uo_out,   // Dedicated outputs
  input  wire [7:0] uio_in,   // IOs: Input path
  output wire [7:0] uio_out,  // IOs: Output path
  output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
  input  wire       ena,      // always 1 when the design is powered, so you can ignore it
  input  wire       clk,      // clock
  input  wire       rst_n     // reset_n - low to reset
);

  // VGA signals
  wire hsync;
  wire vsync;
  wire [1:0] R;
  wire [1:0] G;
  wire [1:0] B;
  wire video_active;
  wire [9:0] pix_x;
  wire [9:0] pix_y;

  // TinyVGA PMOD
  assign uo_out = {hsync, B[0], G[0], R[0], vsync, B[1], G[1], R[1]};

  // Audio enable
  assign uio_oe[7] = 1'b1;

  // Unused outputs assigned to 0.
  assign uio_out[6:0] = 0;
  assign uio_oe[6:0]  = 0;

  // Suppress unused signals warning
  wire _unused_ok = &{ena, ui_in, uio_in};

  // Always nice to have some counters around
  reg [9:0] counter;
  reg [3:0] frame_counter;

  always @(posedge clk, negedge rst_n) begin
    if (~rst_n) begin
      counter <= 0;
    end else begin
      counter <= counter + 1;
    end
  end

  always @(posedge clk, negedge rst_n) begin
    if (~rst_n) begin
      frame_counter <= 0;
    end else if (frame_edges[0]) begin
      frame_counter <= frame_counter + 1;
    end else begin
      frame_counter <= frame_counter;
    end
  end

  // Counter-based signals
  wire allow_angle_upd;
  assign allow_angle_upd = (frame_counter[1:0] == 0);

  // Suppress unused signals warning
  wire _unused_ok_ = &{pix_y};

  // Ship tests
  wire [9:0] ship_x_0, ship_y_0, ship_x_1, ship_y_1;
  wire [2:0] ship_angle_0, ship_angle_1;
  wire [1:0] draw_ship_line, in_ship_hitbox;

  wire [3:0] default_vel;
  assign default_vel = 4'h7;
  localparam SHIP_SIZE = 16;

  simple_ship_wrapper #(.WIDTH(SHIP_SIZE), .HEIGHT(SHIP_SIZE)) ship_wrapper_0 (
    .clk_i(clk), .rst_i(~rst_n), .en_i(1'b1), .pix_x_i(pix_x), .pix_y_i(pix_y), .cardinal_i(udlr),
    .load_x_i(10'd255), .load_y_i(10'd130), .load_angle_i(3'h6), .load_movement_settings_i(ui_in[7]),
    .x_vel_i(default_vel), .y_vel_i(default_vel), .allow_angle_upd_i(allow_angle_upd), .update_movement_settings_i(frame_edges[1]),
    .x_o(ship_x_0), .y_o(ship_y_0), .angle_o(ship_angle_0),
    .draw_ship_line_o(draw_ship_line[0]), .in_ship_hitbox_o(in_ship_hitbox[0])
  );

  simple_ship_wrapper #(.WIDTH(SHIP_SIZE), .HEIGHT(SHIP_SIZE)) ship_wrapper_1 (
    .clk_i(clk), .rst_i(~rst_n), .en_i(1'b1), .pix_x_i(pix_x), .pix_y_i(pix_y), .cardinal_i(xbya),
    .load_x_i(10'd100), .load_y_i(10'd250), .load_angle_i(3'h2), .load_movement_settings_i(ui_in[7]),
    .x_vel_i(default_vel), .y_vel_i(default_vel), .allow_angle_upd_i(allow_angle_upd), .update_movement_settings_i(frame_edges[1]),
    .x_o(ship_x_1), .y_o(ship_y_1), .angle_o(ship_angle_1),
    .draw_ship_line_o(draw_ship_line[1]), .in_ship_hitbox_o(in_ship_hitbox[1])
  );

  // Star tests
  wire star_man_en_0;
  wire [9:0] star_x, star_y;
  wire [5:0] star_man_x_0, star_man_y_0;
  vga_offset_manager star_offset (.en_i(1'b1), .pix_x_i(pix_x >> 3), .pix_y_i(pix_y >> 3), .object_x_i(star_x), .object_y_i(star_y),
    .object_en_o(star_man_en_0), .object_x_o(star_man_x_0), .object_y_o(star_man_y_0));
  
  wire draw_star, in_star_killzone;
  center_star_vga_manager star_man (.clk_i(clk), .rst_i(~rst_n), .en_i(star_man_en_0), .pix_x_i(star_man_x_0), .pix_y_i(star_man_y_0),
    .rng_i(10'b0), .frame_upd_i(1'b0), .draw_star_o(draw_star), .in_star_killzone_o(in_star_killzone));

  assign star_x = 10'd40;
  assign star_y = 10'd10;

  // Noise generator
  wire [12:0] rng;
  wire audio_gun, audio_thrust, audio_death, audio_gun_sync;
  spacewar_noise_generator noise_gen_0 (.clk_i(clk), .rst_i(~rst_n), .en_i(1'b1), .rng_o(rng), .gun_sync_o(audio_gun_sync),
    .gun_o(audio_gun), .thrust_o(audio_thrust), .death_o(audio_death));

  // Gamepad Pmod
  wire inp_b, inp_y, inp_select, inp_start, inp_up, inp_down, inp_left, inp_right, inp_a, inp_x, inp_l, inp_r;
  wire [3:0] udlr, xbya;
  assign udlr = {inp_up, inp_down, inp_left, inp_right};
  assign xbya = {inp_x, inp_b, inp_y, inp_a};

  gamepad_pmod_single gamepad_driver (
      // Inputs:
      .rst_n(rst_n),
      .clk(clk),
      .pmod_data(ui_in[6]),
      .pmod_clk(ui_in[5]),
      .pmod_latch(ui_in[4]),
      // Outputs:
      .b(inp_b),
      .y(inp_y),
      .select(inp_select),
      .start(inp_start),
      .up(inp_up),
      .down(inp_down),
      .left(inp_left),
      .right(inp_right),
      .a(inp_a),
      .x(inp_x),
      .l(inp_l),
      .r(inp_r)
  );

  // VGA
  assign R = {2{video_active}} & {2{(ui_in[3] & |in_ship_hitbox) | in_star_killzone}};
  assign G = {2{1'b1}} & {2{|draw_ship_line}};
  assign B = {2{video_active}} & {2{draw_star}};

  // Audio
  assign uio_out[7] = audio_gun & inp_l;

  // Generate sync signals
  hvsync_generator hvsync_gen (
    .clk(clk),
    .reset(~rst_n),
    .hsync(hsync),
    .vsync(vsync),
    .display_on(video_active),
    .hpos(pix_x),
    .vpos(pix_y)
  );

  wire [1:0] frame_edges;
  hvsync_generator_decoder vga_sync_decoder (
      .hpos_i(pix_x),
      .vpos_i(pix_y),
      .state_o(),
      .flags_o(),
      .active_edges_o(frame_edges)
  );

endmodule // tt_um_spacewar_top
