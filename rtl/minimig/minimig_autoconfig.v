// Minimig autoconfig logic

module minimig_autoconfig
(
	input clk,
	input clk7_en,
	input reset,
	input [7:1] address_in,	//cpu address bus input
	output [15:0] data_out,
	input [15:0] data_in,
	input	rd,					//cpu read
	input	hwr,				//cpu high write
	input	lwr,				//cpu low write
	input sel,
	input	[1:0] fastram_config,
	output reg [2:0] board_configured,
	output reg autoconfig_done
);

reg [1:0] acdevice;
reg [3:0] zii_ramsize;
wire [7:0] roma_rd;
wire [7:0] roma_wr;
wire [3:0] rom_q;
reg rom_we;

assign roma_rd[5:0] = address_in[6:1];
assign roma_rd[7:6] = acdevice;
assign roma_wr[7:0] = 8'h01;	// Fix write address for modifying size of ZII RAM.
assign data_out = sel ? {rom_q,12'hfff} : 16'h0000;

Autoconfig_ROM acrom
(
	.clk(clk),
	.a_read(roma_rd),
	.a_write(roma_wr),	// We only write to change the size of the ZII RAM board
	.we(rom_we),
	.d(zii_ramsize),
	.q(rom_q)
);

reg init;

always @(posedge clk)
begin

	if(reset)
	begin
		init=1'b1;
		board_configured<=3'b000;
		acdevice<=2'b00;
		autoconfig_done <= 1'b0;
	end

	rom_we<=1'b0;
	
	if(init)
	begin
		case(fastram_config)
			2'b00 : zii_ramsize <= 4'b1111;  // don't care, disabled
			2'b01 : zii_ramsize <= 4'b0110;	// 2 Meg
			2'b10 : zii_ramsize <= 4'b0111;	// 4 Meg
			2'b11	: zii_ramsize <= 4'b0000;  // 8 Meg
		endcase
		rom_we<=1'b1;
	
		// Either 1st board (ZII fast RAM) or null board if RAM is disabled
		acdevice <= |fastram_config ? 2'b00 : 2'b11;
		init<=1'b0;
	end
	else
	begin
		if(clk7_en && sel && (lwr|hwr))
		begin
			case({address_in,1'b0})
				8'h48 : begin
					autoconfig_done <= 1'b1;
					case(acdevice)
						2'b00 : begin // ZII RAM
								board_configured[0] <= 1'b1;
								acdevice<=&fastram_config ? 2'b01 : 2'b11; // ZIII RAM next
							end
						2'b01 : begin // ZIII RAM
								board_configured[1] <= 1'b1;
//								acdevice<=2'b10; // Ethernet after ZIII RAM
								acdevice<=2'b11; // NULL device to terminate the chain
							end
						2'b10 : begin // ETH
								board_configured[2] <= 1'b1;
								acdevice<=2'b11; // NULL device to terminate the chain
							end
						default: ;
					endcase
				end
			endcase
		end
	end
end


endmodule
