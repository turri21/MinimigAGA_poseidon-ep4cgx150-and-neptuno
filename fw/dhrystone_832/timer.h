#ifndef TIMER_H
#define TIMER_H

/* Hardware registers for a timer */

#define TIMERBASE 0x0FFFFFD2
#define HW_TIMER(x) *(volatile unsigned short *)(TIMERBASE+x)

#define REG_TIMER_ENABLE 0
#define REG_TIMER_INDEX 4
#define REG_TIMER_COUNTER 8

/*  Legacy millisecond counter, needed for the Dhrystone ZPU demo.
	FIXME - replace this with a TIMER_COUNTER read at some point */

#define REG_MILLISECONDS (0x0FFFFFD2-TIMERBASE)

#endif

