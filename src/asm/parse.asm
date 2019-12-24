; parse.asm

FindColonOrCR           proc
                        ld bc, 0
Loop:                   ld a, (hl)
                        cp ':'
                        ret z
                        cp CR
                        ret z
                        inc hl
                        inc bc
                        jr Loop
pend

FindNonSpace            proc
                        ld de, (ArgsEnd)
Loop:                   ld a, (hl)
                        cp Space
                        ret nz                          ; Return with carry clear if found
                        inc hl
                        ld a, e
                        cp l
                        jr nz, Loop
                        ld a, d
                        cp h
                        jr nz, Loop
                        scf
                        ret                             ; Return with carry set if not found
pend

FindSpace               proc
                        ld bc, 0
                        ld de, (ArgsEnd)
Loop:                   ld a, (hl)
                        cp Space
                        ret z                           ; Return with carry clear if found
                        inc hl
                        inc bc
                        ld a, e
                        cp l
                        jr nz, Loop
                        ld a, d
                        cp h
                        jr nz, Loop
                        scf
                        ret                             ; Return with carry set if not found
pend

FindSpaceColonCR        proc
                        ld bc, 0
                        ld de, (ArgsEnd)
Loop:                   ld a, (hl)
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
                        jr nz, Loop
                        ld a, d
                        cp h
                        jr nz, Loop
                        //scf
                        or a
                        ret                             ; Return with carry set if not found
pend

GetBufferLength         proc
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
pend

ConvertWordToAsc        proc                            ; Input word in hl
                        ld de, WordStart                ; Returns with output word in hl and length in a
                        ld bc, -10000
                        call Num1
                        ld bc, -1000
                        call Num1
                        ld bc, -100
                        call Num1
                        ld c, -10
                        call Num1
                        ld c, -1
                        call Num1
                        ld hl, WordStart
                        ld b, 5
                        ld c, '0'
FindLoop:               ld a, (hl)
                        cp c
                        jp nz, Found
                        inc hl
                        djnz FindLoop
Found:                  ld a, b
                        ld (WordLen), a
                        ld (WordStart), hl
                        ret
Num1:                   ld a, '0'-1
Num2:                   inc a
                        add hl, bc
                        jr c, Num2
                        sbc hl, bc
                        ld (de), a
                        inc de
                        ret
pend

DecimalDigits proc Table:

; Multipler  Index  Digits
  dw      1  ;   0       1
  dw     10  ;   1       2
  dw    100  ;   2       3
  dw   1000  ;   3       4
  dw  10000  ;   4       5
pend

DecodeDecimalProc       proc                            ; IN:   b = digit count
                        ld hl, 0                        ; OUT: hl = return value (0..65535)
                        ld (Total), hl
DigitLoop:              ld a, b
                        dec a
                        add a, a
                        ld hl, DecimalDigits.Table
                        add hl, a
                        ld e, (hl)
                        inc hl
                        ld d, (hl)                      ; de = digit multiplier (1, 10, 100, 1000, 10000)
                        ld (DigitMultiplier), de
DecimalBuffer equ $+1:  ld hl, SMC
                        inc hl
                        ld (DecimalBuffer), hl
                        ld a, (hl)
                        sub '0'                         ; a = digit 0..9 (could also be out of range)
                        exx
                        ld hl, 0
                        or a
                        jp z, DontAdd
MultiplyLoop:
DigitMultiplier equ $+2:add hl, SMC                     ; Next-only opcode
                        dec a
                        jp nz, MultiplyLoop
DontAdd:
Total equ $+2:          add hl, SMC                     ; Next-only opcode
                        ld (Total), hl
                        exx
                        djnz DigitLoop                  ; Repeat until no more digits left (b = 0..5)
                        ld hl, (Total)                  ; hl = return value (0..65535)
                        ret
pend

NextRegReadProc         proc
                        out (c), a
                        inc b
                        in a, (c)
                        ret
pend

