; $Id: bs3-cmn-SelRealModeDataToProtFar16.asm 69111 2017-10-17 14:26:02Z vboxsync $
;; @file
; BS3Kit - Bs3SelRealModeDataToProtFar16.
;

;
; Copyright (C) 2007-2017 Oracle Corporation
;
; This file is part of VirtualBox Open Source Edition (OSE), as
; available from http://www.virtualbox.org. This file is free software;
; you can redistribute it and/or modify it under the terms of the GNU
; General Public License (GPL) as published by the Free Software
; Foundation, in version 2 as it comes in the "COPYING" file of the
; VirtualBox OSE distribution. VirtualBox OSE is distributed in the
; hope that it will be useful, but WITHOUT ANY WARRANTY of any kind.
;
; The contents of this file may alternatively be used under the terms
; of the Common Development and Distribution License Version 1.0
; (CDDL) only, as it comes in the "COPYING.CDDL" file of the
; VirtualBox OSE distribution, in which case the provisions of the
; CDDL are applicable instead of those of the GPL.
;
; You may elect to license modified versions of this file under the
; terms and conditions of either the GPL or the CDDL or both.
;


;*********************************************************************************************************************************
;*      Header Files                                                                                                             *
;*********************************************************************************************************************************
%include "bs3kit-template-header.mac"


;*********************************************************************************************************************************
;*  External Symbols                                                                                                             *
;*********************************************************************************************************************************
BS3_BEGIN_DATA16                        ; For real mode segment value.
BS3_BEGIN_SYSTEM16                      ; Ditto.

TMPL_BEGIN_TEXT
%if TMPL_BITS == 16
CPU 8086
%endif


;;
; @cproto   BS3_CMN_PROTO_NOSB(uint32_t, Bs3SelRealModeDataToProtFar16,(uint32_t uFar1616));
;
; @uses     Only return registers (ax:dx, eax, eax)
; @remarks  No 20h scratch area requirements.
;
BS3_PROC_BEGIN_CMN Bs3SelRealModeDataToProtFar16, BS3_PBC_NEAR      ; Far stub generated by the makefile/bs3kit.h.
        push    xBP
        mov     xBP, xSP

        ;
        ; See if it's our default 16-bit data, stack or system data segment.
        ;
%if TMPL_BITS == 16
        mov     ax, [xBP + xCB + cbCurRetAddr + 2]
%elif TMPL_BITS == 32
        movzx   eax, word [xBP + xCB + cbCurRetAddr + 2]
%else
        mov     eax, ecx
        shr     eax, 16
%endif
        cmp     ax, 0
        jnz     .not_stack
        mov     ax, BS3_SEL_R0_SS16

.quick_return:
%if TMPL_BITS == 16
        mov     dx, ax
        mov     ax, [xBP + xCB + cbCurRetAddr]
%elif TMPL_BITS == 32
        shl     eax, 16
        mov     ax, word [xBP + xCB + cbCurRetAddr]
%else
        shl     eax, 16
        mov     ax, cx
%endif

.return:
        pop     xBP
        BS3_HYBRID_RET

.not_stack:
        cmp     ax, BS3KIT_GRPNM_DATA16
        jne     .not_dgroup
        mov     ax, BS3_SEL_R0_DS16
        jmp     .quick_return

.not_dgroup:
        cmp     ax, BS3SYSTEM16
        jne     .not_system16
        mov     ax, BS3_SEL_SYSTEM16
        jmp     .quick_return

        ;
        ; Compute flat address and translate it to tiled.
        ;
.not_system16:
%if TMPL_BITS == 16
        push    cx

        ; Calc flat address.
        mov     dx, ax
        mov     cl, 12
        shr     dx, cl
        mov     cl, 4
        shl     ax, cl
        add     ax, [xBP + xCB + cbCurRetAddr]
        adc     dx, 0

        ; Convert upper 16-bit to tiled selector.
        mov     cl, X86_SEL_SHIFT
        shl     dx, cl
        add     dx, BS3_SEL_TILED

        pop     cx
%else
        ; Calc flat address.
        shl     eax, 4
 %if TMPL_BITS == 32
        add     ax, [xBP + xCB + cbCurRetAddr]
 %else
        add     ax, cx
 %endif
        jnc     .no_carry
        add     eax, 10000h
.no_carry:

        ; Convert upper 16-bit to tiled selector.
        rol     eax, 16
        shl     ax, X86_SEL_SHIFT
        add     ax, BS3_SEL_TILED
        ror     eax, 16
%endif
        jmp     .return
BS3_PROC_END_CMN   Bs3SelRealModeDataToProtFar16

