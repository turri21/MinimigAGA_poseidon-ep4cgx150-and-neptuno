
#include "hardware.h"
#include "audiotrack.h"

#include <stdio.h>


/* Returns 1 if the audio hardware is currently playing the next buffer. */
int audiotrack_busy(struct audiotrack *track)
{
	return((AUDIO&1)==track->currentbuffer);
}


void audiotrack_play(struct audiotrack *track)
{
	printf("Enabling audio\n");
	AUDIO=AUDIOF_ENA;
}


void audiotrack_stop(struct audiotrack *track)
{
	unsigned char *p=track->buffer;
	int i;
	AUDIO=AUDIOF_CLEAR;
	printf("Clearing audio buffer\n");
	for(i=0;i<track->buffersize*2;++i)
	{
		p[i]=0;
	}
	AUDIO=AUDIOF_ENA;
	i=AUDIO&1;
	printf("Waiting for audio to play cleared buffer\n");
	while((AUDIO&1)==i)
		;
	AUDIO=AUDIOF_CLEAR;
	track->currentbuffer=0;
}


void audiotrack_fill(struct audiotrack *track)
{
	unsigned char *p=track->buffer+track->buffersize*track->currentbuffer;
	int i;
	printf("Filling audio buffer - remain %d\n",track->remain);
	for(i=0;i<track->buffersize;i+=512)
	{
		FileRead(&track->file,p);
		if(track->remain<512)
		{
			int j;
			for(j=track->remain;j<512;++j)
			{
				p[j]=0;
			}
			FileSeek(&track->file,0,SEEK_SET);
			track->remain=track->file.size;
		}
		else
		{
			FileNextSector(&track->file);
			track->remain-=512;
		}
		p+=512;
	}
	track->currentbuffer^=1;
}


void audiotrack_fastforward(struct audiotrack *track)
{
	if(track->remain>AUDIOSEEK_STEP)
	{
		FileSeek(&track->file,AUDIOSEEK_STEP,SEEK_CUR);
		track->remain-=AUDIOSEEK_STEP;
	}
	else
	{
		FileSeek(&track->file,0,SEEK_SET);
		track->remain=track->file.size;
	}
}


void audiotrack_rewind(struct audiotrack *track)
{
	if((track->file.size-track->remain)>AUDIOSEEK_STEP)
	{
		FileSeek(&track->file,-AUDIOSEEK_STEP,SEEK_CUR);
		track->remain+=AUDIOSEEK_STEP;
	}
	else
	{
		FileSeek(&track->file,0,SEEK_SET);
		track->remain=track->file.size;
	}
}


int audiotrack_init(struct audiotrack *track, const char *filename,unsigned char *buffer)
{
	int result=0;
	track->buffer=buffer;
	track->currentbuffer=0;
	track->buffersize=32768;
	audiotrack_stop(track);
	if(FileOpen(&track->file,filename))
	{
		track->remain=track->file.size;
		audiotrack_fill(track);
		result=1;
	}
	printf("Initialised audiotrack\n");
	return(result);
}



