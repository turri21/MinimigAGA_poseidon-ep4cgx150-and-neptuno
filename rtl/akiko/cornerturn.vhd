library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;

entity cornerturn is
port
(
	clk : in std_logic;
	reset_n : in std_logic;
	d : in std_logic_vector(15 downto 0);
	q : out std_logic_vector(15 downto 0);
	wr : in std_logic;
	req : in std_logic;
	ack : out std_logic
);
end entity;

architecture RTL of cornerturn is

type cornerturnbuffer is array(0 to 15) of std_logic_vector(15 downto 0);
signal buf : cornerturnbuffer;
signal wrptr : unsigned(3 downto 0);
signal rdptr : unsigned(3 downto 0);
signal req_d : std_logic;

begin

	turn: for i in 0 to 15 generate    
		q(i) <= buf(i mod 16)(16*(i/16) + to_integer(rdptr));
	end generate;

	process(clk)
	begin
		if rising_edge(clk) then
			req_d<=req;
			if req='0' then
				ack<='0';
			end if;
			if req='1' and req_d='0' then
				ack<='1';
				if wr='1' then
					rdptr<=(others=>'1');
					buf(to_integer(wrptr))<=d;
					wrptr<=wrptr+1;
				else
					wrptr<=(others=>'0');
					rdptr<=rdptr+1;
				end if;
			end if;
		end if;
	end process;

end architecture;
