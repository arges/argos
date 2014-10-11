#include "../drivers/screen.h"

// 0x1000
void main() {
	clear_screen();
	char *str = "awesome ";
	print_string(str);
	// do something here
}

