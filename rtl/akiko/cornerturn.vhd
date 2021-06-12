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

-- In:
-- (0)(15:8) ABCDEFGH  (0)(7:0) IJKLMNOP      (1)(15:0) QRSTUVWX  (1)(7:0) YZ012345
-- (2)(15:8) abcdefgh  (2)(7:0) ijklmnop      (3)(15:0) qrstuvwx  (3)(7:0) yz6789#$
-- (4)(0) ....      (4)(8) .....

-- Out:
-- AIQYaiqy ........   ........ ........
-- BJRZbjrz ........   ........ ........
-- CKS0cks6 ........   ........ ........
-- ........ ........   ........ ........

-- 0,15:8 -> 0(15),0(7), 1(15),1(7), 2(15),2(7) ....
-- 0, 7:0 -> 4(15),4(7), 5(15),5(7), 6(15),6(7) ...

-- 1,15:8 -> 8(15),8(7), 9(15),9(7), 10(15),10(7) ....
-- 1, 7:0 -> 12(15),12(7), 13(15),13(7), 14(15),14(7) ...

-- 2,15:8 -> 0(14),0(6), 1(14),1(6), 2(14),2(6) ....
-- 2, 7:0 -> 4(14),4(6), 5(14),5(6), 6(14),6(6) ...

	turn: for i in 0 to 15 generate    
	   q(i) <= buf(8-8*(to_integer(rdptr) mod 2) + 7 - (i/2))
		            ((7+8*(i mod 2))-(to_integer(rdptr)/2));
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
					rdptr<=(others=>'0');
					buf(to_integer(wrptr))<=d;
					wrptr<=wrptr+1;
				else
					wrptr<=(others=>'0');
					rdptr<=rdptr-1;
				end if;
			end if;
		end if;
	end process;

end architecture;
