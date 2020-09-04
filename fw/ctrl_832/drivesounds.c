#include <stdio.h>
#include <string.h>

#include "hardware.h"
#include "audio.h"
#include "rafile.h"

#include "drivesounds.h"


struct drivesound
{
	enum DriveSound_Type type;
	short *base;
	int length;
	int active;
	int chain;
	int cursor;
};

struct dsevent
{
	enum DriveSound_Type type;
	int timestamp;
};

#define DSEVENTBUFFER_SIZE 8

struct dseventbuffer
{
	volatile int in;
	volatile int out;
	int timestamp;
	int	cursor;
	struct dsevent events[DSEVENTBUFFER_SIZE];
	struct drivesound sounds[DRIVESOUND_COUNT];
};

struct dseventbuffer drivesounds;


void drivesounds_queueevent(enum DriveSound_Type type)
{
	drivesounds.events[drivesounds.in].type=type;
	drivesounds.events[drivesounds.in].timestamp=TIMER;
	drivesounds.in=(drivesounds.in+1)&(DSEVENTBUFFER_SIZE-1);
}


void drivesounds_stop()
{
	audio_stop();
}


void drivesounds_start()
{
	drivesounds.timestamp=TIMER;
	audio_start();
}


struct dsevent *drivesounds_nextevent()
{
	struct dsevent *result=0;
	if(drivesounds.in!=drivesounds.out)
		result=&drivesounds.events[drivesounds.out++];
	drivesounds.out&=(DSEVENTBUFFER_SIZE-1);

//	if(result)
//		printf("Found event %d at time %d\n",result->type,result->timestamp);
	return(result);
}


void drivesounds_finishsound(int i)
{
	int result=0;
	drivesounds.sounds[i].active=0;
	drivesounds.sounds[i].cursor=0;
	i=drivesounds.sounds[i].chain;
	if(i)
	{
//						printf("chained with sound %d\n",drivesounds.sounds[i].chain);
		drivesounds.sounds[i].active=1;
		drivesounds.sounds[i].cursor=0;
	}
}


int drivesounds_render(int timestamp)
{
	int samples;
	int *buf=(int *)AUDIO_BUFFER;
	short *src,*src2;
	int srcc,srcc2;
	int srcl,srcl2;
	int srcs,srcs2;
	int i;
	int active=0;
	int b1,b2;
	samples=(timestamp-drivesounds.timestamp);
	if(samples<0)
		samples+=65536;
	if(samples>127)
		samples=127;
	samples*=256;

//	printf("Rendering %d samples\n",samples);

	while(samples)
	{
		int span=samples;

		src=src2=0;

		for(i=0;i<DRIVESOUND_COUNT;++i)
		{
			if(drivesounds.sounds[i].active)
			{
				src=drivesounds.sounds[i].base;
				srcl=drivesounds.sounds[i].length;
				srcc=drivesounds.sounds[i].cursor;
				src+=srcc;
				srcs=i;
				++i;
				break;
			}
		}
		for(;i<DRIVESOUND_COUNT;++i)
		{
			if(drivesounds.sounds[i].active)
			{
				src2=drivesounds.sounds[i].base;
				srcl2=drivesounds.sounds[i].length;
				srcc2=drivesounds.sounds[i].cursor;
				src2+=srcc2;
				srcs2=i;
				++i;
				break;
			}
		}
		for(;i<DRIVESOUND_COUNT;++i)
		{
			drivesounds.sounds[i].active=0;
		}

		if(((AUDIO_BUFFER_SIZE-drivesounds.cursor)>>1)<span)
			span=(AUDIO_BUFFER_SIZE-drivesounds.cursor)>>1;
		if(src && ((srcl-srcc)<span))
			span=srcl-srcc;
		if(src2 && ((srcl2-srcc2)<span))
			span=srcl2-srcc2;

		buf=(int *)AUDIO_BUFFER;
		buf+=drivesounds.cursor>>1;
		b1=drivesounds.cursor&0x4000;
		drivesounds.cursor+=2*span;
		drivesounds.cursor&=(AUDIO_BUFFER_SIZE)-1;
		b2=drivesounds.cursor&0x4000;

//		putchar('s');
//		if(b1!=b2)
//		{
//			putchar('-');
//			while(audio_busy(b2 ? 1 : 0))
//				;
//		}

//		printf("%x,%x,%x,%x,%x\n",(int)buf,(int)src,(int)src2,samples,span);

 		samples-=span;

		if(src && src2)
		{
			srcc+=span;
			srcc2+=span;
			while(span--)
			{
				int c=*src++;
				c+=*src2++;
				c=((c&255)<<8) | ((c>>8)&255);
				c=c*0x10001;
				*buf++=c;
			}
			drivesounds.sounds[srcs].cursor=srcc;
			drivesounds.sounds[srcs2].cursor=srcc2;
			if(srcc>=srcl)
				drivesounds_finishsound(srcs);
			if(srcc2>=srcl2)
				drivesounds_finishsound(srcs2);
		}
		else if(src)
		{
			srcc+=span;
			while(span--)
			{
				int c=*src++;
				c=((c&255)<<8) | ((c>>8)&255);
				c=c*0x10001;
				*buf++=c;
			}
			drivesounds.sounds[srcs].cursor=srcc;
			if(srcc>=srcl)
				drivesounds_finishsound(srcs);
		}
		else if(span)
		{
			while(span--)
				*buf++=0;
		}
	}

#if 0
//	printf("Rendering %d samples at cursor position %d\n",samples,cursor);
	while(samples--)
	{
		short acc=0;
		int i;
		for(i=0;i<DRIVESOUND_COUNT;++i)
		{
			if(drivesounds.sounds[i].active)
			{
				active=1;
				acc+=drivesounds.sounds[i].base[drivesounds.sounds[i].cursor++];
				if(drivesounds.sounds[i].cursor>=drivesounds.sounds[i].length)
				{
//					printf("Reached end of sound %d\n",i);
					drivesounds.sounds[i].active=0;
					drivesounds.sounds[i].cursor=0;
					if(drivesounds.sounds[i].chain)
					{
//						printf("chained with sound %d\n",drivesounds.sounds[i].chain);
						drivesounds.sounds[drivesounds.sounds[i].chain].active=1;
					}
				}
			}
		}
		i=(acc>>8)&255;
		i|=acc<<8;
		buf[cursor++]=i;
		buf[cursor++]=i;
		cursor&=(AUDIO_BUFFER_SIZE)-1;
	}
#endif
	drivesounds.timestamp=timestamp;
//	printf("Timestamp set to %d\n",drivesounds.timestamp);
	return(active);
}


int drivesounds_fill()
{
	int active;
	struct dsevent *dse;
	while(dse=drivesounds_nextevent())
	{
//		printf("Found event of type %d\n",dse->type);
//		printf("Rendering up to event %d\n",dse->timestamp);
		active|=drivesounds_render(dse->timestamp);
		drivesounds.sounds[dse->type].cursor=0;
		switch(dse->type)
		{
			case DRIVESOUND_MOTORSTART:
				drivesounds.sounds[DRIVESOUND_MOTORSTART].chain=DRIVESOUND_MOTORLOOP;
				drivesounds.sounds[DRIVESOUND_MOTORLOOP].chain=DRIVESOUND_MOTORLOOP;
				drivesounds.sounds[DRIVESOUND_MOTORSTART].active=1;
				break;
			case DRIVESOUND_MOTORSTOP:
				drivesounds.sounds[DRIVESOUND_MOTORLOOP].chain=DRIVESOUND_MOTORSTOP;
				break;
			case DRIVESOUND_STEP:
				dse->type+=TIMER&3;	/* Pick a step sound at "random" */
				drivesounds.sounds[dse->type].active=1;
				drivesounds.sounds[dse->type].chain=0;				
			default:
				drivesounds.sounds[dse->type].active=1;
				drivesounds.sounds[dse->type].chain=0;
				break;
		}
	}
//	printf("Rendering remainder\n");
	active|=drivesounds_render(TIMER);
	return(active);
}


int drivesounds_init(const char *filename)
{
	int result=0;
	char *buf=AUDIO_BUFFER+2*AUDIO_BUFFER_SIZE;
	RAFile file;
	drivesounds.in=0;
	drivesounds.out=0;
	if(RAOpen(&file,filename))
	{
		int size=file.size;
		if(size<(512*1024-2*AUDIO_BUFFER_SIZE))
		{
			printf("Audio file - length %d\n",file.size);		
			RARead(&file,buf,file.size);
			if(strncmp(buf,"DRIVESND",8)==0)
			{
				int id=0;
				buf+=8;
				id=*(long *)buf;
				buf+=4;
				size=*(long *)buf;
				buf+=4;
				while(size)
				{
					if(size && id<DRIVESOUND_COUNT)
					{
						printf("Sound %d at %x, length %d\n",id,buf,size);
						drivesounds.sounds[id].base=buf;
						drivesounds.sounds[id].length=size/2; /* Size needs to be in 16-bit words */
						buf+=size;
						result=1;
						id=*(long *)buf;
						buf+=4;
						size=*(long *)buf;
						buf+=4;
					}
					else
					{
						size=0;
					}
				}
			}
			else
				printf("Bad signature in DriveSounds file\n");
		}
		else
			printf("Drive sounds file too large\n");
	}
	drivesounds.cursor=0;
	return(result);
}

