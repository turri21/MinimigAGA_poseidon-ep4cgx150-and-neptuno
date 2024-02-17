AS_AMIGA=vasmm68k_mot
CC_AMIGA=vc +aos68k -I$(NDK_INC) -+ -O6 -g -lamiga -I./amiga
LD_AMIGA=vc +aos68k -g -lamiga
BUILD_AMIGA=build_amiga

BUILD_UNIX=build_unix
CC_UNIX=gcc -I./unix
LD_UNIX=gcc 


all: $(BUILD_AMIGA)  loaddrivesounds

clean:
	rm $(BUILD_AMIGA)/*

#Amiga Targets


loaddrivesounds: $(BUILD_AMIGA)/loaddrivesounds.o
	$(LD_AMIGA) -o $@ $+

$(BUILD_AMIGA)/%.o: %.c Makefile
	$(CC_AMIGA) -o $@ -c $<

$(BUILD_AMIGA)/%.o: %.s Makefile
	$(AS_AMIGA) -Fhunk -o $@ $<

$(BUILD_AMIGA):
	mkdir $(BUILD_AMIGA)


