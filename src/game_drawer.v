//J�t�khelyzetet �rja az SRAM-ba, hogy a vga_controller kirajzolja azt
module game_drawer (
	input clk,
	input rst,
	input write_enable, //�rhatjuk-e az SRAM-ot (jelenleg nincsen olvasva)
	input [1:0] game_state,
	input [1:0] current_block_type, //Mit olvasunk a p�lyarajzol�sn�l
	input [8:0] character_x,
	input [8:0] character_y,
	input char_state, //Melyik karakter sprite-ot rajzoljuk (anim�ci�hoz)
	input face, //Merre fordul a karakter
	input reach_end, //P�lya v�g�t el�rt�k-e
	input obs_down, //Alattunk van-e akad�ly (ha nincs akkor ugr� sprite-ot jelz�nk ki)
	input vertical_porch_start, //Van-e sok idonk egyszerre, hogy �rjuk a mem�ri�t
	input scene_write, //Jelenleg �rjuk-e a p�lyainform�ci�t, mert csak akkor rajzolunk ha nem
	output reg [8:0] mem_addr_x,
	output reg [8:0] mem_addr_y,
	output reg [5:0] data_out, //Hol �rjuk �s mit a mem�ri�ba
	output [8:0] draw_scene_addr, //Hol olvassuk a p�ly�t a p�lya kirajzol�s�hoz
	output reg enable_color = 1, //Enged�lyezz�k-e az elk�ld�tt inform�ci�nak a mem�ri�ba �r�s�t-e
	output reg draw_scene_done = 0 //Platformok kirajzol�s�nak a v�g�t jelzi
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

	//P�lya 20x20-as egys�gein mennek v�gig
	reg [4:0] counter_x = 0;
	reg [3:0] counter_y = 0;

	//Mindegyik egys�gnek a pixelein mennek v�gig
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

	//J�t�k k�zben vagy t�r�lj�k a karaktert, vagy �rjuk, vagy v�runk
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

		//Ha el�rt�k a v�g�t, akkor DRAW_SCENE �llapotba kit�r�lj�k a karakter r�gi helyzet�t �gyis
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
		//Akkor kezdj�k a karakter t�rl�s�rt, amikor sok idonk van r� egyszerre
		if(vertical_porch_start & draw_state == draw_pause) begin
			draw_state <= remove_character;
			sprite_counter_x <= 0;
			sprite_counter_y <= 0;
		end
		if(game_state != DRAW_SCENE)
			draw_scene_done <= 0;
	end

	 reg [3:0] temp_color;
	 reg [6:0] decoded_color; //Legfelso bitje jelzi, hogy �tl�tsz�-e

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

	//3 sprite van a karakterhez �s az �ll� sprite-okhoz k�tf�le helyze (jobbra vagy balra n�z)
	 assign current_character_color = !obs_down ?
	 	character_jump_sprite[sprite_counter_y * CHARACTER_WIDTH + sprite_counter_x]
		: char_state ?
	 	character_2_sprite[sprite_counter_y * CHARACTER_WIDTH + face * sprite_counter_x + (1 - face) * (CHARACTER_WIDTH - 1 - sprite_counter_x)]
		: character_1_sprite[sprite_counter_y * CHARACTER_WIDTH + face * sprite_counter_x + (1 - face) * (CHARACTER_WIDTH - 1 - sprite_counter_x)];

	//Sprite kirajzol�sa a k�vetkezo
	//Sz�veges f�jlb�l kivesz�nk egy k�dot
	//Ezt megfeleloen dek�doljuk egy case szerkezettel mindegyikhez
	//Be�rjuk a mem�ri�ba a dek�dolt pixelsz�nt
	//Pixelsz�n 6 bites, azonban a dek�dolt sz�n 7 bites, legfelso bit jelzi, hogy �tl�tsz� lesz-e a pixel (�gy nem �rja f�l�l az alatta l�vo objektumot)
	 always @ (posedge clk) begin
	 	if(rst)
			enable_color <= 1; //Ha �tl�tsz� az objektum akkor nem enged�lyezz�k az �r�st
		else if (write_enable & !scene_write) begin
			//J�t�k v�gekor k�k k�pernyot rajzolunk
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
