.model tiny
.code
org 100h
locals @@
key_vector equ 9
timer_vector equ 8

pushr macro
	push ax
	push bx
	push cx
	push dx
    push SP
    push BP
    push SI
    push DI
	push es
	push ds
endm

popr macro
	pop ds
	pop es
    pop DI
    pop SI
    pop BP
    pop SP
	pop dx
	pop cx
	pop bx
	pop ax
endm

ccall macro func
	pushr
	call func
	popr
endm


_start:
jmp	begin

buffer	db 6 dup (0)
buflen equ 6
head	dw	offset buffer
tail	dw	offset buffer


; 0: 40x25   1: 80x25
mode equ 1

video_mode equ mode * 2 + 1
screen_width equ 40 * 2 * (mode + 1)
screen_horizontal_mid equ screen_width / 2
screen_height equ 25
screen_vertical_mid equ screen_height / 2
screen_size equ screen_width * screen_height

position dw screen_width * screen_vertical_mid + screen_horizontal_mid - 2

ticks	dw	0
max_ticks dw 3
old_max_ticks dw max_ticks

propeller_frame_start label near
; propeller_frames db '|/-\'
; propeller_frames db 179, '/', 196, '\'
propeller_frames db 10h, 11h, 12h, 13h, 14h, 15h,  16h, 17h,  18h, 19h,  1ah, 1bh,  1ch, 1dh, 1eh, 1fh
; propeller_frames db '.oO@*'
; propeller_frames db 'p', 'd', 'b', 'o'
; propeller_frames db '|[/-\]'
; propeller_frames db '|[{(COo.oOD)}]'
; propeller_frames db '|[{(|)}]'

propeller_frame_end label	near            ;метка конца кода
propeller_frame_count  equ     offset propeller_frame_end - offset propeller_frame_start
propeller_frame_current dw 0

cmd_vectors	dw 0h
			dw offset timer_tick
			dw offset switch_spravka
			dw offset speed
			dw offset speed
			dw offset speed
			dw offset speed
			dw offset change_direction
			dw offset change_direction
			dw offset change_direction
			dw offset change_direction
			dw offset change_direction

			dw offset step
			dw offset step
			dw offset step
			dw offset step

			dw offset speed_keys
			dw offset speed_keys

			dw offset restart
			dw offset dig

			dw offset ai_walk

; --------------------------------
direction db 0
is_autowalk db 0
is_ai_walk db 0
is_digging db 0

under dw 0, 0 ; under left and right halfs ah-color; al-symbol

wall_color db 0c0h
wall_char db 0b0h
grass_color db 20h
dirt_color db 60h

move_count db 0
egg_pos dw screen_width * screen_vertical_mid + screen_horizontal_mid - 2
score db 0
egg_char db 01h
egg_spawn_rate equ 42
score_position dw screen_width * (screen_height-2) + 2

change_direction proc
	sub al, 7
	mov direction, al
	mov is_autowalk, 1
	mov is_ai_walk, 0
	ret
change_direction endp

step proc
	sub al, 12
	add al, 1 ; skipping 0 dir
	mov direction, al
	mov is_autowalk, 0
	mov is_ai_walk, 0
	ret
step endp

speed_keys proc
	sub al, 16
	mov ah, 2
	mul ah
	dec ax ; -1 1

	mov bx, max_ticks
	add bx, ax
	cmp bx, 0
	jl @@nothing
	cmp bx, 9
	jg @@nothing
	mov max_ticks, bx
@@nothing:
	ret
speed_keys endp

restart proc
	mov position, screen_width * screen_vertical_mid + screen_horizontal_mid - 2
	mov direction, 0
	mov is_ai_walk, 0
	mov direction_left, 1
	mov direction_right, 2
	mov direction_up, 3
	mov direction_down, 4
	mov is_autowalk, 0
	mov move_count, 0
	mov egg_pos, screen_width * screen_vertical_mid + screen_horizontal_mid - 2
	mov score, 0
	mov under[0], 0
	mov under[2], 0
	mov propeller_frame_current, 0
	mov ticks,	0
	mov max_ticks, 3
	mov ax, max_ticks
	mov old_max_ticks, ax
	mov is_digging, 0
	; buffer db 6 dup (0)
	ccall draw_grass
	ccall draw_score
	ret
restart endp

draw_grass proc
	mov bx, 0b800h
	mov es, bx
	mov ah, grass_color
	mov al, 0h
	xor di, di
	mov cx, screen_width / 2 * screen_height
@@l:
	stosw
	loop @@l

; draw walls
	mov di, screen_width * (screen_height - 1) + screen_width / 2
	mov ah, wall_color
	mov al, wall_char
	mov cx, screen_width / 4
@@hline:
	stosw
	loop @@hline

	mov di, screen_width - 4
	mov ah, wall_color
	mov al, wall_char
	mov cx, screen_height / 2
@@vline:
	stosw
	stosw
	add di, screen_width - 4
	loop @@vline

	mov di, screen_width * 2 + screen_width / 4
	mov ah, wall_color
	mov al, wall_char
	mov cx, screen_height / 4
@@vline2:
	stosw
	stosw
	add di, screen_width - 4
	loop @@vline2

	mov di, screen_width * 4 + screen_width / 8
	mov ah, wall_color
	mov al, wall_char
	mov cx, screen_width / 8
@@hline2:
	stosw
	loop @@hline2

	ret
draw_grass endp

dig proc
	cmp is_digging, 0
	je @@to_dig
	mov is_digging, 0
	jmp @@f
@@to_dig:
	mov is_digging, 1
@@f:
	ret
dig endp

ai_walk proc
	cmp is_ai_walk, 0
	je @@to_ai
	mov is_ai_walk, 0
	mov direction, 0
	mov is_autowalk, 0
	jmp @@f
@@to_ai:
	mov is_ai_walk, 1
	mov is_autowalk, 1
@@f:
	ret
ai_walk endp

direction_left db 1
direction_right db 2
direction_up db 3
direction_down db 4

find_free_neighbour_left_hand proc
	; L R U D
	; 1 2 3 4
	mov direction_left, 1
	mov direction_right, 2
	mov direction_up, 3
	mov direction_down, 4

;	\/ 4
	; L R U D
	; 2 1 4 3
	cmp direction, 4
	jne @@next1
	mov direction_left, 2
	mov direction_right, 1
	mov direction_up, 4
	mov direction_down, 3
	jmp @@find
@@next1:

;	> 2
	; L R U D
	; 3 4 2 1
	cmp direction, 2
	jne @@next2
	mov direction_left, 3
	mov direction_right, 4
	mov direction_up, 2
	mov direction_down, 1
	jmp @@find
@@next2:

;	^ 3
	; L R U D
	; 1 2 3 4
	cmp direction, 3
	jne @@next3
	mov direction_left, 1
	mov direction_right, 2
	mov direction_up, 3
	mov direction_down, 4
	jmp @@find
@@next3:
	
;	< 1
	; L R U D
	; 4 3 1 2
	cmp direction, 1
	jne @@next4
	mov direction_left, 4
	mov direction_right, 3
	mov direction_up, 1
	mov direction_down, 2
	jmp @@find
@@next4:

@@find:
	;  Always turn left if you can
	mov cl, direction_left
	call check_direction_free
	jc @@free_found

	; If you cannot turn left, go straight
	mov cl, direction_up
	call check_direction_free
	jc @@free_found

	; If you cannot turn left, or go straight, turn right
	mov cl, direction_right
	call check_direction_free
	jc @@free_found

	; If you cannot turn left, go straight, or turn right, turn around because you must be at a dead end
	mov cl, direction_down
	call check_direction_free
	jc @@free_found

@@not_found:
	clc
	ret
@@free_found:
	stc
	ret
find_free_neighbour_left_hand endp

check_direction_free proc
	call get_next_position
	push ds
	push si
	mov bx, 0b800h
	mov ds, bx
	lodsw ; ax <- ds:si
	mov bx, ax
	lodsw ; ax <- ds:si
	pop si
	pop ds
	cmp ah, dirt_color
	jne @@restricted
	cmp bh, dirt_color
	jne @@restricted
@@free:
	stc
	ret
@@restricted:
	clc
	ret
check_direction_free endp

get_next_position proc
	push es
	mov	bx, 0b800h
	mov	es, bx
	mov si, position

	mov ax, position
	mov dl, screen_width
	div dl ; al /     ah %

	cmp cl, 0
	jz @@f
	cmp cl, 1
	jz @@left
	cmp cl, 2
	jz @@right
	cmp cl, 3
	jz @@up
	cmp cl, 4
	jz @@down

@@left:
	sub si, 2
	cmp ah, 0   ; |*   |  
	jnz @@f
	mov si, position
	add si, screen_width - 2 * 2
	jmp @@f
@@right:
	add si, 2
	cmp ah, screen_width - 2 * 2   ; |   *|  
	jnz @@f
	mov si, position
	sub si, screen_width - 2 * 2
	jmp @@f
@@up:
	sub si, screen_width
	cmp al, 0
	jnz @@f
	mov si, position
	add si, screen_width * (screen_height - 1)
	jmp @@f
@@down:
	add si, screen_width
	cmp al, screen_height - 1
	jnz @@f
	mov si, position
	sub si, screen_width * (screen_height - 1)
	jmp @@f

@@f:
	pop es
	ret
get_next_position endp

spawn_egg proc
	mov al, move_count
	inc al
	cmp move_count, egg_spawn_rate
	jl @@not_ready
	ccall draw_egg
	mov ax, position
	mov egg_pos, ax ; save pos for later
	xor ax,	ax
@@not_ready:
	mov move_count, al
	ret
spawn_egg endp

draw_egg proc
	mov bx, 0b800h
	mov es, bx
	mov di, egg_pos
	mov al, egg_char
	stosb

	ret
draw_egg endp

draw_score proc
	mov bx, 0b800h
	mov es, bx
	mov di, score_position
	xor ax, ax
	xor cx, cx
	mov al, score
	mov bl, 10
@@l:
	div bl ; al //    ah %
	xor dx, dx
	mov dl, ah
	xor ah, ah
	push dx
	inc cx
	cmp al, 0
	jg @@l

@@r:
	pop ax
	add al, 30h
	mov ah, 24h
	stosw
	loop @@r

	ret
draw_score endp

score_str db '___.'

key_int proc
	push ax
	push di
	push es

	mov cx, ds
	mov es, cx ; ВОТ В ЧЕМ БЫЛА ПРОБЛЕМА es 0000 а ds 6028

	mov di, offset buffer; addr of buffer

	in al, 60h ; scan from Key board
	cmp al, 1
	je @@esc

	xor cl, cl
	cmp al, 0bh
	je @@key0
	cmp al, 02h
	je @@key1
	cmp al, 03h
	je @@key2
	cmp al, 04h
	je @@key3
	cmp al, 3bh
	je @@key_spravka
	cmp al, 39h
	je @@key_space
	cmp al, 4bh	; cbh
	je @@key_left
	cmp al, 4dh	; cdh
	je @@key_right
	cmp al, 48h	; c8h
	je @@key_up
	cmp al, 50h	; d0h
	je @@key_down

	cmp al, 1eh
	je @@key_A
	cmp al, 11h
	je @@key_W
	cmp al, 1fh
	je @@key_S
	cmp al, 20h
	je @@key_D

	cmp al, 0ch
	je @@minus
	cmp al, 0dh
	je @@plus

	cmp al, 0eh
	je @@backspace

	cmp al, 1ch
	je @@enter

	cmp al, 0fh
	je @@tab

	jmp skip

@@esc:
	mov al, 0 ; command
	jmp save

@@key3:
	inc cl
@@key2:
	inc cl
@@key1:
	inc cl
@@key0:
	add cl, 3 ; base cmd
	mov al, cl
	jmp save

@@key_spravka:
	mov al, 2
	jmp save

@@key_space:
	mov al, 7
	jmp save
@@key_left:
	mov al, 8
	jmp save
@@key_right:
	mov al, 9
	jmp save
@@key_up:
	mov al, 10
	jmp save
@@key_down:
	mov al, 11
	jmp save

@@key_A:
	mov al, 12
	jmp save
@@key_W:
	mov al, 14
	jmp save
@@key_S:
	mov al, 15
	jmp save
@@key_D:
	mov al, 13
	jmp save

@@minus:
	mov al, 16
	jmp save
@@plus:
	mov al, 17
	jmp save

@@backspace:
	mov al, 18
	jmp save

@@enter:
	mov al, 19
	jmp save

@@tab:
	mov al, 20
	jmp save

save:
	call to_buffer
skip:
	pop	es
	pop di
	in	al, 61h ; al <- port   ввод порта PB
	mov ah, al
	or al, 80h ; установить бит "подтверждение ввода"
	out 61h, al ; port <- al
	xchg ah, al
	out 61h, al
	mov al, 20h
	out 20h, al
	pop ax

	iret
	
	; db	0eah
key_int_old_addr	dw	0, 0
key_int endp
; --------------------------------

timer_int proc near
	push ax
	push es

	mov cx, ds
	mov es, cx ; ВОТ В ЧЕМ БЫЛА ПРОБЛЕМА es 0000 а ds 6028

	mov bx, ticks
	inc bx
	cmp bx, max_ticks
	jb @@1
	ja @@reset
	mov ax, 1
    call to_buffer ; al -> 
@@reset:
	mov bx, 0
@@1:
	mov ticks, bx

; interupt accept!!!
	mov al, 20h
	out 20h, al
	pop es
	pop ax
	iret
	; db	0eah		
timer_int_old_addr	dw	0, 0
timer_int endp
; --------------------------------


begin proc near
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    ; intercept      ; INTERCEPT VECTOR
	; INT TIMER
	push	ds		; 6028

	mov	si,	4*timer_vector ; vector addr 4 byte si point to 9th vector
	mov	di,	offset timer_int_old_addr ; 0104
	xor	ax,	ax
	mov	ds,	ax		; int table 0000

					; old_addr	<- addr int 9
	movsw			; 6028:0104 <- 0000:0024	; 	ES:DI   <- 	 DS:SI
	movsw			; 6028:0106 <- 0000:0026  
	push	ds
	push	es
	pop	ds	; 6028
	pop	es	; 0000
	mov	di,	4*timer_vector
	mov	ax,	offset timer_int ; 0103
	cli
			; int 9 	<- my_int
	stosw 	; 0000:0024	<- 0103	 ES:DI <- AX
	mov	ax,	cs	; 6028
	stosw	; 0000:0026	<- 6028
	sti

	pop es
	push	es		; 6028
;	INT KEY
	mov	si,	4*key_vector ; vector addr 4 byte si point to 9th vector
	mov	di,	offset key_int_old_addr ; 0104
	xor	ax,	ax
	mov	ds,	ax		; int table 0000

					; old_addr	<- addr int 9
	movsw			; 6028:0104 <- 0000:0024	; 	ES:DI   <- 	 DS:SI
	movsw			; 6028:0106 <- 0000:0026  
	push	ds
	push	es
	pop	ds	; 6028
	pop	es	; 0000
	mov	di,	4*key_vector
	mov	ax,	offset key_int ; 0103
	cli
			; int 9 	<- my_int
	stosw 	; 0000:0024	<- 0103	 ES:DI <- AX
	mov	ax,	cs	; 6028
	stosw	; 0000:0026	<- 6028
	sti

;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

push es
; перевести видеоподсистему в режим №1
mov ah, 00h
mov al, video_mode
int 10h
; ; убрать курсор
mov ah, 01h
mov ch, 01h
mov cl, 00h
int 10h
; load sprites
mov ah, 11h
mov al, 00h ; user font
mov bx, ds
mov es, bx ; es:bp table
mov bp, sprite
mov cx, sprites_count * sprite_parts ; char count 
mov dx, 16 ; table char (letter) offset
mov bl, 0 ; font block (0-3)
mov bh, 8 * 2 ; bytes per char
int 10h
; display page
ccall draw_spravka
ccall switch_spravka

ccall restart

@@1:
	hlt ; TODO HALT FOR SLEEP
    ; exits if interrupt occurs
	; int 08h

    call from_buffer ; al <- if carry
	; 0 - exit
	; 1 - timer
	; 2 - spravka/game
	; 3 - speed 0
	; 4 - 1
	; 5 - 2
	; 6 - 3
	; 7 - stop
	; 8 - left
	; 9 - right
	; 10 - up
	; 11 - down
	; 12 - A
	; 13 - W
	; 14 - S
	; 15 - D
	; 16 - -
	; 17 - +
	; 18 - reload
	; 19 - dig
	; 20 - AI walk


    jnc @@1   ; jump carry flag CF == 0
	clc

	cmp al, 0
	jz @@exit
	
; cmd table
	xor bx, bx
    mov bl, al
    shl bx, 1 ; *2 dw 
    ccall cmd_vectors[bx]
	jmp @@1

; ------------------------

speed:
	sub	al,	3
	xor	ah, ah
	mov max_ticks,	ax
	ret
; ------------------------
@@exit:
	pop es
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    ; revert     ; REVER INTERCEPT VECTOR
	; INT TIMER
	mov	di,	4*timer_vector
	mov	si,	offset timer_int_old_addr
	cli
	movsw ; 	ES:DI   <- 	 DS:SI
	movsw
	sti
	; INT KEYBOARD
	mov	di,	4*key_vector
	mov	si,	offset key_int_old_addr
	cli
	movsw ; 	ES:DI   <- 	 DS:SI
	movsw
	sti

	pop	es
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
; cls
	mov ah, 00h
	mov al, 3
	int 10h

    ret
begin endp
; --------------------------------


switch_spravka proc near
	mov al, is_spavka
	cmp al, 0
	je to_spavka
	jmp to_game
to_spavka:
	mov al, 1
	mov is_spavka, al
	mov ax, max_ticks
	mov old_max_ticks, ax
	mov max_ticks, 0
	jmp switch_page
to_game:
	mov al, 0
	mov is_spavka, al
	mov ax, old_max_ticks
	mov max_ticks, ax
	jmp switch_page

switch_page:
	mov ah, 05h
	mov al, is_spavka
	int 10h
	ret	

is_spavka db 0
switch_spravka endp

draw_spravka proc near
	mov	bx, 0b800h
	mov	es, bx
	mov al, '1'
	mov dx, screen_size + 48 * (mode+1) ; 48 is magic const???
	mov di, dx

	xor cx, cx ; line
	xor bx, bx ; char
print_char:
	mov al, spravka[bx]
	cmp al, '$'
	je newline
ok:
	mov ah, 0fh
	stosw
	jmp next
newline:
	inc cl
	mov al, screen_width
	mul cl  ; ax = cl * al
	mov di, dx ; base
	add di, ax ; + line
	jmp next
next:
	inc bx
	cmp bx, spravka_len
	jnz print_char

	ret


spravka_start label
spravka db '$ KALAB', 12h, 13h, 'K THE GAME$', '$', '   ESC - exit$', '   F1 - info/game$', '   UP/DOWN/LEFT/RIGHT - auto walk$', '   A/W/S/D - step$', '   HOLD A/W/S/D - walk$', '   SPACE - stay$', '   1...4 - delay$', '   0 - stop$',  '   -/+ - delay$', '   BACKSPACE - restart$', '   ENTER - dig mode$' , '   TAB - auto walk$' , '$$$by irusland'
spravka_end label

spravka_len equ offset spravka_end - offset spravka_start
draw_spravka endp


timer_tick proc near
	cmp is_ai_walk, 1
	jne @@human
	cli
	call find_free_neighbour_left_hand
	sti
	jnc @@not_found
	mov direction, cl
	jmp @@human
@@not_found:
	mov is_ai_walk, 0
	mov is_autowalk, 0
	mov direction, 0
@@human:
	mov	bx, 0b800h
	mov	es, bx
	mov si, position
	
	mov bx, propeller_frame_current

	mov ax, position
	mov cl, screen_width
	div cl ; al /     ah %

	mov dl, direction
	cmp dl, 0
	jz @@stop
	
	ccall spawn_egg ; has direction

	cmp dl, 1
	jz @@left
	cmp dl, 2
	jz @@right
	cmp dl, 3
	jz @@up
	cmp dl, 4
	jz @@down

@@stop:
	xor bx, bx
	mov propeller_frame_current, bx
	jmp @@f
@@left:
	sub bx, 2
	sub si, 2
	cmp ah, 0   ; |*   |  
	jnz @@f
	mov si, position
	add si, screen_width - 2 * 2
	jmp @@f
@@right:
	add bx, 2
	add si, 2
	cmp ah, screen_width - 2 * 2   ; |   *|  
	jnz @@f
	mov si, position
	sub si, screen_width - 2 * 2
	jmp @@f
@@up:
	sub bx, 2
	sub si, screen_width
	cmp al, 0
	jnz @@f
	mov si, position
	add si, screen_width * (screen_height - 1)
	jmp @@f
@@down:
	add bx, 2
	add si, screen_width
	cmp al, screen_height - 1
	jnz @@f
	mov si, position
	sub si, screen_width * (screen_height - 1)
	jmp @@f

@@f:
	cmp bx, propeller_frame_count
	jge @@reset_frames_start
	cmp bx, 0
	jl @@reset_frames_end
	jmp @@ok
@@reset_frames_start:
	mov bx, 0 ; frame 0
	jmp @@ok
@@reset_frames_end:
	mov bx, propeller_frame_count - 2
@@ok:

	; check walls
	push ds
	push si
	mov cx, 0b800h
	mov ds, cx
	lodsw ; ax <- ds:si
	mov cx, ax
	lodsw ; ax <- ds:si
	pop si
	pop ds
	cmp ah, wall_color
	je @@restricted
	cmp ch, wall_color
	je @@restricted

	; if digging
	cmp is_digging, 0
	je @@no_dig
	mov al, 0h
	mov ah, dirt_color
	mov under + 2, ax
	mov under, ax
@@no_dig:

	; draw under curr
	mov di, position
	mov ax, under + 2
	cmp ax, 0
	je @@under_skip
	stosw
	mov ax, under
	cmp ax, 0
	je @@under_skip
	stosw
@@under_skip:

	; save under next
	push ds
	push si
	mov cx, 0b800h
	mov ds, cx
	lodsw ; ax <- ds:si
	mov cx, ax
	lodsw ; ax <- ds:si
	pop si
	pop ds
	mov under + 2, cx
	mov under, ax

	cmp cl, egg_char
	je @@has_egg
	cmp al, egg_char
	je @@has_egg
	jmp @@no_egg
@@has_egg:
	cmp is_digging, 0
	je @@no_egg
	mov cl, score
	inc cl
	mov score, cl
@@no_egg:
	ccall draw_score

	mov position, si
@@restricted:
	mov	di, position ; screen char position

	mov ax, under + 2
	mov propeller_frame_current, bx
	mov al, propeller_frames[bx]
	stosw ; ax -> es:di
	mov ax, under
	mov al, propeller_frames[bx + 1]
	stosw ; ax -> es:di

	cmp is_autowalk, 1
	je @@auto
	mov direction, 0  ; AWSD step
@@auto:
	ret
timer_tick endp


intercept macro
	mov	si,	4*timer_vector ; vector addr 4 byte si point to 9th vector
	mov	di,	offset timer_int_old_addr ; 0104
	push	ds		; 6028
	xor	ax,	ax
	mov	ds,	ax		; int table 0000

					; old_addr	<- addr int 9
	movsw			; 6028:0104 <- 0000:0024	; 	ES:DI   <- 	 DS:SI
	movsw			; 6028:0106 <- 0000:0026  
	push	ds
	push	es
	pop	ds	; 6028
	pop	es	; 0000
	mov	di,	4*timer_vector
	mov	ax,	offset timer_int ; 0103
	cli
			; int 9 	<- my_int
	stosw 	; 0000:0024	<- 0103	 ES:DI <- AX
	mov	ax,	cs	; 6028
	stosw	; 0000:0026	<- 6028
	sti
endm
; --------------------------------

revert macro
	mov	di,	4*timer_vector
	mov	si,	offset timer_int_old_addr
	cli
	movsw ; 	ES:DI   <- 	 DS:SI
	movsw
	sti
	pop	es
endm


to_buffer proc near ; al -> buffer[tail+1]
	mov	bx,	tail
	inc	bx          ; bx is next
	cmp	bx,	offset buffer + buflen
	jnz	@@1
	mov	bx,	offset buffer

@@1:
	cmp	bx,	head 
	jz	@@2         ; next is head => FULL
	mov	di,	tail
	stosb           ; es:di <- al
	mov	tail,	bx  ; tail += 1 mod buflen
	stc             ; set carry
	ret         ; ADDED

@@2:            ; FULL was not added
	clc             ; clear carry
	ret
to_buffer endp
; --------------------------------
makesound:	
	PUSH AX
	PUSH BX
	PUSH CX
	PUSH DX
	PUSH DI
	MOV AL, 0B6H
	OUT 43H, AL
	MOV DX, 14H 
	MOV AX, 4F38H
	DIV DI
	OUT 42h, AL
	MOV AL, AH
	OUT 42H, AL
	IN AL, 61H
	MOV AH, AL
	OR AL, 3
	OUT 61H, AL
	_MS_WAIT:
	MOV CX, 2801
	_MS_SPKR_ON: 
	LOOP _MS_SPKR_ON
	DEC BX
	JNZ _MS_WAIT
	MOV AL, AH
	OUT 61H, AL
	POP DI
	POP DX
	POP CX 
	POP BX
	POP AX
	RET

from_buffer proc near ; buffer[head] -> al
	mov	bx,	head
	mov dx, tail
    cmp bx, dx
    jz @@empty 

	inc bx
	cmp	bx,	offset buffer + buflen
	jnz	@@has_new
	mov	bx,	offset buffer

@@has_new:
	mov	si,	head
    lodsb       ; al <- ds:si
	mov	head,	bx  ; tail += 1 mod buflen
    stc
    ret
@@empty:
    clc
	ret

from_buffer endp
; --------------------------------

; SPRITES -----
sprite_parts equ 2
sprite_part_size equ 16
sprites_count equ 8
sprite_size equ sprite_part_size * sprite_parts
sprites_size equ sprite_size * sprites_count

sprites_start label
include sprite.asm
sprites_end label

sprites_max equ offset sprites_end
sprite dw offset sprites_start
; SPRITES -----

end _start
