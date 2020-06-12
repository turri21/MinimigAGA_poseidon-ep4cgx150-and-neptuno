/*	Firmware for loading files from SD card.
	Part of the ZPUTest project by Alastair M. Robinson.
	SPI and FAT code borrowed from the Minimig project.

	This boot ROM ends up stored in the ZPU stack RAM
	which in the current incarnation of the project is
	memory-mapped to 0x04000000
	Halfword and byte writes to the stack RAM aren't
	currently supported in hardware, so if you use
    hardware storeh/storeb, and initialised global
    variables in the boot ROM should be declared as
    int, not short or char.
	Uninitialised globals will automatically end up
	in SDRAM thanks to the linker script, which in most
	cases solves the problem.
*/

#include "spi.h"
#include "minfat.h"
#include "checksum.h"
#include "small_printf.h"
#include "fpga.h"
#include "uart.h"

void _boot()
{
	void (*entry)();
	entry=(void (*)())prg_start;
	entry();
}

void _break();


char printbuf[32];

void cvx(int val,char *buf)
{
	int i;
	int c;
	for(i=0;i<8;++i)
	{
		c=(val>>28)&0xf;
		val<<=4;
		if(c>9)
			c+='A'-10;
		else
			c+='0';
		*buf++=c;
	}
}


void ErrorCode(int error)
{
	int count;
    unsigned long i;

	EnableOsd();
	HW_SPI(OSD_CMD_RST);
	HW_SPI(SPI_RST_CPU|SPI_CPU_HLT);
	DisableOsd();

	EnableOsd();
	HW_SPI(OSD_CMD_WR);
	HW_SPI(0x80);	// $DFF180
	HW_SPI(0xF1);
	HW_SPI(0xDF);
	HW_SPI(0x00);
	HW_SPI((error>>8)&255);
	HW_SPI(error&255);
	DisableOsd();
}


int main(int argc,char **argv)
{
	int i;
	int err=0;

	EnableOsd();
	HW_SPI(OSD_CMD_RST);
	HW_SPI(SPI_RST_CPU|SPI_CPU_HLT);
	DisableOsd();

	while(1)
	{
		puts("Initializing SD card\n");
		err=0xf00;
		if(spi_init())
		{
			err=0xff0;
			puts("Hunting for partition\n");
			if(FindDrive())
			{
				err=0xf0;
				int romsize;
				int *checksums;
				if(romsize=LoadFile(OSDNAME,prg_start))
				{
					int error=0;
					char *sector=(char *)prg_start;
					int offset=0;
					_boot();
				}
				else
					BootPrint("Can't load firmware\n");
			}
			else
			{
				BootPrint("Unable to locate partition\n");
				puts("Unable to locate partition\n");
			}
		}
		else
			BootPrint("Failed to initialize SD card\n");
		ErrorCode(err);
	}
	return(0);
}

