//DP memória, A porton olvasunk csak, B porton írunk csak
module scene_memory (
	input clk,
	input we_b,
	input [8:0] addr_a,
	input [8:0]	addr_b,
	input [1:0] data_b,
	output [1:0] q_a
	);

	reg [1:0] scene [0:299];

	// Port A
	assign q_a = (scene[addr_a]);

	// Port B
	always @ (posedge clk)
	begin
		if (we_b)
		begin
			scene[addr_b] <= data_b;
		end
	end

endmodule // scene_memory
