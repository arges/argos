;
; (C) 2014 Chris J Arges <christopherarges@gmail.com>
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;MAIN
[org 0x7c00]

KERNEL_OFFSET	equ 0x1000
mov	[BOOT_DRIVE], dl
mov	bp, 0x9000
mov	sp, bp
mov 	bx, MSG_REAL_MODE
call 	print_string_rm
call	load_kernel
call	switch_to_pm

jmp	$

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;FUNCTIONS

[bits 16]
load_kernel:
	mov	bx, MSG_LOAD_KERNEL
	call	print_string_rm
	mov	bx, KERNEL_OFFSET
	mov	dh, 20
	mov	dl, [BOOT_DRIVE]
	call	disk_load
	ret

disk_load:
	push	dx
	mov	ah, 0x02	; bios read sector function
	mov	al, dh		
	mov	ch, 0x00	; select cylnder 0
	mov	dh, 0x00
	mov	cl, 0x02
	int	0x13
	jc	disk_error
	pop	dx
	cmp	dh, al
	jne	disk_error
	ret
disk_error:
	mov	bx, DISK_ERROR_MSG
	call	print_string_rm
	jmp $

; 16-bit real mode print function
; bx contains memory address of null-terminated string
print_string_rm:
	pusha
_print_string_rm:
	mov 	ah, 0x0e
	mov 	al, [bx]
	int 	0x10
	add 	bx, 0x1
	cmp 	al, 0
	jne 	_print_string_rm
	popa
	ret

switch_to_pm:
	cli
	lgdt	[gdt_descriptor]
	mov	eax, cr0
	or	eax, 0x1
	mov	cr0, eax
	jmp	CODE_SEG:init_pm

[bits 32]
init_pm:
	mov 	ax, DATA_SEG
	mov	ds, ax
	mov	ss, ax
	mov	es, ax
	mov	fs, ax
	mov	gs, ax
	mov	ebp, 0x90000
	mov	esp, ebp
	call	BEGIN_PM

VIDEO_MEMORY equ 0xb8000
WHITE_ON_BLACK equ 0x0f
print_string_pm:
	pusha
	mov 	edx, VIDEO_MEMORY
print_string_pm_loop:
	mov 	al, [ebx]
	mov	ah, WHITE_ON_BLACK
	cmp	al, 0
	je	print_string_pm_done
	mov	[edx], ax
	add	ebx, 1
	add 	edx, 2
	jmp	print_string_pm_loop
print_string_pm_done:
	popa
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;GDT
gdt_start:
gdt_null:
	dd 0x0
	dd 0x0
gdt_code:
	dw 0xffff
	dw 0x0
	db 0x0
	db 10011010b
	db 11001111b
	db 0x0
gdt_data:
	dw 0xffff
	dw 0x0	
	db 0x0
	db 10010010b
	db 11001111b
	db 0x0
gdt_end:

gdt_descriptor:
	dw gdt_end - gdt_start - 1
	dd gdt_start

CODE_SEG equ gdt_code - gdt_start
DATA_SEG equ gdt_data - gdt_start


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
BEGIN_PM:
	mov	ebx, MSG_PROT_MODE	; we are protected!
	call	print_string_pm
	call	KERNEL_OFFSET
	jmp	$


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;GLOBALS
BOOT_DRIVE	db 0
MSG_REAL_MODE	db " 16-bit real mode                                         ", 10, 13, 0
MSG_PROT_MODE	db " 32-bit protected mode                                    ", 10, 13, 0
DISK_ERROR_MSG	db " disk read error                                          ", 10, 13, 0
MSG_LOAD_KERNEL	db " loading kernel into memory                               ", 10, 13, 0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;BOOT
times 	510-($-$$) db 0
dw 	0xaa55
