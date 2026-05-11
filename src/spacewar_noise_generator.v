module spacewar_noise_generator (
  input wire clk_i,
  input wire rst_i,
  input wire en_i,

  output wire [12:0] rng_o,
  output wire gun_sync_o,

  output wire gun_o,
  output wire thrust_o,
  output wire death_o
);

// Parameters

`ifdef HVSYNC_50MHZ
  localparam FREQ = 50000000;
`else
  localparam FREQ = 25200000;
`endif
localparam integer BEEP_FREQ = 2000;
localparam integer BEEP_COUNTER_MAX = FREQ / ((BEEP_FREQ * 2) + 1);

// Counters
reg [14:0] beep_counter;
reg gun_q, gun_sync_q;

always @(posedge clk_i) begin
  if (rst_i) begin
    beep_counter <= 15'b0;
    gun_q <= 1'b0;
    gun_sync_q <= 0;
  end else if (en_i) begin
    if (beep_counter == BEEP_COUNTER_MAX) begin
      beep_counter <= 0;
      gun_q <= ~gun_q;
      gun_sync_q <= 1'b1;
    end else begin
      beep_counter <= beep_counter + 1;
      gun_q <= gun_q;
      gun_sync_q <= 1'b0;
    end
  end else begin
    beep_counter <= beep_counter;
    gun_q <= gun_q;
    gun_sync_q <= gun_sync_q;
  end
end // always @(posedge clk_i) begin

// RNG
reg [12:0] rng;
wire feedback = rng[12] ^ rng[8] ^ rng[2] ^ rng[0] + 1;
always @(posedge clk_i) begin
  rng <= {rng[11:0], feedback};
end

// Output
assign rng_o = rng;
assign gun_sync_o = gun_sync_q;
assign gun_o = gun_q;
assign thrust_o = 1'b0;
assign death_o = 1'b0;

endmodule // spacewar_noise_generator