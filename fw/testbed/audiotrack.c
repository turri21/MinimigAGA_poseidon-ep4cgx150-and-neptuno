#include "rafile.h"
#include "hardware.h"
#include "audiotrack.h"
#include "string.h"

#include <stdio.h>

char tmp[16];

/* Returns 1 if the audio hardware is currently playing the buffer we will fill next. */
int audiotrack_busy(struct audiotrack *track)
{
	return((AUDIO&1)==track->currentbuffer);
}


void audiotrack_cue(struct audiotrack *track)
{
	RASeek(&track->file,track->start,SEEK_SET);
	track->remain=track->length;
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
	if(track->remain>track->buffersize)
	{
		RARead(&track->file,p,track->buffersize);
		track->remain-=track->buffersize;
	}
	else
	{
		int j;
		RARead(&track->file,p,track->remain);
		track->remain-=track->buffersize;
		for(j=track->remain;j<512;++j)
		{
			p[j]=0;
		}
		audiotrack_cue(track);
	}
	track->currentbuffer^=1;
}


void audiotrack_fastforward(struct audiotrack *track)
{
	if(track->remain>AUDIOSEEK_STEP)
	{
		RASeek(&track->file,AUDIOSEEK_STEP,SEEK_CUR);
		track->remain-=AUDIOSEEK_STEP;
	}
	else
	{
		audiotrack_cue(track);
	}
}


void audiotrack_rewind(struct audiotrack *track)
{
	if((track->file.size-track->remain)>AUDIOSEEK_STEP)
	{
		RASeek(&track->file,-AUDIOSEEK_STEP,SEEK_CUR);
		track->remain+=AUDIOSEEK_STEP;
	}
	else
	{
		audiotrack_cue(track);
	}
}


int audiotrack_init(struct audiotrack *track, const char *filename,int offset,int length,unsigned char *buffer)
{
	int result=1;
	track->buffer=buffer;
	track->currentbuffer=0;
	track->buffersize=32768;
	audiotrack_stop(track);
	if(RAOpen(&track->file,filename))
	{
		track->start=offset;
		if(length)
			track->length=length;
		else
			track->length=track->file.size;

		if(!offset)	/* If we have an offset we're dealing with an audio track within a BIN file */
		{			/* Otherwise we probably have a WAV file */
			result&=RARead(&track->file,tmp,12);
			if(result)
			{
				if(strncmp("RIFF",tmp,4)==0 && strncmp("WAVE",&tmp[8],4)==0)
				{
					printf("Found WAVE header\n");
					track->start=0;
					while(result && !track->start)
					{
						int l;
						result&=RARead(&track->file,tmp,8);
						l=(tmp[7]<<24)|(tmp[6]<<16)|(tmp[5]<<8)|tmp[4];
						if(strncmp("fmt ",tmp,4)==0)
						{
							printf("Found fmt chunk\n");
						}
						else if(strncmp("data ",tmp,4)==0)
						{
							printf("Found data chunk, data starts at %d with length %d\n",track->file.ptr,l);
							track->start=track->file.ptr;
							track->length=l;
							l=0;
						}
						else
							printf("Skipping unknown chunk %lx with length %d\n",*(int *)tmp,l);
						if(l)
							RASeek(&track->file,l,SEEK_CUR);
					}
				}
				else /* No WAV header?  Treat as raw.  FIXME - might be better to refuse to play? */
				{
					printf("Treating as RAW data\n");
					RASeek(&track->file,offset,SEEK_SET);
				}
			}
			else
				printf("Can't read header\n");
		}
		audiotrack_cue(track);
		audiotrack_fill(track);
		result=1;
	}
	printf("Initialised audiotrack\n");
	return(result);
}



