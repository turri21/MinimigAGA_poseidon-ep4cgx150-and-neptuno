
# time information
set_time_format -unit ns -decimal_places 3


#create clocks
create_clock -name pll_in_clk -period 125 [get_ports {clk8}]

# pll clocks
derive_pll_clocks

# name PLL clocks
set pll_sdram "virtual_top|amiga_clk|amiga_clk_i|altpll_component|auto_generated|pll1|clk[0]"
set clk_114   "virtual_top|amiga_clk|amiga_clk_i|altpll_component|auto_generated|pll1|clk[1]"
set clk_28    "virtual_top|amiga_clk|amiga_clk_i|altpll_component|auto_generated|pll1|clk[2]"

# generated clocks
create_generated_clock -name clk_sdram -source [get_pins {virtual_top|amiga_clk|amiga_clk_i|altpll_component|auto_generated|pll1|clk[0]}] [get_ports {sd_clk}]
create_generated_clock -name muxclk -source [get_pins $clk_114] -divide_by 2 [get_ports {mux_clk}]

# name SDRAM ports
set sdram_outputs [get_ports {sd_addr[*] sd_ldqm sd_udqm sd_we_n sd_cas_n sd_ras_n sd_ba_* }]
set sdram_dqoutputs [get_ports {sd_data[*]}]
set sdram_inputs  [get_ports {sd_data[*]}]


# clock groups



# clock uncertainty
derive_clock_uncertainty


# MUX constraints
# input delay is XC9572XL-7's TCO (4.5ns) plus a little for signal delays in both directions
set_input_delay -clock muxclk -clock_fall 5 [get_ports {mux_q[*]}]
# Output delay is XC9572XL-7's TSU (4.8ns).  No hold timing required.
set_output_delay -clock muxclk -clock_fall -min 0 [get_ports {mux_d[*]}]
set_output_delay -clock muxclk -clock_fall -max 4.8 [get_ports {mux_d[*]}]
set_output_delay -clock muxclk -clock_fall -min 0 [get_ports {mux[*]}]
set_output_delay -clock muxclk -clock_fall -max 4.8 [get_ports {mux[*]}]

# SDRAM constraints
# input delay
set_input_delay -clock clk_sdram -max 3.0 $sdram_inputs
set_input_delay -clock clk_sdram -min 2.0 $sdram_inputs
# output delay
#set_output_delay -clock clk_sdram -max  1.5 [get_ports {sd_clk}]
#set_output_delay -clock clk_sdram -min  0.5 [get_ports {sd_clk}]

set_output_delay -clock clk_sdram -max  1.5 $sdram_outputs
set_output_delay -clock clk_sdram -max  1.8 $sdram_dqoutputs
#set_output_delay -clock clk_sdram -min -0.8 $sdram_outputs
set_output_delay -clock clk_sdram -min -0.8 $sdram_outputs
set_output_delay -clock clk_sdram -min -0.7 $sdram_dqoutputs


# false paths

set_false_path -from [get_clocks {virtual_top|amiga_clk|amiga_clk_i|altpll_component|auto_generated|pll1|clk[1]}] -to [get_clocks {pll_in_clk}]

# multicycle paths

set_multicycle_path -from {minimig_virtual_top:virtual_top|EightThirtyTwo_Bridge:hostcpu|eightthirtytwo_cpu:my832|*} -to {minimig_virtual_top:virtual_top|EightThirtyTwo_Bridge:hostcpu|eightthirtytwo_cpu:my832|eightthirtytwo_alu:alu|mulresult[*]} -setup -end 2
set_multicycle_path -from {minimig_virtual_top:virtual_top|EightThirtyTwo_Bridge:hostcpu|eightthirtytwo_cpu:my832|*} -to {minimig_virtual_top:virtual_top|EightThirtyTwo_Bridge:hostcpu|eightthirtytwo_cpu:my832|eightthirtytwo_alu:alu|mulresult[*]} -hold -end 2

# Adjust data window for SDRAM reads by 1 cycle
set_multicycle_path -from clk_sdram -to [get_clocks $clk_114] -setup 2

set_multicycle_path -from {virtual_top|tg68k|pf68K_Kernel_inst|*} -setup 4
set_multicycle_path -from {virtual_top|tg68k|pf68K_Kernel_inst|*} -hold 3

set_multicycle_path -from [get_clocks $clk_28] -to [get_clocks $clk_114] -setup 4
set_multicycle_path -from [get_clocks $clk_28] -to [get_clocks $clk_114] -hold 3

