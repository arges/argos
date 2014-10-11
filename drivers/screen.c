#include "screen.h"

inline unsigned short get_screen_offset(int col, int row) {
	return ((row * 80) + col);
}

int get_cursor() {
	int offset = 0;
	port_byte_out(REG_SCREEN_CTRL, 14);
	offset = port_byte_in(REG_SCREEN_DATA) << 8;
	port_byte_out(REG_SCREEN_CTRL, 15);
	offset += port_byte_in(REG_SCREEN_DATA);
	return offset*2;
}

void set_cursor(int col, int row)
{
	unsigned short position=get_screen_offset(col,row);
	port_byte_out(REG_SCREEN_CTRL, 0xf);
	port_byte_out(REG_SCREEN_DATA, (unsigned char)(position&0xff));
	port_byte_out(REG_SCREEN_CTRL, 0xe);
	port_byte_out(REG_SCREEN_DATA, (unsigned char)(position>>8)&0xff);
}

void print_char(unsigned short character, int col, int row, unsigned char attribute) {
	unsigned short *vidmem = (unsigned short*)VIDEO_ADDRESS;
	unsigned short offset = get_screen_offset(col, row);
	vidmem[offset] = ((character << 8) & 0xff00) | attribute;
}

void print_string(unsigned char *string) {
	int r = 0;
	unsigned char *c = string;
	while (*c != '\0') {
		print_char(*c, r++, 0, 0x2f);
		c++;
	}
	set_cursor(r, 0);
}

void clear_screen() {
	int x = 0, y = 0;
	for (x=0;x<MAX_COLS;x++) {
		for (y=0;y<MAX_ROWS;y++) {
			print_char(' ',x,y,0x1f);
		}
	}
	set_cursor(0,0);
}


