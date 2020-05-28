#include <stdio.h>

#include "errors.h"

int ErrorMask=0;

char *ErrorMessages[ERROR_MAX+1]=
{
	"SD Card",
	"Filesystem",
	"Kickstart ROM",
	"Floppy emulation",
	"Harddrive emulation"
};


struct Error Errors[ERROR_MAX];

