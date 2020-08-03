#ifndef AUDIOTRACK_H
#define AUDIOTRACK_H

#include "hardware.h"
#include "rafile.h"

#define AUDIOSEEK_STEP 2048

struct audiotrack
{
	RAFile file;
	int currentbuffer;
	int remain;
	int buffersize;
	int start;
	int length;
	unsigned char *buffer;
};


int audiotrack_busy(struct audiotrack *track);
void audiotrack_cue(struct audiotrack *track);
void audiotrack_play(struct audiotrack *track);
void audiotrack_fastforward(struct audiotrack *track);
void audiotrack_rewind(struct audiotrack *track);
void audiotrack_stop(struct audiotrack *track);
void audiotrack_fill(struct audiotrack *track);
int audiotrack_init(struct audiotrack *track, const char *filename,int offset,int length,unsigned char *buffer);

#endif

