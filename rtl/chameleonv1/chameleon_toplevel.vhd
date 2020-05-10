-- -----------------------------------------------------------------------
--
-- Turbo Chameleon
--
-- Toplevel file for Turbo Chameleon 64
--

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;

library work;

-- -----------------------------------------------------------------------

entity chameleon_toplevel is
	generic (
		resetCycles: integer := 131071
	);
	port (
-- Clocks
		clk8 : in std_logic;
		phi2_n : in std_logic;
		dotclock_n : in std_logic;

-- Bus
		romlh_n : in std_logic;
		ioef_n : in std_logic;

-- Buttons
		freeze_n : in std_logic;

-- MMC/SPI
		spi_miso : in std_logic;
		mmc_cd_n : in std_logic;
		mmc_wp : in std_logic;

-- MUX CPLD
		mux_clk : out std_logic;
		mux : out unsigned(3 downto 0);
		mux_d : out unsigned(3 downto 0);
		mux_q : in unsigned(3 downto 0);

-- USART
		usart_tx : in std_logic;
		usart_clk : in std_logic;
		usart_rts : in std_logic;
		usart_cts : in std_logic;

-- SDRam
		sd_clk : out std_logic;
		sd_data : inout std_logic_vector(15 downto 0);
		sd_addr : out std_logic_vector(12 downto 0);
		sd_we_n : out std_logic;
		sd_ras_n : out std_logic;
		sd_cas_n : out std_logic;
		sd_ba_0 : out std_logic;
		sd_ba_1 : out std_logic;
		sd_ldqm : out std_logic;
		sd_udqm : out std_logic;

-- Video
		red : out unsigned(4 downto 0);
		grn : out unsigned(4 downto 0);
		blu : out unsigned(4 downto 0);
		nHSync : buffer std_logic;
		nVSync : buffer std_logic;

-- Audio
		sigmaL : out std_logic;
		sigmaR : out std_logic
	);
end entity;

-- -----------------------------------------------------------------------

architecture rtl of chameleon_toplevel is
	
-- System clocks
	signal clk_114 : std_logic;
	signal reset_button_n : std_logic;
	signal pll_locked : std_logic;
	
-- Global signals
	signal reset : std_logic;
	signal reset_n : std_logic;
	
-- MUX
	signal mux_clk_reg : std_logic := '0';
	signal mux_reg : unsigned(3 downto 0) := (others => '1');
	signal mux_d_reg : unsigned(3 downto 0) := (others => '1');
	signal mux_d_regd : unsigned(3 downto 0) := (others => '1');
	signal mux_regd : unsigned(3 downto 0) := (others => '1');

-- LEDs
	signal led_green : std_logic;
	signal led_red : std_logic;
	signal socleds : std_logic_vector(7 downto 0);

-- PS/2 Keyboard
	signal ps2_keyboard_clk_in : std_logic;
	signal ps2_keyboard_dat_in : std_logic;
	signal ps2_keyboard_clk_out : std_logic;
	signal ps2_keyboard_dat_out : std_logic;

-- PS/2 Mouse
	signal ps2_mouse_clk_in: std_logic;
	signal ps2_mouse_dat_in: std_logic;
	signal ps2_mouse_clk_out: std_logic;
	signal ps2_mouse_dat_out: std_logic;

-- SD card
	signal spi_mosi : std_logic;
	signal spi_cs : std_logic;
	signal spi_clk : std_logic;
	signal spi_raw_ack : std_logic;
	
-- RS232 serial
	signal rs232_rxd : std_logic;
	signal rs232_txd : std_logic;

-- Sound
	signal audio_l : std_logic_vector(15 downto 0);
	signal audio_r : std_logic_vector(15 downto 0);

-- IO
	signal ena_1mhz : std_logic;
	signal button_reset_n : std_logic;

	signal no_clock : std_logic;
	signal docking_station : std_logic;
	signal c64_keys : unsigned(63 downto 0);
	signal c64_restore_key_n : std_logic;
	signal c64_nmi_n : std_logic;
	signal c64_joy1 : unsigned(5 downto 0);
	signal c64_joy2 : unsigned(5 downto 0);
	signal joystick3 : unsigned(5 downto 0);
	signal joystick4 : unsigned(5 downto 0);
	signal usart_rx : std_logic:='1'; -- Safe default
	signal ir : std_logic;

	signal vga_hsync : std_logic;
	signal vga_vsync : std_logic;
	signal vga_red : std_logic_vector(7 downto 0);
	signal vga_green : std_logic_vector(7 downto 0);
	signal vga_blue : std_logic_vector(7 downto 0);
	
	COMPONENT amiga_clk_altera
	PORT
	(
		areset		:	 IN STD_LOGIC;
		inclk0		:	 IN STD_LOGIC;
		c0		:	 OUT STD_LOGIC;
		c1		:	 OUT STD_LOGIC;
		c2		:	 OUT STD_LOGIC;
		locked		:	 OUT STD_LOGIC
	);
	END COMPONENT;

	COMPONENT hybrid_pwm_sd
		PORT
		(
			clk		:	 IN STD_LOGIC;
			n_reset	:	 IN STD_LOGIC;
			din		:	 IN STD_LOGIC_VECTOR(15 DOWNTO 0);
			dout		:	 OUT STD_LOGIC
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
-- Clocks and PLL
-- -----------------------------------------------------------------------


my1mhz : entity work.chameleon_1mhz
	generic map (
		-- Timer calibration. Clock speed in Mhz.
		clk_ticks_per_usec => 113
	)
	port map(
		clk => clk_114,
		ena_1mhz => ena_1mhz
	);

myReset : entity work.gen_reset
	generic map (
		resetCycles => 15
	)
	port map (
		clk => clk8,	-- Shouldn't run this from a PLL generated clock since it needs to run while the PLLs aren't yet stable.
		enable => '1',
		button => not (button_reset_n and pll_locked),
		reset => reset,
		nreset => reset_n
	);
	
	myIO : entity work.chameleon_io
		generic map (
			enable_docking_station => true,
			enable_c64_joykeyb => true,
			enable_c64_4player => true,
			enable_raw_spi => true,
			enable_iec_access =>true
		)
		port map (
		-- Clocks
			clk => clk_114,
			clk_mux => clk_114,
			ena_1mhz => ena_1mhz,
			reset => reset,
			
			no_clock => no_clock,
			docking_station => docking_station,
			
		-- Chameleon FPGA pins
			-- C64 Clocks
			phi2_n => phi2_n,
			dotclock_n => dotclock_n, 
			-- C64 cartridge control lines
			io_ef_n => ioef_n,
			rom_lh_n => romlh_n,
			-- SPI bus
			spi_miso => spi_miso,
			-- CPLD multiplexer
			mux_clk => mux_clk,
			mux => mux,
			mux_d => mux_d,
			mux_q => mux_q,
			
			to_usb_rx => usart_rx,

		-- SPI raw signals (enable_raw_spi must be set to true)
			mmc_cs_n => spi_cs,
			spi_raw_clk => spi_clk,
			spi_raw_mosi => spi_mosi,
			spi_raw_ack => spi_raw_ack,

		-- LEDs
			led_green => '1',
			led_red => '1',
			ir => ir,
		
		-- PS/2 Keyboard
			ps2_keyboard_clk_out => ps2_keyboard_clk_out,
			ps2_keyboard_dat_out => ps2_keyboard_dat_out,
			ps2_keyboard_clk_in => ps2_keyboard_clk_in,
			ps2_keyboard_dat_in => ps2_keyboard_dat_in,
	
		-- PS/2 Mouse
			ps2_mouse_clk_out => ps2_mouse_clk_out,
			ps2_mouse_dat_out => ps2_mouse_dat_out,
			ps2_mouse_clk_in => ps2_mouse_clk_in,
			ps2_mouse_dat_in => ps2_mouse_dat_in,

		-- Buttons
			button_reset_n => button_reset_n,

		-- Joysticks
			joystick1 => c64_joy1,
			joystick2 => c64_joy2,
			joystick3 => joystick3, 
			joystick4 => joystick4,

		-- Keyboards
			keys => c64_keys,
			restore_key_n => c64_restore_key_n,
			c64_nmi_n => c64_nmi_n

--
--			iec_atn_out => rs232_txd,
--			iec_clk_in => rs232_rxd
--			iec_clk_out : in std_logic := '1';
--			iec_dat_out : in std_logic := '1';
--			iec_srq_out : in std_logic := '1';
--			iec_dat_in : out std_logic;
--			iec_atn_in : out std_logic;
--			iec_srq_in : out std_logic
	
		);


virtual_top : COMPONENT minimig_virtual_top
generic map
	(
		debug => 0
	)
PORT map
	(
		CLK_IN => clk8,
		CLK_114 => clk_114,
		LED => led_red,
		UART_TX => rs232_txd,
		UART_RX => rs232_rxd,
		VGA_HS => vga_hsync,
		VGA_VS => vga_vsync,
		VGA_R	=> vga_red,
		VGA_G	=> vga_green,
		VGA_B	=> vga_blue,
	
		SDRAM_DQ	=> sd_data,
		SDRAM_A => sd_addr,
		SDRAM_DQML => sd_ldqm,
		SDRAM_DQMH => sd_udqm,
		SDRAM_nWE => sd_we_n,
		SDRAM_nCAS => sd_cas_n,
		SDRAM_nRAS => sd_ras_n,
--		SDRAM_nCS => sd_cs,
		SDRAM_BA(1) => sd_ba_1,
		SDRAM_BA(0) => sd_ba_0,
		SDRAM_CLK => sd_clk,
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
		SD_CS => spi_cs,
		SD_ACK => spi_raw_ack
	);
audio_l(0)<='0';
audio_r(0)<='0';

nHSync<=vga_hsync;
nVSync<=vga_vsync;
red<=unsigned(vga_red(7 downto 3));
grn<=unsigned(vga_green(7 downto 3));
blu<=unsigned(vga_blue(7 downto 3));

left_sd : COMPONENT hybrid_pwm_sd
	PORT map
	(
		clk => clk_114,
		n_reset => vga_hsync,
		din(15) => not audio_l(15),
		din(14 downto 0) => audio_l(14 downto 0),
		dout => sigmaL
	);

right_sd : COMPONENT hybrid_pwm_sd
	PORT map
	(
		clk => clk_114,
		n_reset => vga_hsync,
		din(15) => not audio_r(15),
		din(14 downto 0) => audio_r(14 downto 0),
		dout => sigmaR
	);

end architecture;
