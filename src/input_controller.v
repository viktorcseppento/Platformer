//Perifériát kezel, valójában a kijelzoket is muködteti
//Cpld IC-t vezérli
module input_controller(
	input clk,
	input rst,

 	input cpld_miso,
	input [6:0] second_left,
	input [3:0] dig0,
	input [3:0] dig1,

	output reg cpld_mosi,
 	output reg cpld_clk,
 	output reg cpld_load,
 	output cpld_jtagen,
	output cpld_rstn,
 	output nav_u,
 	output nav_d,
 	output nav_l,
 	output nav_r,
 	output nav_sel

    );

	assign cpld_jtagen = 1'b0;

	wire [7:0] led;

	//Hátralévo ido függvényében muködnek a ledek
	assign led[0] = second_left > 0 ? 1'b1 : 1'b0;
	assign led[1] = second_left > 10 ? 1'b1 : 1'b0;
	assign led[2] = second_left > 20 ? 1'b1 : 1'b0;
	assign led[3] = second_left > 30 ? 1'b1 : 1'b0;
	assign led[4] = second_left > 40 ? 1'b1 : 1'b0;
	assign led[5] = second_left > 50 ? 1'b1 : 1'b0;
	assign led[6] = second_left > 60 ? 1'b1 : 1'b0;
	assign led[7] = second_left > 70 ? 1'b1 : 1'b0;

	reg [17:0] cntr = 1'b0;
	reg [15:0] outputs = 1'b0;

	always @ (posedge clk)
		if (rst)
			cntr <= 1'b0;
		else
			cntr <= cntr + 1'b1;

	always @ (posedge clk)	begin
		cpld_clk <= cntr[12];
		cpld_load <= (cntr[16:13] == 15);
		cpld_mosi <= mux_out;
		if(cpld_clk == 1 & cntr[11:0] == 0)
			outputs[cntr[16:13]] <= cpld_miso;
	end

	assign cpld_rstn = ~rst;
	assign nav_u = outputs[8];
	assign nav_d = outputs[9];
	assign nav_l = outputs[10];
	assign nav_r = outputs[11];
	assign nav_sel = outputs[12];

	reg [7:0] seg_dec;
	wire [3:0] dig_mux;
	assign dig_mux = (cntr[17]) ? dig1: dig0;
	always @(*)
    	case (dig_mux)
	      	4'b0001 : seg_dec = 8'b11111001;   // 1
	      	4'b0010 : seg_dec = 8'b10100100;   // 2
	      	4'b0011 : seg_dec = 8'b10110000;   // 3
	      	4'b0100 : seg_dec = 8'b10011001;   // 4
	      	4'b0101 : seg_dec = 8'b10010010;   // 5
	      	4'b0110 : seg_dec = 8'b10000010;   // 6
	      	4'b0111 : seg_dec = 8'b11111000;   // 7
	      	4'b1000 : seg_dec = 8'b10000000;   // 8
	      	4'b1001 : seg_dec = 8'b10010000;   // 9
	      	4'b1010 : seg_dec = 8'b10001000;   // A
	      	4'b1011 : seg_dec = 8'b10000011;   // b
	      	4'b1100 : seg_dec = 8'b11000110;   // C
	      	4'b1101 : seg_dec = 8'b10100001;   // d
	      	4'b1110 : seg_dec = 8'b10000110;   // E
	      	4'b1111 : seg_dec = 8'b10001110;   // F
	      	default : seg_dec = 8'b11000000;   // 0
      endcase

	wire [15:0] mux_in;
	wire mux_out;
	assign mux_in = {~seg_dec, led};
	assign mux_out = mux_in[cntr[16:13]];

endmodule
