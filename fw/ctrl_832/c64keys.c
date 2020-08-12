#include "interrupts.h"

#include "c64keys.h"

char keytable[]=
{
	0x41, /* $00	Inst/Del */
	0x44, /* $01	Return */
	0xff, /* $02	Crsr l/r	- special handling needed */
	0x56, /* $03	F7/F8 */
	0x50, /* $04	F1/F2 */
	0x52, /* $05	F3/F4 */
	0x54, /* $06	F5/F6 */
	0xff, /* $07	Crsr u/d	- special handling needed */

	0x3,  /* $08	3 */
	0x11, /* $09	W */
	0x20, /* $0A	A */
	0x04, /* $0B	4 */
	0x31, /* $0C	Z */
	0x21, /* $0D	S */
	0x12, /* $0E	E */
	0x60, /* $0F	Left Shift - special handling needed */

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
	0x61, /* $34	Right shift - special handling needed */
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
	c64keys[c64frame]=HW_KEYBOARD(REG_KEYBOARD_WORD0);
	c64keys[c64frame+1]=HW_KEYBOARD(REG_KEYBOARD_WORD1);
	c64keys[c64frame+2]=HW_KEYBOARD(REG_KEYBOARD_WORD2);
	c64keys[c64frame+3]=HW_KEYBOARD(REG_KEYBOARD_WORD3);

	for(i=0;i<4;++i)
	{
		unsigned int t=c64keys[i]^c64keys[4+i];
		c64keys[8+i]=t;
		while(t)
		{
			t&=t-1;
			++count;
		}
	}

	/* 	Very unlikely that three or more keys changed state in a single vblank,
		so if that happens we're probably looking at interference from the joystick port. */
	if(count && count<3)
	{
		int idx=63;
		for(i=0;i<4;++i)
		{
			int j;
			unsigned int changed=c64keys[8+i];
			unsigned int status=c64keys[c64frame+i];
			for(j=0;j<16;++j)
			{
				--idx;
				if(changed&0x8000)
				{
					int code=63-(i*16+j);	/* Fetch Amiga scancode for this key */
					code=((code<<3)|(code>>3))&63;	/* bit numbers are transposed compared with c64 scancodes */
					code=keytable[code];
					/* FIXME - check here for special cases like the cursor keys */
					if(status&0x8000)
						code|=0x80; /* Key up */
					ringbuffer_write(&kbbuffer,code);
				}
				changed<<=1;
				status<<=1;
			}
		}
	}

	if(kbbuffer.out_hw!=kbbuffer.out_cpu)
	{
		HW_KEYBOARD(REG_KEYBOARD_OUT)=kbbuffer.outbuf[kbbuffer.out_hw];
		kbbuffer.out_hw=(kbbuffer.out_hw+1) & (RINGBUFFER_SIZE-1);
	}
	c64frame^=4;
	GetInterrupts(); /* Clear interrupt flag last.  If we did this earlier
						we would have disable interrupts first and re-enable them here. */
}

__constructor(101.c64keys) void c64keysconstructor()
{
	int i;
	for(i=0;i<8;++i)
		c64keys[i]=0xffff;
	c64frame=0;
	ringbuffer_init(&kbbuffer);
	SetIntHandler(keyinthandler);
	EnableInterrupts();
}

