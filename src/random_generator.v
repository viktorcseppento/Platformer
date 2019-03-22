//16 bites LFSR randomszám generáló
module random_generator (
	input clk,
	input rst,
	output reg [15:0] rand = 16'hDEAD
	);

	always @ (posedge clk) begin
		if(rst)
			rand <= 16'hDEAD;
		else
			rand <= {rand[14:0], rand[15] ^ rand[13] ^ rand[12] ^ rand[10] ^ 1'b1};
	end

endmodule // random_generator
