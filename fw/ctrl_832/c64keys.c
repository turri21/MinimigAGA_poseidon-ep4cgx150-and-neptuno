#include <stdio.h>

#include "interrupts.h"

#include "c64keys.h"

#define AKIKOBASE 0x0fffff80
#define HW_AKIKO(x) *(volatile unsigned short *)(AKIKOBASE+x)

#define REG_AKIKO_ADDR 2
#define REG_AKIKO_DATA 6

#define AKIKO_REQ 0x8000
#define AKIKO_WRITE 0x4000

#define QUAL_SPECIAL 0x8000
#define QUAL_LSHIFT 0x100
#define QUAL_RSHIFT 0x200
#define QUAL_MASK 0x7f00

struct keyspecial
{
	unsigned char unshifted,shifted;
};

struct keyspecial specialtable[]=
{
	{0x4e,0x4f},	/* cursor keys */
	{0x4d,0x4c},
	{0x50,0x51},	/* F keys */
	{0x52,0x53},
	{0x54,0x55},
	{0x56,0x57}
};

unsigned int keytable[]=
{
	0x41, /* $00	Inst/Del */
	0x44, /* $01	Return */
	QUAL_SPECIAL|0, /* $02	Crsr l/r	- special handling needed */
	QUAL_SPECIAL|5, /* $03	F7/F8 */
	QUAL_SPECIAL|2, /* $04	F1/F2 */
	QUAL_SPECIAL|3, /* $05	F3/F4 */
	QUAL_SPECIAL|4, /* $06	F5/F6 */
	QUAL_SPECIAL|1, /* $07	Crsr u/d	- special handling needed */

	0x3,  /* $08	3 */
	0x11, /* $09	W */
	0x20, /* $0A	A */
	0x04, /* $0B	4 */
	0x31, /* $0C	Z */
	0x21, /* $0D	S */
	0x12, /* $0E	E */
	QUAL_LSHIFT|0x60, /* $0F	Left Shift - special handling needed */

	0x05, /* $10	5 */
	0x13, /* $11	R */
	0x22, /* $12	D */
	0x06, /* $13	6 */
	0x33, /* $14	C */
	0x23, /* $15	F */
	0x14, /* $16	T */
	0x32, /* $17	X */

	0x07, /* $18	7 */
	0x15, /* $19	Y */
	0x24, /* $1A	G */
	0x08, /* $1B	8 */
	0x35, /* $1C	B */
	0x25, /* $1D	H */
	0x16, /* $1E	U */
	0x34, /* $1F	V */

	0x09, /* $20	9 */
	0x17, /* $21	I */
	0x26, /* $22	J */
	0x0a, /* $23	0 */
	0x37, /* $24	M */
	0x27, /* $25	K */
	0x18, /* $26	O */
	0x36, /* $27	N */

	0x0c, /* $28	+ */
	0x19, /* $29	P */
	0x28, /* $2A	L */
	0x0b, /* $2B	− */
	0x38, /* $2C	> */
	0x29, /* $2D	[ */
	0x1a, /* $2E	@ */
	0x39, /* $2F	< */
	
	0x0d, /* $30	£ */
	0x1b, /* $31	* */
	0x2a, /* $32	] */
	0x46, /* $33	Clr/ Home */
	QUAL_RSHIFT|0x61, /* $34	Right shift - special handling needed */
	0x2b, /* $35	= */
	0x00, /* $36	↑ */
	0x3a, /* $37	? */

	0x01, /* $38	1 */
	0x45, /* $39	← */
	0x63, /* $3A	(Unused) */
	0x02, /* $3B	2 */
	0x40, /* $3C	Space */
	0x66, /* $3D	(Unused) */
	0x10, /* $3E	Q */
	0x64  /* $3F	Run/Stop */
};


int c64frame;
unsigned short c64keys[12];
int c64qualifiers;

void ringbuffer_init(struct ringbuffer *r)
{
	r->out_hw=0;
	r->out_cpu=0;
}

void ringbuffer_write(struct ringbuffer *r,int in)
{
/*	Can't wait for the ringbuffer to empty if we're going to fill it from
	within an interrupt.  We will have to accept that keystrokes will be lost
	in the unlikely event that we fill it quicker than we empty it. */
/*	while(r->out_hw==((r->out_cpu+1)&(RINGBUFFER_SIZE-1)))
		;
	DisableInterrupts(); */
	r->outbuf[r->out_cpu]=in;
	r->out_cpu=(r->out_cpu+1) & (RINGBUFFER_SIZE-1);
/*	EnableInterrupts(); */
}

struct ringbuffer kbbuffer;
void keyinthandler()
{
	int i;
	int count=0;
	int idx=63;
	int nextframe=(c64frame+4)%12;
	int prevframe=(c64frame+8)%12;

	unsigned int aa;
	unsigned int ad;

	aa=HW_AKIKO(REG_AKIKO_ADDR);
	ad=HW_AKIKO(REG_AKIKO_DATA);
	if(aa&AKIKO_REQ)
	{
		if(aa&AKIKO_WRITE)
			printf("Akiko write: %x, %x\n",aa,ad);
		else
			printf("Akiko read: %x\n",aa);
		HW_AKIKO(REG_AKIKO_DATA)=0;
	}

	for(i=0;i<4;++i)
	{
		unsigned int t=HW_KEYBOARD(REG_KEYBOARD_WORD0+4*i);
		c64keys[c64frame+i]=t;
		while(t)	/* Count the number of set bits */
		{
			t&=t-1;
			++count;
		}
	}

	/* 	Very unlikely that more than four keys are depressed, so if that happens
		we're probably looking at interference from the joystick port. */
	if(count>=60)
	{
		for(i=0;i<4;++i)
		{
			int j;
			unsigned int changed=c64keys[nextframe+i]^(c64keys[prevframe+i]|c64keys[c64frame+i]);
			unsigned int status=c64keys[c64frame+i];
			for(j=0;j<16;++j)
			{
				--idx;
				if(changed&0x8000)
				{
					int code=63-(i*16+j);	/* Fetch Amiga scancode for this key */
					int amicode;
					int amiqualup=0;
					int amiqualdown=0;
					code=((code<<3)|(code>>3))&63;	/* bit numbers are transposed compared with c64 scancodes */
					amicode=keytable[code];

					if(amicode&QUAL_SPECIAL)
					{
						/* If the key requires special handling, cancel any shifting before sending the key code
							unless both shift keys are down */
						switch(c64qualifiers&(QUAL_LSHIFT|QUAL_RSHIFT))
						{
							case 0:
								amicode=specialtable[amicode&0xff].unshifted;
								break;
							case QUAL_LSHIFT:
								amicode=specialtable[amicode&0xff].shifted;
								if(status&0x8000)
									amiqualdown=0x60;
								else
									amiqualup=0x60|0x80;
								break;
							case QUAL_RSHIFT:
								amicode=specialtable[amicode&0xff].shifted;
								if(status&0x8000)
									amiqualdown=0x61;
								else
								amiqualup=0x61|0x80;
								break;
							default:
								amicode=specialtable[amicode&0xff].shifted;
								break;
						}
					}
					if(status&0x8000)
					{
						amicode|=0x80; /* Key up */
						c64qualifiers&=(~amicode)&QUAL_MASK;
					}
					else
						c64qualifiers|=amicode&QUAL_MASK;
					if(amiqualup)
						ringbuffer_write(&kbbuffer,amiqualup);
					ringbuffer_write(&kbbuffer,amicode);
					if(amiqualdown)
						ringbuffer_write(&kbbuffer,amiqualdown);
				}
				changed<<=1;
				status<<=1;
			}
		}
		c64frame=nextframe;
	}

	if(kbbuffer.out_hw!=kbbuffer.out_cpu)
	{
		HW_KEYBOARD(REG_KEYBOARD_OUT)=kbbuffer.outbuf[kbbuffer.out_hw];
		kbbuffer.out_hw=(kbbuffer.out_hw+1) & (RINGBUFFER_SIZE-1);
	}
	GetInterrupts(); /* Clear interrupt flag last.  If we did this earlier
						we would have disable interrupts first and re-enable them here. */
}

__constructor(101.c64keys) void c64keysconstructor()
{
	int i;
	for(i=0;i<8;++i)
		c64keys[i]=0xffff;
	c64frame=0;
	c64qualifiers=0;
	ringbuffer_init(&kbbuffer);
	SetIntHandler(keyinthandler);
	EnableInterrupts();
}

