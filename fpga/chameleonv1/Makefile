# MINIMIG
# fpga makefile
# 2012, rok.krajnc@gmail.com
# 2020, AMR

include ../../paths.mk

### programs ###
MAP=$(QUARTUS_PATH_CIII)quartus_map
FIT=$(QUARTUS_PATH_CIII)quartus_fit
ASM=$(QUARTUS_PATH_CIII)quartus_asm
PGM=$(QUARTUS_PATH_CIII)quartus_pgm
STA=$(QUARTUS_PATH_CIII)quartus_sta

### project ###
PROJECT=MinimigAGA_TC64V1


### build rules ###

# all
all:
	@echo Making FPGA programming files ...
	@make map
	@make fit
	@make asm
	@make sta

map:
	@echo Running mapper ...
	@$(MAP) $(PROJECT)

fit:
	@echo Running fitter ...
	@$(FIT) $(PROJECT)

asm:
	@echo Running assembler ...
	@$(ASM) $(PROJECT)

sta:
	@echo Running STA ...
	@$(STA) $(PROJECT)
	@grep Design-wide\ TNS $(PROJECT).sta.rpt

run: 
	@$(PGM) -c USB-Blaster -m jtag -o "p;./out/$(PROJECT).sof"

# clean
clean:
	@echo clean
	@rm -rf ./out/
	@rm -rf ./db/
	@rm -rf ./incremental_db/

