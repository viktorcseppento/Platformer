//Ketto 70 Hz-es enegedélyezo jelet generál a ketto úniója egy 140 Hz-es jel, képfrissítés 70 Hz
module double_rategen(
	input clk50M,
	input rst,
	output reg clk70_1,
	output reg clk70_2
);

	reg [22:0] counter = 0;
	localparam  value = 714283; //70Hz
	always @ (posedge clk50M) begin
		if(clk70_1 | rst)
			counter <= 0;
		else
			counter <= counter + 1;

		clk70_1 <= counter == value;
		clk70_2 <= counter == (value / 2);
	end

endmodule
