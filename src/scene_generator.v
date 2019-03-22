//P�lyagener�l� modul
module scene_generator (
	input clk,
	input rst,
	input do_generate, //Menjen-e a gener�l�s
	output [8:0] generate_addr, //Melyik mem�riac�mbe gener�l a scene_memory-ba
	output reg [1:0] scene_in, //Mit gener�l a mem�ri�ba
	output reg generate_done //V�gzett-e
	);

	localparam BACKGROUND = 0;
	localparam BLOCK = 1;
	localparam CACTUS = 2;
	localparam COIN = 3;

	localparam SCENE_BLOCK_WIDTH = 20;
	localparam SCENE_BLOCK_HEIGHT = 15;

	//Bal als� sarokba gener�l elosz�r �s elosz�r f�ggolegesen mozog
	reg [3:0] scene_gen_y = SCENE_BLOCK_HEIGHT - 1;
	reg [4:0] scene_gen_x = 0;

	//Elozo block platform volt-e, tudunk-e coint vagy kaktuszt tenni
	reg was_block = 0;

	assign generate_addr = scene_gen_y * SCENE_BLOCK_WIDTH + scene_gen_x;

	wire [15:0] random;
	random_generator rand_i(.clk(clk), .rst(rst), .rand(random));

	always @ (posedge clk) begin
		if(rst | !do_generate) begin
			scene_gen_x <= 0;
			scene_gen_y <= SCENE_BLOCK_HEIGHT - 1;
			generate_done <= 0;
			was_block <= 0;
			scene_in <= BACKGROUND; //Ha nincs enged�lyezve a gener�l�s, folyamatosan h�tteret ad ki (�rme t�rl�sekor hasznos)
		end
		else if(do_generate) begin
			if(scene_gen_y == 0) begin
				scene_gen_y <= SCENE_BLOCK_HEIGHT - 1;
				if(scene_gen_x == SCENE_BLOCK_WIDTH - 1) begin
					scene_gen_x <= 0;
					generate_done <= 1;
				end
				else begin
					scene_gen_x <= scene_gen_x + 1'b1;
				end
			end
			else begin
				scene_gen_y <= scene_gen_y - 1'b1;
			end

			//Legals� sor teljes platform
 			if(scene_gen_y == SCENE_BLOCK_HEIGHT - 1) begin
				scene_in <= BLOCK;
				was_block <= 1;
			end
			//F�ldszinten k�v�l 2 szinten lehet m�g BLOCK
			else if(scene_gen_y == 4 | scene_gen_y == 9) begin
				if(random[15:11] > 20) begin //~34%
					scene_in <= BLOCK;
					was_block <= 1;
				end
				else begin
					scene_in <= BACKGROUND;
					was_block <= 0;
				end
			end
			//3 szinten (BLOCK szintek f�l�tt) lehetnek objektumok
			else if((scene_gen_y == 13 | scene_gen_y == 8 | scene_gen_y == 3) & was_block) begin
				if(random[11:8] > 13 & scene_gen_x > 1) //6%, elso 2 helyre nem tesz kaktuszt, nehogy r�gt�n belemenj�nk
					scene_in <= CACTUS;
				else if(random[11:8] < 3) //~8.5% hogy �rme lesz
					scene_in <= COIN;
				else begin
					scene_in <= BACKGROUND;
				end
			end
			else begin
				scene_in <= BACKGROUND;
				was_block <= 0;
			end
		end
	end

endmodule // scene_generator
