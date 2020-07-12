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
		addr          		: out std_logic_vector(31 downto 2);
		data_write      	: out std_logic_vector(31 downto 0);
		bytesel				: out std_logic_vector(3 downto 0);
		req					: out std_logic;
		wr						: out std_logic;
		ack					: in std_logic
     );
end EightThirtyTwo_Bridge;

architecture rtl of EightThirtyTwo_Bridge is

type bridgestates is (waiting,waitread,delay);
signal state : bridgestates;

signal mem_req : std_logic;
signal mem_ack : std_logic;
signal mem_read             : std_logic_vector(31 downto 0);
signal mem_write            : std_logic_vector(31 downto 0);
signal mem_addr             : std_logic_vector(31 downto 2);
signal mem_wr      : std_logic; 
signal mem_sel : std_logic_vector(3 downto 0);

signal read_pending : std_logic;
signal write_pending : std_logic;

signal debug_d : std_logic_vector(31 downto 0);
signal debug_q : std_logic_vector(31 downto 0);
signal debug_req : std_logic;
signal debug_ack : std_logic;
signal debug_wr : std_logic;
signal delayctr : unsigned(5 downto 0);

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
	addr => mem_addr,
	d => mem_read,
	q => mem_write,
	wr => mem_wr,
	req => mem_req,
	ack => mem_ack,
	bytesel => mem_sel,
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


process(clk)
begin

	if nReset='0' then
		state<=waiting;
		req<='0';
		wr<='0';
	elsif rising_edge(clk) then

		mem_ack<='0';
	
		case state is
			when waiting =>
				if mem_ack='0' then
					
					if mem_req='1' then

						req<='1';
						addr<=mem_addr;
						data_write<=mem_write;
						bytesel<=mem_sel;
						wr<=mem_wr;
						state<=waitread;
					end if;
				end if;

			when waitread =>
				if ack='1' then
					mem_read<=data_in;
					wr<='0';
					req<='0';
					mem_ack<='1';
					state<=waiting;
				end if;

			when delay =>
				if delayctr=X"0"&"00" then
					state<=waiting;
				end if;
				delayctr<=delayctr+1;

			when others =>
				null;
		end case;
	end if;
end process;

end architecture;
