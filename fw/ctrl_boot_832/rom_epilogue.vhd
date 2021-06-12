	others => (others => x"00")
);

-- Xilinx XST attributes
attribute ram_style: string;
attribute ram_style of ram: signal is "no_rw_check";

-- Altera Quartus attributes
attribute ramstyle: string;
attribute ramstyle of ram: signal is "no_rw_check";

signal q_local : word_t;
signal q2_local : word_t;

begin
    
	process(clk,q_local)
	begin

		q(31 downto 24)<=q_local(0);
		q(23 downto 16)<=q_local(1);
		q(15 downto 8)<=q_local(2);
		q(7 downto 0)<=q_local(3);

		if(rising_edge(clk)) then 
			if(we = '1') then
				-- edit this code if using other than four bytes per word
				if(bytesel(3) = '1') then
					ram(to_integer(unsigned(addr)))(3) <= d(7 downto 0);
				end if;
				if bytesel(2) = '1' then
					ram(to_integer(unsigned(addr)))(2) <= d(15 downto 8);
				end if;
				if bytesel(1) = '1' then
					ram(to_integer(unsigned(addr)))(1) <= d(23 downto 16);
				end if;
				if bytesel(0) = '1' then
					ram(to_integer(unsigned(addr)))(0) <= d(31 downto 24);
				end if;
			end if;
			q_local <= ram(to_integer(unsigned(addr)));
		end if;
	end process;

	-- Second port
	
	process(clk,q2_local)
	begin

		q2(31 downto 24)<=q2_local(0);
		q2(23 downto 16)<=q2_local(1);
		q2(15 downto 8)<=q2_local(2);
		q2(7 downto 0)<=q2_local(3);

		if(rising_edge(clk)) then 
			if(we2 = '1') then
				-- edit this code if using other than four bytes per word
				if(bytesel2(3) = '1') then
					ram(to_integer(unsigned(addr2)))(3) <= d2(7 downto 0);
				end if;
				if bytesel2(2) = '1' then
					ram(to_integer(unsigned(addr2)))(2) <= d2(15 downto 8);
				end if;
				if bytesel2(1) = '1' then
					ram(to_integer(unsigned(addr2)))(1) <= d2(23 downto 16);
				end if;
				if bytesel2(0) = '1' then
					ram(to_integer(unsigned(addr2)))(0) <= d2(31 downto 24);
				end if;
			end if;
			q2_local <= ram(to_integer(unsigned(addr2)));
		end if;
	end process;

end arch;

