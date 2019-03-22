//Hangeffektek kiad�s��rt felelos
module audio_controller (
	input clk,
	input rst,
	input start, //Elkezdje-e a hang kiad�s�t (egy �rajelig akt�v impulzus)
	output sound //Hangsz�r�ra kiadott jel
	);

	reg [6:0] address = 0;
	//Jelzi, hogy az utols� k�t adatot kiadjuk-e m�gegyszer
	reg [4:0] reverse_counter = 0;
	//7 biten kvant�lt hangf�jlunk van, melynek 128 �rt�ke
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
			//Hogy kis m�retu hangf�jlunk legyen, �jraj�tsztuk az utols� k�t hangot 16-szor (�rmefelv�telkor)
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
	
	//Kit�lt�si t�nyezo m�dos�t�s�val tudunk k�l�nb�zo amplit�d�t kiadni
	assign sound = (counter < duty);

endmodule // audio_controller
