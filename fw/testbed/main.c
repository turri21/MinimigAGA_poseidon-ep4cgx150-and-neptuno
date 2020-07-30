
#include "hardware.h"
#include "mmc.h"
#include "fat.h"

#include <stdio.h>

fileTYPE file;

unsigned char *audiobuffer=0x680000;	/* 0xb00000 in Amiga space */

void setstack();
int main(void)
{
	setstack();
	int result=0;
	AUDIO=AUDIOF_CLEAR;

    if (MMC_Init())
	{
	    if (FindDrive())
		{
			int key;
			int override=0;
		    ChangeDirectory(DIRECTORY_ROOT);
			if(FileOpen(&file,"TEST    SND"))
			{
				int buffer=0;
				int i;
				while(1)
				{
					unsigned char *p=audiobuffer+32768*buffer;
					for(i=0;i<32768;i+=512)
					{
						FileRead(&file,p);
						FileNextSector(&file);
						p+=512;
					}
					AUDIO=AUDIOF_ENA;
					while((AUDIO&1)==buffer)
						;
					putchar('.');
					buffer^=1;
				}
			}
			else
				printf("Unable to open test sound file\n");
		}
		else
			printf("Can't open filesystem.\n");
	}
	printf("Can't open SD card\n");

	return(result);
}

