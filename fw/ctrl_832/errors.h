#define ERROR_SDCARD 0
#define ERROR_FILESYSTEM 1
#define ERROR_ROM 2
#define ERROR_FDD 3
#define ERROR_HDD 4
#define ERROR_MAX 4

#define SetError(x,s,y,z) {ErrorMask|=(1<<x); Errors[x].string=s; Errors[x].a=y; Errors[x].b=z;}
#define FDDError(s,a) SetError(ERROR_FDD,s,a,0)
#define SetSubError(x) SubError=x
#define SetSubError2(x) SubError2=x
#define SetSubErrorString(x) SubErrorString=x

extern int ErrorMask;
extern char *ErrorMessages[ERROR_MAX];
struct Error
{
	char *string;
	int a;
	int b;
};
extern struct Error Errors[ERROR_MAX];

void FatalError(unsigned long error);

