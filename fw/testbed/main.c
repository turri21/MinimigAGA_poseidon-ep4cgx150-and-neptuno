
#include "hardware.h"
#include "audiotrack.h"
#include "mmc.h"
#include "fat.h"

#include <stdio.h>

struct audiotrack track;

void setstack();
int main(void)
{
	setstack();
	int result=0;

    if (MMC_Init())
	{
	    if (FindDrive())
		{
		    ChangeDirectory(DIRECTORY_ROOT);

			if(audiotrack_init(&track,"TEST    SND",0x680000))   /* 0xb00000 in Amiga space */
			{
				audiotrack_fill(&track);
				audiotrack_play(&track);
				while(1)
				{
					while(audiotrack_busy(&track))
						;
					putchar('.');
					audiotrack_fill(&track);
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

