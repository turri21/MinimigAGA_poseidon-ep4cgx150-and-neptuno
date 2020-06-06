/********************************************/
/* minimig_mist_top.v                       */
/* MiST Board Top File                      */
/*                                          */
/* 2012-2015, rok.krajnc@gmail.com          */
/********************************************/


// board type define
`define MINIMIG_VIRTUAL

`include "minimig_defines.vh"

module minimig_virtual_top
	#(parameter debug = 0, parameter spimux = 0 )
(
  // clock inputs
  input wire            CLK_IN,
  output wire           CLK_114,
  output wire           CLK_28,
  output wire           PLL_LOCKED,
  input wire            RESET_N,
  
  // Button inputs
  input						MENU_BUTTON,
  
  // LED outputs
  output wire           LED_POWER,  // LED green
  output wire           LED_DISK,   // LED red
  
  // UART
  output wire           CTRL_TX,    // UART Transmitter
  input wire            CTRL_RX,    // UART Receiver
  output wire           AMIGA_TX,    // UART Transmitter
  input wire            AMIGA_RX,    // UART Receiver
  
  // VGA
  output wire           VGA_SELCS,  // Select CSYNC
  output wire           VGA_CS,     // VGA C_SYNC
  output wire           VGA_HS,     // VGA H_SYNC
  output wire           VGA_VS,     // VGA V_SYNC
  output wire [  8-1:0] VGA_R,      // VGA Red[5:0]
  output wire [  8-1:0] VGA_G,      // VGA Green[5:0]
  output wire [  8-1:0] VGA_B,      // VGA Blue[5:0]
  
  // SDRAM
  inout  wire [ 16-1:0] SDRAM_DQ,   // SDRAM Data bus 16 Bits
  output wire [ 13-1:0] SDRAM_A,    // SDRAM Address bus 13 Bits
  output wire           SDRAM_DQML, // SDRAM Low-byte Data Mask
  output wire           SDRAM_DQMH, // SDRAM High-byte Data Mask
  output wire           SDRAM_nWE,  // SDRAM Write Enable
  output wire           SDRAM_nCAS, // SDRAM Column Address Strobe
  output wire           SDRAM_nRAS, // SDRAM Row Address Strobe
  output wire           SDRAM_nCS,  // SDRAM Chip Select
  output wire [  2-1:0] SDRAM_BA,   // SDRAM Bank Address
  output wire           SDRAM_CLK,  // SDRAM Clock
  output wire           SDRAM_CKE,  // SDRAM Clock Enable
  
  // MINIMIG specific
  output wire[14:0]     AUDIO_L,    // sigma-delta DAC output left
  output wire[14:0]     AUDIO_R,    // sigma-delta DAC output right

  // Keyboard / Mouse
  input                 PS2_DAT_I,      // PS2 Keyboard Data
  input                 PS2_CLK_I,      // PS2 Keyboard Clock
  input                 PS2_MDAT_I,     // PS2 Mouse Data
  input                 PS2_MCLK_I,     // PS2 Mouse Clock
  output                PS2_DAT_O,      // PS2 Keyboard Data
  output                PS2_CLK_O,      // PS2 Keyboard Clock
  output                PS2_MDAT_O,     // PS2 Mouse Data
  output                PS2_MCLK_O,     // PS2 Mouse Clock

  // Joystick
  input       [  7-1:0] JOYA,         // joystick port A
  input       [  7-1:0] JOYB,         // joystick port B
  input       [  7-1:0] JOYC,         // joystick port A
  input       [  7-1:0] JOYD,         // joystick port B
  
  // SPI 
  input wire            SD_MISO,     // inout
  output wire           SD_MOSI,
  output wire           SD_CLK,
  output wire           SD_CS,
  input wire            SD_ACK
);


////////////////////////////////////////
// internal signals                   //
////////////////////////////////////////

// clock
wire           clk_sdram;
wire           clk7_en;
wire           clk7n_en;
wire           c1;
wire           c3;
wire           cck;
wire [ 10-1:0] eclk;

// reset
wire           pll_rst;
wire           sdctl_rst;
wire           rst_50;
wire           rst_minimig;

// ctrl
wire           rom_status;
wire           ram_status;
wire           reg_status;

// tg68
wire           tg68_rst;
wire [ 16-1:0] tg68_dat_in;
wire [ 16-1:0] tg68_dat_out;
wire [ 32-1:0] tg68_adr;
wire [  3-1:0] tg68_IPL;
wire           tg68_dtack;
wire           tg68_as;
wire           tg68_uds;
wire           tg68_lds;
wire           tg68_rw;
wire           tg68_ena7RD;
wire           tg68_ena7WR;
wire           tg68_enaWR;
wire [ 16-1:0] tg68_cout;
wire           tg68_cpuena;
wire [  4-1:0] cpu_config;
wire [  6-1:0] memcfg;
wire           turbochipram;
wire           turbokick;
wire           cache_inhibit;
wire [ 32-1:0] tg68_cad;
wire [  6-1:0] tg68_cpustate;
wire           tg68_nrst_out;
//wire           tg68_cdma;
wire           tg68_clds;
wire           tg68_cuds;
wire [  4-1:0] tg68_CACR_out;
wire [ 32-1:0] tg68_VBR_out;
wire           tg68_ovr;

// minimig
wire           led;
wire [ 16-1:0] ram_data;      // sram data bus
wire [ 16-1:0] ramdata_in;    // sram data bus in
wire [ 48-1:0] chip48;        // big chip read
wire [ 23-1:1] ram_address;   // sram address bus
wire           _ram_bhe;      // sram upper byte select
wire           _ram_ble;      // sram lower byte select
wire           _ram_we;       // sram write enable
wire           _ram_oe;       // sram output enable
wire           _15khz;        // scandoubler disable
wire           sdo;           // SPI data output
wire           vs;
wire           hs;
wire           cs;
wire [  8-1:0] red;
wire [  8-1:0] green;
wire [  8-1:0] blue;
reg            cs_reg;
reg            vs_reg;
reg            hs_reg;
reg  [  8-1:0] red_reg;
reg  [  8-1:0] green_reg;
reg  [  8-1:0] blue_reg;

// sdram
wire           reset_out;
wire [  4-1:0] sdram_cs;
wire [  2-1:0] sdram_dqm;
wire [  2-1:0] sdram_ba;

// mist
wire           user_io_sdo;
wire           minimig_sdo;
wire [  16-1:0] joya;
wire [  16-1:0] joyb;
wire [  16-1:0] joyc;
wire [  16-1:0] joyd;
wire [  8-1:0] kbd_mouse_data;
wire           kbd_mouse_strobe;
wire           kms_level;
wire [  2-1:0] kbd_mouse_type;
wire [  3-1:0] mouse_buttons;

// UART
wire minimig_rxd;
wire minimig_txd;
wire debug_rxd;
wire debug_txd;


////////////////////////////////////////
// toplevel assignments               //
////////////////////////////////////////

// SDRAM
assign SDRAM_CKE        = 1'b1;
assign SDRAM_CLK        = clk_sdram;
assign SDRAM_nCS        = sdram_cs[0];
assign SDRAM_DQML       = sdram_dqm[0];
assign SDRAM_DQMH       = sdram_dqm[1];
assign SDRAM_BA         = sdram_ba;

// reset
assign pll_rst          = 1'b0;
assign sdctl_rst        = PLL_LOCKED & RESET_N;

// VGA data
always @ (posedge CLK_28) begin
  cs_reg    <= #1 cs;
  vs_reg    <= #1 vs;
  hs_reg    <= #1 hs;
  red_reg   <= #1 red;
  green_reg <= #1 green;
  blue_reg  <= #1 blue;
end

assign VGA_CS           = cs_reg;
assign VGA_VS           = vs_reg;
assign VGA_HS           = hs_reg;
assign VGA_R[7:0]       = red_reg[7:0];
assign VGA_G[7:0]       = green_reg[7:0];
assign VGA_B[7:0]       = blue_reg[7:0];


//// amiga clocks ////
amiga_clk amiga_clk (
  .rst          (1'b0             ), // async reset input
  .clk_in       (CLK_IN           ), // input clock     ( 27.000000MHz)
  .clk_114      (CLK_114          ), // output clock c0 (114.750000MHz)
  .clk_sdram    (clk_sdram        ), // output clock c2 (114.750000MHz, -146.25 deg)
  .clk_28       (CLK_28           ), // output clock c1 ( 28.687500MHz)
  .clk7_en      (clk7_en          ), // output clock 7 enable (on 28MHz clock domain)
  .clk7n_en     (clk7n_en         ), // 7MHz negedge output clock enable (on 28MHz clock domain)
  .c1           (c1               ), // clk28m clock domain signal synchronous with clk signal
  .c3           (c3               ), // clk28m clock domain signal synchronous with clk signal delayed by 90 degrees
  .cck          (cck              ), // colour clock output (3.54 MHz)
  .eclk         (eclk             ), // 0.709379 MHz clock enable output (clk domain pulse)
  .locked       (PLL_LOCKED       )  // pll locked output
);


//// TG68K main CPU ////

TG68K tg68k (
  .clk          (CLK_114          ),
  .reset        (tg68_rst         ),
  .clkena_in    (1'b1             ),
  .IPL          (tg68_IPL         ),
  .dtack        (tg68_dtack       ),
  .vpa          (1'b1             ),
  .ein          (1'b1             ),
  .addr         (tg68_adr         ),
  .data_read    (tg68_dat_in      ),
  .data_write   (tg68_dat_out     ),
  .as           (tg68_as          ),
  .uds          (tg68_uds         ),
  .lds          (tg68_lds         ),
  .rw           (tg68_rw          ),
  .vma          (                 ),
  .wrd          (                 ),
  .ena7RDreg    (tg68_ena7RD      ),
  .ena7WRreg    (tg68_ena7WR      ),
  .enaWRreg     (tg68_enaWR       ),
  .fromram      (tg68_cout        ),
  .ramready     (tg68_cpuena      ),
  .cpu          (cpu_config[1:0]  ),
  .turbochipram (turbochipram     ),
  .turbokick    (turbokick        ),
  .cache_inhibit(cache_inhibit    ),
  .fastramcfg   ({&memcfg[5:4],memcfg[5:4]}),
  .eth_en       (1'b1), // TODO
  .sel_eth      (),
  .frometh      (16'd0),
  .ethready     (1'b0),
  .ramaddr      (tg68_cad         ),
  .cpustate     (tg68_cpustate    ),
  .nResetOut    (tg68_nrst_out    ),
  .skipFetch    (                 ),
  .ramlds       (tg68_clds        ),
  .ramuds       (tg68_cuds        ),
  .CACR_out     (tg68_CACR_out    ),
  .VBR_out      (tg68_VBR_out     )
);


wire [ 16-1:0] hostRD;
wire [ 16-1:0] hostWR;
wire [ 32-1:0] hostaddr;
reg  [ 32-1:0] hostaddr_d;
wire [  3-1:0] hostState;
wire           hostL;
wire           hostU;
reg  [ 16-1:0] hostdata;
wire           hostramena;
wire           hostena;
wire           hostwe;
wire           hostreq;
wire           hostack;
wire           hostce;

always @(posedge CLK_114) begin
	hostaddr_d<=hostaddr;
end

//sdram sdram (
sdram_ctrl sdram (
  .cache_rst    (tg68_rst         ),
  .cache_inhibit(cache_inhibit    ),
  .cpu_cache_ctrl (tg68_CACR_out    ),
  .sdata        (SDRAM_DQ         ),
  .sdaddr       (SDRAM_A[12:0]    ),
  .dqm          (sdram_dqm        ),
  .sd_cs        (sdram_cs         ),
  .ba           (sdram_ba         ),
  .sd_we        (SDRAM_nWE        ),
  .sd_ras       (SDRAM_nRAS       ),
  .sd_cas       (SDRAM_nCAS       ),
  .sysclk       (CLK_114          ),
  .reset_in     (sdctl_rst        ),
  
  .hostWR       (hostWR           ),
  .hostAddr     (hostaddr_d[23:0] ),
//  .hostState    (hostState        ),
  .hostwe       (hostwe           ),
  .hostce       (hostce           ),
  .hostL        (hostL            ),
  .hostU        (hostU            ),
  .hostRD       (hostRD           ),
  .hostena      (hostramena       ),

  .cpuWR        (tg68_dat_out     ),
  .cpuAddr      (tg68_cad[24:1]   ),
  .cpuU         (tg68_cuds        ),
  .cpuL         (tg68_clds        ),
  .cpustate     (tg68_cpustate    ),
  .cpuRD        (tg68_cout        ),
  .cpuena       (tg68_cpuena      ),

//  .cpu_dma      (tg68_cdma        ),
  .chipWR       (ram_data         ),
  .chipAddr     ({1'b0, ram_address[22:1]}),
  .chipU        (_ram_bhe         ),
  .chipL        (_ram_ble         ),
  .chipRW       (_ram_we          ),
  .chip_dma     (_ram_oe          ),
  .clk7_en      (clk7_en          ),
  .chipRD       (ramdata_in       ),
  .chip48       (chip48           ),

  .reset_out    (reset_out        ),
  .enaRDreg     (                 ),
  .enaWRreg     (tg68_enaWR       ),
  .ena7RDreg    (tg68_ena7RD      ),
  .ena7WRreg    (tg68_ena7WR      )
);


// multiplex spi_do, drive it from user_io if that's selected, drive
// it from minimig if it's selected and leave it open else (also
// to be able to monitor sd card data directly)

wire [8-1 : 0] SPI_CS;
wire SPI_DO;
wire SPI_DI;
wire SPI_SCK;
wire SPI_SS;
wire SPI_SS2;
wire SPI_SS3;
wire SPI_SS4;
wire CONF_DATA0;

//assign SPI_DO = (CONF_DATA0 == 1'b0)?user_io_sdo:
//    (((SPI_SS2 == 1'b0)|| (SPI_SS3 == 1'b0))?minimig_sdo:1'bZ);

assign SD_CLK = SPI_SCK;
assign SD_CS = SPI_CS[1];
assign SD_MOSI = SPI_DI;
assign SPI_SS4 = SPI_CS[6];
assign SPI_SS3 = SPI_CS[5];
assign SPI_SS2 = SPI_CS[4];

//// minimig top ////
minimig minimig (
  //m68k pins
  .cpu_address  (tg68_adr[23:1]   ), // M68K address bus
  .cpu_data     (tg68_dat_in      ), // M68K data bus
  .cpudata_in   (tg68_dat_out     ), // M68K data in
  ._cpu_ipl     (tg68_IPL         ), // M68K interrupt request
  ._cpu_as      (tg68_as          ), // M68K address strobe
  ._cpu_uds     (tg68_uds         ), // M68K upper data strobe
  ._cpu_lds     (tg68_lds         ), // M68K lower data strobe
  .cpu_r_w      (tg68_rw          ), // M68K read / write
  ._cpu_dtack   (tg68_dtack       ), // M68K data acknowledge
  ._cpu_reset   (tg68_rst         ), // M68K reset
  ._cpu_reset_in(tg68_nrst_out    ), // M68K reset out
  .cpu_vbr      (tg68_VBR_out     ), // M68K VBR
  .ovr          (tg68_ovr         ), // NMI override address decoding
  //sram pins
  .ram_data     (ram_data         ), // SRAM data bus
  .ramdata_in   (ramdata_in       ), // SRAM data bus in
  .ram_address  (ram_address[22:1]), // SRAM address bus
  ._ram_bhe     (_ram_bhe         ), // SRAM upper byte select
  ._ram_ble     (_ram_ble         ), // SRAM lower byte select
  ._ram_we      (_ram_we          ), // SRAM write enable
  ._ram_oe      (_ram_oe          ), // SRAM output enable
  .chip48       (chip48           ), // big chipram read
  //system  pins
  .rst_ext      (!RESET_N         ), // reset from ctrl block
  .rst_out      (                 ), // minimig reset status
  .clk          (CLK_28           ), // output clock c1 ( 28.687500MHz)
  .clk7_en      (clk7_en          ), // 7MHz clock enable
  .clk7n_en     (clk7n_en         ), // 7MHz negedge clock enable
  .c1           (c1               ), // clk28m clock domain signal synchronous with clk signal
  .c3           (c3               ), // clk28m clock domain signal synchronous with clk signal delayed by 90 degrees
  .cck          (cck              ), // colour clock output (3.54 MHz)
  .eclk         (eclk             ), // 0.709379 MHz clock enable output (clk domain pulse)
  //rs232 pins
  .rxd          (AMIGA_RX         ),  // RS232 receive
  .txd          (AMIGA_TX         ),  // RS232 send
  .cts          (1'b0             ),  // RS232 clear to send
  .rts          (                 ),  // RS232 request to send
  //I/O
  ._joy1        (JOYA             ),  // joystick 1 [fire7:fire,up,down,left,right] (default mouse port)
  ._joy2        (JOYB             ),  // joystick 2 [fire7:fire,up,down,left,right] (default joystick port)
  ._joy3        (JOYC             ),  // joystick 3 [fire7:fire,up,down,left,right]
  ._joy4        (JOYD             ),  // joystick 4 [fire7:fire,up,down,left,right]
  .mouse_btn1   (1'b1             ), // mouse button 1
  .mouse_btn2   (1'b1             ), // mouse button 2
//  .mouse_btn    (mouse_buttons    ),  // mouse buttons
//  .kbd_mouse_data (kbd_mouse_data ),  // mouse direction data, keycodes
//  .kbd_mouse_type (kbd_mouse_type ),  // type of data
  .kbd_mouse_strobe (1'b0         ), // kbd_mouse_strobe), // kbd/mouse data strobe
  .kms_level    (1'b0             ), // kms_level        ),
  ._15khz       (_15khz           ), // scandoubler disable
  .pwr_led      (LED_POWER        ), // power led
  .disk_led     (LED_DISK         ), // power led
  .msdat_i      (PS2_MDAT_I       ), // PS2 mouse data
  .msclk_i      (PS2_MCLK_I       ), // PS2 mouse clk
  .kbddat_i     (PS2_DAT_I        ), // PS2 keyboard data
  .kbdclk_i     (PS2_CLK_I        ), // PS2 keyboard clk
  .msdat_o      (PS2_MDAT_O       ), // PS2 mouse data
  .msclk_o      (PS2_MCLK_O       ), // PS2 mouse clk
  .kbddat_o     (PS2_DAT_O        ), // PS2 keyboard data
  .kbdclk_o     (PS2_CLK_O        ), // PS2 keyboard clk
  //host controller interface (SPI)
  ._scs         ( {SPI_SS4,SPI_SS3,SPI_SS2}  ),  // SPI chip select spi_chipselect(6 downto 4),
  .direct_sdi   (SD_MISO          ),  // SD Card direct in  SPI_SDO
  .sdi          (SPI_DI           ),  // SPI data input
  .sdo          (SPI_DO           ),  // SPI data output
  .sck          (SPI_SCK          ),  // SPI clock
  //video
  .selcsync     (VGA_SELCS        ),
  ._csync       (cs               ),  // horizontal sync
  ._hsync       (hs               ),  // horizontal sync
  ._vsync       (vs               ),  // vertical sync
  .red          (red              ),  // red
  .green        (green            ),  // green
  .blue         (blue             ),  // blue
  //audio
  .left         (                 ),  // audio bitstream left
  .right        (                 ),  // audio bitstream right
  .ldata        (AUDIO_L          ),  // left DAC data
  .rdata        (AUDIO_R          ),  // right DAC data
  //user i/o
  .cpu_config   (cpu_config       ), // CPU config
  .memcfg       (memcfg           ), // memory config
  .turbochipram (turbochipram     ), // turbo chipRAM
  .turbokick    (turbokick        ), // turbo kickstart
  .init_b       (                 ), // vertical sync for MCU (sync OSD update)
  .fifo_full    (                 ),
  // fifo / track display
  .trackdisp    (                 ),  // floppy track number
  .secdisp      (                 ),  // sector
  .floppy_fwr   (                 ),  // floppy fifo writing
  .floppy_frd   (                 ),  // floppy fifo reading
  .hd_fwr       (                 ),  // hd fifo writing
  .hd_frd       (                 )   // hd fifo  ading
);


EightThirtyTwo_Bridge #( debug ? "true" : "false") hostcpu
(
	.clk(CLK_114),
	.nReset(reset_out),
//	.clkena_in(hostena),
	.data_in(hostdata),
	.addr(hostaddr),
	.data_write(hostWR),
//	.nWr( open, -- uses busstate instead?
	.nUDS(hostU),
	.nLDS(hostL),
	.req(hostreq),
	.ack(hostack),
	.wr(hostwe)
//	.busstate(hostState[1:0])
	);


cfide #(.spimux(spimux ? "true" : "false")) mycfide
( 
		.sysclk(CLK_114),
		.n_reset(reset_out),

		.memce(hostce),
		.cpuena_in(hostramena),
		.memdata_in(hostRD),
		.addr(hostaddr),
		.cpudata_in(hostWR),
		.lds(hostL),
		.uds(hostU),
		.cpu_req(hostreq),
		.cpu_wr(hostwe),
		.cpu_ack(hostack),
		.cpudata(hostdata),

		.sd_di(SPI_DO),
		.sd_cs(SPI_CS),
		.sd_clk(SPI_SCK),
		.sd_do(SPI_DI),
		.sd_dimm(SD_MISO),
		.sd_ack(SD_ACK),

		.debugTxD(CTRL_TX),
		.debugRxD(CTRL_RX),
		.menu_button(MENU_BUTTON),
		.scandoubler(_15khz)
   );
	
endmodule

