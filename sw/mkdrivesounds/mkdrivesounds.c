#include <stdio.h>

enum DriveSound_Type {
	DRIVESOUND_INSERT=1,DRIVESOUND_EJECT,DRIVESOUND_MOTORSTART,DRIVESOUND_MOTORLOOP,DRIVESOUND_MOTORSTOP,
	DRIVESOUND_STEP1,DRIVESOUND_STEP2,DRIVESOUND_STEP3,DRIVESOUND_STEP4
};


void emit_longword_be(unsigned int v)
{
	putchar((v>>24)&255);
	putchar((v>>16)&255);
	putchar((v>>8)&255);
	putchar(v&255);
}

char buffer[512];

int main(int argc,char **argv)
{
	int i;
	for(i=1;i<argc;++i)
	{
		FILE *f;
		unsigned int l;
		fprintf(stderr,"File %s\n",argv[i]);
		f=fopen(argv[i],"rb");
		fseek(f,0,SEEK_END);
		l=ftell(f);
		fseek(f,0,SEEK_SET);
		fprintf(stderr,"Size %d\n",l);
		printf("DRIVESND");
		emit_longword_be(i);
		emit_longword_be(l);
		while(l>0)
		{
			int r=fread(buffer,1,512,f);
			l-=r;
			fwrite(buffer,1,r,stdout);
		}
	}
	return(0);
}

