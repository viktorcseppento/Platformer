//SRAM-ot vezérli
//A memóriát egy 512x512-es négyzetnek nézem és abból csak egy 400x300-as téglalapot használok, minden cellában 6 bitet
module sram_controller(
	input read,
	input write,
	input [8:0] mem_addr_x,
	input [8:0] mem_addr_y,

	input [15:0] data_to_write,
	inout [15:0] data_wire,
	output [17:0] address,
	output sram_csn,
	output oen, //Olvasásengedélyezés
	output wen, //Írásengedélyezés
	output sdram_csn, //SDRAM engedélyezése
	output lbn, //Felso vagy alsó bájtba írnuk/-ból olvasunk
	output ubn
	);

	assign sram_csn = 0; //Az SRAM-ot folyamatosan engedÃ©lyezzÃ¼k
	assign sdram_csn = 1; //Az SDRAM-ot nem hasznÃ¡ljuk

	assign lbn = 0; //Az SRAM-nak csak az alsó bájtját használjuk minden címen
	assign ubn = 1;

	assign oen = ~read;
	assign wen = ~write;
	assign address = {mem_addr_y, mem_addr_x};
	//Ha olvasunk nagyimpedanciába tesszük a vezetékeket
	assign data_wire = read ? 16'bz : data_to_write;


endmodule
