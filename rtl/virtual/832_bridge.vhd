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
		data_in          	: in std_logic_vector(15 downto 0);
		IPL				  	: in std_logic_vector(2 downto 0):="111";
		IPL_autovector   	: in std_logic:='0';
		CPU             	: in std_logic_vector(1 downto 0):="00";  -- 00->68000  01->68010  11->68020(only some parts - yet)
		addr          		: buffer std_logic_vector(31 downto 0);
		data_write      	: out std_logic_vector(15 downto 0);
		nUDS, nLDS	  		: out std_logic;
		req					: out std_logic;
		wr						: out std_logic;
		ack					: in std_logic;
		nResetOut	  		: out std_logic
     );
end EightThirtyTwo_Bridge;

architecture rtl of EightThirtyTwo_Bridge is

type bridgestates is (waiting,waitreadlow,waitreadhigh,waitwritelow,waitwritehigh);
signal state : bridgestates;

constant maxAddrBit : integer := 31;

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
	nResetOut<=nReset;
	if nReset='0' then
		state<=waiting;
		req<='0';
		wr<='0';
		write_pending<='0';
		read_pending<='0';
	elsif rising_edge(clk) then

		mem_ack<='0';
	
		case state is
			when waiting =>
				if mem_ack='0' then
					
					if mem_req='1' and mem_wr='1' then
						write_pending<='0';
						-- Trigger write of either high word, or single word if half or byte cycle.

						if mem_sel(0)='1' or mem_sel(1)='1' then -- High word
							addr(31 downto 0)<=mem_addr(31 downto 2)&"00";
							data_write(15 downto 0)<=mem_write(31 downto 16);
							if mem_sel(1)='0' then
								data_write(7 downto 0)<=mem_write(31 downto 24);
							end if;
							nUDS<=not mem_sel(0);
							nLDS<=not mem_sel(1);
							req<='1';
							wr<='1';
							state<=waitwritehigh;
						else
							addr(31 downto 0)<=mem_addr(31 downto 2)&"10";
							data_write<=mem_write(15 downto 0);
							if mem_sel(3)='0' then
								data_write(7 downto 0)<=mem_write(15 downto 8);
							end if;
							nUDS<=not mem_sel(2);
							nLDS<=not mem_sel(3);
							req<='1';
							wr<='1';
							state<=waitwritelow;						
						end if;
					
					elsif mem_req='1' and mem_wr='0' then
						read_pending<='0';
						addr(31 downto 0)<=mem_addr(31 downto 2)&"00";
						req<='1';
						wr<='0';
						nUDS<='0';
						nLDS<='0';
						state<=waitreadhigh;
					end if;
				end if;

			when waitreadhigh =>
				if ack='1' then
					nUDS<='1';
					nLDS<='1';
					mem_read(31 downto 16)<=data_in;
					addr(31 downto 0)<=mem_addr(31 downto 2)&"10";
					nUDS<='0';
					nLDS<='0';
					req<='1';
					wr<='0';
					state<=waitreadlow;
				end if;

			when waitreadlow =>
				if ack='1' then
					mem_read(15 downto 0)<=data_in;
					nUDS<='1';
					nLDS<='1';
					req<='0';
					wr<='0';
					mem_ack<='1';
					state<=waiting;
				end if;

			when waitwritehigh =>
				if ack='1' then
					nUDS<='1';
					nLDS<='1';
					req<='0';
					wr<='0';

					if mem_sel(2)='1' or mem_sel(3)='1' then -- low word
						addr(31 downto 0)<=mem_addr(31 downto 2)&"10";
						data_write<=mem_write(15 downto 0);
						if mem_sel(3)='0' then
							data_write(7 downto 0)<=mem_write(15 downto 8);
						end if;
						nUDS<=not mem_sel(2);
						nLDS<=not mem_sel(3);
						req<='1';
						wr<='1';
						state<=waitwritelow;
					else
						mem_ack<='1';
						state<=waiting;
					end if;
				end if;

			when waitwritelow =>
				if ack='1' then
					mem_ack<='1';
					req<='0';
					wr<='0';
					nUDS<='1';
					nLDS<='1';
					mem_ack<='1';
					state<=waiting;
				end if;

		end case;
		
	end if;
end process;

end architecture;
