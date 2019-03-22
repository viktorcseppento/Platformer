//SRAM-ot vez�rli
//A mem�ri�t egy 512x512-es n�gyzetnek n�zem �s abb�l csak egy 400x300-as t�glalapot haszn�lok, minden cell�ban 6 bitet
module sram_controller(
	input read,
	input write,
	input [8:0] mem_addr_x,
	input [8:0] mem_addr_y,

	input [15:0] data_to_write,
	inout [15:0] data_wire,
	output [17:0] address,
	output sram_csn,
	output oen, //Olvas�senged�lyez�s
	output wen, //�r�senged�lyez�s
	output sdram_csn, //SDRAM enged�lyez�se
	output lbn, //Felso vagy als� b�jtba �rnuk/-b�l olvasunk
	output ubn
	);

	assign sram_csn = 0; //Az SRAM-ot folyamatosan engedélyezzük
	assign sdram_csn = 1; //Az SDRAM-ot nem használjuk

	assign lbn = 0; //Az SRAM-nak csak az als� b�jtj�t haszn�ljuk minden c�men
	assign ubn = 1;

	assign oen = ~read;
	assign wen = ~write;
	assign address = {mem_addr_y, mem_addr_x};
	//Ha olvasunk nagyimpedanci�ba tessz�k a vezet�keket
	assign data_wire = read ? 16'bz : data_to_write;


endmodule
