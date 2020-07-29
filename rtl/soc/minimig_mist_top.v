/********************************************/
/* minimig_mist_top.v                       */
/* MiST Board Top File                      */
/*                                          */
/* 2012-2015, rok.krajnc@gmail.com          */
/********************************************/


// board type define
`define MINIMIG_MIST

// new cpu define
//`define MINIMIG_MIST_NEWCPU

// simulation define
//`define SOC_SIM

`include "minimig_defines.vh"


module minimig_mist_top (
  // clock inputs
  input  wire [  2-1:0] CLOCK_32,   // 32 MHz
  input  wire [  2-1:0] CLOCK_27,   // 27 MHz
  input  wire [  2-1:0] CLOCK_50,   // 50 MHz
  // LED outputs
  output wire           LED,        // LED Yellow
  // UART
  output wire           UART_TX,    // UART Transmitter
  input wire            UART_RX,    // UART Receiver
  // VGA
  output wire           VGA_HS,     // VGA H_SYNC
  output wire           VGA_VS,     // VGA V_SYNC
  output wire [  6-1:0] VGA_R,      // VGA Red[5:0]
  output wire [  6-1:0] VGA_G,      // VGA Green[5:0]
  output wire [  6-1:0] VGA_B,      // VGA Blue[5:0]
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
  output wire           AUDIO_L,    // sigma-delta DAC output left
  output wire           AUDIO_R,    // sigma-delta DAC output right
  // SPI
  inout wire            SPI_DO,     // inout
  input wire            SPI_DI,
  input wire            SPI_SCK,
  input wire            SPI_SS2,    // fpga
  input wire            SPI_SS3,    // OSD
  input wire            SPI_SS4,    // "sniff" mode
  input wire            CONF_DATA0  // SPI_SS for user_io
);


////////////////////////////////////////
// internal signals                   //
////////////////////////////////////////

// clock
wire           pll_in_clk;
wire           clk_114;
wire           clk_28;
wire           clk_sdram;
wire           pll_locked;
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
wire           tg68_ena28;
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
wire           joy_emu_en;    // joystick emulation enable
wire           sdo;           // SPI data output
wire [ 16-1:0] ldata;         // left DAC data
wire [ 16-1:0] rdata;         // right DAC data
wire           audio_left;
wire           audio_right;

wire           cs;
wire           vs;
wire           hs;
wire [  8-1:0] red;
wire [  8-1:0] green;
wire [  8-1:0] blue;

wire [  6-1:0] mixer_red;
wire [  6-1:0] mixer_green;
wire [  6-1:0] mixer_blue;
wire           mixer_vs;
wire           mixer_hs;

reg [  6-1:0] red_mixed_r;
reg [  6-1:0] green_mixed_r;
reg [  6-1:0] blue_mixed_r;
reg           vs_mixed_r;
reg           hs_mixed_r;

wire [  8-1:0] dithered_red;
wire [  8-1:0] dithered_green;
wire [  8-1:0] dithered_blue;
wire           dithered_vs;
wire           dithered_hs;

reg            vs_reg;
reg            hs_reg;
reg				cs_reg;
reg  [  8-1:0] red_reg;
reg  [  8-1:0] green_reg;
reg  [  8-1:0] blue_reg;

wire vga_selcs;
wire vga_window;
wire vga_selcsync;
wire vga_pixel;

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
wire           mouse_idx;
wire [  2-1:0] kbd_mouse_type;
wire [  3-1:0] mouse0_buttons;
wire [  3-1:0] mouse1_buttons;
wire [  4-1:0] core_config;
wire [ 64-1:0] rtc;

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

// clock
assign pll_in_clk       = CLOCK_27[0];

// reset
assign pll_rst          = 1'b0;
assign sdctl_rst        = pll_locked;

// minimig
assign _15khz           = ~core_config[0];
assign joy_emu_en       = 1'b1;

assign LED              = ~led;

// VGA data
always @ (posedge clk_114) begin
  vs_mixed_r    <= #1 mixer_vs;
  hs_mixed_r    <= #1 mixer_hs;
  red_mixed_r   <= #1 mixer_red;
  green_mixed_r <= #1 mixer_green;
  blue_mixed_r  <= #1 mixer_blue;
end

assign VGA_VS           = vs_mixed_r;
assign VGA_HS           = hs_mixed_r;
assign VGA_R[5:0]       = red_mixed_r[5:0];
assign VGA_G[5:0]       = green_mixed_r[5:0];
assign VGA_B[5:0]       = blue_mixed_r[5:0];

wire   ypbpr            = core_config[1];


//// YPbPr video mixer ////
// Final video mixer
// Not all functions of mixer are used due to some signals are pre-mixed already
video_mixer video_mixer
(
	.scandoubler_disable(0),
	.ypbpr(ypbpr),
	.ypbpr_full(1),

	.r_p      (dithered_red      ),
	.g_p      (dithered_green    ),
	.b_p      (dithered_blue     ),
	.hsync_p  (dithered_hs       ),
	.vsync_p  (dithered_vs       ),

	.VGA_HS (mixer_hs   ),
	.VGA_VS (mixer_vs   ),
	.VGA_R  (mixer_red  ),
	.VGA_G  (mixer_green),
	.VGA_B  (mixer_blue )
);


//// amiga clocks ////
amiga_clk amiga_clk (
  .rst          (pll_rst          ), // async reset input
  .clk_in       (pll_in_clk       ), // input clock     ( 27.000000MHz)
  .clk_114      (clk_114          ), // output clock c0 (114.750000MHz)
  .clk_sdram    (clk_sdram        ), // output clock c2 (114.750000MHz, -146.25 deg)
  .clk_28       (clk_28           ), // output clock c1 ( 28.687500MHz)
  .clk7_en      (clk7_en          ), // output clock 7 enable (on 28MHz clock domain)
  .clk7n_en     (clk7n_en         ), // 7MHz negedge output clock enable (on 28MHz clock domain)
  .c1           (c1               ), // clk28m clock domain signal synchronous with clk signal
  .c3           (c3               ), // clk28m clock domain signal synchronous with clk signal delayed by 90 degrees
  .cck          (cck              ), // colour clock output (3.54 MHz)
  .eclk         (eclk             ), // 0.709379 MHz clock enable output (clk domain pulse)
  .locked       (pll_locked       )  // pll locked output
);


//// TG68K main CPU ////
`ifdef MINIMIG_MIST_NEWCPU
TG68K_SplitClock tg68k (
  .clk          (clk_114          ),
  .clk28        (clk_28           ),
  .reset        (tg68_rst         ),
  .IPL          (tg68_IPL         ),
  .dtack        (tg68_dtack       ),
//  .vpa          (1'b1             ),
//  .ein          (1'b1             ),
  .addr         (tg68_adr         ),
  .data_read    (tg68_dat_in      ),
  .data_write   (tg68_dat_out     ),
  .as           (tg68_as          ),
  .uds          (tg68_uds         ),
  .lds          (tg68_lds         ),
  .rw           (tg68_rw          ),
  .e            (                 ),
  .vma          (                 ),
  .wrd          (                 ),
  .ena7RDreg    (tg68_ena7RD      ),
  .ena7WRreg    (tg68_ena7WR      ),
  .enaWRreg     (tg68_enaWR       ),
  .fromram      (tg68_cout        ),
  .toram      (tg68_cin        ),
  .ramready     (tg68_cpuena      ),
  .cache_valid(cache_valid),
  .cacheable(tg68_cacheable),
  .cpu          (cpu_config[1:0]  ),
  .turbochipram (memcfg[5]&memcfg[4]&turbochipram/*1'b0*//*turbochipram*/     ),
  .fastramcfg   ({memcfg[5]&memcfg[4],memcfg[5:4]}),
  .ramaddr      (tg68_cad         ),
  .cpustate     (tg68_cpustate    ),
  .nResetOut    (tg68_nrst_out    ),
  .skipFetch    (                 ),
  .ramlds       (tg68_clds        ),
  .ramuds       (tg68_cuds        ),
  .VBR_out      (tg68_VBR_out     )
);

`else

TG68K tg68k (
  .clk          (clk_114          ),
  .reset        (tg68_rst         ),
  .clkena_in    (tg68_ena28       ),
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
//.ovr          (tg68_ovr         ),
  .ramaddr      (tg68_cad         ),
  .cpustate     (tg68_cpustate    ),
  .nResetOut    (tg68_nrst_out    ),
  .skipFetch    (                 ),
//  .cpuDMA       (tg68_cdma        ),
  .ramlds       (tg68_clds        ),
  .ramuds       (tg68_cuds        ),
  .CACR_out     (tg68_CACR_out    ),
  .VBR_out      (tg68_VBR_out     ),
  // RTG signals
	.rtg_addr(rtg_baseaddr),
	.rtg_vbend(rtg_vbend),
	.rtg_ext(rtg_ext),
	.rtg_pixelclock(rtg_pixelwidth),
	.rtg_clut(rtg_clut),
	.rtg_clut_idx(rtg_clut_idx),
	.rtg_clut_r(rtg_clut_r),
	.rtg_clut_g(rtg_clut_g),
	.rtg_clut_b(rtg_clut_b),
);

`endif

/*
//// TG68 main CPU ////
TG68 tg68 (
  .clk          (clk_114          ),
  .reset        (tg68_rst         ),
  .clkena_in    (1'b1             ),
  .data_in      (tg68_dat_in      ),
  .data_out     (tg68_dat_out     ),
  .IPL          (tg68_IPL         ),
  .dtack        (tg68_dtack       ),
  .addr         (tg68_adr         ),
  .as           (tg68_as          ),
  .uds          (tg68_uds         ),
  .lds          (tg68_lds         ),
  .rw           (tg68_rw          ),
  .drive_data   (                 ),
  .enaRDreg     (tg68_ena7RD      ),
  .enaWRreg     (tg68_ena7WR      )
);
*/


//// sdram ////
/*
sdram_ctrl sdram (
  // sys
  .sysclk       (clk_114          ),
  .reset_in     (sdctl_rst        ),
  .cache_rst    (tg68_rst         ),
  .reset_out    (reset_out        ),
  .cache_ena    (cpu_config[2]    ),
  // sdram
  .sdaddr       (SDRAM_A[12:0]    ),
  .sd_cs        (sdram_cs         ),
  .ba           (sdram_ba         ),
  .sd_we        (SDRAM_nWE        ),
  .sd_ras       (SDRAM_nRAS       ),
  .sd_cas       (SDRAM_nCAS       ),
  .dqm          (sdram_dqm        ),
  .sdata        (SDRAM_DQ         ),
  // host
  .host_cs      (1'b0             ),
  .host_adr     (22'hxxxxxx       ),
  .host_we      (1'b0             ),
  .host_bs      (2'bxx            ),
  .host_wdat    (16'hxxxx         ),
  .host_rdat    (                 ),
  .host_ack     (                 ),
  // chip
  .chipAddr     ({2'b00, ram_address[21:1]}),
  .chipL        (_ram_ble         ),
  .chipU        (_ram_bhe         ),
  .chipRW       (_ram_we          ),
  .chip_dma     (_ram_oe          ),
  .chipWR       (ram_data         ),
  .chipRD       (ramdata_in       ),
  .chip48       (chip48           ),
  // cpu
  .cpuAddr      (tg68_cad[24:1]   ),
  .cpustate     (tg68_cpustate    ),
  .cpuL         (tg68_clds        ),
  .cpuU         (tg68_cuds        ),
  .cpu_dma      (tg68_cdma        ),
  .cpuWR        (tg68_dat_out     ),
  .cpuRD        (tg68_cout        ),
  .enaWRreg     (tg68_enaWR       ),
  .ena7RDreg    (tg68_ena7RD      ),
  .ena7WRreg    (tg68_ena7WR      ),
  .cpuena       (tg68_cpuena      )
);
*/

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
  .sysclk       (clk_114          ),
  .reset_in     (sdctl_rst        ),
//  .hostWR       (16'h0            ),
//  .hostAddr     (24'h0            ),
//  .hostState    ({1'b0, 2'b01}    ),
//  .hostL        (1'b1             ),
//  .hostU        (1'b1             ),
  .cpuWR        (tg68_dat_out     ),
  .cpuAddr      (tg68_cad[24:1]   ),
  .cpuU         (tg68_cuds        ),
  .cpuL         (tg68_clds        ),
  .cpustate     (tg68_cpustate    ),
//  .cpu_dma      (tg68_cdma        ),
  .chipWR       (ram_data         ),
  .chipAddr     ({1'b0, ram_address[22:1]}),
  .chipU        (_ram_bhe         ),
  .chipL        (_ram_ble         ),
  .chipRW       (_ram_we          ),
  .chip_dma     (_ram_oe          ),
  .clk7_en      (clk7_en          ),
  .hostRD       (                 ),
  .hostena      (                 ),
  .cpuRD        (tg68_cout        ),
  .cpuena       (tg68_cpuena      ),
  .chipRD       (ramdata_in       ),
  .chip48       (chip48           ),
  .rtgAddr      (rtg_addr_mangled ),
  .rtgce        (rtg_ramreq       ),
  .rtgfill      (rtg_fill         ),
  .rtgRd        (rtg_fromram      ), 
  .reset_out    (reset_out        ),
  .enaRDreg     (                 ),
  .enaWRreg     (tg68_ena28       ),
  .ena7RDreg    (tg68_ena7RD      ),
  .ena7WRreg    (tg68_ena7WR      )
);


// multiplex spi_do, drive it from user_io if that's selected, drive
// it from minimig if it's selected and leave it open else (also
// to be able to monitor sd card data directly)
assign SPI_DO = (CONF_DATA0 == 1'b0)?user_io_sdo:
    (((SPI_SS2 == 1'b0)|| (SPI_SS3 == 1'b0))?minimig_sdo:1'bZ);

//// user io has an extra spi channel outside minimig core ////
user_io user_io(
     .clk_sys(clk_28),
     .SPI_CLK(SPI_SCK),
     .SPI_SS_IO(CONF_DATA0),
     .SPI_MISO(user_io_sdo),
     .SPI_MOSI(SPI_DI),
     .JOY0(joya),
     .JOY1(joyb),
     .JOY2(joyc),
     .JOY3(joyd),
     .RTC(rtc),
     .MOUSE0_BUTTONS(mouse0_buttons),
     .MOUSE1_BUTTONS(mouse1_buttons),
     .MOUSE_IDX(mouse_idx),
     .KBD_MOUSE_DATA(kbd_mouse_data),
     .KBD_MOUSE_TYPE(kbd_mouse_type),
     .KBD_MOUSE_STROBE(kbd_mouse_strobe),
     .KMS_LEVEL(kms_level),
     .CORE_TYPE(8'ha5),    // minimig core id (a1 - old minimig id, a5 - new aga minimig id)
     .CONF(core_config)
  );
  
  
wire           VGA_CS_INT;     // VGA C_SYNC
wire           VGA_HS_INT;     // VGA H_SYNC
wire           VGA_VS_INT;     // VGA V_SYNC
wire [  8-1:0] VGA_R_INT;      // VGA Red[5:0]
wire [  8-1:0] VGA_G_INT;      // VGA Green[5:0]
wire [  8-1:0] VGA_B_INT;      // VGA Blue[5:0]
  
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
  .rst_ext      (rst_minimig      ), // reset from ctrl block
  .rst_out      (                 ), // minimig reset status
  .clk          (clk_28           ), // output clock c1 ( 28.687500MHz)
  .clk7_en      (clk7_en          ), // 7MHz clock enable
  .clk7n_en     (clk7n_en         ), // 7MHz negedge clock enable
  .c1           (c1               ), // clk28m clock domain signal synchronous with clk signal
  .c3           (c3               ), // clk28m clock domain signal synchronous with clk signal delayed by 90 degrees
  .cck          (cck              ), // colour clock output (3.54 MHz)
  .eclk         (eclk             ), // 0.709379 MHz clock enable output (clk domain pulse)
  //rs232 pins
  .rxd          (UART_RX          ),  // RS232 receive
  .txd          (UART_TX          ),  // RS232 send
  .cts          (1'b0             ),  // RS232 clear to send
  .rts          (                 ),  // RS232 request to send
  //I/O
  ._joy1        (~joya            ),  // joystick 1 [fire7:fire,up,down,left,right] (default mouse port)
  ._joy2        (~joyb            ),  // joystick 2 [fire7:fire,up,down,left,right] (default joystick port)
  ._joy3        (~joyc            ),  // joystick 3 [fire7:fire,up,down,left,right]
  ._joy4        (~joyd            ),  // joystick 4 [fire7:fire,up,down,left,right]
  .mouse_btn1   (1'b1             ), // mouse button 1
  .mouse_btn2   (1'b1             ), // mouse button 2
  .mouse0_btn   (mouse0_buttons   ),  // mouse buttons for first mouse
  .mouse1_btn   (mouse1_buttons   ),  // mouse buttons for second mouse
  .mouse_idx    (mouse_idx        ),  // mouse index
  .kbd_reset_n  (1'b1             ),  // Aux keyboard reset (not used with MiST)
  .kbd_mouse_data (kbd_mouse_data ),  // mouse direction data, keycodes
  .kbd_mouse_type (kbd_mouse_type ),  // type of data
  .kbd_mouse_strobe (kbd_mouse_strobe), // kbd/mouse data strobe
  .kms_level    (kms_level        ),
  ._15khz       (_15khz           ),  // scandoubler disable
  .pwr_led      (led              ),  // power led
  .rtc          (rtc              ),
  .msdat        (                 ),  // PS2 mouse data
  .msclk        (                 ),  // PS2 mouse clk
  .kbddat       (                 ),  // PS2 keyboard data
  .kbdclk       (                 ),  // PS2 keyboard clk
  //host controller interface (SPI)
  ._scs         ( {SPI_SS4,SPI_SS3,SPI_SS2}  ),  // SPI chip select
  .direct_sdi   (SPI_DO           ),  // SD Card direct in  SPI_SDO
  .sdi          (SPI_DI           ),  // SPI data input
  .sdo          (minimig_sdo      ),  // SPI data output
  .sck          (SPI_SCK          ),  // SPI clock
  //video
	.selcsync     (vga_selcs        ),
	._csync       (cs               ),  // horizontal sync
	._hsync       (hs               ),  // horizontal sync
	._vsync       (vs               ),  // vertical sync
	.red          (red              ),  // red
	.green        (green            ),  // green
	.blue         (blue             ),  // blue
  //audio
  .left         (                 ),  // audio bitstream left
  .right        (                 ),  // audio bitstream right
  .ldata        (ldata            ),  // left DAC data
  .rdata        (rdata            ),  // right DAC data
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
  .hd_frd       (                 ),   // hd fifo  ading
	.hblank_out   (hblank_out       ),
	.vblank_out   (vblank_out       ),
	.osd_blank_out(osd_window       ),  // Let the toplevel dither module handle drawing the OSD.
	.osd_pixel_out(osd_pixel        ),
	.rtg_ena      (rtg_ena          )
);


wire [15:0] lunsigned;
assign lunsigned[15]=!ldata[15];
assign lunsigned[14:0]=ldata[14:0];

wire [15:0] runsigned;
assign runsigned[15]=!rdata[15];
assign runsigned[14:0]=rdata[14:0];

hybrid_pwm_sd sd(
	.clk(clk_114),
	.d_l(lunsigned),
	.q_l(AUDIO_L),
	.d_r(runsigned),
	.q_r(AUDIO_R)
);

assign vga_window = 1'b1;
video_vga_dither #(.outbits(6)) dither
(
	.clk(clk_114),
	.pixel(vga_pixel),
	.vidEna(vga_window),
	.iSelcsync(vga_selcsync),
	.iCsync(VGA_CS_INT),
	.iHsync(VGA_HS_INT),
	.iVsync(VGA_VS_INT),
	.iRed(VGA_R_INT),
	.iGreen(VGA_G_INT),
	.iBlue(VGA_B_INT),
	.oHsync(dithered_hs),
	.oVsync(dithered_vs),
	.oRed(dithered_red[7:2]),
	.oGreen(dithered_green[7:2]),
	.oBlue(dithered_blue[7:2])
	);

assign dithered_red[1:0]=2'b0;
assign dithered_green[1:0]=2'b0;
assign dithered_blue[1:0]=2'b0;
	

// RTG support...

wire rtg_ena;	// RTG screen on/off
wire rtg_clut;	// Are we in high-colour or 8-bit CLUT mode?

reg [3:0] rtg_pixelctr;	// Counter, compared against rtg_pixelwidth
wire [3:0] rtg_pixelwidth; // Number of clocks per fetch - 1
wire [7:0] rtg_clut_idx;	// The currently selected colour in indexed mode
wire rtg_pixel;	// Strobe the next pixel from the FIFO

wire hblank_out;
wire vblank_out;
reg rtg_vblank;
wire rtg_blank;
reg rtg_blank_d;
reg [6:0] rtg_vbcounter;	// Vvbco counter
wire [6:0] rtg_vbend; // Size of VBlank area


wire [7:0] rtg_r;	// 16-bit mode RGB data
wire [7:0] rtg_g;
wire [7:0] rtg_b;
reg rtg_clut_in_sel;	// Select first or second byte of 16-bit word as CLUT index
reg rtg_clut_in_sel_d;
wire rtg_ext;	// Extend the active area by one clock.
wire [7:0] rtg_clut_r;	// RGB data from CLUT
wire [7:0] rtg_clut_g;
wire [7:0] rtg_clut_b;


// RTG data fetch strobe
assign rtg_pixel=(rtg_ena && (!rtg_blank || (!rtg_blank_d && rtg_ext)) && rtg_pixelctr==rtg_pixelwidth) ? 1'b1 : 1'b0;

wire rtg_clut_pixel;
assign rtg_clut_pixel = rtg_clut_in_sel & !rtg_clut_in_sel_d; // Detect rising edge;
reg rtg_pixel_d;
// Export a VGA pixel strobe for the dither module.
assign vga_pixel=rtg_ena ? (rtg_pixel_d | (rtg_clut_pixel & rtg_clut)) : vga_strobe;

reg [2:0] vga_strobe_ctr;
wire vga_strobe;
assign vga_strobe = vga_strobe_ctr==3'b000 ? 1'b1 : 1'b0;

always @(posedge clk_114) begin
	rtg_pixel_d<=rtg_pixel;
	vga_strobe_ctr<=_15khz ? {vga_strobe_ctr[2:1],1'b0}+3'b010 : vga_strobe_ctr+3'b001;

	// Delayed copies of signals
	rtg_blank_d<=rtg_blank;
	rtg_clut_in_sel_d<=rtg_clut_in_sel;

	// Alternate colour index at twice the fetch clock.
	if(rtg_pixelctr=={1'b0,rtg_pixelwidth[3:1]})
		rtg_clut_in_sel<=1'b1;
	
	// Increment the fetch clock, reset during blank.
	if(rtg_blank || rtg_pixel) begin
		rtg_pixelctr<=3'b0;
		rtg_clut_in_sel<=1'b0;
	end else begin
		rtg_pixelctr<=rtg_pixelctr+1;
	end
end


always @(posedge clk_28)
begin
	// Handle vblank manually, since the OS makes it awkward to use the chipset for this.
  cs_reg    <= #1 cs;
  vs_reg    <= #1 vs;
  hs_reg    <= #1 hs;
	if(vblank_out) begin
		rtg_vblank<=1'b1;
		rtg_vbcounter<=5'b0;
	end else if(rtg_vbcounter==rtg_vbend) begin
		rtg_vblank<=1'b0;
	end else if(hs & !hs_reg) begin
		rtg_vbcounter<=rtg_vbcounter+1;
	end
end

assign rtg_blank = rtg_vblank | hblank_out;

assign rtg_clut_idx = rtg_clut_in_sel_d ? rtg_dat[7:0] : rtg_dat[15:8];
assign rtg_r=!rtg_blank ? {rtg_dat[14:10],rtg_dat[14:12]} : 16'b0 ;
assign rtg_g=!rtg_blank ? {rtg_dat[9:5],rtg_dat[9:7]} : 16'b0 ;
assign rtg_b=!rtg_blank ? {rtg_dat[4:0],rtg_dat[4:2]} : 16'b0 ;

wire [24:4] rtg_baseaddr;
wire [24:0] rtg_addr;
wire [15:0] rtg_dat;

wire rtg_ramreq;
wire [15:0] rtg_fromram;
wire rtg_fill;

// Replicate the CPU's address mangling.
wire [24:0] rtg_addr_mangled;
assign rtg_addr_mangled[24]=rtg_addr[24];
assign rtg_addr_mangled[23]=rtg_addr[23]^(rtg_addr[22]|rtg_addr[21]);
assign rtg_addr_mangled[22:0]=rtg_addr[22:0];

VideoStream myvs
(
	.clk(clk_114),
	.reset_n((!vblank_out) & rtg_ena),
	.enable(rtg_ena),
	.baseaddr({rtg_baseaddr[24:4],4'b0}),
	// SDRAM interface
	.a(rtg_addr),
	.req(rtg_ramreq),
	.d(rtg_fromram),
	.fill(rtg_fill),
	// Display interface
	.rdreq(rtg_pixel),
	.q(rtg_dat)
);


always @ (posedge clk_114) begin
  red_reg   <= #1 rtg_ena && !rtg_blank ? rtg_clut ? rtg_clut_r : rtg_r : red;
  green_reg <= #1 rtg_ena && !rtg_blank ? rtg_clut ? rtg_clut_g : rtg_g : green;
  blue_reg  <= #1 rtg_ena && !rtg_blank ? rtg_clut ? rtg_clut_b : rtg_b : blue;
end


wire osd_window;
wire osd_pixel;
wire [1:0] osd_r;
wire [1:0] osd_g;
wire [1:0] osd_b;
assign osd_r = osd_pixel ? 2'b11 : 2'b00;
assign osd_g = osd_pixel ? 2'b11 : 2'b00;
assign osd_b = osd_pixel ? 2'b11 : 2'b10;
assign VGA_CS_INT           = cs_reg;
assign VGA_VS_INT           = vs_reg;
assign VGA_HS_INT           = hs_reg;
assign VGA_R_INT[7:0]       = osd_window ? {osd_r,red_reg[7:2]} : red_reg[7:0];
assign VGA_G_INT[7:0]       = osd_window ? {osd_g,green_reg[7:2]} : green_reg[7:0];
assign VGA_B_INT[7:0]       = osd_window ? {osd_b,blue_reg[7:2]} : blue_reg[7:0];

	
endmodule

