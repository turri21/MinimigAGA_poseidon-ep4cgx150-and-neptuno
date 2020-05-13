
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- -----------------------------------------------------------------------

architecture rtl of chameleon2_toplevel is
   constant reset_cycles : integer := 131071;
	
-- System clocks

	signal clk_114 : std_logic;
	signal pll_locked : std_logic;
	signal ena_1mhz : std_logic;
	signal ena_1khz : std_logic;
	signal phi2 : std_logic;
	
-- Global signals
	signal reset : std_logic;
	signal n_reset : std_logic;

-- LEDs
	signal led_green : std_logic;
	signal led_red : std_logic;

-- Docking station
	signal no_clock : std_logic;
	signal docking_station : std_logic;
	signal phi_cnt : unsigned(7 downto 0);
	signal phi_end_1 : std_logic;
	
-- PS/2 Keyboard socket - used for second mouse
	signal ps2_keyboard_clk_in : std_logic;
	signal ps2_keyboard_dat_in : std_logic;
	signal ps2_keyboard_clk_out : std_logic;
	signal ps2_keyboard_dat_out : std_logic;

-- PS/2 Mouse
	signal ps2_mouse_clk_in: std_logic;
	signal ps2_mouse_dat_in: std_logic;
	signal ps2_mouse_clk_out: std_logic;
	signal ps2_mouse_dat_out: std_logic;
	
	signal sdram_req : std_logic := '0';
	signal sdram_ack : std_logic;
	signal sdram_we : std_logic := '0';
	signal sdram_a : unsigned(24 downto 0) := (others => '0');
	signal sdram_d : unsigned(7 downto 0);
	signal sdram_q : unsigned(7 downto 0);

	signal hsync : std_logic;
	signal vsync : std_logic;	
	signal wred : unsigned(7 downto 0);
	signal wgrn : unsigned(7 downto 0);
	signal wblu : unsigned(7 downto 0);

	-- Video
	signal vga_r: std_logic_vector(7 downto 0);
	signal vga_g: std_logic_vector(7 downto 0);
	signal vga_b: std_logic_vector(7 downto 0);
	signal vga_window : std_logic;
	signal vga_hsync : std_logic;
	signal vga_vsync : std_logic;
	
	
-- RS232 serial
	signal rs232_rxd : std_logic;
	signal rs232_txd : std_logic;

-- Sound
	signal audio_l : std_logic_vector(15 downto 0);
	signal audio_r : std_logic_vector(15 downto 0);

-- IO
	signal button_reset_n : std_logic;

	signal c64_keys : unsigned(63 downto 0);
	signal c64_restore_key_n : std_logic;
	signal c64_nmi_n : std_logic;
	signal c64_joy1 : unsigned(5 downto 0);
	signal c64_joy2 : unsigned(5 downto 0);
	signal joystick3 : unsigned(5 downto 0);
	signal joystick4 : unsigned(5 downto 0);
	signal gp1_run : std_logic;
	signal gp1_select : std_logic;
	signal joy1 : unsigned(7 downto 0);
	signal joy2 : unsigned(7 downto 0);
	signal joy3 : unsigned(7 downto 0);
	signal joy4 : unsigned(7 downto 0);
	signal ir : std_logic;
	signal ir_d : std_logic;

	-- Sigma Delta audio
	COMPONENT hybrid_pwm_sd
	PORT
	(
		clk	:	IN STD_LOGIC;
		n_reset	:	IN STD_LOGIC;
		din	:	IN STD_LOGIC_VECTOR(15 DOWNTO 0);
		dout	:	OUT STD_LOGIC
	);
	END COMPONENT;

	COMPONENT video_vga_dither
	GENERIC ( outbits : INTEGER := 4 );
	PORT
	(
		clk	:	IN STD_LOGIC;
		hsync	:	IN STD_LOGIC;
		vsync	:	IN STD_LOGIC;
		vid_ena	:	IN STD_LOGIC;
		iRed	:	IN UNSIGNED(7 DOWNTO 0);
		iGreen	:	IN UNSIGNED(7 DOWNTO 0);
		iBlue	:	IN UNSIGNED(7 DOWNTO 0);
		oRed	:	OUT UNSIGNED(outbits-1 DOWNTO 0);
		oGreen	:	OUT UNSIGNED(outbits-1 DOWNTO 0);
		oBlue	:	OUT UNSIGNED(outbits-1 DOWNTO 0)
	);
	END COMPONENT;

	COMPONENT minimig_virtual_top
	generic
	( debug : integer := 0 );
	PORT
	(
		CLK_114		:	 out STD_LOGIC;
		CLK_IN : in std_logic;
--		RESET_N : in STD_LOGIC;
		LED		:	 OUT STD_LOGIC;
		UART_TX		:	 OUT STD_LOGIC;
		UART_RX		:	 IN STD_LOGIC;
		VGA_HS		:	 OUT STD_LOGIC;
		VGA_VS		:	 OUT STD_LOGIC;
		VGA_R		:	 OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
		VGA_G		:	 OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
		VGA_B		:	 OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
		SDRAM_DQ		:	 INOUT STD_LOGIC_VECTOR(15 DOWNTO 0);
		SDRAM_A		:	 OUT STD_LOGIC_VECTOR(12 DOWNTO 0);
		SDRAM_DQML		:	 OUT STD_LOGIC;
		SDRAM_DQMH		:	 OUT STD_LOGIC;
		SDRAM_nWE		:	 OUT STD_LOGIC;
		SDRAM_nCAS		:	 OUT STD_LOGIC;
		SDRAM_nRAS		:	 OUT STD_LOGIC;
		SDRAM_nCS		:	 OUT STD_LOGIC;
		SDRAM_BA		:	 OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
		SDRAM_CLK		:	 OUT STD_LOGIC;
		SDRAM_CKE		:	 OUT STD_LOGIC;
		AUDIO_L		:	 OUT STD_LOGIC_VECTOR(14 downto 0);
		AUDIO_R		:	 OUT STD_LOGIC_VECTOR(14 downto 0);
		PS2_DAT_I		:	 IN STD_LOGIC;
		PS2_CLK_I		:	 IN STD_LOGIC;
		PS2_MDAT_I		:	 IN STD_LOGIC;
		PS2_MCLK_I		:	 IN STD_LOGIC;
		PS2_DAT_O	:	 OUT STD_LOGIC;
		PS2_CLK_O	:	 OUT STD_LOGIC;
		PS2_MDAT_O	:	 OUT STD_LOGIC;
		PS2_MCLK_O	:	 OUT STD_LOGIC;
		JOYA		:	 IN STD_LOGIC_VECTOR(6 DOWNTO 0);
		JOYB		:	 IN STD_LOGIC_VECTOR(6 DOWNTO 0);
		JOYC		:	 IN STD_LOGIC_VECTOR(6 DOWNTO 0);
		JOYD		:	 IN STD_LOGIC_VECTOR(6 DOWNTO 0);
		SD_MISO	:	 IN STD_LOGIC;
		SD_MOSI	:	 OUT STD_LOGIC;
		SD_CLK	:	 OUT STD_LOGIC;
		SD_CS		:	 OUT STD_LOGIC;
		SD_ACK	:	 IN STD_LOGIC
	);
	END COMPONENT;

begin
-- -----------------------------------------------------------------------
-- Unused pins
-- -----------------------------------------------------------------------
	iec_clk_out <= '0';
	iec_atn_out <= '0';
	iec_dat_out <= '0';
	iec_srq_out <= '0';
	irq_out <= '0';
	nmi_out <= '0';
	usart_rx<='1';

	-- put these here?
	flash_cs <= '1';
	rtc_cs <= '0';
	

-- -----------------------------------------------------------------------
-- Reset
-- -----------------------------------------------------------------------
	myReset : entity work.gen_reset
		generic map (
			resetCycles => reset_cycles
		)
		port map (
			clk => clk_114,
			enable => '1',

			button => not reset_btn,
			reset => reset,
			nreset => n_reset
		);

-- -----------------------------------------------------------------------
-- 1 Mhz and 1 Khz clocks
-- -----------------------------------------------------------------------
	my1Mhz : entity work.chameleon_1mhz
		generic map (
			clk_ticks_per_usec => 100
		)
		port map (
			clk => clk_114,
			ena_1mhz => ena_1mhz,
			ena_1mhz_2 => open
		);

	my1Khz : entity work.chameleon_1khz
		port map (
			clk => clk_114,
			ena_1mhz => ena_1mhz,
			ena_1khz => ena_1khz
		);
	
-- -----------------------------------------------------------------------
-- PS2IEC multiplexer
-- -----------------------------------------------------------------------
	io_ps2iec_inst : entity work.chameleon2_io_ps2iec
		port map (
			clk => clk_114,

			ps2iec_sel => ps2iec_sel,
			ps2iec => ps2iec,

			ps2_mouse_clk => ps2_mouse_clk_in,
			ps2_mouse_dat => ps2_mouse_dat_in,
			ps2_keyboard_clk => ps2_keyboard_clk_in,
			ps2_keyboard_dat => ps2_keyboard_dat_in,

			iec_clk => open, -- iec_clk_in,
			iec_srq => open, -- iec_srq_in,
			iec_atn => open, -- iec_atn_in,
			iec_dat => open  -- iec_dat_in
		);

-- -----------------------------------------------------------------------
-- LED, PS2 and reset shiftregister
-- -----------------------------------------------------------------------
	io_shiftreg_inst : entity work.chameleon2_io_shiftreg
		port map (
			clk => clk_114,

			ser_out_clk => ser_out_clk,
			ser_out_dat => ser_out_dat,
			ser_out_rclk => ser_out_rclk,

			reset_c64 => reset,
			reset_iec => reset,
			ps2_mouse_clk => ps2_mouse_clk_out,
			ps2_mouse_dat => ps2_mouse_dat_out,
			ps2_keyboard_clk => ps2_keyboard_clk_out,
			ps2_keyboard_dat => ps2_keyboard_dat_out,
			led_green => led_green,
			led_red => led_red
		);

-- -----------------------------------------------------------------------
-- Chameleon IO, docking station and cartridge port
-- -----------------------------------------------------------------------
	chameleon2_io_blk : block
	begin
		chameleon2_io_inst : entity work.chameleon2_io
			generic map (
				enable_docking_station => true,
				enable_cdtv_remote => true,
				enable_c64_joykeyb => true,
				enable_c64_4player => true
			)
			port map (
				clk => clk_114,
				ena_1mhz => ena_1mhz,
				phi2_n => phi2_n,
				dotclock_n => dotclk_n,

				reset => reset,

				ir_data => ir,
				ioef => ioef,
				romlh => romlh,

				dma_out => dma_out,
				game_out => game_out,
				exrom_out => exrom_out,

				ba_in => ba_in,
--				rw_in => rw_in,
				rw_out => rw_out,

				sa_dir => sa_dir,
				sa_oe => sa_oe,
				sa15_out => sa15_out,
				low_a => low_a,

				sd_dir => sd_dir,
				sd_oe => sd_oe,
				low_d => low_d,

				no_clock => no_clock,
				docking_station => docking_station,

				phi_cnt => phi_cnt,
				phi_end_1 => phi_end_1,

				joystick1 => c64_joy1,
				joystick2 => c64_joy2,
				joystick3 => joystick3,
				joystick4 => joystick4,
				keys => c64_keys,
--				restore_key_n => restore_n
				restore_key_n => open
			);
	end block;

-- Synchronise IR signal
process (clk_114)
begin
	if rising_edge(clk_114) then
		ir_d<=ir_data;
		ir<=ir_d;
	end if;
end process;

		
--joy1<=not gp1_run & not gp1_select & (c64_joy1 and cdtv_joy1);
gp1_run<=c64_keys(11) and c64_keys(56) when c64_joy1="111111" else '1';
gp1_select<=c64_keys(60) when c64_joy1="111111" else '1';
joy1<=gp1_run & gp1_select & c64_joy1;
joy2<="11" & c64_joy2;
joy3<="11" & joystick3;
joy4<="11" & joystick4;
	

vga_window<='1';

virtual_top : COMPONENT minimig_virtual_top
generic map
	(
		debug => 0
	)
PORT map
	(
		CLK_IN => clk50m,
		CLK_114 => clk_114,
		LED => led_red,
		UART_TX => rs232_txd,
		UART_RX => rs232_rxd,
		VGA_HS => vga_hsync,
		VGA_VS => vga_vsync,
		VGA_R	=> vga_r,
		VGA_G	=> vga_g,
		VGA_B	=> vga_b,
	
		SDRAM_DQ	=> std_logic_vector(ram_d),
		unsigned(SDRAM_A) => ram_a,
		SDRAM_DQML => ram_ldqm,
		SDRAM_DQMH => ram_udqm,
		SDRAM_nWE => ram_we,
		SDRAM_nCAS => ram_cas,
		SDRAM_nRAS => ram_ras,
--		SDRAM_nCS => sd_cs,
		SDRAM_BA(1) => ram_ba(1),
		SDRAM_BA(0) => ram_ba(0),
		SDRAM_CLK => ram_clk,
--		SDRAM_CKE => sd_CKE,

		AUDIO_L => audio_l(15 downto 1),
		AUDIO_R => audio_r(15 downto 1),
		
		PS2_DAT_I => ps2_keyboard_dat_in,
		PS2_CLK_I => ps2_keyboard_clk_in,
		PS2_MDAT_I => ps2_mouse_dat_in,
		PS2_MCLK_I => ps2_mouse_clk_in,
		PS2_DAT_O => ps2_keyboard_dat_out,
		PS2_CLK_O => ps2_keyboard_clk_out,
		PS2_MDAT_O => ps2_mouse_dat_out,
		PS2_MCLK_O => ps2_mouse_clk_out,

		JOYA(6) => '1',
		JOYB(6) => '1',
		JOYC(6) => '1',
		JOYD(6) => '1',
		JOYA(5 downto 0) => std_logic_vector(c64_joy1),
		JOYB(5 downto 0) => std_logic_vector(c64_joy2),
		JOYC(5 downto 0) => std_logic_vector(joystick3),
		JOYD(5 downto 0) => std_logic_vector(joystick4),

		SD_MISO => spi_miso,
		SD_MOSI => spi_mosi,
		SD_CLK => spi_clk,
		SD_CS => mmc_cs,
		SD_ACK => '1'
	);
audio_l(0)<='0';
audio_r(0)<='0';
	
-- Dither the video down to 5 bits per gun.
	vga_window<='1';
	hsync_n<= not vga_hsync;
	vsync_n<= not vga_vsync;	
	red<=unsigned(vga_r(7 downto 3));
	grn<=unsigned(vga_g(7 downto 3));
	blu<=unsigned(vga_b(7 downto 3));
--	mydither : component video_vga_dither
--		generic map(
--			outbits => 5
--		)
--		port map(
--			clk=>clk_114,
--			hsync=>vga_hsync,
--			vsync=>vga_vsync,
--			vid_ena=>vga_window,
--			iRed => unsigned(vga_r),
--			iGreen => unsigned(vga_g),
--			iBlue => unsigned(vga_b),
--			oRed => red,
--			oGreen => grn,
--			oBlue => blu
--		);
	
leftsd: component hybrid_pwm_sd
	port map
	(
		clk => clk_114,
		n_reset => n_reset,
		din(15) => not audio_l(15),
		din(14 downto 0) => std_logic_vector(audio_l(14 downto 0)),
		dout => sigma_l
	);
	
rightsd: component hybrid_pwm_sd
	port map
	(
		clk => clk_114,
		n_reset => n_reset,
		din(15) => not audio_r(15),
		din(14 downto 0) => std_logic_vector(audio_r(14 downto 0)),
		dout => sigma_r
	);


end architecture;

