//Generikus engedélyezojel-generáló
module rategen #(
	parameter COUNTER_WIDTH = 2,
	parameter DIVISOR = 4
	)(
	input clk,
	input rst,
	output en
	);

	reg [COUNTER_WIDTH - 1:0] counter = 0;

	always @ (posedge clk) begin
		if(en | rst)
			counter <= 0;
		else
			counter <= counter + 1'b1;

	end
	
	assign en = counter == DIVISOR - 1'b1;


endmodule // rategen
