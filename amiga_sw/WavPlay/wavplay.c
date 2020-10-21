#include <stdio.h>
#include <stdlib.h>

#include <exec/types.h>
#include <exec/ports.h>
#include <dos/dos.h>
#include <workbench/startup.h>
#include <intuition/intuition.h>

#include <clib/exec_protos.h>
#include <clib/dos_protos.h>

#include "minimigaudio.h"
#include "wav.h"

void *IntuitionBase=0;

void _chkabort(){}
struct MsgPort *rendezvous;

char *Main_Setup();
void Main_Cleanup();

extern struct WBStartup *WBenchMsg;


void ErrorMessage(char *message)
{
    if(WBenchMsg && IntuitionBase)
    {
        struct EasyStruct myes={sizeof(struct EasyStruct),0,"WavPlay",0,"OK",};
        myes.es_TextFormat=message;
        EasyRequestArgs(NULL,&myes,NULL,NULL);
    }
    else
        printf("Error: %s\n",message);
}


char *getarg(char **argv,int i)
{
    if(WBenchMsg)
    {
        struct WBArg *args=WBenchMsg->sm_ArgList;
        if(i<WBenchMsg->sm_NumArgs)
        {
            CurrentDir(args[i+1].wa_Lock);
            return(args[i+1].wa_Name);
        }
        else
            return(0);
    }
    return(argv[i+1]);
}


int countargs(int argc)
{
    int args;
    if(WBenchMsg)
    {
        args=WBenchMsg->sm_NumArgs-1;
    }
    else
        args=argc-1;
    return(args);
}


int main(int argc, char **argv)
{
    char *error;
    int counter=0;
    struct AudioContext *MyAC;
    struct Wav *wav=0;
    int args;

    if(error=Main_Setup())
    {
      ErrorMessage(error);
      return(10);
    }

    args=countargs(argc);

    if(MyAC=Audio_Create())
    {
        int i;

        SetTaskPri(FindTask(NULL),19);

        for(i=0;i<args;++i)
        {
            BOOL cont=TRUE;
            wav=wav_open(getarg(argv,i));
            if(wav)
            {
                MyAC->SetFillFunction(MyAC,(int(*)(void *, char *,int))wav_read,wav);

                MyAC->Enable(MyAC);

                while(cont)
                {
                    unsigned long sigs;

                    sigs=(1<<rendezvous->mp_SigBit)|MyAC->Signals|SIGBREAKF_CTRL_C;
                    sigs=Wait(sigs);

                    cont&=MyAC->Handle(MyAC,sigs);

                    if(sigs&SIGBREAKF_CTRL_C)
                    {
                        cont=FALSE;
                        i=args;
                    }
                    if(sigs&(1<<rendezvous->mp_SigBit))
                    {
                        struct Message *msg;
                        cont=FALSE;
                        i=args;
                        if(msg=GetMsg(rendezvous))
                            ReplyMsg(msg);
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

#define PORTNAME "minimig_wavplay"

BPTR currentdir=0;

char *Main_Setup()
{
  struct MsgPort *other=0;

  if(WBenchMsg)
    currentdir=CurrentDir(WBenchMsg->sm_ArgList->wa_Lock);

  if(!(IntuitionBase=OpenLibrary("intuition.library",0)))
    return("Can't open intuition.library");
  if(!(rendezvous=CreateMsgPort()))
    return("Can't create rendezvous port");

  other=FindPort(PORTNAME);
  if(other)
  {
    struct Message quitmsg;
    quitmsg.mn_Length=sizeof(struct Message);
    quitmsg.mn_ReplyPort=rendezvous;
    PutMsg(other,&quitmsg);
    WaitPort(rendezvous);
    GetMsg(rendezvous);
  }
  rendezvous->mp_Node.ln_Name=PORTNAME;
  AddPort(rendezvous);

  return(NULL);
}


void Main_Cleanup()
{
  if(rendezvous)
  {
    RemPort(rendezvous);
    DeleteMsgPort(rendezvous);
  }
  if(IntuitionBase)
    CloseLibrary(IntuitionBase);
  IntuitionBase=NULL;

  if(currentdir)
    CurrentDir(currentdir);
}

