%include	"pm.inc"


PageDirBase		equ	200000h
PageTblBase		equ	201000h

org	0100h
	jmp	LABEL_BEGIN

[SECTION	.gdt]
LABEL_GDT:				Descriptor	0,				0,					0
LABEL_DESC_NORMAL:		Descriptor	0,				0ffffh,				DA_DRW
LABEL_DESC_CODE32:		Descriptor	0,				SegCode32Len - 1,	DA_C + DA_32
LABEL_DESC_CODE16:		Descriptor	0,				0ffffh,				DA_C
LABEL_DESC_DATA:	Descriptor	0,			DataLen - 1,		DA_DRW
LABEL_DESC_STACK:		Descriptor	0,				TopOfStack,			DA_DRWA + DA_32
LABEL_DESC_VIDEO:		Descriptor	0b8000h,		0ffffh,				DA_DRW
LABEL_DESC_PAGE_DIR:	Descriptor	PageDirBase,	4095,				DA_DRW
LABEL_DESC_PAGE_TBL:	Descriptor	PageTblBase,	1023,				DA_DRW | DA_LIMIT_4K

GdtLen	equ	$ - LABEL_GDT	; GDT长度
GdtPtr	dw	GdtLen - 1		; GDT界限
		dd	0

; GDT选择子
SelectorNormal	equ	LABEL_DESC_NORMAL	- LABEL_GDT
SelectorCode32	equ	LABEL_DESC_CODE32	- LABEL_GDT
SelectorCode16	equ	LABEL_DESC_CODE16	- LABEL_GDT
SelectorData	equ	LABEL_DESC_DATA		- LABEL_GDT
SelectorStack	equ	LABEL_DESC_STACK	- LABEL_GDT
SelectorVideo	equ	LABEL_DESC_VIDEO	- LABEL_GDT
SelectorPageDir	equ	LABEL_DESC_PAGE_DIR	- LABEL_GDT
SelectorPageTbl	equ	LABEL_DESC_PAGE_TBL	- LABEL_GDT

[SECTION .data1]
ALIGN    32
[BITS    32]
LABEL_DATA:
SPValueInRealMode	dw	0
PMMessage:			db	"I'm in protect mode!", 0
OffsetPMMessage		equ	PMMessage - $$
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
	
	; 返回实模式
	jmp		SelectorCode16:0

SetupPaging:
	
	mov		ax,		SelectorPageDir
	mov		es,		ax
	mov		ecx,	1024
	xor		edi,	edi
	xor		eax,	eax
	mov		eax,	PageTblBase | PG_P | PG_USU | PG_RWW
.1:
	stosd
	add		eax,	4096
	loop	.1
	
	mov		ax,		SelectorPageTbl
	mov		es,		ax
	mov		ecx,	1024 * 1024
	xor		edi,	edi
	xor		eax,	eax
	mov		eax,	PG_P | PG_USU | PG_RWW
.2:
	stosd
	add		eax,	4096
	loop	.2
	
	mov		eax,	PageDirBase
	mov		cr3,	eax
	mov		eax,	cr0
	mov		eax,	80000000h
	mov		cr0,	eax
	jmp		short	.3
.3:
	nop
	
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
