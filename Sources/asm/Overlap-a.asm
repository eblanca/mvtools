%include "include/x86inc.asm"


SECTION .rodata

;dword256 times 4 dd 0x00000100
; PF 20180221 replace rounding of 256 with 32
; Instead of 
; (Sum(pixel + 256) >> 6) >> 5 ; So far >>5 happened at the internal_buffer->final_frame, w/o any rounding
; Let's use:
; ((Sum(pixel + 32) >> 6) + 16) >> 5 ; Now we round at a second time, before applying >>5 at the internal_buffer->final_frame
dword256 times 4 dd 0x00000020


SECTION .text


%macro OVERS2 0
    movd m0, [srcpq] ; two more than needed
    punpcklbw m0, m7
    movd m1, [winpq]
    movdqa m2, m0
    pmullw m0, m1
    pmulhw m2, m1
    punpcklwd m0, m2
    paddd m0, m6
    psrld m0, 6
    packssdw m0, m7
    movd m1, [dstpq]
    paddusw m0, m1
    movd [dstpq], m0

    add dstpq, dst_strideq
    add srcpq, src_strideq
    add winpq, win_strideq
%endmacro


INIT_XMM
cglobal Overlaps2x2_sse2, 6, 6, 8, dstp, dst_stride, srcp, src_stride, winp, win_stride

%if ARCH_X86_64
	movsxd dst_strideq, dst_strided
	movsxd src_strideq, src_strided
	movsxd win_strideq, win_strided
%endif

    ; prepare constants
    movdqa m6, [dword256]
    pxor m7, m7    ; =0

    ; They're in pixels, apparently.
    add dst_strideq, dst_strideq
    add win_strideq, win_strideq

    OVERS2
    OVERS2

    RET


INIT_XMM
cglobal Overlaps2x4_sse2, 6, 6, 8, dstp, dst_stride, srcp, src_stride, winp, win_stride

%if ARCH_X86_64
	movsxd dst_strideq, dst_strided
	movsxd src_strideq, src_strided
	movsxd win_strideq, win_strided
%endif

    ; prepare constants
    movdqa m6, [dword256]
    pxor m7, m7    ; =0

    ; They're in pixels, apparently.
    add dst_strideq, dst_strideq
    add win_strideq, win_strideq

    OVERS2
    OVERS2
    OVERS2
    OVERS2

    RET

; 0 or 1 parameters.
%macro OVERS4 0-1
; Done like this because if I supply a default value (of 0) for %1,
; %0 is always 1, whether a parameter was actually passed or not.
%if %0 == 0
    %assign offset 0
%else
    %assign offset %1
%endif
    movd m0, [srcpq + offset/2]
    punpcklbw m0, m7
    movq m1, [winpq + offset]
    movdqa m2, m0
    pmullw m0, m1
    pmulhw m2, m1
    punpcklwd m0, m2
    paddd m0, m6
    psrld m0, 6
    packssdw m0, m7
    movq m1, [dstpq + offset]
    paddusw m0, m1
    movq [dstpq + offset], m0

; if no parameters were passed
%if %0 == 0
    add dstpq, dst_strideq
    add srcpq, src_strideq
    add winpq, win_strideq
%endif
%endmacro


INIT_XMM
cglobal Overlaps4x2_sse2, 6, 6, 8, dstp, dst_stride, srcp, src_stride, winp, win_stride

%if ARCH_X86_64
	movsxd dst_strideq, dst_strided
	movsxd src_strideq, src_strided
	movsxd win_strideq, win_strided
%endif

    ; prepare constants
    movdqa m6, [dword256]
    pxor m7, m7    ; =0

    ; They're in pixels, apparently.
    add dst_strideq, dst_strideq
    add win_strideq, win_strideq

    OVERS4
    OVERS4

    RET


INIT_XMM
cglobal Overlaps4x4_sse2, 6, 6, 8, dstp, dst_stride, srcp, src_stride, winp, win_stride

%if ARCH_X86_64
	movsxd dst_strideq, dst_strided
	movsxd src_strideq, src_strided
	movsxd win_strideq, win_strided
%endif

    ; prepare constants
    movdqa m6, [dword256]
    pxor m7, m7    ; =0

    ; They're in pixels, apparently.
    add dst_strideq, dst_strideq
    add win_strideq, win_strideq

    OVERS4
    OVERS4
    OVERS4
    OVERS4

    RET


INIT_XMM
cglobal Overlaps4x8_sse2, 6, 6, 8, dstp, dst_stride, srcp, src_stride, winp, win_stride

%if ARCH_X86_64
	movsxd dst_strideq, dst_strided
	movsxd src_strideq, src_strided
	movsxd win_strideq, win_strided
%endif

    ; prepare constants
    movdqa m6, [dword256]
    pxor m7, m7    ; =0

    ; They're in pixels, apparently.
    add dst_strideq, dst_strideq
    add win_strideq, win_strideq

    OVERS4
    OVERS4
    OVERS4
    OVERS4

    OVERS4
    OVERS4
    OVERS4
    OVERS4

    RET


; 0 or 1 parameters.
%macro OVERS8 0-1
; Done like this because if I supply a default value (of 0) for %1,
; %0 is always 1, whether a parameter was actually passed or not.
%if %0 == 0
    %assign offset 0
%else
    %assign offset %1
%endif

    movq m0, [srcpq + offset/2]
    punpcklbw m0, m7
    movdqu m1, [winpq + offset] ; TODO: check if winpq is aligned
    movdqa m2, m0
    pmullw m0, m1
    pmulhw m2, m1
    movdqa m1, m0
    punpcklwd m0, m2
    punpckhwd m1, m2
    paddd m0, m6
    paddd m1, m6
    psrld m0, 6
    psrld m1, 6
    packssdw m0, m1
    movdqu m1, [dstpq + offset] ; TODO: check if dstpq is aligned
    paddusw m0, m1
    movdqu [dstpq + offset], m0

; if no parameters were passed
%if %0 == 0
    add dstpq, dst_strideq
    add srcpq, src_strideq
    add winpq, win_strideq
%endif
%endmacro


INIT_XMM
cglobal Overlaps8x1_sse2, 6, 6, 8, dstp, dst_stride, srcp, src_stride, winp, win_stride

%if ARCH_X86_64
	movsxd dst_strideq, dst_strided
	movsxd src_strideq, src_strided
	movsxd win_strideq, win_strided
%endif

    ; prepare constants
    movdqa m6, [dword256]
    pxor m7, m7

    OVERS8

    RET


INIT_XMM
cglobal Overlaps8x2_sse2, 6, 6, 8, dstp, dst_stride, srcp, src_stride, winp, win_stride

%if ARCH_X86_64
	movsxd dst_strideq, dst_strided
	movsxd src_strideq, src_strided
	movsxd win_strideq, win_strided
%endif

    ; prepare constants
    movdqa m6, [dword256]
    pxor m7, m7

    ; They're in pixels, apparently.
    add dst_strideq, dst_strideq
    add win_strideq, win_strideq

    OVERS8
    OVERS8

    RET


INIT_XMM
cglobal Overlaps8x4_sse2, 6, 6, 8, dstp, dst_stride, srcp, src_stride, winp, win_stride

%if ARCH_X86_64
	movsxd dst_strideq, dst_strided
	movsxd src_strideq, src_strided
	movsxd win_strideq, win_strided
%endif

    ; prepare constants
    movdqa m6, [dword256]
    pxor m7, m7

    ; They're in pixels, apparently.
    add dst_strideq, dst_strideq
    add win_strideq, win_strideq

    OVERS8
    OVERS8
    OVERS8
    OVERS8

    RET


INIT_XMM
cglobal Overlaps8x8_sse2, 6, 6, 8, dstp, dst_stride, srcp, src_stride, winp, win_stride

%if ARCH_X86_64
	movsxd dst_strideq, dst_strided
	movsxd src_strideq, src_strided
	movsxd win_strideq, win_strided
%endif

    ; prepare constants
    movdqa m6, [dword256]
    pxor m7, m7

    ; They're in pixels, apparently.
    add dst_strideq, dst_strideq
    add win_strideq, win_strideq

    OVERS8
    OVERS8
    OVERS8
    OVERS8

    OVERS8
    OVERS8
    OVERS8
    OVERS8

    RET

INIT_XMM
cglobal Overlaps8x32_sse2, 6, 6, 8, dstp, dst_stride, srcp, src_stride, winp, win_stride

%if ARCH_X86_64
	movsxd dst_strideq, dst_strided
	movsxd src_strideq, src_strided
	movsxd win_strideq, win_strided
%endif

    ; prepare constants
    movdqa m6, [dword256]
    pxor m7, m7

    ; They're in pixels, apparently.
    add dst_strideq, dst_strideq
    add win_strideq, win_strideq

    OVERS8
    OVERS8
    OVERS8
    OVERS8

    OVERS8
    OVERS8
    OVERS8
    OVERS8

    OVERS8
    OVERS8
    OVERS8
    OVERS8

    OVERS8
    OVERS8
    OVERS8
    OVERS8

    OVERS8
    OVERS8
    OVERS8
    OVERS8

    OVERS8
    OVERS8
    OVERS8
    OVERS8

    OVERS8
    OVERS8
    OVERS8
    OVERS8

    OVERS8
    OVERS8
    OVERS8
    OVERS8

    RET


INIT_XMM
cglobal Overlaps8x16_sse2, 6, 6, 8, dstp, dst_stride, srcp, src_stride, winp, win_stride

%if ARCH_X86_64
	movsxd dst_strideq, dst_strided
	movsxd src_strideq, src_strided
	movsxd win_strideq, win_strided
%endif

    ; prepare constants
    movdqa m6, [dword256]
    pxor m7, m7

    ; They're in pixels, apparently.
    add dst_strideq, dst_strideq
    add win_strideq, win_strideq

    OVERS8
    OVERS8
    OVERS8
    OVERS8

    OVERS8
    OVERS8
    OVERS8
    OVERS8

    OVERS8
    OVERS8
    OVERS8
    OVERS8

    OVERS8
    OVERS8
    OVERS8
    OVERS8

    RET

; OVERS12 is three OVERS4 per line.
%macro OVERS12 0
    OVERS4 0
    OVERS4 8
    OVERS4 16

    add dstpq, dst_strideq
    add srcpq, src_strideq
    add winpq, win_strideq
%endmacro

INIT_XMM
cglobal Overlaps12x48_sse2, 6, 6, 8, dstp, dst_stride, srcp, src_stride, winp, win_stride

%if ARCH_X86_64
	movsxd dst_strideq, dst_strided
	movsxd src_strideq, src_strided
	movsxd win_strideq, win_strided
%endif

    ; prepare constants
    movdqa m6, [dword256]
    pxor m7, m7

    ; They're in pixels, apparently.
    add dst_strideq, dst_strideq
    add win_strideq, win_strideq
    ; 1-24
    OVERS12
    OVERS12
    OVERS12
    OVERS12

    OVERS12
    OVERS12
    OVERS12
    OVERS12

    OVERS12
    OVERS12
    OVERS12
    OVERS12

    OVERS12
    OVERS12
    OVERS12
    OVERS12

    OVERS12
    OVERS12
    OVERS12
    OVERS12

    OVERS12
    OVERS12
    OVERS12
    OVERS12

    ; 25-48
    OVERS12
    OVERS12
    OVERS12
    OVERS12

    OVERS12
    OVERS12
    OVERS12
    OVERS12

    OVERS12
    OVERS12
    OVERS12
    OVERS12

    OVERS12
    OVERS12
    OVERS12
    OVERS12

    OVERS12
    OVERS12
    OVERS12
    OVERS12

    OVERS12
    OVERS12
    OVERS12
    OVERS12

    RET

INIT_XMM
cglobal Overlaps12x24_sse2, 6, 6, 8, dstp, dst_stride, srcp, src_stride, winp, win_stride

%if ARCH_X86_64
	movsxd dst_strideq, dst_strided
	movsxd src_strideq, src_strided
	movsxd win_strideq, win_strided
%endif

    ; prepare constants
    movdqa m6, [dword256]
    pxor m7, m7

    ; They're in pixels, apparently.
    add dst_strideq, dst_strideq
    add win_strideq, win_strideq
    ; 1-24
    OVERS12
    OVERS12
    OVERS12
    OVERS12

    OVERS12
    OVERS12
    OVERS12
    OVERS12

    OVERS12
    OVERS12
    OVERS12
    OVERS12

    OVERS12
    OVERS12
    OVERS12
    OVERS12

    OVERS12
    OVERS12
    OVERS12
    OVERS12

    OVERS12
    OVERS12
    OVERS12
    OVERS12

    RET

INIT_XMM
cglobal Overlaps12x16_sse2, 6, 6, 8, dstp, dst_stride, srcp, src_stride, winp, win_stride

%if ARCH_X86_64
	movsxd dst_strideq, dst_strided
	movsxd src_strideq, src_strided
	movsxd win_strideq, win_strided
%endif

    ; prepare constants
    movdqa m6, [dword256]
    pxor m7, m7

    ; They're in pixels, apparently.
    add dst_strideq, dst_strideq
    add win_strideq, win_strideq

    OVERS12
    OVERS12
    OVERS12
    OVERS12

    OVERS12
    OVERS12
    OVERS12
    OVERS12

    OVERS12
    OVERS12
    OVERS12
    OVERS12

    OVERS12
    OVERS12
    OVERS12
    OVERS12

    RET

INIT_XMM
cglobal Overlaps12x12_sse2, 6, 6, 8, dstp, dst_stride, srcp, src_stride, winp, win_stride

%if ARCH_X86_64
	movsxd dst_strideq, dst_strided
	movsxd src_strideq, src_strided
	movsxd win_strideq, win_strided
%endif

    ; prepare constants
    movdqa m6, [dword256]
    pxor m7, m7

    ; They're in pixels, apparently.
    add dst_strideq, dst_strideq
    add win_strideq, win_strideq

    OVERS12
    OVERS12
    OVERS12
    OVERS12

    OVERS12
    OVERS12
    OVERS12
    OVERS12

    OVERS12
    OVERS12
    OVERS12
    OVERS12

    RET

INIT_XMM
cglobal Overlaps12x6_sse2, 6, 6, 8, dstp, dst_stride, srcp, src_stride, winp, win_stride

%if ARCH_X86_64
	movsxd dst_strideq, dst_strided
	movsxd src_strideq, src_strided
	movsxd win_strideq, win_strided
%endif

    ; prepare constants
    movdqa m6, [dword256]
    pxor m7, m7

    ; They're in pixels, apparently.
    add dst_strideq, dst_strideq
    add win_strideq, win_strideq

    OVERS12
    OVERS12
    OVERS12
    OVERS12

    OVERS12
    OVERS12

    RET

INIT_XMM
cglobal Overlaps12x3_sse2, 6, 6, 8, dstp, dst_stride, srcp, src_stride, winp, win_stride

%if ARCH_X86_64
	movsxd dst_strideq, dst_strided
	movsxd src_strideq, src_strided
	movsxd win_strideq, win_strided
%endif

    ; prepare constants
    movdqa m6, [dword256]
    pxor m7, m7

    ; They're in pixels, apparently.
    add dst_strideq, dst_strideq
    add win_strideq, win_strideq

    OVERS12
    OVERS12
    OVERS12

    RET


; OVERS16 is two OVERS8 per line.
%macro OVERS16 0
    OVERS8 0
    OVERS8 16

    add dstpq, dst_strideq
    add srcpq, src_strideq
    add winpq, win_strideq
%endmacro


INIT_XMM
cglobal Overlaps16x2_sse2, 6, 6, 8, dstp, dst_stride, srcp, src_stride, winp, win_stride

%if ARCH_X86_64
	movsxd dst_strideq, dst_strided
	movsxd src_strideq, src_strided
	movsxd win_strideq, win_strided
%endif

    ; prepare constants
    movdqa m6, [dword256]
    pxor m7, m7

    ; They're in pixels, apparently.
    add dst_strideq, dst_strideq
    add win_strideq, win_strideq

    OVERS16
    OVERS16

    RET

; added 160803 PF
INIT_XMM
cglobal Overlaps16x4_sse2, 6, 6, 8, dstp, dst_stride, srcp, src_stride, winp, win_stride

%if ARCH_X86_64
	movsxd dst_strideq, dst_strided
	movsxd src_strideq, src_strided
	movsxd win_strideq, win_strided
%endif

    ; prepare constants
    movdqa m6, [dword256]
    pxor m7, m7

    ; They're in pixels, apparently.
    add dst_strideq, dst_strideq
    add win_strideq, win_strideq

    OVERS16
    OVERS16
    OVERS16
    OVERS16

    RET


INIT_XMM
cglobal Overlaps16x8_sse2, 6, 6, 8, dstp, dst_stride, srcp, src_stride, winp, win_stride

%if ARCH_X86_64
	movsxd dst_strideq, dst_strided
	movsxd src_strideq, src_strided
	movsxd win_strideq, win_strided
%endif

    ; prepare constants
    movdqa m6, [dword256]
    pxor m7, m7

    ; They're in pixels, apparently.
    add dst_strideq, dst_strideq
    add win_strideq, win_strideq

    OVERS16
    OVERS16
    OVERS16
    OVERS16

    OVERS16
    OVERS16
    OVERS16
    OVERS16

    RET

INIT_XMM
cglobal Overlaps16x12_sse2, 6, 6, 8, dstp, dst_stride, srcp, src_stride, winp, win_stride

%if ARCH_X86_64
	movsxd dst_strideq, dst_strided
	movsxd src_strideq, src_strided
	movsxd win_strideq, win_strided
%endif

    ; prepare constants
    movdqa m6, [dword256]
    pxor m7, m7

    ; They're in pixels, apparently.
    add dst_strideq, dst_strideq
    add win_strideq, win_strideq

    OVERS16
    OVERS16
    OVERS16
    OVERS16

    OVERS16
    OVERS16
    OVERS16
    OVERS16

    OVERS16
    OVERS16
    OVERS16
    OVERS16

    RET



INIT_XMM
cglobal Overlaps16x16_sse2, 6, 6, 8, dstp, dst_stride, srcp, src_stride, winp, win_stride

%if ARCH_X86_64
	movsxd dst_strideq, dst_strided
	movsxd src_strideq, src_strided
	movsxd win_strideq, win_strided
%endif

    ; prepare constants
    movdqa m6, [dword256]
    pxor m7, m7

    ; They're in pixels, apparently.
    add dst_strideq, dst_strideq
    add win_strideq, win_strideq

    OVERS16
    OVERS16
    OVERS16
    OVERS16

    OVERS16
    OVERS16
    OVERS16
    OVERS16

    OVERS16
    OVERS16
    OVERS16
    OVERS16

    OVERS16
    OVERS16
    OVERS16
    OVERS16

    RET


INIT_XMM
cglobal Overlaps16x32_sse2, 6, 6, 8, dstp, dst_stride, srcp, src_stride, winp, win_stride

%if ARCH_X86_64
	movsxd dst_strideq, dst_strided
	movsxd src_strideq, src_strided
	movsxd win_strideq, win_strided
%endif

    ; prepare constants
    movdqa m6, [dword256]
    pxor m7, m7

    ; They're in pixels, apparently.
    add dst_strideq, dst_strideq
    add win_strideq, win_strideq

    OVERS16
    OVERS16
    OVERS16
    OVERS16

    OVERS16
    OVERS16
    OVERS16
    OVERS16

    OVERS16
    OVERS16
    OVERS16
    OVERS16

    OVERS16
    OVERS16
    OVERS16
    OVERS16

    OVERS16
    OVERS16
    OVERS16
    OVERS16

    OVERS16
    OVERS16
    OVERS16
    OVERS16

    OVERS16
    OVERS16
    OVERS16
    OVERS16

    OVERS16
    OVERS16
    OVERS16
    OVERS16

    RET

INIT_XMM
cglobal Overlaps16x64_sse2, 6, 6, 8, dstp, dst_stride, srcp, src_stride, winp, win_stride

%if ARCH_X86_64
	movsxd dst_strideq, dst_strided
	movsxd src_strideq, src_strided
	movsxd win_strideq, win_strided
%endif

    ; prepare constants
    movdqa m6, [dword256]
    pxor m7, m7

    ; They're in pixels, apparently.
    add dst_strideq, dst_strideq
    add win_strideq, win_strideq
	; 1-32
    OVERS16
    OVERS16
    OVERS16
    OVERS16

    OVERS16
    OVERS16
    OVERS16
    OVERS16

    OVERS16
    OVERS16
    OVERS16
    OVERS16

    OVERS16
    OVERS16
    OVERS16
    OVERS16

    OVERS16
    OVERS16
    OVERS16
    OVERS16

    OVERS16
    OVERS16
    OVERS16
    OVERS16

    OVERS16
    OVERS16
    OVERS16
    OVERS16

    OVERS16
    OVERS16
    OVERS16
    OVERS16

	; 33-64
    OVERS16
    OVERS16
    OVERS16
    OVERS16

    OVERS16
    OVERS16
    OVERS16
    OVERS16

    OVERS16
    OVERS16
    OVERS16
    OVERS16

    OVERS16
    OVERS16
    OVERS16
    OVERS16

    OVERS16
    OVERS16
    OVERS16
    OVERS16

    OVERS16
    OVERS16
    OVERS16
    OVERS16

    OVERS16
    OVERS16
    OVERS16
    OVERS16

    OVERS16
    OVERS16
    OVERS16
    OVERS16

    RET

; OVERS24 is three OVERS8 per line.
%macro OVERS24 0
    OVERS8 0
    OVERS8 16
    OVERS8 32

    add dstpq, dst_strideq
    add srcpq, src_strideq
    add winpq, win_strideq
%endmacro

INIT_XMM
cglobal Overlaps24x48_sse2, 6, 6, 8, dstp, dst_stride, srcp, src_stride, winp, win_stride

%if ARCH_X86_64
	movsxd dst_strideq, dst_strided
	movsxd src_strideq, src_strided
	movsxd win_strideq, win_strided
%endif

    ; prepare constants
    movdqa m6, [dword256]
    pxor m7, m7

    ; They're in pixels, apparently.
    add dst_strideq, dst_strideq
    add win_strideq, win_strideq
    ; 1-32
    OVERS24
    OVERS24
    OVERS24
    OVERS24

    OVERS24
    OVERS24
    OVERS24
    OVERS24

    OVERS24
    OVERS24
    OVERS24
    OVERS24

    OVERS24
    OVERS24
    OVERS24
    OVERS24

    OVERS24
    OVERS24
    OVERS24
    OVERS24

    OVERS24
    OVERS24
    OVERS24
    OVERS24

    OVERS24
    OVERS24
    OVERS24
    OVERS24

    OVERS24
    OVERS24
    OVERS24
    OVERS24

    ; 33-48
    OVERS24
    OVERS24
    OVERS24
    OVERS24

    OVERS24
    OVERS24
    OVERS24
    OVERS24

    OVERS24
    OVERS24
    OVERS24
    OVERS24

    OVERS24
    OVERS24
    OVERS24
    OVERS24

    RET


INIT_XMM
cglobal Overlaps24x32_sse2, 6, 6, 8, dstp, dst_stride, srcp, src_stride, winp, win_stride

%if ARCH_X86_64
	movsxd dst_strideq, dst_strided
	movsxd src_strideq, src_strided
	movsxd win_strideq, win_strided
%endif

    ; prepare constants
    movdqa m6, [dword256]
    pxor m7, m7

    ; They're in pixels, apparently.
    add dst_strideq, dst_strideq
    add win_strideq, win_strideq

    OVERS24
    OVERS24
    OVERS24
    OVERS24

    OVERS24
    OVERS24
    OVERS24
    OVERS24

    OVERS24
    OVERS24
    OVERS24
    OVERS24

    OVERS24
    OVERS24
    OVERS24
    OVERS24

    OVERS24
    OVERS24
    OVERS24
    OVERS24

    OVERS24
    OVERS24
    OVERS24
    OVERS24

    OVERS24
    OVERS24
    OVERS24
    OVERS24

    OVERS24
    OVERS24
    OVERS24
    OVERS24

    RET

INIT_XMM
cglobal Overlaps24x24_sse2, 6, 6, 8, dstp, dst_stride, srcp, src_stride, winp, win_stride

%if ARCH_X86_64
	movsxd dst_strideq, dst_strided
	movsxd src_strideq, src_strided
	movsxd win_strideq, win_strided
%endif

    ; prepare constants
    movdqa m6, [dword256]
    pxor m7, m7

    ; They're in pixels, apparently.
    add dst_strideq, dst_strideq
    add win_strideq, win_strideq
    ; 1-24
    OVERS24
    OVERS24
    OVERS24
    OVERS24

    OVERS24
    OVERS24
    OVERS24
    OVERS24

    OVERS24
    OVERS24
    OVERS24
    OVERS24

    OVERS24
    OVERS24
    OVERS24
    OVERS24

    OVERS24
    OVERS24
    OVERS24
    OVERS24

    OVERS24
    OVERS24
    OVERS24
    OVERS24

    RET

INIT_XMM
cglobal Overlaps24x12_sse2, 6, 6, 8, dstp, dst_stride, srcp, src_stride, winp, win_stride

%if ARCH_X86_64
	movsxd dst_strideq, dst_strided
	movsxd src_strideq, src_strided
	movsxd win_strideq, win_strided
%endif

    ; prepare constants
    movdqa m6, [dword256]
    pxor m7, m7

    ; They're in pixels, apparently.
    add dst_strideq, dst_strideq
    add win_strideq, win_strideq

    OVERS24
    OVERS24
    OVERS24
    OVERS24

    OVERS24
    OVERS24
    OVERS24
    OVERS24

    OVERS24
    OVERS24
    OVERS24
    OVERS24

    RET

INIT_XMM
cglobal Overlaps24x6_sse2, 6, 6, 8, dstp, dst_stride, srcp, src_stride, winp, win_stride

%if ARCH_X86_64
	movsxd dst_strideq, dst_strided
	movsxd src_strideq, src_strided
	movsxd win_strideq, win_strided
%endif

    ; prepare constants
    movdqa m6, [dword256]
    pxor m7, m7

    ; They're in pixels, apparently.
    add dst_strideq, dst_strideq
    add win_strideq, win_strideq

    OVERS24
    OVERS24
    OVERS24
    OVERS24

    OVERS24
    OVERS24

    RET

; OVERS32 is four OVERS8 per line.
%macro OVERS32 0
    OVERS8 0
    OVERS8 16
    OVERS8 32
    OVERS8 48

    add dstpq, dst_strideq
    add srcpq, src_strideq
    add winpq, win_strideq
%endmacro

; added 160803 PF
INIT_XMM
cglobal Overlaps32x8_sse2, 6, 6, 8, dstp, dst_stride, srcp, src_stride, winp, win_stride

%if ARCH_X86_64
	movsxd dst_strideq, dst_strided
	movsxd src_strideq, src_strided
	movsxd win_strideq, win_strided
%endif

    ; prepare constants
    movdqa m6, [dword256]
    pxor m7, m7

    ; They're in pixels, apparently.
    add dst_strideq, dst_strideq
    add win_strideq, win_strideq

    OVERS32
    OVERS32
    OVERS32
    OVERS32

    OVERS32
    OVERS32
    OVERS32
    OVERS32

    RET


INIT_XMM
cglobal Overlaps32x16_sse2, 6, 6, 8, dstp, dst_stride, srcp, src_stride, winp, win_stride

%if ARCH_X86_64
	movsxd dst_strideq, dst_strided
	movsxd src_strideq, src_strided
	movsxd win_strideq, win_strided
%endif

    ; prepare constants
    movdqa m6, [dword256]
    pxor m7, m7

    ; They're in pixels, apparently.
    add dst_strideq, dst_strideq
    add win_strideq, win_strideq

    OVERS32
    OVERS32
    OVERS32
    OVERS32

    OVERS32
    OVERS32
    OVERS32
    OVERS32

    OVERS32
    OVERS32
    OVERS32
    OVERS32

    OVERS32
    OVERS32
    OVERS32
    OVERS32

    RET

INIT_XMM
cglobal Overlaps32x24_sse2, 6, 6, 8, dstp, dst_stride, srcp, src_stride, winp, win_stride

%if ARCH_X86_64
	movsxd dst_strideq, dst_strided
	movsxd src_strideq, src_strided
	movsxd win_strideq, win_strided
%endif

    ; prepare constants
    movdqa m6, [dword256]
    pxor m7, m7

    ; They're in pixels, apparently.
    add dst_strideq, dst_strideq
    add win_strideq, win_strideq

    OVERS32
    OVERS32
    OVERS32
    OVERS32

    OVERS32
    OVERS32
    OVERS32
    OVERS32

    OVERS32
    OVERS32
    OVERS32
    OVERS32

    OVERS32
    OVERS32
    OVERS32
    OVERS32

    OVERS32
    OVERS32
    OVERS32
    OVERS32

    OVERS32
    OVERS32
    OVERS32
    OVERS32

    RET

INIT_XMM
cglobal Overlaps32x32_sse2, 6, 6, 8, dstp, dst_stride, srcp, src_stride, winp, win_stride

%if ARCH_X86_64
	movsxd dst_strideq, dst_strided
	movsxd src_strideq, src_strided
	movsxd win_strideq, win_strided
%endif

    ; prepare constants
    movdqa m6, [dword256]
    pxor m7, m7

    ; They're in pixels, apparently.
    add dst_strideq, dst_strideq
    add win_strideq, win_strideq

    OVERS32
    OVERS32
    OVERS32
    OVERS32

    OVERS32
    OVERS32
    OVERS32
    OVERS32

    OVERS32
    OVERS32
    OVERS32
    OVERS32

    OVERS32
    OVERS32
    OVERS32
    OVERS32

    OVERS32
    OVERS32
    OVERS32
    OVERS32

    OVERS32
    OVERS32
    OVERS32
    OVERS32

    OVERS32
    OVERS32
    OVERS32
    OVERS32

    OVERS32
    OVERS32
    OVERS32
    OVERS32

    RET

;PF 170507
INIT_XMM
cglobal Overlaps32x64_sse2, 6, 6, 8, dstp, dst_stride, srcp, src_stride, winp, win_stride

%if ARCH_X86_64
	movsxd dst_strideq, dst_strided
	movsxd src_strideq, src_strided
	movsxd win_strideq, win_strided
%endif

    ; prepare constants
    movdqa m6, [dword256]
    pxor m7, m7

    ; They're in pixels, apparently.
    add dst_strideq, dst_strideq
    add win_strideq, win_strideq

	;1-32
    OVERS32
    OVERS32
    OVERS32
    OVERS32

    OVERS32
    OVERS32
    OVERS32
    OVERS32

    OVERS32
    OVERS32
    OVERS32
    OVERS32

    OVERS32
    OVERS32
    OVERS32
    OVERS32

    OVERS32
    OVERS32
    OVERS32
    OVERS32

    OVERS32
    OVERS32
    OVERS32
    OVERS32

    OVERS32
    OVERS32
    OVERS32
    OVERS32

    OVERS32
    OVERS32
    OVERS32
    OVERS32

	;33-64
    OVERS32
    OVERS32
    OVERS32
    OVERS32

    OVERS32
    OVERS32
    OVERS32
    OVERS32

    OVERS32
    OVERS32
    OVERS32
    OVERS32

    OVERS32
    OVERS32
    OVERS32
    OVERS32

    OVERS32
    OVERS32
    OVERS32
    OVERS32

    OVERS32
    OVERS32
    OVERS32
    OVERS32

    OVERS32
    OVERS32
    OVERS32
    OVERS32

    OVERS32
    OVERS32
    OVERS32
    OVERS32

    RET

; OVERS48 is six OVERS8 per line.
%macro OVERS48 0
    OVERS8 0
    OVERS8 16
    OVERS8 32
    OVERS8 48
    OVERS8 64
    OVERS8 80

    add dstpq, dst_strideq
    add srcpq, src_strideq
    add winpq, win_strideq
%endmacro

;PF 170507
INIT_XMM
cglobal Overlaps48x64_sse2, 6, 6, 8, dstp, dst_stride, srcp, src_stride, winp, win_stride

%if ARCH_X86_64
	movsxd dst_strideq, dst_strided
	movsxd src_strideq, src_strided
	movsxd win_strideq, win_strided
%endif

    ; prepare constants
    movdqa m6, [dword256]
    pxor m7, m7

    ; They're in pixels, apparently.
    add dst_strideq, dst_strideq
    add win_strideq, win_strideq

    ;1-32
    OVERS48
    OVERS48
    OVERS48
    OVERS48

    OVERS48
    OVERS48
    OVERS48
    OVERS48

    OVERS48
    OVERS48
    OVERS48
    OVERS48

    OVERS48
    OVERS48
    OVERS48
    OVERS48

    OVERS48
    OVERS48
    OVERS48
    OVERS48

    OVERS48
    OVERS48
    OVERS48
    OVERS48

    OVERS48
    OVERS48
    OVERS48
    OVERS48

    OVERS48
    OVERS48
    OVERS48
    OVERS48

	;33-64
    OVERS48
    OVERS48
    OVERS48
    OVERS48

    OVERS48
    OVERS48
    OVERS48
    OVERS48

    OVERS48
    OVERS48
    OVERS48
    OVERS48

    OVERS48
    OVERS48
    OVERS48
    OVERS48

    OVERS48
    OVERS48
    OVERS48
    OVERS48

    OVERS48
    OVERS48
    OVERS48
    OVERS48

    OVERS48
    OVERS48
    OVERS48
    OVERS48

    OVERS48
    OVERS48
    OVERS48
    OVERS48

    RET

;PF 170507
INIT_XMM
cglobal Overlaps48x48_sse2, 6, 6, 8, dstp, dst_stride, srcp, src_stride, winp, win_stride

%if ARCH_X86_64
	movsxd dst_strideq, dst_strided
	movsxd src_strideq, src_strided
	movsxd win_strideq, win_strided
%endif

    ; prepare constants
    movdqa m6, [dword256]
    pxor m7, m7

    ; They're in pixels, apparently.
    add dst_strideq, dst_strideq
    add win_strideq, win_strideq

    ;1-32
    OVERS48
    OVERS48
    OVERS48
    OVERS48

    OVERS48
    OVERS48
    OVERS48
    OVERS48

    OVERS48
    OVERS48
    OVERS48
    OVERS48

    OVERS48
    OVERS48
    OVERS48
    OVERS48

    OVERS48
    OVERS48
    OVERS48
    OVERS48

    OVERS48
    OVERS48
    OVERS48
    OVERS48

    OVERS48
    OVERS48
    OVERS48
    OVERS48

    OVERS48
    OVERS48
    OVERS48
    OVERS48

	;33-48
    OVERS48
    OVERS48
    OVERS48
    OVERS48

    OVERS48
    OVERS48
    OVERS48
    OVERS48

    OVERS48
    OVERS48
    OVERS48
    OVERS48

    OVERS48
    OVERS48
    OVERS48
    OVERS48

    RET

;PF 170507
INIT_XMM
cglobal Overlaps48x24_sse2, 6, 6, 8, dstp, dst_stride, srcp, src_stride, winp, win_stride

%if ARCH_X86_64
	movsxd dst_strideq, dst_strided
	movsxd src_strideq, src_strided
	movsxd win_strideq, win_strided
%endif

    ; prepare constants
    movdqa m6, [dword256]
    pxor m7, m7

    ; They're in pixels, apparently.
    add dst_strideq, dst_strideq
    add win_strideq, win_strideq

    ;1-24
    OVERS48
    OVERS48
    OVERS48
    OVERS48

    OVERS48
    OVERS48
    OVERS48
    OVERS48

    OVERS48
    OVERS48
    OVERS48
    OVERS48

    OVERS48
    OVERS48
    OVERS48
    OVERS48

    OVERS48
    OVERS48
    OVERS48
    OVERS48

    OVERS48
    OVERS48
    OVERS48
    OVERS48

    RET

;PF 170507
INIT_XMM
cglobal Overlaps48x12_sse2, 6, 6, 8, dstp, dst_stride, srcp, src_stride, winp, win_stride

%if ARCH_X86_64
	movsxd dst_strideq, dst_strided
	movsxd src_strideq, src_strided
	movsxd win_strideq, win_strided
%endif

    ; prepare constants
    movdqa m6, [dword256]
    pxor m7, m7

    ; They're in pixels, apparently.
    add dst_strideq, dst_strideq
    add win_strideq, win_strideq

    ;1-12
    OVERS48
    OVERS48
    OVERS48
    OVERS48

    OVERS48
    OVERS48
    OVERS48
    OVERS48

    OVERS48
    OVERS48
    OVERS48
    OVERS48

    RET

; added 170507 PF
; OVERS64 is eight OVERS8 per line.
%macro OVERS64 0
    OVERS8 0
    OVERS8 16
    OVERS8 32
    OVERS8 48
    OVERS8 64
    OVERS8 80
    OVERS8 96
    OVERS8 112

    add dstpq, dst_strideq
    add srcpq, src_strideq
    add winpq, win_strideq
%endmacro

;PF 170507
INIT_XMM
cglobal Overlaps64x16_sse2, 6, 6, 8, dstp, dst_stride, srcp, src_stride, winp, win_stride

%if ARCH_X86_64
	movsxd dst_strideq, dst_strided
	movsxd src_strideq, src_strided
	movsxd win_strideq, win_strided
%endif

    ; prepare constants
    movdqa m6, [dword256]
    pxor m7, m7

    ; They're in pixels, apparently.
    add dst_strideq, dst_strideq
    add win_strideq, win_strideq

    OVERS64
    OVERS64
    OVERS64
    OVERS64

    OVERS64
    OVERS64
    OVERS64
    OVERS64

    OVERS64
    OVERS64
    OVERS64
    OVERS64

    OVERS64
    OVERS64
    OVERS64
    OVERS64

    RET


INIT_XMM
cglobal Overlaps64x32_sse2, 6, 6, 8, dstp, dst_stride, srcp, src_stride, winp, win_stride

%if ARCH_X86_64
	movsxd dst_strideq, dst_strided
	movsxd src_strideq, src_strided
	movsxd win_strideq, win_strided
%endif

    ; prepare constants
    movdqa m6, [dword256]
    pxor m7, m7

    ; They're in pixels, apparently.
    add dst_strideq, dst_strideq
    add win_strideq, win_strideq

    OVERS64
    OVERS64
    OVERS64
    OVERS64

    OVERS64
    OVERS64
    OVERS64
    OVERS64

    OVERS64
    OVERS64
    OVERS64
    OVERS64

    OVERS64
    OVERS64
    OVERS64
    OVERS64

    OVERS64
    OVERS64
    OVERS64
    OVERS64

    OVERS64
    OVERS64
    OVERS64
    OVERS64

    OVERS64
    OVERS64
    OVERS64
    OVERS64

    OVERS64
    OVERS64
    OVERS64
    OVERS64

    RET

;PF 170507
INIT_XMM
cglobal Overlaps64x48_sse2, 6, 6, 8, dstp, dst_stride, srcp, src_stride, winp, win_stride

%if ARCH_X86_64
	movsxd dst_strideq, dst_strided
	movsxd src_strideq, src_strided
	movsxd win_strideq, win_strided
%endif

    ; prepare constants
    movdqa m6, [dword256]
    pxor m7, m7

    ; They're in pixels, apparently.
    add dst_strideq, dst_strideq
    add win_strideq, win_strideq

	;1-32
    OVERS64
    OVERS64
    OVERS64
    OVERS64

    OVERS64
    OVERS64
    OVERS64
    OVERS64

    OVERS64
    OVERS64
    OVERS64
    OVERS64

    OVERS64
    OVERS64
    OVERS64
    OVERS64

    OVERS64
    OVERS64
    OVERS64
    OVERS64

    OVERS64
    OVERS64
    OVERS64
    OVERS64

    OVERS64
    OVERS64
    OVERS64
    OVERS64

    OVERS64
    OVERS64
    OVERS64
    OVERS64

	;33-48
    OVERS64
    OVERS64
    OVERS64
    OVERS64

    OVERS64
    OVERS64
    OVERS64
    OVERS64

    OVERS64
    OVERS64
    OVERS64
    OVERS64

    OVERS64
    OVERS64
    OVERS64
    OVERS64

    RET

;PF 170507
INIT_XMM
cglobal Overlaps64x64_sse2, 6, 6, 8, dstp, dst_stride, srcp, src_stride, winp, win_stride

%if ARCH_X86_64
	movsxd dst_strideq, dst_strided
	movsxd src_strideq, src_strided
	movsxd win_strideq, win_strided
%endif

    ; prepare constants
    movdqa m6, [dword256]
    pxor m7, m7

    ; They're in pixels, apparently.
    add dst_strideq, dst_strideq
    add win_strideq, win_strideq

	;1-32
    OVERS64
    OVERS64
    OVERS64
    OVERS64

    OVERS64
    OVERS64
    OVERS64
    OVERS64

    OVERS64
    OVERS64
    OVERS64
    OVERS64

    OVERS64
    OVERS64
    OVERS64
    OVERS64

    OVERS64
    OVERS64
    OVERS64
    OVERS64

    OVERS64
    OVERS64
    OVERS64
    OVERS64

    OVERS64
    OVERS64
    OVERS64
    OVERS64

    OVERS64
    OVERS64
    OVERS64
    OVERS64

	;33-64
    OVERS64
    OVERS64
    OVERS64
    OVERS64

    OVERS64
    OVERS64
    OVERS64
    OVERS64

    OVERS64
    OVERS64
    OVERS64
    OVERS64

    OVERS64
    OVERS64
    OVERS64
    OVERS64

    OVERS64
    OVERS64
    OVERS64
    OVERS64

    OVERS64
    OVERS64
    OVERS64
    OVERS64

    OVERS64
    OVERS64
    OVERS64
    OVERS64

    OVERS64
    OVERS64
    OVERS64
    OVERS64

    RET
