//Játékhelyzetet írja az SRAM-ba, hogy a vga_controller kirajzolja azt
module game_drawer (
	input clk,
	input rst,
	input write_enable, //Írhatjuk-e az SRAM-ot (jelenleg nincsen olvasva)
	input [1:0] game_state,
	input [1:0] current_block_type, //Mit olvasunk a pályarajzolásnál
	input [8:0] character_x,
	input [8:0] character_y,
	input char_state, //Melyik karakter sprite-ot rajzoljuk (animációhoz)
	input face, //Merre fordul a karakter
	input reach_end, //Pálya végét elértük-e
	input obs_down, //Alattunk van-e akadály (ha nincs akkor ugró sprite-ot jelzünk ki)
	input vertical_porch_start, //Van-e sok idonk egyszerre, hogy írjuk a memóriát
	input scene_write, //Jelenleg írjuk-e a pályainformációt, mert csak akkor rajzolunk ha nem
	output reg [8:0] mem_addr_x,
	output reg [8:0] mem_addr_y,
	output reg [5:0] data_out, //Hol írjuk és mit a memóriába
	output [8:0] draw_scene_addr, //Hol olvassuk a pályát a pálya kirajzolásához
	output reg enable_color = 1, //Engedélyezzük-e az elküldött információnak a memóriába írását-e
	output reg draw_scene_done = 0 //Platformok kirajzolásának a végét jelzi
	);

	reg [2:0] character_1_sprite [0:799];
	reg [2:0] character_2_sprite [0:799];
	reg [2:0] character_jump_sprite [0:799];
	reg block_sprite [0:399];
	reg [1:0] coin_sprite [0:399];
	reg [1:0] cactus_sprite [0:399];

	initial begin
		$readmemh("./resources/character_1.txt", character_1_sprite);
		$readmemh("./resources/character_2.txt", character_2_sprite);
		$readmemh("./resources/character_jump.txt", character_jump_sprite);
		$readmemh("./resources/block.txt", block_sprite);
		$readmemh("./resources/cactus.txt", cactus_sprite);
		$readmemh("./resources/coin.txt", coin_sprite);
	end

	//Pálya 20x20-as egységein mennek végig
	reg [4:0] counter_x = 0;
	reg [3:0] counter_y = 0;

	//Mindegyik egységnek a pixelein mennek végig
	reg [4:0] sprite_counter_x = 0; //BLOCK_WIDTH-ig vagy CHARACTER_WIDTH-ig szamol
	reg [5:0] sprite_counter_y = 0; //BLOCK_HEIGHT-ig vagy CHARACTER_HEIGHT-ig szamol

	localparam SCENE_BLOCK_WIDTH = 20;
	localparam SCENE_BLOCK_HEIGHT = 15;

	localparam BLOCK_WIDTH = 20;
	localparam BLOCK_HEIGHT = 20;

	localparam CHARACTER_WIDTH = BLOCK_WIDTH;
	localparam CHARACTER_HEIGHT = 2 * BLOCK_HEIGHT;

	localparam GENERATE = 0;
	localparam DRAW_SCENE = 1;
	localparam PLAY = 2;
	localparam END = 3;

	//Játék közben vagy töröljük a karaktert, vagy írjuk, vagy várunk
	localparam remove_character = 0;
	localparam draw_character = 1;
	localparam draw_pause = 2;

	reg [1:0] draw_state = draw_character;

  	reg [8:0] character_old_x; //Kirajzolashoz, hogy mit toroljunk
   reg [8:0] character_old_y;

	assign draw_scene_addr = counter_y * SCENE_BLOCK_WIDTH + counter_x;

	always @ (posedge clk) begin
		if(game_state != DRAW_SCENE & game_state != END) begin
			counter_x <= 0;
			counter_y <= 0;
		end

		//Ha elértük a végét, akkor DRAW_SCENE állapotba kitöröljük a karakter régi helyzetét úgyis
		if(reach_end) begin
			character_old_x <= 0;
			character_old_y <= 239;
		end

		if(rst) begin
			counter_x <= 0;
			counter_y <= 0;
			sprite_counter_x <= 0;
			sprite_counter_y <= 0;
			draw_scene_done <= 0;
			draw_state <= remove_character;
			character_old_x <= 0;
			character_old_y <= 239;
		end
		else if(write_enable) begin
			if((game_state == DRAW_SCENE | game_state == END) & !scene_write) begin
				draw_state <= remove_character;
				if(sprite_counter_x >= BLOCK_WIDTH - 1) begin
					sprite_counter_x <= 0;
					if(sprite_counter_y >= BLOCK_HEIGHT - 1) begin
						sprite_counter_y <= 0;
						if(counter_x >= SCENE_BLOCK_WIDTH - 1) begin
							counter_x <= 0;
							if(counter_y >= SCENE_BLOCK_HEIGHT - 1) begin
								counter_y <= 0;
								draw_scene_done <= 1;
							end
							else begin
								counter_y <= counter_y + 1;
							end
						end
						else begin
							counter_x <= counter_x + 1;
						end
					end
					else begin
						sprite_counter_y <= sprite_counter_y + 1;
					end
				end
				else begin
					sprite_counter_x <= sprite_counter_x + 1;
				end
			end
			else if(game_state == PLAY & draw_state != draw_pause) begin
				if(sprite_counter_x >= CHARACTER_WIDTH - 1) begin
					sprite_counter_x <= 0;
					if(sprite_counter_y >= CHARACTER_HEIGHT - 1) begin
						sprite_counter_y <= 0;
						if(draw_state == remove_character) begin
							draw_state <= draw_character;
						end
						else if(draw_state == draw_character) begin
							character_old_x <= character_x;
							character_old_y <= character_y;
							draw_state <= draw_pause;
						end
					end
					else begin
						sprite_counter_y <= sprite_counter_y + 1;
					end
				end
				else
					sprite_counter_x <= sprite_counter_x + 1;
			end
		end
		//Akkor kezdjük a karakter törlésért, amikor sok idonk van rá egyszerre
		if(vertical_porch_start & draw_state == draw_pause) begin
			draw_state <= remove_character;
			sprite_counter_x <= 0;
			sprite_counter_y <= 0;
		end
		if(game_state != DRAW_SCENE)
			draw_scene_done <= 0;
	end

	 reg [3:0] temp_color;
	 reg [6:0] decoded_color; //Legfelso bitje jelzi, hogy átlátszó-e

	 localparam BACKGROUND = 0;
	 localparam BLOCK = 1;
	 localparam CACTUS = 2;
	 localparam COIN = 3;
	 localparam background_color = 6'b011011;

	 //Sprite selection
 	 wire [2:0] character_1_color;
 	 wire [2:0] current_character_color;
 	 wire [2:0] character_2_color;
 	 wire [2:0] character_jump_color;

	//3 sprite van a karakterhez és az álló sprite-okhoz kétféle helyze (jobbra vagy balra néz)
	 assign current_character_color = !obs_down ?
	 	character_jump_sprite[sprite_counter_y * CHARACTER_WIDTH + sprite_counter_x]
		: char_state ?
	 	character_2_sprite[sprite_counter_y * CHARACTER_WIDTH + face * sprite_counter_x + (1 - face) * (CHARACTER_WIDTH - 1 - sprite_counter_x)]
		: character_1_sprite[sprite_counter_y * CHARACTER_WIDTH + face * sprite_counter_x + (1 - face) * (CHARACTER_WIDTH - 1 - sprite_counter_x)];

	//Sprite kirajzolása a következo
	//Szöveges fájlból kiveszünk egy kódot
	//Ezt megfeleloen dekódoljuk egy case szerkezettel mindegyikhez
	//Beírjuk a memóriába a dekódolt pixelszínt
	//Pixelszín 6 bites, azonban a dekódolt szín 7 bites, legfelso bit jelzi, hogy átlátszó lesz-e a pixel (így nem írja fölül az alatta lévo objektumot)
	 always @ (posedge clk) begin
	 	if(rst)
			enable_color <= 1; //Ha átlátszó az objektum akkor nem engedélyezzük az írást
		else if (write_enable & !scene_write) begin
			//Játék végekor kék képernyot rajzolunk
			if(game_state == END) begin
				mem_addr_x <= counter_x * BLOCK_WIDTH + sprite_counter_x;
				mem_addr_y <= counter_y * BLOCK_HEIGHT + sprite_counter_y;
				decoded_color = {1'b0, background_color};
				enable_color <= 1;
			end
			else if(game_state == DRAW_SCENE) begin
				mem_addr_x <= counter_x * BLOCK_WIDTH + sprite_counter_x;
				mem_addr_y <= counter_y * BLOCK_HEIGHT + sprite_counter_y;
				if(current_block_type == BACKGROUND) begin
					decoded_color = background_color;
				end
				else if(current_block_type == BLOCK) begin
					temp_color = block_sprite[sprite_counter_y * BLOCK_WIDTH + sprite_counter_x];
					case (temp_color)
						1'h0: decoded_color[6:0] = 7'b0010101;
						1'h1: decoded_color[6:0] = 7'b0100100;
						default: decoded_color[6] = 1'b1;
					endcase
				end
				else if(current_block_type == CACTUS) begin
					temp_color = cactus_sprite[sprite_counter_y * BLOCK_WIDTH + sprite_counter_x];
					case (temp_color)
						2'h0: decoded_color[6:0] = {1'b0, background_color};
						2'h1: decoded_color[6:0] = 7'b0000100;
						2'h2: decoded_color[6:0] = 7'b0000000;
						default: decoded_color[6] = 1'b1;
					endcase
				end
				else if(current_block_type == COIN) begin
					temp_color = coin_sprite[sprite_counter_y * BLOCK_WIDTH + sprite_counter_x];
					case (temp_color)
						2'h0: decoded_color[6:0] = {1'b0, background_color};
						2'h1: decoded_color[6:0] = 7'b0111100;
						2'h2: decoded_color[6:0] = 7'b0111000;
						default: decoded_color[6] = 1'b1;
					endcase
				end
				enable_color <= 1;
			end //DRAW_SCENE

			else if(game_state == PLAY) begin
				if(draw_state == draw_character) begin
					case (current_character_color)
						3'h0: decoded_color[6:0] = {1'b0, background_color};
						3'h1: decoded_color[6:0] = 7'b0000001;
						3'h2: decoded_color[6:0] = 7'b0000100;
						3'h3: decoded_color[6:0] = 7'b0100101;
						3'h4: decoded_color[6:0] = 7'b0110000;
						3'h5: decoded_color[6:0] = 7'b0111100;
						default: decoded_color[6] = 1'b1;
					endcase

					mem_addr_x <= sprite_counter_x + character_x;
					mem_addr_y <= sprite_counter_y + character_y;
					enable_color <= 1;
				end
				else if(draw_state == remove_character) begin
					mem_addr_x <= sprite_counter_x + character_old_x;
					mem_addr_y <= sprite_counter_y + character_old_y;
					decoded_color = {1'b0, background_color};
					enable_color <= 1;
				end
				else
					enable_color <= 0;
			end
			data_out <= decoded_color[5:0];
	 	end
	 end
endmodule // game_drawer
