#include <stdio.h>
#include <stdlib.h>

#include <exec/types.h>
#include <dos/dos.h>

#include <clib/exec_protos.h>
#include <clib/dos_protos.h>

#include "minimigaudio.h"
#include "wav.h"

void *IntuitionBase;

void _chkabort(){}

char *Main_Setup();
void Main_Cleanup();

int main(int argc, char **argv)
{
    char *error;
    int counter=0;
    struct AudioContext *MyAC;
    struct Wav *wav=0;

    if(error=Main_Setup())
    {
      printf("Error: %s\n",error);
      return(10);
    }

    if(MyAC=Audio_Create())
    {
        int i;
        printf("Everything setup OK!\n");

        SetTaskPri(FindTask(NULL),19);

        for(i=1;i<argc;++i)
        {
            BOOL cont=TRUE;
            wav=wav_open(argv[i]);
            if(wav)
            {
                MyAC->SetFillFunction(MyAC,(int(*)(void *, char *,int))wav_read,wav);

                MyAC->Enable(MyAC);


                while(cont)
                {
                    unsigned long sigs;

                    sigs=MyAC->Signals|SIGBREAKF_CTRL_C;
                    sigs=Wait(sigs);

                    cont&=MyAC->Handle(MyAC,sigs);

                    if(sigs&SIGBREAKF_CTRL_C)
                    {
                        cont=FALSE;
                        i=argc;
                    }
                }

                MyAC->Disable(MyAC);
                wav_close(wav);
            }
        }
        MyAC->Dispose(MyAC);
    }
    Main_Cleanup();

    return(0);
}


char *Main_Setup()
{
  if(!(IntuitionBase=OpenLibrary("intuition.library",0)))
    return("Can't open intuition.library");
  return(NULL);
}


void Main_Cleanup()
{
  if(IntuitionBase)
    CloseLibrary(IntuitionBase);
  IntuitionBase=NULL;
}

