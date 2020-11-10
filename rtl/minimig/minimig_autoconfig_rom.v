module Autoconfig_ROM
(
	input clk,
	input [3:0] d,
	input [8:0] a_read, a_write,
	input we,
	output [3:0] q
);

reg [3:0] ram[(2**9)-1:0] /* synthesis ramstyle = "auto" */;
// Set to "logic" if you don't want to use a RAM block for this.
integer j;

initial
begin

	// Default to 1111 for any addresses not specifically set
	for(j = 0; j < 2**9; j = j+1) 
		ram[j] = 4'b1111;

	// Use the upper two bits as an index
	// so 00 is ZII RAM, 01 is ZIII RAM and 10 is ETH
	// with a NULL board at 11 to terminate the chain.

	// Up to 8 meg of 24-bit Fast RAM
	
	ram['h00+'h0] = 4'b1110;	// Zorro-II card, add mem, no ROM
	ram['h00+'h2/2] = 4'b0000;	// 0110 => 2MB, 0111 => 4MB, 0000 => 8MB
	ram['h00+'h10/2] = 4'b1110;	// Manufacturer ID: 0x139c
	ram['h00+'h12/2] = 4'b1100;
	ram['h00+'h14/2] = 4'b0110;
	ram['h00+'h16/2] = 4'b0011;
	ram['h00+'h26/2] = 4'b1110;	// Serial no: 1

	// 16 meg of 32-bit Fast RAM

	ram['h40+'h0] = 4'b1010;	// Zorro-III card, add mem, no ROM
	ram['h40+'h2/2] = 4'b0000;	// 8MB (extended to 16 in reg 08
	ram['h40+'h4/2] = 4'b1110;	// ProductID = 0x10 (only setting upper nybble)
	ram['h40+'h8/2] = 4'b0000;	// Memory card, not silenceable, extended size (16 meg), reserved
	ram['h40+'ha/2] = 4'b1111;	// 0000 - logical size matches physical size
	ram['h40+'h10/2] = 4'b1110;	// Manufacturer ID: 0x139c
	ram['h40+'h12/2] = 4'b1100;
	ram['h40+'h14/2] = 4'b0110;
	ram['h40+'h16/2] = 4'b0011;
	ram['h40+'h26/2] = 4'b1101;	// Serial no: 2

	// 2 or 4 meg of 32-bit Fast RAM (unused RAM in Bank 0)

	ram['h80+'h0] = 4'b1010;	// Zorro-III card, add mem, no ROM
	ram['h80+'h2/2] = 4'b0111;	// 4MB
	ram['h80+'h4/2] = 4'b1110;	// ProductID = 0x11
	ram['h80+'h6/2] = 4'b1110;	// ProductID = 0x11
	ram['h80+'h8/2] = 4'b0010;	// Memory card, not silenceable, reserved
	ram['h80+'ha/2] = 4'b1000;	// 0111 - 2 meg
	ram['h80+'h10/2] = 4'b1110;	// Manufacturer ID: 0x1399
	ram['h80+'h12/2] = 4'b1100;
	ram['h80+'h14/2] = 4'b0110;
	ram['h80+'h16/2] = 4'b0110;
	ram['h80+'h26/2] = 4'b1100;	// Serial no: 3

	// Ethernet
	
	ram['hc0+'h0] = 4'b1000;	// Zorro-III card, no link, no ROM
	ram['hc0+'h2/2] = 4'b0001;	// Next board not related, size 'h40k
	ram['hc0+'h4/2] = 4'b1101;	// ProductID = 0x20 (only setting upper nybble)
	ram['hc0+'h8/2] = 4'b1110;	// Not memory, silenceable, normal size, Zorro III
	ram['hc0+'ha/2] = 4'b1101;	// logical size 'h40k
	ram['hc0+'h10/2] = 4'b1110;	// Manufacturer ID: 0x139c
	ram['hc0+'h12/2] = 4'b1100;
	ram['hc0+'h14/2] = 4'b0110;
	ram['hc0+'h16/2] = 4'b0011;
	ram['hc0+'h26/2] = 4'b1100;	// Serial no: 3
	
end

reg [3:0] q_loc;
reg [8:0] a_loc;
always @ (posedge clk)
begin
	a_loc<=a_read;
	if (we)
		ram[a_write] <= d;
	q_loc<=ram[a_loc];
end

assign q = q_loc;

endmodule
