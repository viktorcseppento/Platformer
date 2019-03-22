//Memóriából olvasó monitorra rajzoló vezérlo
module vga_controller(
	input pixel_clk,
	input rst,
	input [5:0] rgb_color,

	output [8:0] screen_x_to_read,
	output [8:0] screen_y_to_read,
	output read_display,

	output red_out_h,
	output red_out_l,
	output green_out_h,
	output green_out_l,
	output blue_out_h,
	output blue_out_l,
	output hsync_out,
	output vsync_out,

	output vertical_porch_start
    );

	localparam  SCREEN_WIDTH = 800;
	localparam  SCREEN_HEIGHT = 600;
	//Pálya mérete csak 400x300-as egy logikai pixel 2x2 valódi pixel
	localparam  SCENE_WIDTH = 400;
	localparam  SCENE_HEIGHT = 300;

	assign vertical_porch_start = vertical_pos == SCREEN_HEIGHT;

	//1040 x 666 osszesen, számlálók
	reg [10:0] horizontal_pos = 11'b0;
	reg [9:0] vertical_pos = 10'b0;


	always @ (posedge pixel_clk) begin
		if (rst) begin
			vertical_pos <= 11'b0;
			horizontal_pos <= 10'b0;
		end
		else begin
			if(horizontal_pos == 1039) begin
				horizontal_pos <= 11'b0;
				if(vertical_pos == 665)
					vertical_pos <= 10'b0;
				else
					vertical_pos <= vertical_pos + 1'b1;
			end
			else
				horizontal_pos <= horizontal_pos + 1'b1;
		end
	end

	//Vagy rajzolunk, vagy várunk hogy szinkronjelet adjunk ki, vagy szinkronjelet adunk ki
	assign is_drawing = (horizontal_pos < SCREEN_WIDTH & vertical_pos < SCREEN_HEIGHT);

	assign read_display = screen_x_to_read < SCENE_WIDTH & screen_y_to_read < SCENE_HEIGHT;
	//(horizontal_pos < 799 & vertical_pos < 600) | (horizontal_pos >= 1038 & vertical_pos < 600);

	//Jelenleg melyik memóricímrol olvassunk ki pixelinformációt, van benne egy kis eloretekintés
	assign screen_x_to_read = horizontal_pos >= 1039 ? 1'b0 : ((horizontal_pos + 1) >> 1); //Osztunk 2-vel, mert egy darab rajzolt pixel 2x2 db valódi pixel lesz
	assign screen_y_to_read = vertical_pos >= 665 ? 1'b0 : horizontal_pos >= 1039 ? ((vertical_pos + 1) >> 1) : (vertical_pos) >> 1;


	assign red_out_h = is_drawing ? rgb_color[5] : 1'b0;
	assign red_out_l = is_drawing ? rgb_color[4] : 1'b0;
	assign green_out_h = is_drawing ? rgb_color[3] : 1'b0;
	assign green_out_l = is_drawing ? rgb_color[2] : 1'b0;
	assign blue_out_h = is_drawing ? rgb_color[1] : 1'b0;
	assign blue_out_l = is_drawing ? rgb_color[0] : 1'b0;

	assign hsync_out = (horizontal_pos >= 856 & horizontal_pos < 976) ? 1'b1 : 1'b0;
	assign vsync_out = (vertical_pos >= 637 & vertical_pos < 643) ? 1'b1 : 1'b0;

endmodule
