AS=vasmm68k_mot
INC_ASM=~/NDK_3.9/Include/include_i/
VASM_FLAGS	:= -quiet -nowarn=1012 -m68020 -Fhunkexe -kick1hunks -nosym -no-opt

TARGET		:= minimig.card
SOURCE		:= minimig.card.asm
INCLUDES	:= P96BoardInfo.i P96CardStruct.i P96ModeInfo.i

all: $(TARGET)
	@echo ""

$(TARGET): Makefile
$(TARGET): $(INCLUDES)
$(TARGET): $(SOURCE)
	$(AS) $< -o $@ $(VASM_FLAGS) -I $(INC_ASM)

clean:
	rm -rf $(TARGET) $(LISTFILE)

