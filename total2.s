.data
mmm: .string "Некоректные данные\n"
.align 4
_pi: .long 0
str1:
	.ascii "%i\n"
.globl main
.text
main:
	#Преобразование аргумента
	pop %rsi
	pop %rsi
	pop %rsi
#	lodsb
#	sub $48,%eax
	mov $30,%rsi
	cvtsi2ss %rsi, %xmm0
	#Обозначение базовых переменных
	mov $1, %edi
	cvtsi2ss %edi,%xmm3 #текущее простое число
	cvtsi2ss %edi,%xmm4 #текущий факториал
	cvtsi2ss %edi,%xmm5 #текущий знак
	mov $-1, %edi
	cvtsi2ss %edi,%xmm6 #-1
	mov $0, %edi
	cvtsi2ss %edi,%xmm7 #текущий x
	cvtsi2ss %edi,%xmm8 #ответ
	mov $1, %edi
	cvtsi2ss %edi,%xmm10
	#Вычисление pi
	finit
	fldpi
	fst _pi
	movss _pi, %xmm2
	
	#Вычисление множителя для градуса
	mov $180, %edi
	cvtsi2ss %edi,%xmm1
	divss %xmm1,%xmm2
	
	mulss %xmm2,%xmm0
	movss %xmm0,%xmm7
	mov $0, %rbx
	
	
	#функция тейлора
	t1:
	add $1,%rbx
	movss %xmm8,%xmm9
	addss %xmm7,%xmm8
	comiss %xmm8,%xmm9
	je fin
	jmp pow
	t2:
	jmp f1
	t3:
	mulss %xmm6,%xmm5
	
	mulss %xmm5,%xmm7
	
	jmp t1
	
	
	f1:
	addss %xmm10,%xmm3
	divss %xmm3,%xmm7
	addss %xmm10,%xmm3
	divss %xmm3,%xmm7
	jmp t3
	
	pow:
	mulss %xmm0,%xmm7
	mulss %xmm0,%xmm7
	jmp t2
	
	
	
	#вывод
	fin:
#	mov %rbx,%rsi
#	mov  $str2, %rdi
#	mov  $0, %eax
#	call printf
	
	mov $1000000000,%edi
	cvtsi2ss %edi,%xmm1
	mulss %xmm1,%xmm8
	cvtss2si %xmm8,%rsi
  	mov  $str1, %rdi
 	mov  $0, %eax
	call printf
	
	mov $60, %eax
	xor %edi,%edi
	syscall
	err:
	mov $60, %eax
	xor %edi,%edi
	syscall
	error:
	mov $10,%rbx
	mov $0,%rax
	div %rbx
	mov $mmm,%rdi
	
