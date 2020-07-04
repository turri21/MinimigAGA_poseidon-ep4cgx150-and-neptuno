-- Bridge to interface 32-bit CPU to 16-bit host CPU  bus

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity EightThirtyTwo_Bridge is
	generic (
		debug : boolean := false
	);
   port(
		clk             : in std_logic;
		nReset            : in std_logic;			--low active
		data_in          	: in std_logic_vector(31 downto 0);
		addr          		: buffer std_logic_vector(31 downto 2);
		data_write      	: out std_logic_vector(31 downto 0);
		req					: out std_logic;
		bytesel				: out std_logic_vector(3 downto 0);
		wr						: out std_logic;
		ack					: in std_logic;
		nResetOut	  		: out std_logic
     );
end EightThirtyTwo_Bridge;

architecture rtl of EightThirtyTwo_Bridge is

signal debug_d : std_logic_vector(31 downto 0);
signal debug_q : std_logic_vector(31 downto 0);
signal debug_req : std_logic;
signal debug_ack : std_logic;
signal debug_wr : std_logic;

begin


my832 : entity work.eightthirtytwo_cpu
generic map (
	littleendian => false,
	interrupts => false,
	dualthread => false,
	forwarding => false,
	debug => debug
)
port map(
	clk => clk, 
	reset_n => nReset,
	addr => addr,
	d => data_in,
	q => data_write,
	wr => wr,
	req => req,
	ack => ack,
	bytesel => bytesel,
	debug_d => debug_d,
	debug_q => debug_q,
	debug_req => debug_req,
	debug_ack => debug_ack,
	debug_wr => debug_wr
);


gendebugbridge:
if debug=true generate
debugbridge : entity work.debug_bridge_jtag
port map(
	clk => clk,
	reset_n => nReset,
	d => debug_q,
	q => debug_d,
	req => debug_req,
	ack => debug_ack,
	wr => debug_wr
);
end generate;


end architecture;
