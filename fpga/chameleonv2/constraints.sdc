
# time information
set_time_format -unit ns -decimal_places 3


#create clocks
create_clock -name pll_in_clk -period 20 [get_ports {clk50m}]

# pll clocks
derive_pll_clocks

# name PLL clocks
set pll_sdram "virtual_top|amiga_clk|amiga_clk_i|altpll_component|auto_generated|pll1|clk[0]"
set clk_114   "virtual_top|amiga_clk|amiga_clk_i|altpll_component|auto_generated|pll1|clk[1]"
set clk_28    "virtual_top|amiga_clk|amiga_clk_i|altpll_component|auto_generated|pll1|clk[2]"

# generated clocks
create_generated_clock -name clk_sdram -source [get_pins {virtual_top|amiga_clk|amiga_clk_i|altpll_component|auto_generated|pll1|clk[0]}] [get_ports {ram_clk}]


# name SDRAM ports
set sdram_outputs [get_ports {ram_d[*] ram_a[*] ram_ldqm ram_udqm ram_we ram_cas ram_ras ram_ba[*] }]
set sdram_inputs  [get_ports {ram_d[*]}]


# clock groups



# clock uncertainty
derive_clock_uncertainty


# input delay
set_input_delay -clock clk_sdram -max 6.4 $sdram_inputs
set_input_delay -clock clk_sdram -min 3.2 $sdram_inputs

#output delay
#set_output_delay -clock $clk_sdram -max  1.5 [get_ports sm_clk]
#set_output_delay -clock $clk_sdram -min -0.8 [get_ports sm_clk]
set_output_delay -clock clk_sdram -max  1.5 $sdram_outputs
set_output_delay -clock clk_sdram -min -0.8 $sdram_outputs


# false paths


# multicycle paths

set_multicycle_path -from {minimig_virtual_top:virtual_top|EightThirtyTwo_Bridge:hostcpu|eightthirtytwo_cpu:my832|*} -to {minimig_virtual_top:virtual_top|EightThirtyTwo_Bridge:hostcpu|eightthirtytwo_cpu:my832|eightthirtytwo_alu:alu|mulresult[*]} -setup -end 2
set_multicycle_path -from {minimig_virtual_top:virtual_top|EightThirtyTwo_Bridge:hostcpu|eightthirtytwo_cpu:my832|*} -to {minimig_virtual_top:virtual_top|EightThirtyTwo_Bridge:hostcpu|eightthirtytwo_cpu:my832|eightthirtytwo_alu:alu|mulresult[*]} -hold -end 2

# Adjust data window for SDRAM reads by 1 cycle
set_multicycle_path -from clk_sdram -to [get_clocks $clk_114] -setup 2

set_multicycle_path -from {virtual_top|tg68k|pf68K_Kernel_inst|*} -setup 4
set_multicycle_path -from {virtual_top|tg68k|pf68K_Kernel_inst|*} -hold 3

set_multicycle_path -from [get_clocks $clk_28] -to [get_clocks $clk_114] -setup 4
set_multicycle_path -from [get_clocks $clk_28] -to [get_clocks $clk_114] -hold 3

