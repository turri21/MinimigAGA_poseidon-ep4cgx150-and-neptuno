-- A minimalist FIFO-based video buffer
--
-- Copyright 2020 by Alastair M. Robinson
--
-- 512 words of 16 bit each to fill one M9K
-- On vblank, reset inpointer and start filling.
-- Thereafter, compare inptr with outptr and fill any time they differ.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;

entity VideoStream is
port
(
	clk : in std_logic;
	reset_n : in std_logic;
	enable : in std_logic;
	-- RAM interface
	baseaddr : in std_logic_vector(24 downto 0);
	a : out std_logic_vector(24 downto 0);
	req : out std_logic;
	d : in std_logic_vector(15 downto 0);
	fill : in std_logic;
	-- Display interface
	rdreq : in std_logic;
	q : out std_logic_vector(15 downto 0)
);
end entity;

architecture rtl of VideoStream is

type samplebuffer is array(0 to 511) of std_logic_vector(15 downto 0);
signal samplebuf : samplebuffer;
signal inptr : unsigned(8 downto 0);
signal outptr : unsigned(8 downto 0);
signal address : unsigned(24 downto 0);
signal first_fill : std_logic;
signal fill_d : std_logic;
signal full : std_logic;

begin

-- The req signal should be high any time the output process
-- is in the same half of the buffer as the fill process.

-- req<=reset_n and enable and (first_fill or (inptr(8) xor outptr(8) xor full));
req<=reset_n and enable and (first_fill or not full);

-- Need to drop the req signal a few cycles early when the buffer fills up.
full<='1' when inptr(8 downto 4) = outptr(8 downto 4) else '0';

-- Fill from RAM
a<=std_logic_vector(address);
inptr<=address(9 downto 1);

process(clk)
begin
	if rising_edge(clk) then
		fill_d<=fill;

		if reset_n='0' then
			address<=unsigned(baseaddr);
			first_fill<='1';
		elsif fill='1' then
			samplebuf(to_integer(inptr))<=d;
			address<=address+2;
			if address(9)/=baseaddr(9) then
				first_fill<='0';
			end if;
		end if;
	end if;
end process;


-- Output to video

process(clk)
begin
	if rising_edge(clk) then
		if rdreq='1' then
			outptr<=outptr+1;
		end if;
		if reset_n='0' then
--			outptr<=(others=>'0');
--			outptr(8)<=baseaddr(9);
			outptr<=unsigned(baseaddr(9 downto 1));
		end if;
		q<=samplebuf(to_integer(outptr));
	end if;
end process;


end architecture;