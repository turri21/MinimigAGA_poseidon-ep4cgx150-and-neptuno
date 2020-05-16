#define ERROR_NONE 0
#define ERROR_SDCARD 1
#define ERROR_FILESYSTEM 2
#define ERROR_FILE_NOT_FOUND 3
#define ERROR_MAX 3

extern unsigned char Error;
extern char *ErrorMsg;

void FatalError(unsigned long error);
void ErrorMessage(char *message, unsigned char code);
