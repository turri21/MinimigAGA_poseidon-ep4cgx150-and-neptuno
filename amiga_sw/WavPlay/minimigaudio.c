#include <stdio.h>
#include <stdlib.h>

#include <exec/types.h>
#include <exec/interrupts.h>
#include <hardware/intbits.h>

#include <clib/exec_protos.h>
#include <clib/dos_protos.h>

#include "minimigaudio.h"

void Audio_Dispose(struct AudioContext *ac);
BOOL Audio_Handle(struct AudioContext *ac,unsigned long Signals);
void Audio_Enable(struct AudioContext *ac);
void Audio_Disable(struct AudioContext *ac);
void Audio_SetFillFunction(struct AudioContext *ac,int (*fillfunc)(void *,char *,int),void *userdata);

extern void *Audio_ServerStub;
void *InputBase;

extern struct IntuitionBase *IntuitionBase;

void Audio_Enable(struct AudioContext *ac)
{
  if(ac->Active==FALSE)
  {
    int i;
    int *buf=(int *)AUDIOBUFFER;
    ac->Interrupt.is_Node.ln_Name="Minimig Audio";
    ac->Interrupt.is_Node.ln_Type=NT_INTERRUPT;
    ac->Interrupt.is_Node.ln_Pri=0;
    ac->Interrupt.is_Code=ac->Server;
    ac->Interrupt.is_Data=ac;
    AddIntServer(INTB_EXTER,&ac->Interrupt);
    ac->Active=TRUE;

    for(i=0;i<AUDIOBUFFERSIZE;i+=2)
    {
        *buf++=0;
    }
    ac->ActiveBuffer=1;
    AUDIOHW=AUDIOACTIVE|AUDIOINTACTIVE;
  }
}


void Audio_Disable(struct AudioContext *ac)
{
  if(ac->Active)
  {
    RemIntServer(INTB_EXTER,&ac->Interrupt);
    ac->Active=FALSE;
    AUDIOHW=0;
  }
}


struct AudioContext *Audio_Create()
{
  struct AudioContext *ac;
  if(!(ac=malloc(sizeof(struct AudioContext))))
    return(NULL);
  memset(ac,0,sizeof(struct AudioContext));
  ac->Dispose=Audio_Dispose;
  ac->Handle=Audio_Handle;
  ac->Enable=Audio_Enable;
  ac->Disable=Audio_Disable;
  ac->SetFillFunction=Audio_SetFillFunction;

  ac->Server=&Audio_ServerStub;  /* Just an Asm stub */

  ac->Active=FALSE;
  ac->SigTask=FindTask(NULL);
  if((ac->SigBit=AllocSignal(-1))==-1)
  {
    ac->Dispose(ac);
    return(NULL);
  }
  ac->Signals=1<<ac->SigBit;

  return(ac);
}


void Audio_Dispose(struct AudioContext *ac)
{
  if(ac)
  {
    if(ac->Active)
      ac->Disable(ac);

    if(ac->SigBit>-1)
      FreeSignal(ac->SigBit);
    ac->SigBit=-1;

    free(ac);
  }
}


BOOL Audio_Handle(struct AudioContext *ac,unsigned long Signals)
{
  int bytesread=0;
  if(Signals&ac->Signals)
  {
    int buf=AUDIOHW&1;
    char *buffer=AUDIOBUFFER+(1-buf)*AUDIOBUFFERSIZE;
    if(ac->FillFunction)
        bytesread=ac->FillFunction(ac->FillUserData,buffer,AUDIOBUFFERSIZE);
    if(bytesread<AUDIOBUFFERSIZE)
    {
      int i;
      for(i=bytesread;i<AUDIOBUFFERSIZE;++i)
      {
        buffer[i]=0;
      }
    }
  }
  return(bytesread>0);
}

void Audio_SetFillFunction(struct AudioContext *ac,int (*fillfunc)(void *,char *,int),void *userdata)
{
    if(ac)
    {
        ac->FillFunction=fillfunc;
        ac->FillUserData=userdata;
    }
}

