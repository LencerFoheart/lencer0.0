#
# Small/boot/head.s
#
# (C) 2012-2013 Yafei Zheng
# V0.0 2012-12-7 10:44:39
#
# Email: e9999e@163.com, QQ: 1039332004
#

.globl startup_32

LATCH		= 11930				# ��ʱ����ʼ����ֵ����10����
SCRN_SEL	= 0x18				# ��Ļ��ʾ�ڴ��ѡ���
TSS0_SEL	= 0X20
LDT0_SEL	= 0X28
TSS1_SEL	= 0x30
LDT1_SEL	= 0X38
NO_TASK		= 111				# current==NO_TASK ��ʾ��ǰ��δ��ʼִ���κ�����

.text
startup_32:
	movl	$0x10,%eax
	mov		%ax,%ds
	lss		init_stack,%esp
# ���µ�λ����������GDT,IDT
	call	setup_gdt
	call	setup_idt
	movl	$0x10,%eax
	mov		%ax,%ds
	mov		%ax,%es
	mov		%ax,%fs
	mov		%ax,%gs
	lss		init_stack,%esp
# ����8253��ʱ��оƬ��ÿ10���뷢��һ��ʱ���ж��ź�
	movb	$0x36,%al
	outb	%al,$0x43
	movw	$LATCH,%ax
	outb	%al,$0x40
	movb	%ah,%al
	outb	%al,$0x40
# OK! We move to the user-mode and run task0 now.
	pushfl
	andl	$0xffffbfff,(%esp)	# ��λ���¼Ĵ�����Ƕ�������־λNT
	popfl
	movl	$LDT0_SEL,%eax
	lldt	%ax
	movl	$TSS0_SEL,%eax
	ltr		%ax
	movl	$NO_TASK,current
	movl	$0,scr_loc
	sti							# ע�⣬�˴����ж�Ҫ��pushfl֮ǰ����������
	movl	$0x17,%eax
	mov		%ax,%ds
	mov		%ax,%es		
	mov		%ax,%fs
	mov		%ax,%gs
	mov		%esp,%eax
	pushl	$0x17
	pushl	%eax
	pushfl
	pushl	$0x0f
	pushl	$task0
	iretl

# ----------------------------------------------------
.align 4
setup_gdt:
	lgdt	gdt_new_48
	ret

.align 4
setup_idt:
	pushl	%edx
	pushl	%eax
	pushl	%ecx
	pushl	%edi
	lea		ignore_int,%edx
	movl	$0x00080000,%eax
	mov		%dx,%ax
	movw	$0x8e00,%dx			# �ж������ͣ���Ȩ��0
	lea		idt,%edi
	movl	$256,%ecx
rp:	movl	%eax,(%edi)
	movl	%edx,4(%edi)
	addl	$8,%edi
	dec		%ecx
	cmpl	$0,%ecx
	jne		rp
	lea		timer_int,%edx		# ����ʱ���ж���������
	mov		%dx,%ax
	movw	$0x8e00,%dx			# �ж������ͣ���Ȩ��0
	movl	$0x08,%ecx
	lea		idt(,%ecx,8),%edi
	movl	%eax,(%edi)
	movl	%edx,4(%edi)
	lea		system_call,%edx	# ����ϵͳ����������������
	mov		%dx,%ax
	movw	$0xef00,%dx			# ���������ͣ���Ȩ��3
	movl	$0x80,%ecx
	lea		idt(,%ecx,8),%edi
	movl	%eax,(%edi)
	movl	%edx,4(%edi)		
	lidt	idt_new_48
	popl	%edi
	popl	%ecx
	popl	%eax
	popl	%edx
	ret

.align 4
write_char:
	pushl	%ebx
	pushl	%gs
	movw	$SCRN_SEL,%bx
	mov		%bx,%gs
	movl	scr_loc,%ebx
	shl		$1,%ebx
	movw	%ax,%gs:(%ebx)
	shr		$1,%ebx
	inc		%ebx
	cmpl	$2000,%ebx
	jne		1f
	movl	$0,%ebx
1:	movl	%ebx,scr_loc
	popl	%gs
	popl	%ebx
	ret

.align 4
ignore_int:
	pushl	%ds
	pushl	%eax	
	pushl	%ebx
	pushl	%ecx
	pushl	%edx
	movl	$0x0449,%eax		# �ַ�"I"�����ԣ���ɫ �ڵ� ����˸ ������
	movl	$0x10,%ebx
	mov		%bx,%ds
	call	write_char
	xorb	%al,%al
	inb		$0x64,%al			# 8042������64h�˿�λ0���鿴��������Ƿ��������������һ���ַ�
	andb	$0x01,%al
	cmpb	$0, %al
	je		1f
	inb		$0x60,%al			# ���������������һ���ַ�
# ����ע�͵Ĵ��������μ������룬Ȼ�����������ڸ�λ�������롣��8042��Ҳ���Բ���
#	inb		$0x61,%al
#	orb		$0x80,%al
#	.word	0x00eb,0x00eb		# �˴���2��jmp $+2��$Ϊ��ǰָ���ַ������ʱ���ã���ͬ
#	outb	%al,$0x61
#	andb	$0x7f,%al
#	.word	0x00eb,0x00eb
#	outb	%al,$0x61
1:	movb	$0x20,%al			# ��8259A��оƬ����EOI����,����ISR�е���Ӧλ����
	outb	%al,$0x20
	popl	%edx
	popl	%ecx
	popl	%ebx
	popl	%eax
	popl	%ds
	iret

.align 4
timer_int:
	pushl	%ebx
	pushl	%ds
	movb	$0x20,%al			# ��8259A��оƬ����EOI����,����ISR�е���Ӧλ����.���������л�֮ǰ,����ʱ���ж��޷��ٴ���Ӧ
	outb	%al,$0x20
	movl	$0x10,%ebx
	mov		%bx,%ds
	cmpl	$NO_TASK,current
	je		OK
	cmpl	$0,current
	jne		t0
	movl	$1,current
	ljmp	$TSS1_SEL,$0
	jmp		OK
t0:	movl	$0,current
	ljmp	$TSS0_SEL,$0
OK:	popl	%ds
	popl	%ebx
	iret

.align 4
system_call:
	pushl	%ds
	pushl	%eax	
	pushl	%ebx
	pushl	%ecx
	pushl	%edx
	movl	$0x10,%ebx
	mov		%bx,%ds
	call	write_char
	popl	%edx
	popl	%ecx
	popl	%ebx
	popl	%eax
	popl	%ds
	iret

# ----------------------------------------------------
current:						# ��ǰ�����
	.long NO_TASK
scr_loc:						# ��Ļ��ǰ��ʾλ�ã������Ͻǵ����½�������ʾ
	.long 0

# GDT,IDT����
.align 4
gdt_new_48:
	.word (end_gdt-gdt)-1
	.long gdt

idt_new_48:
	.word 256*8-1
	.long idt

.align 8
gdt:
	.quad 0x0000000000000000
	.quad 0x00c09a00000007ff
	.quad 0x00c09200000007ff
	.quad 0x00c0920b80000002
	.word 0x68, tss0, 0xe900, 0x0
	.word 0x40, ldt0, 0xe200, 0x0
	.word 0x68, tss1, 0xe900, 0x0
	.word 0x40, ldt1, 0xe200, 0x0
end_gdt:

idt:
	.fill 256,8,0

# �ں˳�ʼ����ջ��Ҳ�Ǻ�������0���û�ջ
.align 4
	.fill 128,4,0
init_stack:
	.long init_stack
	.word 0x10

# ����0��LDT,TSS���ں�ջ
.align 8
ldt0:
	.quad 0x0000000000000000
	.quad 0x00c0fa00000003ff	# �ֲ����������������Ӧѡ���0x0f������ַ0x0
	.quad 0x00c0f200000003ff	# �ֲ����ݶ�����������Ӧѡ���0x17������ַ0x0
.align 4
tss0:
	.long 0
	.long ker_stk0,0x10
	.long 0,0,0,0,0
	.long 0,0,0,0,0
	.long 0,0,0,0,0
	.long 0,0,0,0,0,0
	.long LDT0_SEL,0x08000000

	.fill 128,4,0
ker_stk0:

# ����1��LDT,TSS���ں�ջ
.align 8
ldt1:
	.quad 0x0000000000000000
	.quad 0x00c0fa00000003ff	# �ֲ����������������Ӧѡ���0x0f������ַ0x0
	.quad 0x00c0f200000003ff	# �ֲ����ݶ�����������Ӧѡ���0x17������ַ0x0
.align 4
tss1:
	.long 0
	.long ker_stk1,0x10
	.long 0,0,0,0,0
	.long task1,0x200,0,0,0
	.long 0,usr_stk1,0,0,0
	.long 0x17,0x0f,0x17,0x17,0x17,0x17
	.long LDT1_SEL,0x08000000

	.fill 128,4,0
ker_stk1:

# ����0��1�Ĵ���
.align 4
task0:
	movl	$0,current
1:	movl	$0x0141,%eax		# �ַ�"A"�����ԣ���ɫ �ڵ� ����˸ ������
	int		$0x80
	movl	$0x5ffff,%ecx
p0:	loop	p0
	jmp		1b

.align 4
task1:
	movl	$0x0242,%eax		# �ַ�"B"�����ԣ���ɫ �ڵ� ����˸ ������
	int		$0x80
	movl	$0x5ffff,%ecx
p1:	loop	p1
	jmp		task1

# ����1���û�̬��ջ
.align 4
	.fill 128,4,0
usr_stk1:
