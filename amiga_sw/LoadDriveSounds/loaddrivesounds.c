#include <clib/dos_protos.h>
#include <stdio.h>

BOOL LoadAbsolute(char filename[],APTR buffer,ULONG buflen)
{
  BPTR fh;
  ULONG filelen;
  if(fh=Open(filename,MODE_OLDFILE))
  {
    Seek(fh,0,OFFSET_END);
    filelen=Seek(fh,0,OFFSET_BEGINNING);
    {
      Read(fh,buffer,(filelen<buflen ? filelen : buflen));
    }
    Close(fh);
    return(TRUE);
  }
  else
    return(FALSE);
}

struct drivesnd {
	unsigned short sig1;
	unsigned short sig2;
};

int main(int argc,char **argv)
{
	int sounds=3;
	int sig;
	struct drivesnd *ds;
	if(argc>1)
	{
		/* Load drivesounds to space reserved for firmware, leaving the last 64K free for Wav Player */
		LoadAbsolute(argv[1],0xeb0000,0x4000);
	}
	if(argc>2)
	{
		char *p=argv[2];
		char c;
		sounds=0;
		while((c=*p++))
		{
			switch(c&~32) {
			
				case 'F':
					sounds|=1;
					break;
					
				case 'H':
					sounds|=2;
					break;
					
				default:
					break;
			}
		}
	}

	ds=(struct drivesnd *)0xeb0000;
	sig=ds->sig1;
	if((sig&0xfff0)==0x445)
	{
		printf("Drive sounds successfully loaded\n");
		sig=(sig&0xfff0) | sounds; /* Enable floppy drive and hard disk sounds */
		ds->sig1=sig;
		if(sig&1)
			printf("Enabled floppy drive sounds\n");
		if(sig&2)
			printf("Enabled hard disk sounds\n");			
	}
	return(0);
}

