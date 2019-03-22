//Hangeffektek kiadásáért felelos
module audio_controller (
	input clk,
	input rst,
	input start, //Elkezdje-e a hang kiadását (egy órajelig aktív impulzus)
	output sound //Hangszóróra kiadott jel
	);

	reg [6:0] address = 0;
	//Jelzi, hogy az utolsó két adatot kiadjuk-e mégegyszer
	reg [4:0] reverse_counter = 0;
	//7 biten kvantált hangfájlunk van, melynek 128 értéke
	wire [6:0] duty;

	wire en;

	rategen #(.COUNTER_WIDTH(14), .DIVISOR(9766)) sample (clk, rst, en); //5120 Hz

	sound_memory sound_memory_i(.address(address), .en(1'b1), .data(duty));

	always @ (posedge clk) begin
		if(rst | start) begin
			address <= 0;
			reverse_counter <= 0;
		end
		else begin
			//Hogy kis méretu hangfájlunk legyen, újrajátsztuk az utolsó két hangot 16-szor (érmefelvételkor)
			if(en & address < 127) begin
				reverse_counter <= reverse_counter + 1;
				if(address[0] == 1 & reverse_counter != 31 & reverse_counter[0] == 1) begin
					address <= address - 1;
				end
				else
					address <= address + 1;
			end
		end
	end

	reg [6:0] counter = 0;
	always @ (posedge clk)
		if(rst)
			counter <= 0;
		else
			counter <= counter + 1;
	
	//Kitöltési tényezo módosításával tudunk különbözo amplitúdót kiadni
	assign sound = (counter < duty);

endmodule // audio_controller
