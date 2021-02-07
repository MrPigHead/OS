%include	"pm.inc"

org	0100h
	jmp	LABEL_BEGIN

[SECTION	.gdt]
LABEL_GDT:				Descriptor	0,					0,						0
LABEL_DESC_NORMAL:		Descriptor	0,					0ffffh,					DA_DRW
LABEL_DESC_CODE32:		Descriptor	0,					SegCode32Len - 1,		DA_C + DA_32
LABEL_DESC_CODE16:		Descriptor	0,					0ffffh,					DA_C
LABEL_DESC_DATA:		Descriptor	0,					DataLen - 1,			DA_DRW
LABEL_DESC_STACK:		Descriptor	0,					TopOfStack,				DA_DRWA + DA_32
LABEL_DESC_TEST:		Descriptor	0500000h,			0ffffh,					DA_DRW
LABEL_DESC_VIDEO:		Descriptor	0b8000h,			0ffffh,					DA_DRW
LABEL_DESC_LDT:			Descriptor	0,					LDTLen - 1,				DA_LDT
LABEL_DESC_CODE_DEST:	Descriptor	0,					SegCodeDestLen - 1,		DA_C + DA_32
LABEL_DESC_CODE_RING3:	Descriptor	0,					SegCodeRing3Len - 1,	DA_C + DA_32 + DA_DPL3
LABEL_DESC_STACK3:		Descriptor	0,					TopOfStack3,			DA_DRWA + DA_32 + DA_DPL3
LABEL_DESC_RING3_VIDEO:	Descriptor	0b8000h,			0ffffh,					DA_DRW + DA_DPL3
LABEL_DESC_TSS:			Descriptor	0,					TSSLen - 1,				DA_386TSS

LABEL_CALL_GATE_TEST:		Gate		SelectorCodeDest,	0,						0,				DA_386CGate + DA_DPL0
LABEL_CALL_GATE_TEST_RING3:	Gate		SelectorCodeDest,	0,						0,				DA_386CGate + DA_DPL3

GdtLen	equ	$ - LABEL_GDT	; GDT长度
GdtPtr	dw	GdtLen - 1		; GDT界限
		dd	0

; GDT选择子
SelectorNormal				equ	LABEL_DESC_NORMAL			- LABEL_GDT
SelectorCode32				equ	LABEL_DESC_CODE32			- LABEL_GDT
SelectorCode16				equ	LABEL_DESC_CODE16			- LABEL_GDT
SelectorData				equ	LABEL_DESC_DATA				- LABEL_GDT
SelectorStack				equ	LABEL_DESC_STACK			- LABEL_GDT
SelectorTest				equ	LABEL_DESC_TEST				- LABEL_GDT
SelectorVideo				equ	LABEL_DESC_VIDEO			- LABEL_GDT
SelectorLDT					equ	LABEL_DESC_LDT				- LABEL_GDT
SelectorCodeDest			equ	LABEL_DESC_CODE_DEST		- LABEL_GDT
SelectorCodeRing3			equ	LABEL_DESC_CODE_RING3		- LABEL_GDT + SA_RPL3
SelectorStack3				equ	LABEL_DESC_STACK3			- LABEL_GDT + SA_RPL3
SelectorRing3Video			equ	LABEL_DESC_RING3_VIDEO		- LABEL_GDT + SA_RPL3
SelectorTSS					equ	LABEL_DESC_TSS				- LABEL_GDT

SelectorCallGateTest		equ	LABEL_CALL_GATE_TEST		- LABEL_GDT
SelectorCallGateTestRing3	equ	LABEL_CALL_GATE_TEST_RING3	- LABEL_GDT + SA_RPL3

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

[SECTION	.s3]
ALIGN		32
[BITS		32]
LABEL_STACK3:
	times	512	db	0

TopOfStack3			equ	$ - LABEL_STACK3 - 1

[SECTION	.tss]
ALIGN		32
[BITS		32]
LABEL_TSS:
	DD	0					; Back
	DD	TopOfStack			; Stack0
	DD	SelectorStack		; 
	DD	0					; Stack1
	DD	0					; 
	DD	0					; Stack2
	DD	0					; 
	DD	0					; CR3
	DD	0					; EIP
	DD	0					; EFLAGS
	DD	0					; EAX
	DD	0					; ECX
	DD	0					; EDX
	DD	0					; EBX
	DD	0					; ESP
	DD	0					; EBP
	DD	0					; ESI
	DD	0					; EDI
	DD	0					; ES
	DD	0					; CS
	DD	0					; SS
	DD	0					; DS
	DD	0					; FS
	DD	0					; GS
	DD	0					; LDT
	DW	0					; 调试陷阱标志
	DW	$ - LABEL_TSS + 2	; I/O位图基址
	DB	0ffh				; I/O位图结束标志

TSSLen				equ	$ - LABEL_TSS

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
	
	; 初始化LDT中的描述符
	xor		eax,	eax
	mov		ax,		ds
	shl		eax,	4
	add		eax,	LABEL_CODE_A
	mov		word	[LABEL_LDT_DESC_CODEA + 2], ax
	shr		eax,	16
	mov		byte	[LABEL_LDT_DESC_CODEA + 4],	al
	mov		byte	[LABEL_LDT_DESC_CODEA + 7],	ah
	
	; 初始化测试调用门的描述符
	xor		eax,	eax
	mov		ax,		ds
	shl		eax,	4
	add		eax,	LABEL_SEG_CODE_DEST
	mov		word	[LABEL_DESC_CODE_DEST + 2], ax
	shr		eax,	16
	mov		byte	[LABEL_DESC_CODE_DEST + 4],	al
	mov		byte	[LABEL_DESC_CODE_DEST + 7],	ah
	
	; 初始化Ring3的描述符
	xor		eax,	eax
	mov		ax,		ds
	shl		eax,	4
	add		eax,	LABEL_CODE_RING3
	mov		word	[LABEL_DESC_CODE_RING3 + 2], 	ax
	shr		eax,	16
	mov		byte	[LABEL_DESC_CODE_RING3 + 4],	al
	mov		byte	[LABEL_DESC_CODE_RING3 + 7],	ah
	
	; 初始化Ring3堆栈的描述符
	xor		eax,	eax
	mov		ax,		ds
	shl		eax,	4
	add		eax,	LABEL_STACK3
	mov		word	[LABEL_DESC_STACK3 + 2], 	ax
	shr		eax,	16
	mov		byte	[LABEL_DESC_STACK3 + 4],	al
	mov		byte	[LABEL_DESC_STACK3 + 7],	ah
	
	; 初始化TSS的描述符
	xor		eax,	eax
	mov		ax,		ds
	shl		eax,	4
	add		eax,	LABEL_TSS
	mov		word	[LABEL_DESC_TSS + 2], 	ax
	shr		eax,	16
	mov		byte	[LABEL_DESC_TSS + 4],	al
	mov		byte	[LABEL_DESC_TSS + 7],	ah
	
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
	mov		ax,		SelectorTSS
	ltr		ax
	
	; 进入Ring3
	push	SelectorStack3
	push	TopOfStack3
	push	SelectorCodeRing3
	push	0
	retf
	
	call	SelectorCallGateTest:0
	
	; 加载LDT
	mov		ax,		SelectorLDT
	lldt	ax
	
	jmp		SelectorLDTCodeA:0	; 跳入局部任务

SegCode32Len	equ	$ - LABEL_SEG_CODE32

[SECTION	.sdest]
[BITS		32]
; 调用门目标
LABEL_SEG_CODE_DEST:
	mov		ax,		SelectorVideo
	mov		gs,		ax
	
	mov		edi,		(80 * 12 + 0) * 2	; 第12行第0列
	mov		ah,			0ch					; 颜色
	mov		al,			'C'
	mov		[gs:edi],	ax
	
	retf

SegCodeDestLen	equ	$ - LABEL_SEG_CODE_DEST

[SECTION	.ldt]
ALIGN		32
LABEL_LDT:
LABEL_LDT_DESC_CODEA:	Descriptor	0,					CodeALen - 1,			DA_C + DA_32

LDTLen			equ	$ - LABEL_LDT	; LDT长度

; LDT选择子
SelectorLDTCodeA			equ	LABEL_LDT_DESC_CODEA		- LABEL_LDT + SA_TIL

[SECTION	.la]
ALIGN		32
[BITS		32]
LABEL_CODE_A:
	; 视频段选择子
	mov		ax,		SelectorVideo
	mov		gs,		ax
	
	mov		edi,		(80 * 11 + 0) * 2	; 第11行第0列
	mov		ah,			0ch					; 颜色
	mov		al,			'L'
	mov		[gs:edi],	ax
	
	; 跳回实模式
	jmp		SelectorCode16:0

CodeALen		equ	$ - LABEL_CODE_A

[SECTION	.ring3]
ALIGN		32
[BITS		32]
; Ring3代码段
LABEL_CODE_RING3:
	; 视频段选择子
	mov		ax,		SelectorRing3Video
	mov		gs,		ax
	
	mov		edi,		(80 * 13 + 0) * 2	; 第13行第0列
	mov		ah,			0ch					; 颜色
	mov		al,			'3'
	mov		[gs:edi],	ax
	
	call	SelectorCallGateTestRing3:0
	
	; 无限循环
	jmp		$

SegCodeRing3Len	equ	$ - LABEL_CODE_RING3

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
