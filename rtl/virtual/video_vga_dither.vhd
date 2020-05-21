library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;

entity video_vga_dither is
	generic (
		outbits : integer :=4
	);
	port (
		clk : in std_logic;
		invertSync : in std_logic :='0';
		vidEna : in std_logic :='1';
		iHsync : in std_logic;
		iVsync : in std_logic;
		iRed : in unsigned(7 downto 0);
		iGreen : in unsigned(7 downto 0);
		iBlue : in unsigned(7 downto 0);
		oHsync : out std_logic;
		oVsync : out std_logic;
		oRed : out unsigned(outbits-1 downto 0);
		oGreen : out unsigned(outbits-1 downto 0);
		oBlue : out unsigned(outbits-1 downto 0)
	);
end entity;

architecture rtl of video_vga_dither is
	signal field : std_logic := '0';
	signal row : std_logic := '0';
	signal red : unsigned(7 downto 0);
	signal green : unsigned(7 downto 0);
	signal blue : unsigned(7 downto 0);
	signal rdither : unsigned(7 downto 0);
	signal gdither : unsigned(7 downto 0);
	signal bdither : unsigned(7 downto 0);
	signal ctr : unsigned(2 downto 0);
	signal prevhsync : std_logic :='0';
	signal prevvsync : std_logic :='0';
	signal vid_ena_d : std_logic :='0';
	signal vid_ena_d2 : std_logic :='0';
	signal lfsr_reg : unsigned(24 downto 0) := X"A5A5A5"&"0";
	signal kernelidx : unsigned(1 downto 0);
	signal selkernel : std_logic_vector(1 downto 0);
	signal kernel : unsigned(7 downto 0);

	constant vidmax : unsigned(7 downto 0) := "11111111";
begin

	oHsync<=not iHsync when invertSync='1' else iHsync;
	oVsync<=not iVsync when invertSync='1' else iVsync;

	oRed <= red(7 downto (8-outbits)) when vid_ena_d='1' else (others=>'0');
	oGreen <= green(7 downto (8-outbits)) when vid_ena_d='1' else (others=>'0');
	oBlue <= blue(7 downto (8-outbits)) when vid_ena_d='1' else (others=>'0');

kernel<="00110110";
selkernel<=(ctr(2) xor field) & (row xor field);

rdither(7 downto 8-outbits)<=(others=>'0');
with selkernel select rdither(7-outbits downto 6-outbits) <=
	kernel(7 downto 6) when "00",
	kernel(5 downto 4) when "01",
	kernel(3 downto 2) when "10",
	kernel(1 downto 0) when "11";
		
gdither(7 downto 8-outbits)<=(others=>'0');
with selkernel select gdither(7-outbits downto 6-outbits) <=
	not kernel(7 downto 6) when "00",
	not kernel(5 downto 4) when "01",
	not kernel(3 downto 2) when "10",
	not kernel(1 downto 0) when "11";
	
bdither(7 downto 8-outbits)<=(others=>'0');
with selkernel select bdither(7-outbits downto 6-outbits) <=
	kernel(7 downto 6) when "00",
	kernel(5 downto 4) when "01",
	kernel(3 downto 2) when "10",
	kernel(1 downto 0) when "11";
	
	process(clk)
	begin
		if rising_edge(clk) then
		
			ctr <= ctr+1;

			vid_ena_d2<=vidEna; -- Delay by the same amount as the video itself.
			vid_ena_d<=vid_ena_d2; -- Delay by the same amount as the video itself.
		
			if iRed(7 downto (8-outbits))=vidmax(7 downto (8-outbits)) then
				red <= iRed;
			else
				red <= iRed + rdither;
			end if;
			
			if iGreen(7 downto (8-outbits))=vidmax(7 downto (8-outbits)) then
				green <= iGreen;
			else
				green <= iGreen + gdither;
			end if;

			if iBlue(7 downto (8-outbits))=vidmax(7 downto (8-outbits)) then
				blue <= iBlue;
			else
				blue <= iBlue+ bdither;
			end if;

			if prevhsync='0' and iHsync='1' then
				row<=not row;
			end if;
			
			prevhsync<=iHsync;
			
			if prevvsync='0' and iVsync='1' then
				lfsr_reg<=lfsr_reg(23 downto 0) & (lfsr_reg(24) xor lfsr_reg(21));
				if kernelidx=23 then
					kernelidx<="00000";
				else
					kernelidx<=kernelidx+1;
				end if;
--				kernelidx<=lfsr_reg+lfsr_reg+lfsr_reg;
				field<=not field;
				row<='0';
			end if;
			prevvsync<=iVsync;
			
		end if;
	end process;
end architecture;
