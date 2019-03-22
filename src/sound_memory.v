//Hanganyagok tartalmazó memória, csak olvasható
module sound_memory (
	input [6:0] address,
	input en,
	output [6:0] data
	);

	reg [6:0] sound_file [127:0];

	initial $readmemh("./resources/sound.txt", sound_file);

	assign data = en ? sound_file[address] : 0;

endmodule // sound_memory
