%include	"pm.inc"

org	0100h
	jmp	LABEL_BEGIN

[SECTION	.gdt]
LABEL_GDT:				Descriptor	0,			0,					0
LABEL_DESC_NORMAL:		Descriptor	0,			0ffffh,				DA_DRW
LABEL_DESC_CODE32:		Descriptor	0,			SegCode32Len - 1,	DA_C + DA_32
LABEL_DESC_CODE16:		Descriptor	0,			0ffffh,				DA_C
LABEL_DESC_DATA:		Descriptor	0,			DataLen - 1,		DA_DRW + DA_DPL1
LABEL_DESC_STACK:		Descriptor	0,			TopOfStack,			DA_DRWA + DA_32
LABEL_DESC_TEST:		Descriptor	0500000h,	0ffffh,				DA_DRW
LABEL_DESC_VIDEO:		Descriptor	0b8000h,	0ffffh,				DA_DRW
LABEL_DESC_LDT:			Descriptor	0,			LDTLen - 1,			DA_LDT
LABEL_DESC_LDTTEST:	Descriptor	0,			LDTTestLen - 1,			DA_LDT

GdtLen	equ	$ - LABEL_GDT	; GDT长度
GdtPtr	dw	GdtLen - 1		; GDT界限
		dd	0

; GDT选择子
SelectorNormal			equ	LABEL_DESC_NORMAL	- LABEL_GDT
SelectorCode32			equ	LABEL_DESC_CODE32	- LABEL_GDT
SelectorCode16			equ	LABEL_DESC_CODE16	- LABEL_GDT
SelectorData			equ	LABEL_DESC_DATA		- LABEL_GDT + SA_RPL3
SelectorStack			equ	LABEL_DESC_STACK	- LABEL_GDT
SelectorTest			equ	LABEL_DESC_TEST		- LABEL_GDT
SelectorVideo			equ	LABEL_DESC_VIDEO	- LABEL_GDT
SelectorLDT				equ	LABEL_DESC_LDT		- LABEL_GDT
SelectorLDTTest			equ	LABEL_DESC_LDTTEST	- LABEL_GDT

[SECTION	.data1]
ALIGN		32
[BITS		32]
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
	mov		ax,		cs
	mov		ds,		ax
	mov		es,		ax
	mov		ss,		ax
	mov		sp,		0100h
	
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
	
	; 初始化LDT在GDT的描述符
	xor		eax,	eax
	mov		ax,		ds
	shl		eax,	4
	add		eax,	LABEL_LDT
	mov		word	[LABEL_DESC_LDT + 2], ax
	shr		eax,	16
	mov		byte	[LABEL_DESC_LDT + 4],	al
	mov		byte	[LABEL_DESC_LDT + 7],	ah
	
	; 初始化LDTTest在GDT的描述符
	xor		eax,	eax
	mov		ax,		ds
	shl		eax,	4
	add		eax,	LABEL_LDTTEST
	mov		word	[LABEL_DESC_LDTTEST + 2], ax
	shr		eax,	16
	mov		byte	[LABEL_DESC_LDTTEST + 4],	al
	mov		byte	[LABEL_DESC_LDTTEST + 7],	ah
	
	; 初始化LDT中的描述符A
	xor		eax,	eax
	mov		ax,		ds
	shl		eax,	4
	add		eax,	LABEL_CODE_A
	mov		word	[LABEL_LDT_DESC_CODEA + 2], ax
	shr		eax,	16
	mov		byte	[LABEL_LDT_DESC_CODEA + 4],	al
	mov		byte	[LABEL_LDT_DESC_CODEA + 7],	ah
	
	; 初始化LDTTest中的描述符B
	xor		eax,	eax
	mov		ax,		ds
	shl		eax,	4
	add		eax,	LABEL_CODE_B
	mov		word	[LABEL_LDTTEST_DESC_CODEB + 2], ax
	shr		eax,	16
	mov		byte	[LABEL_LDTTEST_DESC_CODEB + 4],	al
	mov		byte	[LABEL_LDTTEST_DESC_CODEB + 7],	ah
	
	; 初始化LDTTest中的描述符C
	xor		eax,	eax
	mov		ax,		ds
	shl		eax,	4
	add		eax,	LABEL_CODE_C
	mov		word	[LABEL_LDTTEST_DESC_CODEC + 2], ax
	shr		eax,	16
	mov		byte	[LABEL_LDTTEST_DESC_CODEC + 4],	al
	mov		byte	[LABEL_LDTTEST_DESC_CODEC + 7],	ah
	
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
	mov		ax,		SelectorData
	mov		ds,		ax
	mov		ax,		SelectorTest
	mov		es,		ax
	mov		ax,		SelectorVideo
	mov		gs,		ax
	
	; 堆栈段
	mov		ax,		SelectorStack
	mov		ss,		ax
	
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
	
	; 加载LDT
	mov		ax,		SelectorLDT
	lldt	ax
	
	jmp		SelectorLDTCodeA:0	; 跳入局部任务A

SegCode32Len	equ	$ - LABEL_SEG_CODE32

[SECTION	.ldt]
ALIGN		32
LABEL_LDT:
LABEL_LDT_DESC_CODEA:	Descriptor	0,			CodeALen - 1,		DA_C + DA_32

LDTLen			equ	$ - LABEL_LDT	; LDT长度

; LDT选择子
SelectorLDTCodeA		equ	LABEL_LDT_DESC_CODEA	- LABEL_LDT + SA_TIL

[SECTION	.ldttest]
ALIGN		32
LABEL_LDTTEST:
LABEL_LDTTEST_DESC_CODEB:	Descriptor	0,			CodeBLen - 1,		DA_C + DA_32
LABEL_LDTTEST_DESC_CODEC:	Descriptor	0,			CodeCLen - 1,		DA_C + DA_32

LDTTestLen		equ	$ - LABEL_LDTTEST	; LDT长度

; LDT选择子
SelectorLDTTestCodeB	equ	LABEL_LDTTEST_DESC_CODEB	- LABEL_LDTTEST + SA_TIL
SelectorLDTTestCodeC	equ	LABEL_LDTTEST_DESC_CODEC	- LABEL_LDTTEST + SA_TIL

[SECTION	.la]
ALIGN		32
[BITS		32]
LABEL_CODE_A:
	; 视频段选择子
	mov		ax,		SelectorVideo
	mov		gs,		ax
	
	mov		edi,		(80 * 11 + 0) * 2	; 第11行第0列
	mov		ah,			0ch					; 颜色
	mov		al,			'A'
	mov		[gs:edi],	ax
	
	; 不同LDT需要先加载
	; 加载LDT
	mov		ax,			SelectorLDTTest
	lldt	ax
	
	jmp		SelectorLDTTestCodeB:0	; 跳入局部任务B

CodeALen		equ	$ - LABEL_CODE_A

[SECTION	.lb]
ALIGN		32
[BITS		32]
LABEL_CODE_B:
	; 视频段选择子
	mov		ax,		SelectorVideo
	mov		gs,		ax
	
	mov		edi,		(80 * 12 + 0) * 2	; 第12行第0列
	mov		ah,			0ch
	mov		al,			'B'
	mov		[gs:edi],	ax
	
	; 同一LDT可以直接跳转
	jmp		SelectorLDTTestCodeC:0	; 跳入局部任务C
	
CodeBLen		equ	$ - LABEL_CODE_B

[SECTION	.lc]
ALIGN		32
[BITS		32]
LABEL_CODE_C:
	; 视频段选择子
	mov		ax,		SelectorVideo
	mov		gs,		ax
	
	mov		edi,		(80 * 13 + 0) * 2	; 第13行第0列
	mov		ah,			0ch
	mov		al,			'C'
	mov		[gs:edi],	ax
	
	; 跳回实模式
	jmp		SelectorCode16:0
	
CodeCLen		equ	$ - LABEL_CODE_C

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

Code16Len		equ	$ - LABEL_SEG_CODE16
