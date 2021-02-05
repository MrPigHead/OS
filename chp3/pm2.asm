%include	"pm.inc"

org	0100h
	jmp	LABEL_BEGIN

[SECTION	.gdt]
LABEL_GDT:			Descriptor	0,			0,					0
LABEL_DESC_NORMAL:	Descriptor	0,			0ffffh,				DA_DRW
LABEL_DESC_CODE32:	Descriptor	0,			SegCode32Len - 1,	DA_C + DA_32
LABEL_DESC_CODE16:	Descriptor	0,			0ffffh,				DA_C
LABEL_DESC_DATA:	Descriptor	0,			DataLen - 1,		DA_DRW
LABEL_DESC_STACK:	Descriptor	0,			TopOfStack,			DA_DRWA + DA_32
LABEL_DESC_TEST:	Descriptor	0500000h,	0ffffh,				DA_DRW
LABEL_DESC_VIDEO:	Descriptor	0b8000h,	0ffffh,				DA_DRW

GdtLen	equ	$ - LABEL_GDT	; GDT长度
GdtPtr	dw	GdtLen - 1		; GDT界限
		dd	0

; GDT选择子
SelectorNormal	equ	LABEL_DESC_NORMAL	- LABEL_GDT
SelectorCode32	equ	LABEL_DESC_CODE32	- LABEL_GDT
SelectorCode16	equ	LABEL_DESC_CODE16	- LABEL_GDT
SelectorData	equ	LABEL_DESC_DATA		- LABEL_GDT
SelectorStack	equ	LABEL_DESC_STACK	- LABEL_GDT
SelectorTest	equ	LABEL_DESC_TEST		- LABEL_GDT
SelectorVideo	equ	LABEL_DESC_VIDEO	- LABEL_GDT

[SECTION	.data1]
ALIGN		32
[BITS		32]
LABEL_DATA:
SPValueInRealMode	dw	0
PMMessage:			db	"I'm in protect mode!", 0
OffsetPMMessage		equ	PMMessage - $$
StrTest:			db	"ABCDEFGHIJKLMNOPQRSTUVWXYZ", 0
OffsetStrTest		equ	StrTest - $$
DataLen				equ	$ - LABEL_DATA
[SECTION	.gs]
ALIGN		32
[BITS		32]
LABEL_STACK:
	times	512	db	0

TopOfStack			equ	$ - LABEL_STACK - 1

[SECTION	.s16]
[BITS		16]
LABEL_BEGIN:
	mov		ax,	cs
	mov		ds,	ax
	mov		es,	ax
	mov		ss,	ax
	mov		sp,	0100h
	
	mov		[LABEL_GO_BACK_TO_REAL + 3],	ax
	mov		[SPValueInRealMode],			sp
	
	; 初始化16位段描述符
	xor		eax,	eax
	mov		ax,		ds
	shl		eax,	4
	add		eax,	LABEL_SEG_CODE16
	mov		word	[LABEL_DESC_CODE16 + 2], ax
	shr		eax,	16
	mov		byte	[LABEL_DESC_CODE16 + 4],	al
	mov		byte	[LABEL_DESC_CODE16 + 7],	ah
	
	; 初始化32位段描述符
	xor		eax,	eax
	mov		ax,		cs
	shl		eax,	4
	add		eax,	LABEL_SEG_CODE32
	mov		word	[LABEL_DESC_CODE32 + 2],	ax
	shr		eax,	16
	mov		byte	[LABEL_DESC_CODE32 + 4],	al
	mov		byte	[LABEL_DESC_CODE32 + 7],	ah
	
	; 初始化数据段描述符
	xor		eax,	eax
	mov		ax,		ds
	shl		eax,	4
	add		eax,	LABEL_DATA
	mov		word	[LABEL_DESC_DATA + 2], ax
	shr		eax,	16
	mov		byte	[LABEL_DESC_DATA + 4],	al
	mov		byte	[LABEL_DESC_DATA + 7],	ah
	
	; 初始化堆栈段描述符
	xor		eax,	eax
	mov		ax,		ds
	shl		eax,	4
	add		eax,	LABEL_STACK
	mov		word	[LABEL_DESC_STACK + 2], ax
	shr		eax,	16
	mov		byte	[LABEL_DESC_STACK + 4],	al
	mov		byte	[LABEL_DESC_STACK + 7],	ah
	
	; 准备加载GDTR
	xor		eax,					eax
	mov		ax,						ds
	shl		eax,					4
	add		eax,					LABEL_GDT
	mov		dword	[GdtPtr + 2],	eax
	
	lgdt	[GdtPtr]	; 加载GDTR
	
	cli	; 关中断
	
	; 使用端口92h实现开启A20寻址
	in		al,		92h
	or		al,		00000010b
	out		92h,	al
	
	; 切换保护模式
	mov		eax,	cr0
	or		eax,	1
	mov		cr0,	eax
	
	; 真正进入保护模式
	jmp		dword	SelectorCode32:0

LABEL_REAL_ENTRY:
	mov		ax,		cs
	mov		ds,		ax
	mov		es,		ax
	mov		ss,		ax
	
	mov		sp,		[SPValueInRealMode]
	
	; 关闭A20寻址
	in		al,		92h
	and		al,		11111101b
	out		92h,	al
	
	sti	; 开中断
	
	; 回到DOS
	mov		ax,		4c00h
	int		21h

[SECTION	.s32]
[BITS		32]
LABEL_SEG_CODE32:
	; 数据段、测试段、显示段
	mov		ax,	SelectorData
	mov		ds,	ax
	mov		ax,	SelectorTest
	mov		es,	ax
	mov		ax,	SelectorVideo
	mov		gs,	ax
	
	; 堆栈段
	mov		ax,	SelectorStack
	mov		ss,	ax
	
	mov		esp,	TopOfStack
	
	mov		ah,		0ch					; 颜色
	xor		esi,	esi
	xor		edi,	edi
	mov		esi,	OffsetPMMessage
	mov		edi,	(80 * 10 + 0) * 2	; 第10行第0列
	cld
.1:	; 显示1字
	; 加载1字
	lodsb
	test	al,			al
	jz		.2
	; 显示这个字
	mov		[gs:edi],	ax
	add		edi,		2
	; 循环
	jmp		.1
.2:	; 显示完毕
	
	call	DispReturn
	
	call	TestRead
	call	TestWrite
	call	TestRead
	
	; 返回实模式
	jmp		SelectorCode16:0

TestRead:
	xor		esi,	esi
	mov		ecx,	8			; 位数
.loop:
	mov		al,		[es:esi]
	call	DispAL
	inc		esi
	loop	.loop				; 循环
	
	call DispReturn
	
	ret

TestWrite:
	push	esi
	push	edi
	xor		esi,	esi
	xor		edi,	edi
	mov		esi,	OffsetStrTest
	cld
.1:
	; 加载1字
	lodsb
	test	al,			al
	jz		.2
	; 存储该字
	mov		[es:edi],	al
	inc		edi
	jmp		.1
.2:
	
	pop		edi
	pop		esi
	
	ret

DispAL:	; 显示al寄存器的内容
	push	ecx
	push	edx
	
	mov		ah,		0ch
	mov		dl,		al
	shr		al,		4
	mov		ecx,	2
.begin:
	and		al,		01111b
	cmp		al,		9
	jz		.1
	add		al,		'0'
	jmp		.2
.1:
	sub		al,		0ah
	add		al,		'A'
.2:
	mov		[gs:edi],	ax
	add		edi,		2
	
	mov		al,		dl
	loop	.begin			; 循环
	add		edi,	2
	
	pop		edx
	pop		ecx
	
	ret

DispReturn:
	push	eax
	push	ebx
	mov		eax,	edi
	mov		bl,		160
	div		bl
	and		eax,	0ffh
	inc		eax
	mov		bl,		160
	mul		bl
	mov		edi,	eax
	pop		ebx
	pop		eax
	
	ret

SegCode32Len	equ	$ - LABEL_SEG_CODE32

[SECTION	.s16code]
ALIGN		32
[BITS		16]
LABEL_SEG_CODE16:
	; 清除选择子
	mov		ax,		SelectorNormal
	mov		ds,		ax
	mov		es,		ax
	mov		fs,		ax
	mov		gs,		ax
	mov		ss,		ax
	
	; 切换实模式
	mov		eax,	cr0
	and		al,		11111110b
	mov		cr0,	eax

LABEL_GO_BACK_TO_REAL:
	; 真正退出保护模式
	jmp		0:LABEL_REAL_ENTRY

Code16Len	equ	$ - LABEL_SEG_CODE16
