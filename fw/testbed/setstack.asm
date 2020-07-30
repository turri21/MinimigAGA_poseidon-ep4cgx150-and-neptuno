	.section .text.setstack
	.global	_setstack

	// Seed function - call this from main to have the appropriate code included.
_setstack:
	mr	r7

__setstack:
	mr	r0
	.liabs	_STACKTOP
	exg	r6
	stdec	r6
	mt	r0
	mr	r7

__restorestack:
	mr	r0
	ldinc	r6
	mr	r6
	mt	r0
	mr	r7

	.ctor	200.setstack
	.ref	__setstack

	.dtor	200.restorestack
	.ref	__restorestack

