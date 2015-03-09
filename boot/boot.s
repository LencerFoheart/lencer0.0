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
SYSLEN		= 17					! 占用磁盘最大扇区数

entry start
start:
	jmpi	go,#BOOTSEG
go:	mov		ax,cs
	mov		ds,ax
	mov		ss,ax
	mov		sp,#0x400				! 设置临时堆栈

! 加载内核代码到0x10000
! INT 13h 的使用方法如下：
!	ah = 02h - 读磁盘扇区到内存；	al = 需要读出的扇区数量；
!	ch = 磁道（柱面）号的低8位；	cl = 开始扇区（0－5位），磁道号高2位（6－7）；
!	dh = 磁头号；					dl = 驱动器号（如果是硬盘则要置为7）；
!	es:bx ->指向数据缓冲区；		
!	如果出错则CF标志置位。 
load_system:
	mov		ax,#SYSSEG
	mov		es,ax
	xor		bx,bx
	mov		ax,#0x0200+SYSLEN		! 读取17个扇区
	mov		cx,#0x0002
	mov		dx,#0x0000
	int		0x13
	jnc		ok_load
die:
	jmp		die

! 将内核移动到0x0处，内核不会超过8KB(16*512b)
ok_load:
	cli								! 关中断
	mov		ax,#SYSSEG
	mov		ds,ax
	xor		ax,ax
	mov		es,ax
	mov		cx,#1024*4
	sub		si,si
	sub		di,di
	rep
	movw

! 装载GDTR,IDTR
	mov		ax,#BOOTSEG
	mov		ds,ax
	lgdt	gdt_48
	lidt	idt_48

! 打开A20地址线
	call	empty_8042
	mov		al,#0xd1
	out		#0x64,al
	call	empty_8042
	mov		al,#0xdf
	out		#0x60,al
	call	empty_8042

! 置CR0的PE位进入保护模式，并跳转至head模块执行
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

! GDT,IDT定义
gdt:
	.word 0,0,0,0					! 不用

	.word 0x07ff					! 代码段描述符
	.word 0x0000
	.word 0x9a00
	.word 0x00c0

	.word 0x07ff					! 数据段描述符
	.word 0x0000
	.word 0x9200
	.word 0x00c0

gdt_48:
	.word 0x07ff
	.word 0x7c00+gdt,0

idt_48:
	.word 0
	.word 0,0

! 引导扇区有效标志，必须位于引导扇区最后2个字节
.org 510
	.word 0xaa55
