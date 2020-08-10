
#include "hardware.h"
#include "audiotrack.h"
#include "bincue.h"
#include "mmc.h"
#include "fat.h"
#include "malloc.h"

#include <stdio.h>

struct audiotrack track;

struct cdimage cd;
RAFile cuefile;
char linebuffer[512];

int counter;

void myinthandler()
{
	GetInterrupts();
	++counter;
}


void setstack();
int main(void)
{
	setstack();
	int result=0;

	char *testbuf;
	testbuf=(char *)malloc(131072);
	printf("Allocated memory at %xz\n",(int)testbuf);
	free(testbuf);

	SetIntHandler(myinthandler);
	EnableInterrupts();

    if (MMC_Init())
	{
	    if (FindDrive())
		{
//			int dir=FindDirectory(DIRECTORY_ROOT,"BANDS      ");
			int foundtrack=0;
//		    ChangeDirectory(dir);

			if(RAOpen(&cuefile,"EXODUS_THELASTWAR.CUE"))
//			if(RAOpen(&cuefile,"Bubba 'N' Stix (1994)(Core)[!].cue"))
			{
				while(1)
				{
					if(!RAReadLine(&cuefile,linebuffer,512))
						break;
					printf("Got line %s\n",linebuffer);
					if(cd_gettrack(&cd,linebuffer,3))
					{
						printf("Track found in %s, starting at byte offset %d, length %d\n",cd.filename,cd.offset,cd.length);
						foundtrack=1;
						break;
					}
				}
			}
			else
				printf("Failed to open cuefile\n");

//			if(audiotrack_init(&track,"TEST    SND",0x680000))   /* 0xb00000 in Amiga space */
			if(foundtrack)
			{
				if(audiotrack_init(&track,cd.filename,cd.offset,cd.length,0x680000))   /* 0xb00000 in Amiga space */
				{
					audiotrack_fill(&track);
					audiotrack_play(&track);
					while(1)
					{
						while(audiotrack_busy(&track))
							;
						audiotrack_fill(&track);
						printf("Vblank counter: %d\n",counter);
					}
				}
				else
					printf("Unable to open sound file\n");
			}
		}
		else
			printf("Can't open filesystem.\n");
	}
	printf("Can't open SD card\n");

	return(result);
}

