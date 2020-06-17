library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;

entity akiko is
port (
	clk : in std_logic;
	reset_n : in std_logic;
	addr : in std_logic_vector(10 downto 0);
	req : in std_logic;
	wr : in std_logic;
	ack : out std_logic;
	d : in std_logic_vector(15 downto 0);
	q : out std_logic_vector(15 downto 0);
	-- RTG signals
	rtg_addr : out std_logic_vector(24 downto 4);
	rtg_vbend : out std_logic_vector(4 downto 0);
	rtg_ext : out std_logic;
	rtg_pixelclock : out std_logic_vector(2 downto 0);
	rtg_clut : out std_logic;
	rtg_clut_idx : in std_logic_vector(7 downto 0);
	rtg_clut_r : out std_logic_vector(7 downto 0);
	rtg_clut_g : out std_logic_vector(7 downto 0);
	rtg_clut_b : out std_logic_vector(7 downto 0)
);
end entity;

architecture rtl of akiko is

signal id_q : std_logic_vector(15 downto 0);
signal id_sel : std_logic;
signal id_ack : std_logic;
signal ct_sel : std_logic;
signal ct_q : std_logic_vector(15 downto 0);
signal ct_ack : std_logic;

signal rtg_sel : std_logic;
signal rtg_ack : std_logic;
signal clut_sel : std_logic;
signal clut_wr : std_logic;
signal clut_idx_w : std_logic_vector(7 downto 0);
signal clut_high : std_logic_vector(7 downto 0);
type clutarray is array(0 to 255) of std_logic_vector(31 downto 0);
signal clut : clutarray;
signal clut_rgb : std_logic_vector(31 downto 0);
begin

-- ID Register

id_sel <= '1' when addr(7 downto 2)=X"0"&"00" else '0';
id_q <= X"C0CA" when addr(1)='0' else X"CAFE";
id_ack<=req and id_sel;


-- Cornerturn for Chunky to Planar

ct_sel <= '1' when addr(7 downto 2)=X"3"&"10" else '0';	-- Cornerturn at 0xb80038

myc2p: entity work.cornerturn
port map
(
	clk => clk,
	reset_n => reset_n,
	d => d,
	q => ct_q,
	wr => wr,
	req => req and ct_sel,
	ack => ct_ack
);


-- RTG registers and CLUT

rtg_sel <='1' when addr(10 downto 8)="001" else '0';	-- RTG registers at 0xb801xx
clut_sel <='1' when addr(10)='1' else '0';	-- RTG CLUT at 0xb80400 - 7ff
clut_idx_w <= addr(9 downto 2);	-- 256 CLUT entries mapped from b80400 - b807ff
clut_wr <= wr and addr(1); -- Write 32-bit clut entry on write to lower word.

rtg_ack <=req and (rtg_sel or clut_sel);

rtg_clut_r<=clut_rgb(23 downto 16);
rtg_clut_g<=clut_rgb(15 downto 8);
rtg_clut_b<=clut_rgb(7 downto 0);

process(clk)
begin
	if rising_edge(clk) then

		clut_rgb<=clut(to_integer(unsigned(rtg_clut_idx)));
	
		if req='1' and wr='1' then
			if rtg_sel='1' then
				case addr(4 downto 1) is
					when X"0" =>
						rtg_addr(24 downto 16)<=d(8 downto 0);
					when X"1" =>
						rtg_addr(15 downto 4)<=d(15 downto 4);
					when X"2" =>
						rtg_pixelclock<=d(2 downto 0);
						rtg_vbend<=d(12 downto 8);
						rtg_clut<=d(15);
						rtg_ext<=d(14);
					when others =>
						null;
				end case;
			end if;
			if clut_sel='1' then
				if clut_wr='1' then
					clut(to_integer(unsigned(clut_idx_w)))<=X"00"&clut_high&d;
				else
					clut_high<=d(7 downto 0);
				end if;
			end if;		
		end if;	
	end if;
end process;


-- CPU read cycles

q <= id_q when id_sel='1'
	else ct_q when ct_sel='1'
		-- No reading from RTG registers
	else X"ffff";
	
ack <= ct_ack or id_ack or rtg_ack;

	
end architecture;

