#ifndef BINCUE_H
#define BINCUE_H

#include "rafile.h"
#include "audiotrack.h"

enum cdimagetype {CD_INVALID,CD_BINARY,CD_WAVE};
enum cderror {CD_OK,CD_FILENOTFOUND,CD_TRACKNOTFOUND};

struct cdimage
{
	enum cderror error;
	int tracks;
	int audiotracks;
	int currenttrack;
	int offset;
	int length;	/* 0 for standalone WAV files. */
	enum cdimagetype type;
	RAFile cuefile;
	struct audiotrack audio;
	char linebuffer[512];
	char filename[261];
};

int cd_setcuefile(struct cdimage *cd,const char *filename);
int cd_findtrack(struct cdimage *cd,int track);
int cd_cueaudio(struct cdimage *cd,int track);
int cd_playaudio(struct cdimage *cd,int track);
void cd_continueaudio(struct cdimage *cd);

#endif

