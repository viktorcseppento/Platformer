module game_logic (
	input clk50M,
	input rst,

	input write_enable, //Írhatunk-e a memóriába
	input vertical_porch_start, //Kezdhetjük-e a burst kirajzolást

	input btn0, //Felhasználói input
	input btn1,
	input btn2,
	input nav_u,
	input nav_r,
	input nav_d,
	input nav_l,
	input nav_sel,

	output [8:0] mem_addr_x, //Memóriaírása
	output [8:0] mem_addr_y,
	output [5:0] data_out,
	output enable_color, //Engedélyezzük, hogy a kiadott adat menjen-e a memóriába
	
	output [6:0] second_left, //Hátralévo ido
	output [7:0] score, //Szerzett pontszám
	output start_sound //Kezdhetjük-e a hangeffektet
	);

	//Akkor kezdjük a hangeffektet, mikor felvettünk egy érmét
	assign start_sound = to_remove;

	//Karaktermozgatásért felelos
	reg move_up, move_right, move_left;

	wire game_clock_1, game_clock_2, slow_clock, second_clock; //Mozgásért, animációért, idoszámolásért felelos engedélyezo jelek
	//Külön frissítjük az x és y koordinátákat
	double_rategen game_clock_gen(clk50M, rst, game_clock_1, game_clock_2); //2 darab 70 Hz
	rategen #(.COUNTER_WIDTH(23), .DIVISOR(5000000)) slow_clock_gen (clk50M, rst, slow_clock); //10 Hz, animációért
	rategen #(.COUNTER_WIDTH(26), .DIVISOR(50000000)) one_second_gen (clk50M, rst, second_clock); //1 Hz, másodpercszámláló

	localparam START_TIME = 7'b1010000; //80 másodpercünk van a játékra

	reg [6:0] second_counter = START_TIME;

	//400x300 pixeles a képernyo, ami 20x15 nagyobb egységre bontható fel
	//Minden akadály, érme, kaktusz 1 egységben van
	localparam SCENE_WIDTH = 400;
	localparam SCENE_HEIGHT = 300;

	localparam SCENE_BLOCK_WIDTH = 20;
	localparam SCENE_BLOCK_HEIGHT = 15;

	localparam BLOCK_WIDTH = 20;
	localparam BLOCK_HEIGHT = 20;

	localparam CHARACTER_WIDTH = BLOCK_WIDTH;
	localparam CHARACTER_HEIGHT = 2 * BLOCK_HEIGHT;
	
	//Maximum 120 pixel magasra ugorhatunk
	localparam jump_max = 120;

	always @ (posedge clk50M) begin
		if(rst)
			second_counter <= START_TIME;
		else if(second_clock & second_counter > 0) begin
			second_counter <= second_counter - 1'b1;
		end
	end

	assign second_left = second_counter;

	reg [8:0] character_x = 0;
 	reg [8:0] character_y = 239;
	reg [6:0] jump_left = 0;

	//Karakter milyen irányba néz, jobbra - 1, balra - 0
	reg face = 1;

	//A játék 4 éllapotból áll
	//Generálunk random pályát, kirajzoljuk a fobb részeket, játék maga, végeképernyo
	localparam GENERATE = 0;
	localparam DRAW_SCENE = 1;
	localparam PLAY = 2;
	localparam END = 3;

	reg [1:0] game_state = GENERATE;

	always @ (posedge clk50M) begin
		//Pályagenerálással kezdünk, ekkor reset-eljük 
		if(rst | game_state == GENERATE) begin
			face <= 1;
			character_x <= 0;
			character_y <= 239;
			move_up = 0;
			move_right = 0;
			move_left = 0;
		end
		else if(game_clock_1 & game_state == PLAY & collision_detect_done) begin // Az utolsó feltétel mindig igaz lesz, csak biztonsági okokból van ott
			move_up = btn1 | nav_u; //Kétféle módon irányíthatunk
			move_right = btn0 | nav_r;
			move_left = btn2 | nav_l;

			//Ha nem akarunk ugrani
			if(!move_up) begin
				if(obs_down)
					jump_left <= jump_max;
				else begin //Ha nem nyomjuk a gombot és a levegoben van a karakter, nem tud többet emelkedni
					jump_left <= 0;
				end
			end //!move_up
			if(jump_left == 0 & !obs_down)
				character_y <= character_y + 1'b1; //Gravitáció

			if(move_up) begin
				if(jump_left != 0) begin
					if(!obs_up) begin
						character_y <= character_y - 1'b1;
						jump_left <= jump_left - 1'b1;
					end
					else begin //Ha van fölöttünk akadály jobban csökken az ugrásszámláló
						if(jump_left > 10)
							jump_left <= jump_left - 10;
						else
							jump_left <= 0;
					end
				end
			end //move_up

		end //else if(game_clock_1)
		else if(game_clock_2 & game_state == PLAY & collision_detect_done) begin
			if(move_right & !move_left) begin
				face <= 1;
				if(!obs_right)
					character_x <= character_x + 1'b1; //Csak akkor mozgunk ha nincs mellettünk akadály
			end //move_right
			else if(move_left & !move_right) begin
				face <= 0; //Ha balra megyünk másik irányba nézünk
				if(!obs_left)
					character_x <= character_x - 1'b1;
			end //move_left

		end //else if(game_clock_2)
	end  //always


	reg char_state = 0; //Jelenleg melyik animáció van

	//Animating
	always @ (posedge clk50M) begin
		if(rst)
			char_state <= 0;
		if(slow_clock) begin
			char_state <= (move_right ^ move_left) ? ~char_state : 1'b0; //Ha mozgunk változik az animáció
		end
	end

	always @ (posedge clk50M) begin
		if(rst)
			game_state <= GENERATE;
		else if(generate_done & game_state == GENERATE) begin
			game_state <= DRAW_SCENE; //Ha végeztünk a generálással kirajzoljuk a platformokat
		end
		else if(draw_scene_done & game_state == DRAW_SCENE)
			game_state <= PLAY; //Ha kirajzoltuk a platformokat, kezdodhet a játék
		else if(game_state == PLAY) begin
			if(die | second_counter == 0)
				game_state <= END; //Ha meghalt a karakter vagy lejárt az ido vége a játéknak
			else if(reach_end) begin
				game_state <= GENERATE; //Ha elértük a pálya végét újat generálunk
			end
			else if(to_remove) //Ha felvettünk egy érmét akkor újra kirajzoljuk a pályát
				game_state <= DRAW_SCENE;
		end
	end

	wire generate_done;
	wire draw_scene_done;

	wire [8:0] generate_addr; //Jelenleg melyik helyre generálunk
	wire [8:0] collision_detect_addr; //Ütközésészlelésnél jelenleg melyik blokkot nézzük
	wire [8:0] draw_scene_addr; //Kirajzolásnál melyik pozíción lévo dolgot rajzoljuk
	wire [8:0] remove_coin_addr; //Érmefelvételkor melyik pozíción lévo érmét töröljük

	wire [1:0] scene_in; //Mit írjunk
	wire [1:0] scene_out; //Mit olvasunk
	wire [8:0] scene_addr_read; //Honnan olvasunk
	reg [8:0] scene_addr_write; //Hova írunk
	wire scene_write;

	//Platformok, érmék, kaktuszok pozícióját tároló memória, dualport, olvasás mindig engedélyezve van
	scene_memory memory(
		.clk(clk50M),
		.we_b(scene_write),
		.addr_a(scene_addr_read),
		.addr_b(scene_addr_write),
		.data_b(scene_in),
		.q_a(scene_out)
		);


	//Scene memóriában 4-féle érték lehet
	localparam BACKGROUND = 0;
	localparam BLOCK = 1;
	localparam CACTUS = 2;
	localparam COIN = 3;

	//Generál nekünk egy pályát
	scene_generator scene_generator_i(
		.clk(clk50M),
		.rst(rst),
		.do_generate(game_state == GENERATE),
		.generate_addr(generate_addr),
		.scene_in(scene_in),
		.generate_done(generate_done)
		);

	wire [1:0] current_block_type;
	//Olvasókimenet
	assign current_block_type = scene_out;

	//Akkor írunk, ha generálunk vagy törlünk érmét
	assign scene_write = (game_state == GENERATE | just_removed);

	//Akkor olvasunk ha rajzolunk vagy ütközést észlelünk
	assign scene_addr_read = (game_state == DRAW_SCENE) ? draw_scene_addr : collision_detect_addr;

	always @ (posedge clk50M) begin
		if (game_state == GENERATE)
			scene_addr_write <= generate_addr;
		if(to_remove | just_removed)
			scene_addr_write <= remove_coin_addr;
	end

	//Ütközést észlel, jelez ha nem tudunk egy irányba mozogni, felvettünk-e érmét, kaktuszba mentünk vagy elértük a pálya végét
	collision_detector collision_detector_i(
		.clk(clk50M),
		.rst(rst),
		.game_clock(game_clock_1 | game_clock_2),
		.current_block_type(current_block_type),
		.play_state(game_state == PLAY),
		.character_x(character_x),
		.character_y(character_y),
		.collision_detect_addr(collision_detect_addr),
		.remove_coin_addr(remove_coin_addr),
		.reach_end(reach_end),
		.to_remove(to_remove),
		.just_removed(just_removed),
		.obs_up(obs_up),
		.obs_right(obs_right),
		.obs_down(obs_down),
		.obs_left(obs_left),
		.die(die),
		.score(score),
		.collision_detect_done(collision_detect_done)
		);

	//Rajzol nekünk, a platformokat ritkán (generálás utan/érmefelvételkor) karaktert mindig
	game_drawer game_drawer_i(
		.clk(clk50M),
		.rst(rst),
		.write_enable(write_enable),
		.game_state(game_state),
		.current_block_type(current_block_type),
		.character_x(character_x),
		.character_y(character_y),
		.char_state(char_state),
		.face(face),
		.reach_end(reach_end),
		.obs_down(obs_down),
		.vertical_porch_start(vertical_porch_start),
		.scene_write(scene_write),
		.mem_addr_x(mem_addr_x),
		.mem_addr_y(mem_addr_y),
		.data_out(data_out),
		.draw_scene_addr(draw_scene_addr),
		.enable_color(enable_color),
		.draw_scene_done(draw_scene_done)
		);

endmodule // game_logic
