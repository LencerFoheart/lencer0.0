!
! Small/boot/boot.s
!
! (C) 2012-2013 Yafei Zheng
! V0.0 2012-12-6 20:24:19
!
! Email: e9999e@163.com, QQ: 1039332004
!


BOOTSEG		= 0x07c0
SYSSEG		= 0x1000
SYSLEN		= 17					! ռ�ô������������

entry start
start:
	jmpi	go,#BOOTSEG
go:	mov		ax,cs
	mov		ds,ax
	mov		ss,ax
	mov		sp,#0x400				! ������ʱ��ջ

! �����ں˴��뵽0x10000
! INT 13h ��ʹ�÷������£�
!	ah = 02h - �������������ڴ棻	al = ��Ҫ����������������
!	ch = �ŵ������棩�ŵĵ�8λ��	cl = ��ʼ������0��5λ�����ŵ��Ÿ�2λ��6��7����
!	dh = ��ͷ�ţ�					dl = �������ţ������Ӳ����Ҫ��Ϊ7����
!	es:bx ->ָ�����ݻ�������		
!	���������CF��־��λ�� 
load_system:
	mov		ax,#SYSSEG
	mov		es,ax
	xor		bx,bx
	mov		ax,#0x0200+SYSLEN		! ��ȡ17������
	mov		cx,#0x0002
	mov		dx,#0x0000
	int		0x13
	jnc		ok_load
die:
	jmp		die

! ���ں��ƶ���0x0�����ں˲��ᳬ��8KB(16*512b)
ok_load:
	cli								! ���ж�
	mov		ax,#SYSSEG
	mov		ds,ax
	xor		ax,ax
	mov		es,ax
	mov		cx,#1024*4
	sub		si,si
	sub		di,di
	rep
	movw

! װ��GDTR,IDTR
	mov		ax,#BOOTSEG
	mov		ds,ax
	lgdt	gdt_48
	lidt	idt_48

! ��A20��ַ��
	call	empty_8042
	mov		al,#0xd1
	out		#0x64,al
	call	empty_8042
	mov		al,#0xdf
	out		#0x60,al
	call	empty_8042

! ��CR0��PEλ���뱣��ģʽ������ת��headģ��ִ��
	mov		ax,#0x0001
	lmsw	ax
	jmpi	0,8

! -----------------------------------------------
empty_8042:
	.word 0x00eb,0x00eb
	in		al,#0x64
	test	al,#0x02
	jnz		empty_8042
	ret

! GDT,IDT����
gdt:
	.word 0,0,0,0					! ����

	.word 0x07ff					! �����������
	.word 0x0000
	.word 0x9a00
	.word 0x00c0

	.word 0x07ff					! ���ݶ�������
	.word 0x0000
	.word 0x9200
	.word 0x00c0

gdt_48:
	.word 0x07ff
	.word 0x7c00+gdt,0

idt_48:
	.word 0
	.word 0,0

! ����������Ч��־������λ�������������2���ֽ�
.org 510
	.word 0xaa55
