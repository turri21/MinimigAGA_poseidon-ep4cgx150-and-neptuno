#ifndef AUDIOTRACK_H
#define AUDIOTRACK_H

#include "hardware.h"
#include "fat.h"

#define AUDIOSEEK_STEP 2048

struct audiotrack
{
	fileTYPE file;
	int currentbuffer;
	int remain;
	int buffersize;
	unsigned char *buffer;
};


int audiotrack_busy(struct audiotrack *track);
void audiotrack_play(struct audiotrack *track);
void audiotrack_fastforward(struct audiotrack *track);
void audiotrack_rewind(struct audiotrack *track);
void audiotrack_stop(struct audiotrack *track);
void audiotrack_fill(struct audiotrack *track);
int audiotrack_init(struct audiotrack *track, const char *filename,unsigned char *buffer);

#endif

