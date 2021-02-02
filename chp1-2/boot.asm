org		07c00h			; 跳转到地址7c00
   ; 设置ds、es，以便程序继续执行
	mov		ax,	cs
	mov		ds,	ax
	mov		es,	ax
	call	DispStr			; 调用显示字符串
	jmp		$				; 无限循环
DispStr:
	mov		ax,	BootMessage
	mov		bp,	ax			; 地址
	mov		cx,	12			; 字符串长度
	mov		ax,	01301h		; 颜色等
	mov		bx,	000ch		; 页码
	mov		dl,	0
	int		10h				; 中断10
	ret
BootMessage:		db	"Hello world!"
; 填充0到末尾
times	510-($-$$)	db	0
dw		0xaa55