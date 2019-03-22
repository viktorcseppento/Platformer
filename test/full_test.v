`timescale 1ns / 1ps

module full_test;

	// Inputs
	reg rstn;
	reg clk50M;
	reg btn_0;
	reg btn_1;
	reg btn_2;
	reg cpld_miso;

	// Outputs
	wire cpld_mosi;
	wire cpld_jtagen;
	wire cpld_rstn;
	wire cpld_clk;
	wire cpld_load;
	wire [17:0] mem_addr;
	wire mem_wen;
	wire mem_lbn;
	wire mem_ubn;
	wire sram_oen;
	wire sram_csn;
	wire sdram_csn;
	wire [16:4] aio;

	// Bidirs
	wire [15:0] mem_data;

	// Instantiate the Unit Under Test (UUT)
	top_level uut (
		.rstn(rstn), 
		.clk50M(clk50M), 
		.btn_0(btn_0), 
		.btn_1(btn_1), 
		.btn_2(btn_2), 
		.cpld_miso(cpld_miso), 
		.cpld_mosi(cpld_mosi), 
		.cpld_jtagen(cpld_jtagen), 
		.cpld_rstn(cpld_rstn), 
		.cpld_clk(cpld_clk), 
		.cpld_load(cpld_load), 
		.mem_addr(mem_addr), 
		.mem_data(mem_data), 
		.mem_wen(mem_wen), 
		.mem_lbn(mem_lbn), 
		.mem_ubn(mem_ubn), 
		.sram_oen(sram_oen), 
		.sram_csn(sram_csn), 
		.sdram_csn(sdram_csn), 
		.aio(aio)
	);

	initial begin
		// Initialize Inputs
		rstn = 0;
		clk50M = 0;
		btn_0 = 0;
		btn_1 = 0;
		btn_2 = 0;
		cpld_miso = 0;

		// Wait 100 ns for global reset to finish
		#100;
		rstn = 1;
        
		// Add stimulus here

	end

	always #10
		clk50M <= ~clk50M;
      
endmodule

