#ifndef BINCUE_H
#define BINCUE_H

enum cdimagetype {CD_INVALID,CD_BINARY,CD_WAVE};

struct cdimage
{
	int tracks;
	int audiotracks;
	int currenttrack;
	int offset;
	int length;	/* 0 for standalone WAV files. */
	enum cdimagetype type;
	char filename[261];
};

int cd_gettrack(struct cdimage *cd, char *in,int track);

#endif

