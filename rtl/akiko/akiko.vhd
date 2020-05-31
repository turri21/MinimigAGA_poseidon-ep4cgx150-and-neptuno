library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;

entity akiko is
port (
	clk : in std_logic;
	reset_n : in std_logic;
	addr : in std_logic_vector(7 downto 0);
	req : in std_logic;
	wr : in std_logic;
	ack : out std_logic;
	d : in std_logic_vector(15 downto 0);
	q : out std_logic_vector(15 downto 0)
);
end entity;

architecture rtl of akiko is

signal id_q : std_logic_vector(15 downto 0);
signal id_sel : std_logic;
signal id_ack : std_logic;
signal ct_sel : std_logic;
signal ct_q : std_logic_vector(15 downto 0);
signal ct_ack : std_logic;

begin

id_sel <= '1' when addr(7 downto 2)=X"0"&"00" else '0';
id_q <= X"C0CA" when addr(1)='0' else X"CAFE";
id_ack<=req and id_sel;

ct_sel <= '1' when addr(7 downto 2)=X"3"&"10" else '0';	-- 0xb80038

q <= id_q when id_sel='1'
	else ct_q when ct_sel='1' 
	else X"ffff";

ack <= ct_ack or id_ack;

	
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
	
end architecture;

