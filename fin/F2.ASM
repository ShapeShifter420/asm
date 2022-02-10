.model tiny
.386
.code
org 100h
start:
jmp main

main:
	mov ah, 0
	mov al, 3
	int 10h
	mov ah,1
    mov ch,20h
    mov cl,20h
    int 10h
	;call initseed
	call recap
	call inithelp
	call setfont
	call initstepmode
	jmp showhelp
	ret
	
	
initstepmode:
	mov kolrow, 23
	mov kolcolumn, 3
	mov oldrow, 23
	mov oldcolumn, 3	
	mov isdigging, 0
	mov isrunning, 0
	mov koldirection, 1
	mov nowleftsym, 180
	mov nowrightsym, 181
	push 0B800h
	pop es
	mov al, 00111111b
	call fillall
	call drawwalls
	call drawkolobok
	ret
	

nowleftsym db 0
nowrightsym db 0
	
	
needticks db 2
kolrow db 23
kolcolumn db 23
oldrow db 0
oldcolumn db 0
kolposition db 0
koldirection db 1
isdigging db 0
isrunning db 1
stepmode:
	mov ah, 05h
	mov al, 0
	int 10h
	mov trig, 0
_sm_loop:
	mov cl, needticks
	cmp trig, cl
	jl _sm_nottriggered
	mov trig, 0
	cmp isrunning, 1
	jne _sm_nottriggered
	call removekolobok
	call makestep
	call changekolsyms
	call drawkolobok
	cmp isdigging, 1
	jne _sm_notdigging
	call dig
	mov di, 700
	mov bx, 33
	call sound
	jmp _sm_notdiggingsound
_sm_notdigging:
	mov di, 300
	mov bx, 33
	call sound
_sm_notdiggingsound:
_sm_nottriggered:
	call getkeyboard
	cmp ah, 01h
	jne _sm_notesc
	call exit
_sm_notesc:
	cmp ah, 3Bh
	jne _sm_notf1
	call showhelp
_sm_notf1:
	cmp ah, 3Dh
	jne _sm_notf3
	mov isdigging, 1
_sm_notf3:
	cmp ah, 3Eh
	jne _sm_notf4
	mov isdigging, 0
_sm_notf4:
	cmp ah, 3Fh
	jne _sm_notf5
	call initstepmode
_sm_notf5:
	cmp ah, 40h
	jne _sm_notf6
	jmp keymode
_sm_notf6:
	cmp ah, 4Dh
	jne _sm_notright
	mov koldirection, 1
_sm_notright:
	cmp ah, 4Bh
	jne _sm_notleft
	mov koldirection, 2
_sm_notleft:
	cmp ah, 48h
	jne _sm_notup
	mov koldirection, 3
_sm_notup:
	cmp ah, 50h
	jne _sm_notdown
	mov koldirection, 4
_sm_notdown:
	cmp ah,4eh
	jne _sm_notplus
	cmp needticks,1
	jl _sm_loop
	dec needticks
_sm_notplus:
	cmp ah,4ah
	jne _sm_notminus
	cmp needticks, 9
	jg _sm_loop
	inc needticks
_sm_notminus:
	cmp ah, 02h
	jne _sm_notone
	mov needticks, 9
_sm_notone:
	cmp ah, 03h
	jne _sm_nottwo
	mov needticks, 8
_sm_nottwo:
	cmp ah, 04h
	jne _sm_notthree
	mov needticks, 7
_sm_notthree:
	cmp ah, 05h
	jne _sm_notfour
	mov needticks, 6
_sm_notfour:
	cmp ah, 06h
	jne _sm_notfive
	mov needticks, 5
_sm_notfive:
	cmp ah, 07h
	jne _sm_notsix
	mov needticks, 4
_sm_notsix:
	cmp ah, 08h
	jne _sm_notseven
	mov needticks, 3
_sm_notseven:
	cmp ah, 09h
	jne _sm_noteight
	mov needticks, 2
_sm_noteight:
	cmp ah, 0Ah
	jne _sm_notnine
	mov needticks, 1
_sm_notnine:
	cmp ah, 39h
	jne _sm_notspace
	mov nowleftsym, 180
	mov nowrightsym, 181
	call drawkolobok
	xor isrunning, 1
_sm_notspace:
	jmp _sm_loop
	ret
	
	
iskeypressed db 0
keymode:
	mov iskeypressed, 0
_km_loop:
	cmp iskeypressed, 1
	jne _km_endneedtostep
	cmp trig, 0
	je _km_endneedtostep
	mov trig, 0
	call removekolobok
	call makestep
	call changekolsyms
	call drawkolobok
	cmp isdigging, 1
	jne _km_notdigging
	call dig
	mov di, 700
	mov bx, 33
	call sound
	jmp _km_notdiggingsound
_km_notdigging:
	mov di, 300
	mov bx, 33
	call sound
_km_notdiggingsound:
_km_endneedtostep:
	call getkeyboard
	cmp ah, 0
	jne _km_notreleased
	mov iskeypressed, 0
_km_notreleased:
	cmp ah, 01h
	jne _km_notesc
	call exit
_km_notesc:
	cmp ah, 3Bh
	jne _km_notf1
	call showhelp
_km_notf1:
	cmp ah, 3Dh
	jne _km_notf3
	mov isdigging, 1
_km_notf3:
	cmp ah, 3Eh
	jne _km_notf4
	mov isdigging, 0
_km_notf4:
	cmp ah, 3Fh
	jne _km_notf5
	call initstepmode
_km_notf5:
	cmp ah, 41h
	jne _km_notf7
	jmp stepmode
_km_notf7:
	cmp ah, 4Dh
	jne _km_notright
	mov iskeypressed, 1
	mov koldirection, 1
_km_notright:
	cmp ah, 4Bh
	jne _km_notleft
	mov iskeypressed, 1
	mov koldirection, 2
_km_notleft:
	cmp ah, 48h
	jne _km_notup
	mov iskeypressed, 1
	mov koldirection, 3
_km_notup:
	cmp ah, 50h
	jne _km_notdown
	mov iskeypressed, 1
	mov koldirection, 4
_km_notdown:
	jmp _km_loop
	ret
	
	
	
dig:	
	mov cx, 0
	mov dx, 0
	;firstsym
	mov cl, kolrow
	mov dl, kolcolumn
	mov al, 80
	mul cl
	add ax, dx
	mov bx, ax
	add bx, bx
	inc bx
	mov byte ptr es:[bx], 00001110b
	;secondsym
	inc dl
	cmp dl, 80
	jne _dig_notkolover
	mov dl, 0
_dig_notkolover:
	mov al, 80
	mul cl
	add ax, dx
	mov bx, ax
	add bx, bx
	inc bx
	mov byte ptr es:[bx], 00001110b	
	ret
	
removekolobok:
	mov cx, 0
	mov dx, 0
	;firstsym
	mov cl, kolrow
	mov dl, kolcolumn
	mov al, 80
	mul cl
	add ax, dx
	mov bx, ax
	add bx, bx
	mov byte ptr es:[bx], ' '
	;secondsym
	inc dl
	cmp dl, 80
	jne _rk_notkolover
	mov dl, 0
_rk_notkolover:
	mov al, 80
	mul cl
	add ax, dx
	mov bx, ax
	add bx, bx
	mov byte ptr es:[bx], ' '
	ret
	
	
changekolsyms:
	cmp koldirection, 1
	jne _cks_notright
	call changesymright
_cks_notright:
	cmp koldirection, 2
	jne _cks_notleft
	call changesymleft
_cks_notleft:
	cmp koldirection, 3
	jne _cks_notup
	call changesymup
_cks_notup:
	cmp koldirection, 4
	jne _cks_notdown
	call changesymdown
_cks_notdown:
	ret
	
changesymright:
	sub nowleftsym, 2
	sub nowrightsym, 2
	cmp nowleftsym, 178
	jne _csr_notoverflow
	mov nowleftsym, 194
	mov nowrightsym, 195
_csr_notoverflow:
	ret
	
changesymleft:
	add nowleftsym, 2
	add nowrightsym, 2
	cmp nowleftsym, 196
	jne _csl_notoverflow
	mov nowleftsym, 180
	mov nowrightsym, 181
_csl_notoverflow:
	ret
	
changesymup:
	cmp nowleftsym, 180
	jne _csu_nottop
	mov nowleftsym, 184
	mov nowrightsym, 185
	jmp _csu_exit
_csu_nottop:
	cmp nowleftsym, 184
	jne _csu_notright
	mov nowleftsym, 180
	mov nowrightsym, 181
	jmp _csu_exit
_csu_notright:
	mov nowleftsym, 180
	mov nowrightsym, 181
	jmp _csu_exit
_csu_exit:
	ret
	
changesymdown:
	cmp nowleftsym, 180
	jne _csd_nottop
	mov nowleftsym, 184
	mov nowrightsym, 185
	jmp _csd_exit
_csd_nottop:
	cmp nowleftsym, 184
	jne _csd_notright
	mov nowleftsym, 180
	mov nowrightsym, 181
	jmp _csd_exit
_csd_notright:
	mov nowleftsym, 184
	mov nowrightsym, 185
_csd_exit:
	ret
	

drawkolobok:
	mov cx, 0
	mov dx, 0
	;firstsym
	mov cl, kolrow
	mov dl, kolcolumn
	mov al, 80
	mul cl
	add ax, dx
	mov bx, ax
	add bx, bx
	mov ch, nowleftsym
	cmp byte ptr es:[bx], 03h
	jne _dk_notbonus1
	pusha
	mov di, 1000
	mov bx, 33
	;call drawbonus
	popa
_dk_notbonus1:
	mov byte ptr es:[bx], ch
	;secondsym
	inc dl
	cmp dl, 80
	jne _dk_notkolover
	mov dl, 0
_dk_notkolover:
	mov al, 80
	mul cl
	add ax, dx
	mov bx, ax
	add bx, bx
	mov ch, nowrightsym
	cmp byte ptr es:[bx], 03h
	jne _dk_notbonus2
	pusha
	mov di, 1000
	mov bx, 33
	;call drawbonus
	popa
_dk_notbonus2:
	mov byte ptr es:[bx], ch
	ret
	
	
	
	
makestep:
	mov dl, kolrow
	mov oldrow, dl
	mov dl, kolcolumn
	mov oldcolumn, dl
	cmp koldirection, 1
	jne _ms_notright
	call makestepright
_ms_notright:
	cmp koldirection, 2
	jne _ms_notleft
	call makestepleft
_ms_notleft:
	cmp koldirection, 3
	jne _ms_notup
	call makestepup
_ms_notup:
	cmp koldirection, 4
	jne _ms_notdown
	call makestepdown
_ms_notdown:
	call checkwallandreturn
	ret
	
	
checkwallandreturn:
	cmp kolrow, 24
	jne _cwr_notbottomoverflow
	cmp kolcolumn, 39
	jge _cwr_return
_cwr_notbottomoverflow:
	cmp kolcolumn, 39
	jl _cwr_exit
	cmp kolrow, 0
	je _cwr_return
	jmp _cwr_exit
_cwr_return:
	mov dl, oldcolumn
	mov kolcolumn, dl
	mov dl, oldrow
	mov kolrow, dl
_cwr_exit:
	ret
	
makestepright:
	inc kolcolumn
	cmp kolcolumn, 80
	jne _msr_notoverflow
	mov kolcolumn, 0
_msr_notoverflow:
	ret
	
makestepleft:
	dec kolcolumn
	cmp kolcolumn, 0FFh
	jne _msl_notoverflow
	mov kolcolumn, 79
_msl_notoverflow:
	ret
	
makestepdown:
	inc kolrow
	cmp kolrow, 25
	jne _msu_notoverflow
	mov kolrow, 0
_msu_notoverflow:
	ret
	
makestepup:
	dec kolrow
	cmp kolrow, 0FFh
	jne _msd_notoverflow
	mov kolrow, 24
_msd_notoverflow:
	ret
	
	
	
	
inithelp:
	push 0B900h
	pop es
	mov al, 00101111b
	call fillall
	mov ch, 00001111b
	;call fillsmall
	ret
	
fillall:
	mov bx, 0
_fillall_loop:
	mov byte ptr es:[bx], ' '
	inc bx
	mov byte ptr es:[bx], al
	inc bx
	cmp bx, 4000
	jl _fillall_loop
	ret
	
	
drawwalls:
	call drawupwall
	call drawbottomwall
	ret

drawupwall:
	push 0B800h
	pop es
	mov cx, 40
	mov dl, 24
_duw_loop:
	mov al, 0
	mul dl
	add ax, cx
	mov bx, ax
	add bx, bx
	inc bx
	mov byte ptr es:[bx], 00011111b
	inc cl
	cmp cl, 79
	jle _duw_loop
	ret
	
drawbottomwall:
	push 0B800h
	pop es
	mov cx, 40
	mov dl, 24
_dbw_loop:
	mov al, 80
	mul dl
	add ax, cx
	mov bx, ax
	add bx, bx
	inc bx
	mov byte ptr es:[bx], 00011111b
	inc cl
	cmp cl, 79
	jle _dbw_loop
	ret
	
showhelp:
	mov ah, 05h
	mov al, 1
	int 10h
	call writetxt
	mov di, 500
	mov bx, 100
	mov di, 1000
	mov bx, 100
_help_loop:
	call getkeyboard
	cmp ah, 01
	jne _help_notesc
	call exit
_help_notesc:
	cmp ah, 3Ch
	jne _help_notf2
	jmp stepmode
_help_notf2:
	jmp _help_loop
	ret
	
exit:
	mov di, 1000
	mov bx, 100
	mov di, 500
	mov bx, 100
	call releasehook
	mov ah, 0
	mov al, 3
	int 10h
	mov ah, 01h
	int 19h
mm equ 1

vi equ mm * 2 + 1
screen_width equ 40 * 2 * (mm + 1)
screen_horizontal_mid equ screen_width / 2
screen_height equ 25
screen_vertical_mid equ screen_height / 2
screen_size equ screen_width * screen_height

position dw screen_width * screen_vertical_mid + screen_horizontal_mid - 2

writetxt proc near
	mov	bx, 0b800h
	mov	es, bx
	mov al, '1'
	mov dx, screen_size + 48 * (mm+1)
	mov di, dx

	xor cx, cx
	xor bx, bx
print_char:
	mov al, help_text[bx]
	cmp al, '&'
	je newline
ok:
	mov ah, 05h
	stosw
	jmp next
newline:
	inc cl
	mov al, screen_width
	mul cl
	mov di, dx
	add di, ax 
	jmp next
next:
	inc bx
	cmp bx, spravka_len
	jnz print_char

	ret


helpp label
help_text db '$         SUPER KOLOBOK&', '&', 'ESC - exit&', 'F1 - help F2 - game&', 'WASD - direction&', '1-9 0 +- speed&', 'SPACE - stop&','F3 F4- dig&','F5 restart&'
help_ts label

trig db 0
intt8old dd 0
intt8:
	inc trig
	jmp cs:intt8old
old08 	dw	0, 0	

spravka_len equ offset help_ts - offset helpp
writetxt endp	
recap:

	push    ds
    xor     bx,bx
    mov     ds,bx

    mov     bx,[ds:0020h]
    mov     es,[ds:0022h]
	pop ds
	mov word ptr intt8old, bx
	mov word ptr intt8old+2, es
	push    ds
    xor     bx,bx
    mov     ds,bx
    lea     bx,[cs:intt8]
    mov     [ds:0020h],bx    
    mov     [ds:0022h],cs
    pop     ds
	ret
	
releasehook:
	cli
	push 0
	pop es
	mov dx, word ptr intt8old
	mov word ptr es:20h, dx
	mov dx, word ptr intt8old+2
	mov word ptr es:22h, dx
	sti
	
getkeyboard:
	mov ah, 01h
	int 16h
	jz _getkeyboard_return_none
	push ax
	mov ah, 00h
	int 16h
	pop ax
	ret
_getkeyboard_return_none:
	mov ah, 00h
	ret
	
	
	
L8: db 03h, 0Ch, 10h, 24h, 2Ah, 4Ah, 44h, 40h, 48h, 26h, 21h, 10h, 0Ch, 03h, 0, 0
R8: db 0C0h, 30h, 08h, 24h, 54h, 52h, 22h, 02h, 12h, 64h, 84h, 08h, 30h, 0C0h, 0, 0
L7: db 03h, 0ch, 10h, 21h, 22h, 43h, 48h, 48h, 48h, 24h, 23h, 10h, 0ch, 03h, 0, 0
R7: db 0c0h, 30h, 08h, 84h, 84h, 32h, 52h, 62h, 02h, 04h, 84h, 08h, 30h, 0c0h, 0, 0
L6: db 03h, 0ch, 10h, 22h, 24h, 48h, 48h, 48h, 48h, 24h, 22h, 10h, 0ch, 03h, 0, 0
R6: db 0c0h, 30h, 08h, 64h, 94h, 62h, 02h, 02h, 62h, 94h, 64h, 08h, 30h, 0c0h, 0, 0
L5: db 03h, 0ch, 10h, 23h, 24h, 48h, 48h, 48h, 43h, 22h, 21h, 10h, 0ch, 03h, 0, 0
R5: db 0c0h, 30h, 08h, 84h, 04h, 02h, 62h, 52h, 32h, 84h, 84h, 08h, 30h, 0c0h, 0, 0
L4: db 03h, 0ch, 10h, 23h, 24h, 48h, 40h, 44h, 4ah, 2ah, 24h, 10h, 0ch, 03h, 0, 0
R4: db 0c0h, 30h, 08h, 0c4h, 24h, 12h, 02h, 22h, 52h, 54h, 24h, 08h, 30h, 0c0h, 0, 0
L3: db 03h, 0ch, 10h, 21h, 20h, 40h, 46h, 4ah, 4ch, 21h, 21h, 10h, 0ch, 03h, 0, 0
R3: db 0c0h, 30h, 08h, 0c4h, 24h, 12h, 12h, 12h, 0c2h, 44h, 84h, 08h, 30h, 0c0h, 0, 0
L2: db 03h, 0ch, 10h, 26h, 29h, 46h, 40h, 40h, 46h, 29h, 26h, 10h, 0ch, 03h, 0, 0
R2: db 0c0h, 30h, 08h, 44h, 24h, 12h, 12h, 12h, 12h, 24h, 44h, 08h, 30h, 0c0h, 0, 0
L1: db 03h, 0ch, 10h, 21h, 21h, 4ch, 4ah, 46h, 40h, 20h, 21h, 10h, 0ch, 03h, 0, 0
R1: db 0c0h, 30h, 08h, 84h, 44h, 0c2h, 12h, 12h, 12h, 24h, 0c4h, 08h, 30h, 0c0h, 0, 0
COINSYM: db 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh

				   
	
setfont:
	mov ah, 11h
	mov al, 0
	push ds
	pop es
	mov bp, offset L1
	mov cx, 1
	mov dx, 180
	mov bl, 0
	mov bh, 16
	int 10h
	push ds
	pop es
	mov bp, offset R1
	mov cx, 1
	mov dx, 181
	mov bl, 0
	mov bh, 16
	int 10h
	push ds
	pop es
	mov bp, offset L2
	mov cx, 1
	mov dx, 182
	mov bl, 0
	mov bh, 16
	int 10h
	push ds
	pop es
	mov bp, offset R2
	mov cx, 1
	mov dx, 183
	mov bl, 0
	mov bh, 16
	int 10h
	push ds
	pop es
	mov bp, offset L3
	mov cx, 1
	mov dx, 184
	mov bl, 0
	mov bh, 16
	int 10h
	push ds
	pop es
	mov bp, offset R3
	mov cx, 1
	mov dx, 185
	mov bl, 0
	mov bh, 16
	int 10h
	push ds
	pop es
	mov bp, offset L4
	mov cx, 1
	mov dx, 186
	mov bl, 0
	mov bh, 16
	int 10h
	push ds
	pop es
	mov bp, offset R4
	mov cx, 1
	mov dx, 187
	mov bl, 0
	mov bh, 16
	int 10h
	push ds
	pop es
	mov bp, offset L5
	mov cx, 1
	mov dx, 188
	mov bl, 0
	mov bh, 16
	int 10h
	push ds
	pop es
	mov bp, offset R5
	mov cx, 1
	mov dx, 189
	mov bl, 0
	mov bh, 16
	int 10h
	push ds
	pop es
	mov bp, offset L6
	mov cx, 1
	mov dx, 190
	mov bl, 0
	mov bh, 16
	int 10h
	push ds
	pop es
	mov bp, offset R6
	mov cx, 1
	mov dx, 191
	mov bl, 0
	mov bh, 16
	int 10h
	push ds
	pop es
	mov bp, offset L7
	mov cx, 1
	mov dx, 192
	mov bl, 0
	mov bh, 16
	int 10h
	push ds
	pop es
	mov bp, offset R7
	mov cx, 1
	mov dx, 193
	mov bl, 0
	mov bh, 16
	int 10h
	push ds
	pop es
	mov bp, offset L8
	mov cx, 1
	mov dx, 194
	mov bl, 0
	mov bh, 16
	int 10h
	push ds
	pop es
	mov bp, offset R8
	mov cx, 1
	mov dx, 195
	mov bl, 0
	mov bh, 16
	int 10h
	push ds
	pop es
	mov bp, offset COINSYM
	mov cx, 1
	mov dx, 196
	mov bl, 0
	mov bh, 16
	int 10h
	ret

sound:	
	push AX
	push BX
	push CX
	push DX
	push DI
	mov AL, 0B6H
	out 43H, AL
	mov DX, 14H 
	mov AX, 4F38H
	div DI
	out 42h, AL
	mov AL, AH
	out 42H, AL
	in AL, 61H
	mov AH, AL
	or AL, 3
	out 61H, AL
	_MS_WAIT:
	mov CX, 2000
	_MS_SPKR_ON: 
	loop _MS_SPKR_ON
	dec BX
	jnz _MS_WAIT
	mov AL, AH
	out 61H, AL
	pop DI
	pop DX
	pop CX 
	pop BX
	pop AX
	ret
	
end start 