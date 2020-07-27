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
		addr					: out std_logic_vector(31 downto 2);
		q			      	: out std_logic_vector(31 downto 0);
		sel					: out std_logic_vector(3 downto 0);
		wr						: out std_logic;

		ram_req				: out std_logic;
		ram_ack				: in std_logic;
		ram_d					: in std_logic_vector(31 downto 0);

		hw_req            : out std_logic;
		hw_ack            : in std_logic;
		hw_d					: in std_logic_vector(15 downto 0)		
	);
end EightThirtyTwo_Bridge;

architecture rtl of EightThirtyTwo_Bridge is

type bridgestates is (waiting,ram,hw,rom);
signal state : bridgestates;

signal cpu_req : std_logic;
signal cpu_ack : std_logic;
signal cpu_d 	: std_logic_vector(31 downto 0);
signal cpu_q	: std_logic_vector(31 downto 0);
signal cpu_addr	: std_logic_vector(31 downto 2);
signal cpu_wr	: std_logic; 
signal cpu_sel : std_logic_vector(3 downto 0);

signal debug_d : std_logic_vector(31 downto 0);
signal debug_q : std_logic_vector(31 downto 0);
signal debug_req : std_logic;
signal debug_ack : std_logic;
signal debug_wr : std_logic;

signal rom_d : std_logic_vector(31 downto 0);
signal rom_wr : std_logic;
signal rom_select : std_logic;
signal hw_select : std_logic;

begin


my832 : entity work.eightthirtytwo_cpu
generic map (
	littleendian => false,
	interrupts => false,
	dualthread => false,
	forwarding => false,
	prefetch => false,
	debug => debug
)
port map(
	clk => clk, 
	reset_n => nReset,
	addr => cpu_addr,
	d => cpu_d,
	q => cpu_q,
	wr => cpu_wr,
	req => cpu_req,
	ack => cpu_ack,
	bytesel => cpu_sel,
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


bootrom: entity work.OSDBoot_832_ROM
	generic map
	(
		maxAddrBitBRAM => 14
	)
	PORT MAP 
	(
		addr => cpu_addr(14 downto 2),
		clk   => clk,
		d	=> cpu_q,
		we	=> rom_wr,
		bytesel => cpu_sel,
		q		=> rom_d
	);

rom_select <= '1' when cpu_addr(23 downto 13)=X"00"&"000" ELSE '0';

hw_select <= cpu_addr(23);

process(clk)
begin

	if nReset='0' then
		state<=waiting;
		hw_req<='0';
		ram_req<='0';
		wr<='0';
	elsif rising_edge(clk) then

		cpu_ack<='0';
		rom_wr<='0';

		case state is
			when waiting =>
				if cpu_ack='0' and cpu_req='1' then

					addr<=cpu_addr;
					q<=cpu_q;
					sel<=cpu_sel;
					wr<=cpu_wr;
					
					if rom_select='1' then
						rom_wr<=cpu_wr;
						state<=rom;
					elsif hw_select='1' then
						hw_req<='1';
						state<=hw;
					else
						ram_req<='1';
						state<=ram;
					end if;
				end if;

			when rom =>
				cpu_d<=rom_d;
				wr<='0';
				rom_wr<='0';
				cpu_ack<='1';
				state<=waiting;
				
			when ram =>
				if ram_ack='1' then
					cpu_d<=ram_d;
					wr<='0';
					ram_req<='0';
					cpu_ack<='1';
					state<=waiting;
				end if;

			when hw =>
				if hw_ack='1' then
					cpu_d(31 downto 0)<=(others=>'0');
					cpu_d(15 downto 0)<=hw_d;
					wr<='0';
					hw_req<='0';
					cpu_ack<='1';
					state<=waiting;
				end if;

			when others =>
				null;
		end case;
	end if;
end process;

end architecture;
