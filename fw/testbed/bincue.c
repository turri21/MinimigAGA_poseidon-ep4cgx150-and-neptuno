#include <stdio.h>
#include <string.h>

#include "bincue.h"

char *cue="FILE \"EXODUS_THELASTWAR.BIN\" BINARY\n\
  TRACK 01 MODE1/2352\n\
    INDEX 01 00:00:00\n\
  TRACK 02 AUDIO\n\
    PREGAP 00:02:00\n\
    INDEX 01 44:18:21\n\
  TRACK 03 AUDIO\n\
    INDEX 01 49:02:57\n\
  TRACK 04 AUDIO\n\
    INDEX 01 51:03:58\n\
  TRACK 05 AUDIO\n\
    INDEX 01 52:06:66\n\
  TRACK 06 AUDIO\n\
    INDEX 01 57:10:05\n\
  TRACK 07 AUDIO\n\
    INDEX 01 64:18:14\n\
  TRACK 08 AUDIO\n\
    INDEX 01 69:42:35\n\
  TRACK 09 AUDIO\n\
    INDEX 01 70:41:64\n\
  TRACK 10 AUDIO\n\
    INDEX 01 71:44:33\n";


static char delims[]="\"\t \n\r";

int cd_gettrack(struct cdimage *cd, char *in,int track)
{
	char *tok;
	tok=strtok(in,delims);
	if(tok)
	{
		if(strcmp(tok,"FILE")==0)
		{
			if(tok=strtok(0,"\""))
			{
				printf("Filename %s\n",tok);
				strncpy(cd->filename,tok,261);
			}
			else
				cd->filename[0]=0;
			cd->type=CD_INVALID;
			if(tok=strtok(0,delims))
			{
				if(strcmp(tok,"BINARY")==0)
					cd->type=CD_BINARY;
				else if(strcmp(tok,"WAVE")==0)
					cd->type=CD_WAVE;
			}
			cd->currenttrack=-1;
		}		
		if(strcmp(tok,"TRACK")==0)
		{
			if(tok=strtok(0,delims))
			{
				char *endptr;
				cd->currenttrack=strtoul(tok,&endptr,10);
				printf("Track %d\n",track);
				if(endptr!=tok)
				{	
					if(cd->currenttrack>cd->tracks)
						cd->tracks=cd->currenttrack;
				}
			}

			if(tok=strtok(0,delims))
			{
				if(strcmp(tok,"AUDIO")==0 && cd->currenttrack>-1)
					cd->audiotracks|=(1<<cd->currenttrack);
			}
		}		
		if(cd->currenttrack>=track && strcmp(tok,"INDEX")==0)
		{
			if(tok=strtok(0,delims))
			{
				int mins,seconds,frames;
				int id;
				char *endptr;
				printf("IDX: %s\n",tok);
				if(tok=strtok(0,delims))
				{
					mins=strtoul(tok,&endptr,10);
					tok=endptr+1;
					seconds=strtoul(tok,&endptr,10);
					tok=endptr+1;
					frames=strtoul(tok,&endptr,10);
					frames+=75*seconds+(75*60)*mins;
					if(cd->currenttrack==track)
					{
						cd->offset=frames*2352;
						cd->length=0;
						if(!cd->offset)	/* If we have a standalone file we don't need to worry about the track's length */
							return(1);
					}
					if(cd->currenttrack==track+1)
					{
						cd->length=frames*2352-cd->offset;
						return(1);
					}
				}
			}
		}		
	}
	return(0);
}

