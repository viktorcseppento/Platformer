//Ütközésészlelo modul
module collision_detector (
	input clk,
	input rst,
	input game_clock,
	input [1:0] current_block_type, //Mit olvasunk a kiadott helyen
	input play_state, //JÁTÉK állapot van-e
	input [8:0] character_x,
	input [8:0] character_y,
	output [8:0] collision_detect_addr, //Jelenleg hol vizsgálunk objektumot
	output [8:0] remove_coin_addr, //Melyik érmét kell törölni
	output reg reach_end = 0, //Elértük-e a pálya végét
	output reg to_remove = 0, //Kell-e érmét törölni
	output reg just_removed = 0,
	output reg obs_up, //Jelzik, hogy vannak-e mellettünk BLOCK-ok
	output reg obs_right,
	output reg obs_down,
	output reg obs_left,
	output reg die = 0, //Meghalást jelzo
	output reg [7:0] score = 0, //Pontszám
	output collision_detect_done //Észlelés végét jelzi
	);

	localparam BACKGROUND = 0;
	localparam BLOCK = 1;
	localparam CACTUS = 2;
	localparam COIN = 3;

	localparam SCENE_BLOCK_WIDTH = 20;
	localparam SCENE_BLOCK_HEIGHT = 15;

	localparam SCENE_WIDTH = 400;
	localparam SCENE_HEIGHT = 300;

	localparam BLOCK_WIDTH = 20;
	localparam BLOCK_HEIGHT = 20;

	localparam CHARACTER_WIDTH = BLOCK_WIDTH;
	localparam CHARACTER_HEIGHT = 2 * BLOCK_HEIGHT;

	//Ezekkel megyünk végig a pályán
	reg [4:0] scene_counter_x = 0; //SCENE_BLOCK_WIDTH-ig szamol
	reg [3:0] scene_counter_y = 0; //SCENE_BLOCK_HEIGHT-ig szamol
	
	wire [8:0] collision_block_x;
	wire [8:0] collision_block_y;
	
	assign collision_block_x = scene_counter_x * BLOCK_WIDTH;
	assign collision_block_y = scene_counter_y * BLOCK_HEIGHT;

	reg [4:0] removable_coin_x;
	reg [3:0] removable_coin_y;

	//3 állapotó ütközésészlelés
	localparam collision_init = 0;
	localparam collision_do = 1;
	localparam collision_stop = 2;

	reg [1:0] collision_state = collision_init;
	
	assign collision_detect_done = (collision_state == collision_stop);

	assign remove_coin_addr = removable_coin_y * SCENE_BLOCK_WIDTH + removable_coin_x;

	assign collision_detect_addr = scene_counter_y * SCENE_BLOCK_WIDTH + scene_counter_x;

	//Számlálókkal végigmegyünk az összes pozíción
	always @ (posedge clk) begin
		if (rst | !play_state) begin
			scene_counter_x <= 0;
			scene_counter_y <= 0;
			collision_state <= collision_init;
		end
		else if(play_state) begin
			if(collision_state == collision_do) begin
				if(scene_counter_x == SCENE_BLOCK_WIDTH - 1) begin
					scene_counter_x <= 0;
					if(scene_counter_y == SCENE_BLOCK_HEIGHT - 1) begin
						scene_counter_y <= 0;
						collision_state <= collision_stop;
					end
					else
						scene_counter_y <= scene_counter_y + 1'b1;
				end
				else begin
					scene_counter_x <= scene_counter_x + 1'b1;
				end
			end

			else if(collision_state == collision_stop) begin
				//Ha jel jött elkezdjük újra az észlelést
				if(game_clock)
					collision_state <= collision_init;
				scene_counter_x <= 0;
				scene_counter_y <= 0;
			end
			else if(collision_state == collision_init)
				collision_state <= collision_do;
		end
	end


	always @ (posedge clk) begin
		if(rst) begin
			die <= 1'b0;
			reach_end <= 1'b0;
			score <= 8'b0;
			to_remove <= 1'b0;
			just_removed <= 1'b0;
		end
		else if(play_state) begin
			if(collision_state == collision_do) begin
				if(current_block_type == BLOCK) begin
					//UP
					if(character_y == collision_block_y + BLOCK_HEIGHT) begin
						if(character_x + CHARACTER_WIDTH > collision_block_x & character_x < collision_block_x + BLOCK_WIDTH)
							obs_up <= 1;
					end
					else if(character_y == 0)
						obs_up <= 1;
					//END UP

					//RIGHT
					if(character_x + CHARACTER_WIDTH == collision_block_x ) begin
						if(character_y + CHARACTER_HEIGHT > collision_block_y & character_y < collision_block_y + BLOCK_HEIGHT)
							obs_right <= 1;
					end
					else if(character_x + CHARACTER_WIDTH / 2 == SCENE_WIDTH) begin
						reach_end <= 1;
					end
					//END RIGHT

					//DOWN
					if(character_y + CHARACTER_HEIGHT == collision_block_y) begin
						if(character_x + CHARACTER_WIDTH > collision_block_x & character_x < collision_block_x + BLOCK_WIDTH)
							obs_down <= 1;
					end
					else if(character_y + CHARACTER_HEIGHT == SCENE_HEIGHT)
						obs_down <= 1;
					//END DOWN

					//LEFT
					if(character_x == collision_block_x + BLOCK_WIDTH) begin
						if(character_y + CHARACTER_HEIGHT > collision_block_y & character_y < collision_block_y + BLOCK_HEIGHT)
							obs_left <= 1;
					end
					else if(character_x == 0)
						obs_left <= 1;
					//END LEFT
				end //IF BLOCK
				//Ha benne vagyunk egy kaktuszban vagy érmében
				if(character_x <= collision_block_x + BLOCK_WIDTH - 1
					& character_x + CHARACTER_WIDTH - 1 >= collision_block_x
					& character_y <= collision_block_y + BLOCK_HEIGHT - 1
					& character_y + CHARACTER_HEIGHT - 1 >= collision_block_y) begin

					if(current_block_type == CACTUS) begin
						die <= 1;
					end
					//Ha érmében vagyunk akkor felvesszük azt
					else if(current_block_type == COIN & !to_remove) begin
						to_remove <= 1'b1;
						removable_coin_x <= scene_counter_x;
						removable_coin_y <= scene_counter_y;
						score <= score + 1'b1;
						if(score[3:0] == 4'b1001) begin
							score[3:0] <= 0;
							score[7:4] <= score[7:4] + 1'b1;
						end
					end
				end
			end
			else if(collision_state == collision_init) begin
				obs_up <= 0;
				obs_right <= 0;
				obs_down <= 0;
				obs_left <= 0;
				reach_end <= 0;
			end
		end
		//2 órajelig töröljük ha vettünk fel érmét
		if(to_remove) begin
			to_remove <= 0;
			just_removed <= 1;
		end
		if(just_removed)
			just_removed <= 0;
	end

endmodule // collision_detector
