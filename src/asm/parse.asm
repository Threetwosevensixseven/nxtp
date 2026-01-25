; parse.asm

;  Copyright 2019-2026 Robin Verhagen-Guest
;
; Licensed under the Apache License, Version 2.0 (the "License");
; you may not use this file except in compliance with the License.
; You may obtain a copy of the License at
;
;     http://www.apache.org/licenses/LICENSE-2.0
;
; Unless required by applicable law or agreed to in writing, software
; distributed under the License is distributed on an "AS IS" BASIS,
; WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
; See the License for the specific language governing permissions and
; limitations under the License.

FindColonOrCR:
                        ld bc, 0
.loop:                  ld a, (hl)
                        cp ':'
                        ret z
                        cp CR
                        ret z
                        inc hl
                        inc bc
                        jr .loop

FindNonSpace:
                        ld de, (ArgsEnd)
.loop:                  ld a, (hl)
                        cp Space
                        ret nz                          ; Return with carry clear if found
                        inc hl
                        ld a, e
                        cp l
                        jr nz, .loop
                        ld a, d
                        cp h
                        jr nz, .loop
                        scf
                        ret                             ; Return with carry set if not found

FindSpace:
                        ld bc, 0
                        ld de, (ArgsEnd)
.loop:                  ld a, (hl)
                        cp Space
                        ret z                           ; Return with carry clear if found
                        inc hl
                        inc bc
                        ld a, e
                        cp l
                        jr nz, .loop
                        ld a, d
                        cp h
                        jr nz, .loop
                        scf
                        ret                             ; Return with carry set if not found

FindSpaceColonCR:
                        ld bc, 0
                        ld de, (ArgsEnd)
.loop:                  ld a, (hl)
                        cp Space
                        ret z                           ; Return with carry clear if found
                        cp ':'
                        ret z                           ; Return with carry clear if found
                        cp CR
                        ret z                           ; Return with carry clear if found
                        inc hl
                        inc bc
                        ld a, e
                        cp l
                        jr nz, .loop
                        ld a, d
                        cp h
                        jr nz, .loop
                        //scf
                        or a
                        ret                             ; Return with carry set if not found

GetBufferLength:
                        push hl
                        ld bc, BufferLen
                        xor a
                        cpir
                        dec hl
                        pop de
                        push de
                        sbc hl, de
                        ld e, l
                        pop hl
                        ret

ConvertWordToAsc:                                       ; Input word in hl
                        ld de, WordStart                ; Returns with output word in hl and length in a
                        ld bc, -10000
                        call .num1
                        ld bc, -1000
                        call .num1
                        ld bc, -100
                        call .num1
                        ld c, -10
                        call .num1
                        ld c, -1
                        call .num1
                        ld hl, WordStart
                        ld b, 5
                        ld c, '0'
.findLoop:              ld a, (hl)
                        cp c
                        jp nz, .found
                        inc hl
                        djnz .findLoop
.found:                 ld a, b
                        ld (WordLen), a
                        ld (WordStart), hl
                        ret
.num1:                  ld a, '0'-1
.num2:                  inc a
                        add hl, bc
                        jr c, .num2
                        sbc hl, bc
                        ld (de), a
                        inc de
                        ret

DecimalDigits.Table:
; Multipler  Index  Digits
  dw      1  ;   0       1
  dw     10  ;   1       2
  dw    100  ;   2       3
  dw   1000  ;   3       4
  dw  10000  ;   4       5


DecodeDecimalProc:                                      ; IN:   b = digit count
                        ld hl, 0                        ; OUT: hl = return value (0..65535)
                        ld (DDP.total), hl
DDP.digitLoop:
                        ld a, b
                        dec a
                        add a, a
                        ld hl, DecimalDigits.Table
                        add hl, a
                        ld e, (hl)
                        inc hl
                        ld d, (hl)                      ; de = digit multiplier (1, 10, 100, 1000, 10000)
                        ld (DDP.digitMultiplier), de
DecodeDecimalProc.DecimalBuffer+*:ld hl, SMC
                        inc hl
                        ld (DecodeDecimalProc.DecimalBuffer), hl
                        ld a, (hl)
                        sub '0'                         ; a = digit 0..9 (could also be out of range)
                        exx
                        ld hl, 0
                        or a
                        jp z, DDP.dontAdd
DDP.multiplyLoop:
DDP.digitMultiplier+*:  add hl, SMC                     ; Next-only opcode
                        dec a
                        jp nz, DDP.multiplyLoop
DDP.dontAdd:
DDP.total+*:            add hl, SMC                     ; Next-only opcode
                        ld (DDP.total), hl
                        exx
                        djnz DDP.digitLoop              ; Repeat until no more digits left (b = 0..5)
                        ld hl, (DDP.total)                 ; hl = return value (0..65535)
                        ret

NextRegReadProc:
                        out (c), a
                        inc b
                        in a, (c)
                        ret

ReadAndCheckDigit:
                        ld a, (hl)
                        cp '0'
                        ret c                           ; Return with carry set if < 0
                        cp '9'+1
                        jr nc, .err                     ; Return with carry set if > 9
                        or a
                        ret                             ; Return with carry clear if 0..9
.err:                   scf
                        ret

WaitFramesProc:
                        ei
.loop:                   halt
                        djnz .loop
                        di
                        ret
