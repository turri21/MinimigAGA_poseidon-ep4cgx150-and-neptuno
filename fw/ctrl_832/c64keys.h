#ifndef C64KEYS_H
#define C64KEYS_H

#define KEYBOARDBASE 0x0fffff90
#define HW_KEYBOARD(x) *(volatile unsigned short *)(KEYBOARDBASE+x)

#define REG_KEYBOARD_WORD0 2
#define REG_KEYBOARD_WORD1 6
#define REG_KEYBOARD_WORD2 0xa
#define REG_KEYBOARD_WORD3 0xe

#define REG_KEYBOARD_OUT 2

#define RINGBUFFER_SIZE 16
struct ringbuffer
{
	volatile int out_hw;
	volatile int out_cpu;
	unsigned int outbuf[RINGBUFFER_SIZE];
};

void ringbuffer_init(struct ringbuffer *r);
void ringbuffer_write(struct ringbuffer *r,int in);

void c64keys_inthandler();
extern int c64qualifiers;

#endif
