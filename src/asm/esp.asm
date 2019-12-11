; esp.asm

ESPSend                 macro(Text)                     ; 1 <= length(Text) <= 253
                        ld hl, Address                  ; Start of the text to send
                        ld e, length(Text)+2            ; Length of the text to send, including terminating CRLF
                        jp ESPSendProc                  ; Remaining send code is generic and reusable
Address:                db Text                         ; Text bytes get planted at the end of the macro
                        db CR, LF                       ; Followed by CRLF
mend                                                    ; ESPSendProc jumps back to the address after the CRLF.

ESPSendBytes            macro(Address, Length)          ; 1 <= length(Text) <= 255 - MUST HAVE CRLF termination
                        ld hl, Address                  ; Start of the text to send
                        ld e, Length                    ; Length of the text to send, including terminating CRLF
                        jp ESPSendProc                  ; Remaining send code is generic and reusable
mend                                                    ; ESPSendProc jumps back to the address after the CRLF.

ESPSendBuffer           macro(Address)                  ; 1 <= length(Text) <= 255 - MUST HAVE CRLF termination
                        ld hl, Address                  ; Start of the text to send
                        call GetBufferLength            ; returns with length in e and hl preserved
                        call ESPSendBufferProc          ; Remaining send code is generic and reusable
mend

ESPSendBufferLen        macro(Address, LenAddr)         ; 1 <= length(Text) <= 255 - MUST HAVE CRLF termination
                        ld hl, Address                  ; Start of the text to send
                        ld de, (LenAddr)
                        call ESPSendBufferProc          ; Remaining send code is generic and reusable
mend

ESPSendProc             proc
                        di
                        call InitESPTimeout
                        ld bc, UART_GetStatus           ; UART Tx port also gives the UART status when read
ReadNextChar:           ld d, (hl)                      ; Read the next byte of the text to be sent
WaitNotBusy:            in a, (c)                       ; Read the UART status
                        and UART_mTX_BUSY               ; and check the busy bit (bit 1)
                        jr nz, CheckTimeout             ; If busy, keep trying until not busy
                        out (c), d                      ; Otherwise send the byte to the UART Tx port
                        inc hl                          ; Move to next byte of the text
                        dec e                           ; Check whether there are any more bytes of text
                        jp nz, ReadNextChar             ; If there are, read and repeat
                        ei
                        jp (hl)                         ; Otherwise we are now pointing at the byte after the macro
CheckTimeout:           call CheckESPTimeout
                        jp WaitNotBusy
pend

ESPSendBufferProc       proc
                        di
                        call InitESPTimeout
                        ld bc, UART_GetStatus           ; UART Tx port also gives the UART status when read
ReadNextChar:           ld d, (hl)                      ; Read the next byte of the text to be sent
WaitNotBusy:            in a, (c)                       ; Read the UART status
                        and UART_mTX_BUSY               ; and check the busy bit (bit 1)
                        jr nz, CheckTimeout             ; If busy, keep trying until not busy
                        out (c), d                      ; Otherwise send the byte to the UART Tx port
                        inc hl                          ; Move to next byte of the text
                        dec e                           ; Check whether there are any more bytes of text
                        jp nz, ReadNextChar             ; If there are, read and repeat
                        ei
                        ret
CheckTimeout:           call CheckESPTimeout
                        jp WaitNotBusy
pend

ESPReceiveWaitOK        proc
                        di
                        call InitESPTimeout
                        xor a
                        ld (State), a
                        ld hl, FirstChar
                        ld (StateJump), hl
NotReady:               ld a, 255
                        ld(23692), a                    ; Turn off ULA scroll
                        ld a, high UART_GetStatus       ; Are there any characters waiting?
                        in a, (low UART_GetStatus)      ; This inputs from the 16-bit address UART_GetStatus
                        rrca                            ; Check UART_mRX_DATA_READY flag in bit 0
                        jp nc, CheckTimeout             ; If not, retry
                        ld a, high UART_RxD             ; Otherwise Read the byte
                        in a, (low UART_RxD)            ; from the UART Rx port
StateJump equ $+1:      jp SMC
FirstChar:              cp 'O'
                        jp z, MatchOK
                        cp 'E'
                        jp z, MatchError
                        cp 'S'
                        jp z, MatchSendFail
                        jp Print
SubsequentChar:         cp (hl)
                        jp z, MatchSubsequent
                        ld hl, FirstChar
                        ld (StateJump), hl
Print:                  call CheckESPTimeout
Compare equ $+1:        ld de, SMC
                        CpHL(de)
                        jp nz, NotReady
                        ld a, (State)
                        cp 0
                        ei
                        ret
MatchSubsequent:        inc hl
                        jp Print
MatchOK:                ld hl, SubsequentChar
                        ld (StateJump), hl
                        ld hl, OKEnd
                        ld (Compare), hl
                        ld hl, OK
                        xor a
                        ld (State), a
                        jp Print
MatchError:             ld hl, SubsequentChar
                        ld (StateJump), hl
                        ld hl, ErrorEnd
                        ld (Compare), hl
                        ld hl, Error
                        ld a, 1
                        ld (State), a
                        jp Print
MatchSendFail:          ld hl, SubsequentChar
                        ld (StateJump), hl
                        ld hl, SendFailEnd
                        ld (Compare), hl
                        ld hl, Error
                        ld a, 2
                        ld (State), a
                        jp Print
CheckTimeout:           call CheckESPTimeout
                        jp NotReady
State:                  db 0
OK:                     db "K", CR, LF
OKEnd:
Error:                  db "RROR", CR, LF
ErrorEnd:
SendFail:               db "END FAIL", CR, LF
SendFailEnd:
pend

ESPReceiveWaitPrompt    proc
                        di
                        call InitESPTimeout
                        ld a, high UART_GetStatus       ; Are there any characters waiting?
WaitNotBusy:            in a, (low UART_GetStatus)      ; This inputs from the 16-bit address UART_GetStatus
                        rrca                            ; Check UART_mRX_DATA_READY flag in bit 0
                        jp nc, CheckTimeout             ; If not, retry
                        ld a, high UART_RxD             ; Otherwise Read the byte
                        in a, (low UART_RxD)            ; from the UART Rx port
                        cp '>'
                        jp z, Success
CheckTimeout:           call CheckESPTimeout
                        jp WaitNotBusy
Success:                or a
                        ret
pend

InitESPTimeout          proc
                        push hl
                        ld hl, ESPTimeout
                        ld (CheckESPTimeout.Value), hl
                        pop hl
                        ret
pend

CheckESPTimeout         proc
                        push hl
                        push af
Value equ $+1:          ld hl, SMC
                        dec hl
                        ld (Value), hl
                        ld a, h
                        or l
                        jp z, Failure
Success:
                        pop af
                        pop hl
                        ret
Failure:
                        pop af
                        pop hl
                        pop af
                        scf
                        ret
pend
/*
ESPReceiveIPDInit       proc
                        ld a, $F3                       ; $F3 = di
                        ld (ESPReceiveIPD), a
                        //ld a, Teletext.ClearBit7
                        //ld (ESPReceiveIPD.Bit7), a
                        //ld hl, ESPReceiveIPD.SizeBuffer
                        ld (ESPReceiveIPD.SizePointer), hl
                        FillLDIR(ESPReceiveIPD.SizeBuffer, ESPReceiveIPD.SizeBufferLen, 0)
                        FillLDIR(Buffer, BufferLen, ' ')
                        ld hl, ESPReceiveIPD.FirstChar
                        ld (ESPReceiveIPD.StateJump), hl
                        ld (ESPReceiveIPD.CurrentState), hl
                        ret
pend

ESPReceiveIPD           proc
                        di
CurrentState equ $+1:   ld hl, SMC
                        ld a, high UART_GetStatus       ; Are there any characters waiting?
                        in a, (low UART_GetStatus)      ; This inputs from the 16-bit address UART_GetStatus
                        rrca                            ; Check UART_mRX_DATA_READY flag in bit 0
                        jp nc, Return                   ; Return immmediately if not ready (we call this in a tight loop)
                        ld a, high UART_RxD             ; Otherwise Read the byte
                        in a, (low UART_RxD)            ; from the UART Rx port
StateJump equ $+1:      jp SMC
FirstChar:              cp '+'
                        jp z, MatchPlusIPD
SubsequentChar:         cp (hl)
                        jp z, MatchSubsequent
Print:
Compare equ $+1:        ld de, SMC
                        CpHL(de)
                        jp z, MatchSize
Return:                 ld a, 1
                        or a                            ; Clear Z flag
                        ei
                        ret
MatchPlusIPD:           ld hl, SubsequentChar
                        ld (StateJump), hl
                        ld hl, PlusIPDEnd
                        ld (Compare), hl
                        ld hl, PlusIPD
                        ld (CurrentState), hl
                        jp Print
MatchSize:              ld hl, CaptureSize
                        ld (StateJump), hl
                        ld (Compare), hl
                        jp Return
MatchSubsequent:        inc hl
                        ld (CurrentState), hl
                        jp Print
//Hex:                    call PrintHex
//                        jp PrintReturn
CaptureSize:            cp ':'
                        jp z, EndOfSize
                        cp ';'
                        jp z, EndOfSize
SizePointer equ $+1:    ld hl, SMC
                        ld (hl), a
                        inc hl
                        ld (SizePointer), hl
                        jp Print
FillBuffer:             ld b, a
                        //cp Teletext.Escape
                        //jp z, EscapeNextChar
FillBufferPointer equ $+1: ld hl, SMC
                        //or [Bit7]SMC
                        ld (hl), a
                        inc hl
                        ld (FillBufferPointer), hl
                        ld hl, (PacketSize)
                        dec hl
                        ld (PacketSize), hl
                        dec hl
                        ld a, h
                        or l
                        //ld a, Teletext.ClearBit7
                        //ld (Bit7), a
                        ld a, b
                        jp z, PacketCompleted
                        jp Print
EscapeNextChar:         //ld a, Teletext.SetBit7
                        //ld (Bit7), a
                        //ld hl, (ProcessESPBufferToPage.SourceCount)
                        //dec hl
                        //ld (ProcessESPBufferToPage.SourceCount), hl
                        //ld hl, (PacketSize)
                        //dec hl
                        //ld (PacketSize), hl
                        ld a, b
                        jp Print
EndOfSize:              ld hl, FillBuffer
                        ld (StateJump), hl
                        ld hl, 0
                        ld (PacketSize), hl
                        ld hl, SizeBuffer-1
                        ld (SizePointer2), hl
                        ld hl, (SizePointer)
DigitLoop:              ld de, SizeBuffer
                        sbc hl, de
                        ld a, l
                        or a
                        jp z, FinishedCounting
                        dec a
                        add a, a
                        ld hl, DecimalDigits
                        add hl, a
                        ld e, (hl)
                        inc hl
                        ld d, (hl)
SizePointer2 equ $+1:   ld hl, SMC
                        inc hl
                        ld (SizePointer2), hl
                        ld a, (hl)
                        sub '0'
                        jp z, Zero
                        ld b, a
PacketSize equ $+1:     ld hl, SMC
Add:                    add hl, de
                        djnz Add
                        ld (PacketSize), hl
Zero:                   ld hl, (SizePointer)
                        dec hl
                        ld (SizePointer), hl
                        jp DigitLoop
FinishedCounting:
                        ld hl, (PacketSize)
                        inc hl
                        ld (PacketSize), hl
                        dec hl
                        //ld (ProcessESPBufferToPage.SourceCount), hl
                        ld hl, Buffer
                        ld (FillBufferPointer), hl
                        jp Print
PacketCompleted:        //ld b, a
                        ld a, $C9                       ; $C9 = ret
                        ld (ESPReceiveIPD), a
                        //call ProcessESPBufferToPage
                        //ld a, b
                        //jp Print
                        xor a                           ; Clear Z flag
                        ei
                        ret
PlusIPD:                db "IPD,"
PlusIPDEnd:
SizeBuffer:             ds 6
                        ds 6
SizeBufferLen           equ $-SizeBuffer
SizeBufferEnd           equ $-1
pend
*/

