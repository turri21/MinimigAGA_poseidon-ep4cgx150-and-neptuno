
#include <exec/types.h>

#include "audiotest.h"


void Audio_Server(struct AudioContext *ac)
{
    short s=AUDIOHW;
    AUDIOHW=ac->Active ? AUDIOACTIVE|AUDIOINTACTIVE : 0;
    s&=1;
    if(ac->ActiveBuffer!=s)
    {
        Signal(ac->SigTask,ac->Signals);
    }
    ac->ActiveBuffer=s&1;
}

