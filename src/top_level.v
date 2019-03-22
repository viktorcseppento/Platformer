module top_level(
    input clk50M,
    input rstn,

	//Felhaszn�l�i interface
	input btn_0,
	input btn_1,
	input btn_2,

	input cpld_miso,

	output cpld_mosi,
 	output cpld_jtagen,
	output cpld_rstn,
	output cpld_clk,
	output cpld_load,

	//Mem�ria kezel�se
	output [17:0] mem_addr,
	inout [15:0] mem_data,
	output mem_wen,
	output mem_lbn,
	output mem_ubn,
	output sram_oen,
	output sram_csn,
	output sdram_csn,

   output [12:4] aio //Bov�tok�rtya bemenetei
    );

	//Vagy olvassuk a mem�ri�t vagy �rjuk, a k�lso mem�ri�ban csak pixelsz�n-inform�ci�k vannak
	parameter read_display_mem = 1'b0;
	parameter write_display_mem = 1'b1;

	reg mem_state = read_display_mem;
	reg next_mem_state = read_display_mem;

	always @ (posedge clk50M) begin
		mem_state <= next_mem_state;
	end

	always @ ( * ) begin
		if(read_display)
			next_mem_state <= read_display_mem;
		else
			next_mem_state <= write_display_mem;
	end

	reg read, write;
	wire read_display;
	wire [15:0] data_to_write;

	//Melyik c�mre �rjunk/olvassunk
	reg [8:0] mem_addr_x;
	reg [8:0] mem_addr_y;
	
	//A rajzol�shoz a mem�ri�b�l mit olvassunk ki
	wire [8:0] read_screen_y; //max 300
	wire [8:0] read_screen_x; //max 400

	//A mem�ri�ba mit �rjuk hogy kirajzolja a k�pernyore
	wire [8:0] write_screen_y; //max 300
	wire [8:0] write_screen_x; //max 400

	always @ (*) begin
		case (mem_state)
			read_display_mem: begin
				mem_addr_x <= read_screen_x;
				mem_addr_y <= read_screen_y;
				write <= 0;
				read <= 1;
			end
			write_display_mem: begin
				mem_addr_x <= write_screen_x;
				mem_addr_y <= write_screen_y;
				write <= logic_enable_write;
				read <= 0;
			end
		endcase
	end

	//J�t�k logika eneg�lyezi-e a mem�ri�ba�r�st
	wire logic_enable_write;

	wire [6:0] second_left;
	wire [7:0] score;

	//J�t�k muk�d�s�t int�zi
	game_logic game_logic_i(
		.clk50M(clk50M),
		.rst(~rstn),

		.write_enable(~read_display),
		.vertical_porch_start(vertical_porch_start),

		.btn0(btn_0),
		.btn1(btn_1),
		.btn2(btn_2),
		.nav_u(nav_u),
		.nav_r(nav_r),
		.nav_d(nav_d),
		.nav_l(nav_l),
		.nav_sel(nav_sel),

		.mem_addr_x(write_screen_x), //Hova �rjon a mem�ri�ba �s mit
		.mem_addr_y(write_screen_y),
		.data_out(data_to_write[5:0]),
		.enable_color(logic_enable_write),
		.second_left(second_left),
		.score(score),
		.start_sound(start_sound)
	);

	//K�rty�n tal�lhat� SRAM-ba val� �r�s�rt �s olvas�s�rt felel
	sram_controller sram_controller_i(
		.read(read),
		.write(write),
		.mem_addr_x(mem_addr_x),
		.mem_addr_y(mem_addr_y),
		.data_to_write(data_to_write),

		.data_wire(mem_data),
		.address(mem_addr),
		.sram_csn(sram_csn),
		.oen(sram_oen),
		.wen(mem_wen),
		.sdram_csn(sdram_csn),
		.lbn(mem_lbn),
		.ubn(mem_ubn)
	);


	//800x600-as monitorra val� kirajzol�s��rt felel
	vga_controller vga_controller_i(
		.pixel_clk(clk50M),
		.rst(~rstn),

		.rgb_color(mem_data[5:0]),

		.red_out_h(aio[5]),
		.red_out_l(aio[6]),
		.green_out_h(aio[7]),
		.green_out_l(aio[8]),
		.blue_out_h(aio[9]),
		.blue_out_l(aio[10]),

		.hsync_out(aio[12]),
		.vsync_out(aio[11]),

		.screen_x_to_read(read_screen_x), //Olvass-e jelenleg a mem�ri�t �s hol
		.screen_y_to_read(read_screen_y),
		.read_display(read_display),

		.vertical_porch_start(vertical_porch_start)
	);

	//Gombhelyzetek beolvas�s��rt illetve a led-ek �s kijelzo muk�dtet�s��rt felelos
	input_controller input_controller_i(
		.clk(clk50M),
		.rst(~rstn),

		.second_left(second_left),
		.dig0(score[7:4]),
		.dig1(score[3:0]),

		.cpld_miso(cpld_miso),
		.cpld_mosi(cpld_mosi),
		.cpld_rstn(cpld_rstn),
		.cpld_clk(cpld_clk),
		.cpld_load(cpld_load),
		.cpld_jtagen(cpld_jtagen),

		.nav_u(nav_u),
		.nav_d(nav_d),
		.nav_l(nav_l),
		.nav_r(nav_r),
		.nav_sel(nav_sel)
	);
	
	
	//�rmefelv�telkor megfelelo hangot ad ki
	audio_controller audio_controller_i(
		.clk(clk50M),
		.rst(~rstn),
		.start(start_sound),
		.sound(aio[4])
		);


endmodule
