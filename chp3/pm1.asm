%include	"pm.inc"

org	0100h
	jmp	LABEL_BEGIN

[SECTION	.gdt]
LABEL_GDT:			Descriptor	0,			0,					0
LABEL_DESC_CODE32:	Descriptor	0,			SegCode32Len - 1,	DA_C + DA_32
LABEL_DESC_VIDEO:	Descriptor	0b8000h,	0ffffh,				DA_DRW

GdtLen	equ	$ - LABEL_GDT	; GDT长度
GdtPtr	dw	GdtLen - 1		; GDT界限
		dd	0

; GDT选择子
SelectorCode32	equ	LABEL_DESC_CODE32 - LABEL_GDT
SelectorVideo	equ	LABEL_DESC_VIDEO - LABEL_GDT

[SECTION	.s16]
[BITS		16]
LABEL_BEGIN:
	mov	ax,	cs
	mov	ds,	ax
	mov	es,	ax
	mov	ss,	ax
	mov	sp,	0100h
	
	; 初始化32位段描述符
	xor	eax,	eax
	mov	ax,		cs
	shl	eax,	4
	add	eax,	LABEL_SEG_CODE32
	mov	word	[LABEL_DESC_CODE32 + 2],	ax
	shr	eax,	16
	mov	byte	[LABEL_DESC_CODE32 + 4],	al
	mov	byte	[LABEL_DESC_CODE32 + 7],	ah
	
	; 准备加载GDTR
	xor	eax,					eax
	mov	ax,						cs
	shl	eax,					4
	add	eax,					LABEL_GDT
	mov	dword	[GdtPtr + 2],	eax
	
	lgdt	[GdtPtr]	; 加载GDTR
	
	cli	; 关中断
	
	; 使用端口92h实现开启A20寻址
	in	al,		92h
	or	al,		00000010b
	out	92h,	al
	
	; 切换保护模式
	mov	eax,	cr0
	or	eax,	1
	mov	cr0,	eax
	
	; 真正进入保护模式
	jmp	dword	SelectorCode32:0

[SECTION	.s32]
[BITS		32]
LABEL_SEG_CODE32:
	mov	ax,	SelectorVideo
	mov	gs,	ax
	
	mov	edi,		0	;位置
	mov	ah,			0ch	;样式（高位）
	mov	al,			'P'	;文字（低位）
	mov	[gs:edi],	ax	;写入
	
	jmp $

SegCode32Len	equ	$-LABEL_SEG_CODE32
