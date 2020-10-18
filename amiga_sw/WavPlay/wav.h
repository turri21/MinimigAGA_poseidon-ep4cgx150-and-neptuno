#ifndef AUDIOTRACK_H
#define AUDIOTRACK_H

struct Wav
{
    BPTR file;
    int length;
};


int wav_read(struct Wav *wav,char *buf,int length);
struct Wav *wav_open(const char *filename);
void wav_close(struct Wav *wav);


#endif

