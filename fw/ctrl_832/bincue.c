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

int cd_parsecueline(struct cdimage *cd,int track)
{
	char *tok;
	tok=strtok(cd->linebuffer,delims);
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


int cd_setcuefile(struct cdimage *cd,const char *filename)
{
	int foundtrack=0;
	cd->tracks=-1;

	if(RAOpen(&cd->cuefile,filename))
	{
		cd->tracks=0;
		cd->error=CD_OK;
	}
	else
		cd->error=CD_FILENOTFOUND;
	return(cd->tracks==0);
}


int cd_findtrack(struct cdimage *cd, int track)
{
	int foundtrack=0;
	if(cd->error!=CD_OK)
		return(0);

	cd->error=CD_TRACKNOTFOUND;

	RASeek(&cd->cuefile,0,SEEK_SET);
	while(1)
	{
		if(!RAReadLine(&cd->cuefile,cd->linebuffer,512))
			break;
		printf("Got line %s\n",cd->linebuffer);
		if(cd_parsecueline(cd,3))
		{
			printf("Track found in %s, starting at byte offset %d, length %d\n",cd->filename,cd->offset,cd->length);
			foundtrack=1;
			cd->error=CD_OK;
			break;
		}
	}
	return(foundtrack);
}


int cd_cueaudio(struct cdimage *cd,int track)
{
	int result=0;
	cd_findtrack(cd,track);
	if(cd->error==CD_OK)
	{
		cd->error=CD_FILENOTFOUND;
		if(audiotrack_init(&cd->audio,cd->filename,cd->offset,cd->length,AUDIO_BUFFER))   /* 0xef0000 in Amiga space */
		{
			cd->error=CD_OK;
			audiotrack_fill(&cd->audio);
			result=1;			
		}
	}
	return(result);
}


int cd_playaudio(struct cdimage *cd,int track)
{
	cd_cueaudio(cd,track);
	if(cd->error==CD_OK)
		audiotrack_play(&cd->audio);
	return(cd->error==CD_OK);
}


void cd_continueaudio(struct cdimage *cd)
{
	if(cd->error!=CD_OK)
		return;
	if(!audiotrack_busy(&cd->audio))
		audiotrack_fill(&cd->audio);
}

