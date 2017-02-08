;  CS 218 - Assignment #11
;  Functions Template
;  Anthony Pallone 
;  1002

; ***********************************************************************
;  Data declarations
;	Note, the error message strings should NOT be changed.
;	All other variables may changed or ignored...

section	.data

; -----
;  Define standard constants.

TRUE		equ	1
FALSE		equ	0

SUCCESS		equ	0			; successful operation
NOSUCCESS	equ	1			; unsuccessful operation

STDIN		equ	0			; standard input
STDOUT		equ	1			; standard output
STDERR		equ	2			; standard error

SYS_read	equ	0			; system call code for read
SYS_write	equ	1			; system call code for write
SYS_open	equ	2			; system call code for file open
SYS_close	equ	3			; system call code for file close
SYS_lseek	equ	8			; system call code for file repositioning
SYS_fork	equ	57			; system call code for fork
SYS_exit	equ	60			; system call code for terminate
SYS_creat	equ	85			; system call code for file open/create
SYS_time	equ	201			; system call code for get time

LF		equ	10
SPACE		equ	" "
NULL		equ	0
ESC		equ	27

O_CREAT		equ	0x40
O_TRUNC		equ	0x200
O_APPEND	equ	0x400

O_RDONLY	equ	000000q			; file permission - read only
O_WRONLY	equ	000001q			; file permission - write only
O_RDWR		equ	000002q			; file permission - read and write

S_IRUSR		equ	00400q
S_IWUSR		equ	00200q
S_IXUSR		equ	00100q

; -----
;  Define program specific constants.

KEY_MAX		equ	56
KEY_MIN		equ	16

BUFF_SIZE	equ	800000			; buffer size

; -----
;  Variables for getOptions() function.

eof		db	FALSE
eoftwo		db	FALSE	

usageMsg	db	"Usage: blowfish <-en|-de> -if <inputFile> "
		db	"-of <outputFile>", LF, NULL
errIncomplete	db	"Error, command line arguments incomplete."
		db	LF, NULL
errExtra	db	"Error, too many command line arguments."
		db	LF, NULL
errFlag		db	"Error, encryption/decryption flag not "
		db	"valid.", LF, NULL
errReadSpec	db	"Error, invalid read file specifier.", LF, NULL
errWriteSpec	db	"Error, invalid write file specifier.", LF, NULL
errReadFile	db	"Error, opening input file.", LF, NULL
errWriteFile	db	"Error, opening output file.", LF, NULL

; -----
;  Variables for getX() function.

buffMax		dq	BUFF_SIZE-1
curr		dq	BUFF_SIZE
wasEOF		db	FALSE

errRead		db	"Error, reading from file.", LF,
		db	"Program terminated.", LF, NULL

; -----
;  Variables for writeX() function.

errWrite	db	"Error, writting to file.", LF,
		db	"Program terminated.", LF, NULL

; -----
;  Variables for readKey() function.

chr		db	0

keyPrompt	db	"Enter Key (16-56 characters): ", NULL
keyError	db	"Error, invalid key size.  Key must be between 16 and "
		db	"56 characters long.", LF, NULL

; ------------------------------------------------------------------------
;  Unitialized data

section	.bss

buffer		resb	BUFF_SIZE


; ############################################################################

section	.text

; ***************************************************************
;  Routine to get arguments (encryption flag, input file
;	name, and output file name) from the command line.
;	Verify files by atemptting to open the files (to make
;	sure they are valid and available).

;  Command Line format:
;	./blowfish <-en|-de> -if <inputFileName> -of <outputFileName>

; -----
;  Arguments:
;	argc (value)					rdi	rbx
;	address of argv table				rsi	r12
;	address of encryption/decryption flag (byte)	rdx	r13	True for encrypt false for decrypt
;	address of read file descriptor (qword)		rcx	r14
;	address of write file descriptor (qword)	r8	r15
;  Returns:
;	TRUE or FALSE

global 	getOptions
getOptions:
	
	push 	rbp
	mov	rbp, rsp
	push	rbx
	push	r12
	push	r13
	push	r14
	push	r15

	mov	rbx, rdi
	mov	r12, rsi
	mov	r13, rdx
	mov	r14, rcx
	mov	r15, r8

	cmp	rbx, 1
	je	getOptionsError1

	cmp	rbx, 6
	jl	getOptionsError2
	jg	getOptionsError3

	mov	rdi, qword[r12+8]
	cmp	dword[rdi], 0x006E652D ;should compare it to -en

	je	encrypt
	cmp	dword[rdi], 0x0065642D ;should compare it to -de
	jne	getOptionsError4
	mov	byte[r13], FALSE
	jmp	getOptionsAfter1

encrypt:	
	mov	byte[r13], TRUE

getOptionsAfter1:
	mov	rdi, qword[r12+16]
	cmp	dword[rdi], 0x0066692D
	jne	getOptionsError5

	mov	rdi, qword[r12+24]
	mov	rax, SYS_open
	mov	rsi, O_RDONLY
	syscall

	cmp	rax, 0
	jl	getOptionsError6

	mov	qword[r14], rax

	mov	rdi, qword[r12+32]
	cmp	dword[rdi], 0x00666F2D
	jne	getOptionsError7

	mov	rdi, qword[r12+40]
	mov	rax, SYS_creat
	mov	rsi, S_IRUSR | S_IWUSR	
	syscall

	cmp	rax, 0
	jl	getOptionsError8

	mov	qword[r15], rax
	
	mov	rax, TRUE
	
getOptionsEnd:
	pop	r15
	pop	r14
	pop	r13
	pop	r12
	pop	rbx
	mov	rsp, rbp
	pop	rbp
	ret

getOptionsError1:
	mov	rdi, usageMsg
	call	printString
	mov	rax, FALSE
	jmp	getOptionsEnd
	
getOptionsError2:
	mov	rdi, errIncomplete
	call	printString
	mov	rax, FALSE
	jmp	getOptionsEnd
	
getOptionsError3:
	mov	rdi, errExtra
	call	printString
	mov	rax, FALSE
	jmp	getOptionsEnd
	
getOptionsError4:
	mov	rdi, errFlag
	call	printString
	mov	rax, FALSE
	jmp	getOptionsEnd
	
getOptionsError5:
	mov	rdi, errReadSpec
	call	printString
	mov	rax, FALSE
	jmp	getOptionsEnd
	
getOptionsError6:
	mov	rdi, errReadFile
	call	printString
	mov	rax, FALSE
	jmp	getOptionsEnd
	
getOptionsError7:
	mov	rdi, errWriteSpec	;might need to add file closes here
	call	printString
	mov	rax, FALSE
	jmp	getOptionsEnd
	
getOptionsError8:
	mov	rdi, errWriteFile
	call	printString
	mov	rax, FALSE
	jmp	getOptionsEnd
	


; ***************************************************************
;  Return the X array, 8 characters, from read buffer.
;	This routine performs all buffer management.

; -----
;   Arguments:
;	value of read file descriptor			rdi	r12
;	address of X array				rsi	r13
;  Returns:
;	TRUE or FALSE

;     NOTE's:
;	- returns TRUE when X array has been filled
;	- if < 8 characters in buffer, NULL fill
;	- returns FALSE only when asked for 8 characters
;		but there are NO more at all (which occurs
;		only when ALL previous characters have already
;		been returned).

;  The read buffer itself and some misc. variables are used
;  ONLY by this routine and as such are not passed.

global	getX
getX:	
	push	rbp
	mov	rbp, rsp
	push	r12
	push	r13
	push	r14		;error is that it needs to write one more time but it exits false and then 
	push	rbx

	mov	r12, rdi
	mov	r13, rsi
	
	mov	qword[r13], NULL
	mov	r14, 0			;r11 = i

getNextChr:
	cmp	byte[eoftwo], TRUE
	je	getXend
	
	mov	rax, qword[curr]
	cmp	rax, qword[buffMax]
	jle	getXskip1

	cmp	byte[eof], TRUE
	jne	getXskip3
	cmp	byte[eoftwo], TRUE
	je	getXend
	jne	getXend2
	mov	byte[eoftwo], TRUE
	
getXskip3:	
	mov	rax, SYS_read
	mov	rdi, r12
	mov	rsi, buffer
	mov	rdx, BUFF_SIZE
	syscall
	
	cmp	rax, 0
	jl	getXerror1
	je	getXend
	cmp	rax, BUFF_SIZE
	je	getXskip2
	mov	byte[eof], TRUE
	mov	qword[buffMax], rax
	dec	qword[buffMax]
getXskip2:
	mov	qword[curr], 0
	
getXskip1:
	mov	rbx, qword[curr]
	mov	al, byte[buffer+rbx]
	mov	byte[r13+r14], al
	inc	r14
	inc	qword[curr]
	mov	rax, BUFF_SIZE
	dec 	rax
	cmp	rax, qword[buffMax]
	je	getXskip4
	mov	rax, qword[curr]
	cmp	rax, qword[buffMax]
	jle	getXskip4
	jmp	getXend2
	
getXskip4:	
	cmp	r14, 8
	jl	getNextChr
	
	mov	rax, TRUE
	pop	rbx
	pop	r14
	pop	r13
	pop	r12
	mov	rsp, rbp
	pop	rbp
	ret

getXend:
	mov	rax, FALSE
	pop	rbx
	pop	r14
	pop	r13
	pop	r12
	mov	rsp, rbp
	pop	rbp
	ret
	
getXerror1:	
	mov	rdi, errRead
	call 	printString
	jmp	getXend

getXend2:
	mov	byte[eoftwo], TRUE
	mov	rax, TRUE
	pop	rbx
	pop	r14
	pop	r13
	pop	r12
	mov	rsp, rbp
	pop	rbp
	ret

; ***************************************************************
;  Write X array (8 characters) to output file.
;	No requirement to buffer here.

;     NOTE:	for encryption write -> always write 8 characters
;		for decryption write -> exclude any trailing NULLS

;     NOTE:	this routine returns FALSE only if there is an
;		error on write (which would not normally occur).

; -----
;  Arguments are:
;	value of write file descriptor		rdi	r12
;	address of X array			rsi	r13	
;	value of encryption flag		rdx	r14
;  Returns:
;	TRUE or FALSE

global 	writeX
writeX:	
	push 	rbp
	push	r12
	push	r13
	push	r14
	mov	r12, rdi
	mov	r13, rsi
	mov	r14, rdx
	cmp	byte[eoftwo], TRUE
	je	decryptloop
	cmp	r14, TRUE
	je	encryption

decryptloop:
	mov	al, byte[r13]
	cmp	al, NULL
	je	writeXdone
	mov	rax, SYS_write
	mov	rdi, r12
	mov	rsi, r13
	mov	rdx, 1
	syscall
	cmp	rax, 0
	jl	writeXerror
	inc	r13
	jmp	decryptloop
	

encryption:
	mov	rax, SYS_write
	mov	rdi, r12
	mov	rsi, r13
	mov	rdx, 8
	syscall

	cmp	rax, 0
	jl	writeXerror
	;; write error jump here later

writeXdone:	
	mov	rax, TRUE
writeXend:	
	pop	r14
	pop	r13
	pop	r12
	pop	rbp
	ret
	
writeXerror:
	mov	rdi, errWrite
	call 	printString
	mov	rax, FALSE
	jmp 	writeXend
	
	
	


; ***************************************************************
;  Get a encryption/decryption key from user.
;	Key must be between MIN and MAX characters long.

;     NOTE:	must ensure there are no buffer overflow
;		if the user enters >MAX characters
	
; -----
;  Arguments:
;	address of the key buffer		rdi	r12
;	value of key MIN length			rsi	r13
;	value of key MAX length			rdx	r14

global	readKey
readKey:

	
	push 	rbp
	mov	rbp, rsp	
	push	r12
	push	r13
	push	r14
	push	r15
	push	rbx

	mov	r14, rdx
	mov	r13, rsi
	mov	r12, rdi
	
	
readKeystart:	
	mov	rdi, keyPrompt
	call 	printString
	mov 	dword[rbp-62], 0 ;this will be our counter range 62-59
	lea	rbx, byte[rbp-57]
	mov	r15, 0
	
readKeyloop:
	mov	rax, SYS_read
	mov	rdi, STDIN
	mov	rsi, chr
	mov	rdx, 1
	syscall

	mov	al, byte[chr]
	cmp	al, LF
	je 	readKeydone
	cmp	r15, KEY_MAX
	jg	readKeyloop
	mov	byte[r12+r15], al
	inc	r15
	jmp	readKeyloop

readKeydone:
	cmp	r15, KEY_MIN
	jl	KeyError
	cmp	r15, KEY_MAX
	ja	KeyError
	mov	byte[r12+r15], NULL

	pop	rbx
	pop	r15
	pop	r14
	pop	r13
	pop	r12
	mov	rsp, rbp
	pop	rbp
	ret

KeyError:	
	mov	rdi, keyError
	call 	printString
	jmp	readKeystart
	
	
	


; ***************************************************************
;  Generic function to display a string to the screen.
;  String must be NULL terminated.

;  Algorithm:
;	Count characters in string (excluding NULL)
;	Use syscall to output characters

; -----
;  HLL Call:
;	printString(stringAddr);

;  Arguments:
;	1) address, string
;  Returns:
;	nothing

global	printString
printString:

; -----
;  Count characters to write.

	mov	rdx, 0
strCountLoop:
	cmp	byte [rdi+rdx], NULL
	je	strCountLoopDone
	inc	rdx
	jmp	strCountLoop
strCountLoopDone:
	cmp	rdx, 0
	je	printStringDone

; -----
;  Call OS to output string.

	mov	rax, SYS_write			; system code for write()
	mov	rsi, rdi			; address of char to write
	mov	rdi, STDOUT			; file descriptor for std in
						; rdx=count to write, set above
	syscall					; system call

; -----
;  String printed, return to calling routine.

printStringDone:
	ret

; ***************************************************************

