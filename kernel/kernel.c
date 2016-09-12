#include "../drivers/screen.h"

extern void clear_screen();
extern void print_string(char *);

// 0x1000
void main() {
	clear_screen();
	char *str = "awesome ";
	print_string(str);
	// do something here
}

