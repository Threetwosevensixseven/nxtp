; esp.asm

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

Cmd.CIPSTART1:          db "AT+CIPSTART=\"TCP\",\""
Cmd.CIPSTART1Len        equ $-Cmd.CIPSTART1
Cmd.CIPSTART2:          db "\","
Cmd.CIPSTART2Len        equ $-Cmd.CIPSTART2
Cmd.Terminate:          db CR, LF, 0
Cmd.TerminateLen        equ $-Cmd.Terminate
Cmd.CIPSEND:            db "AT+CIPSEND="
Cmd.CIPSENDLen          equ $-Cmd.CIPSEND

Baud.Table:
                        dw $8173, $8178, $817F, $8204, $820D, $8215, $821E, $816A
                        
ESPSendProc:
                        call InitESPTimeout
                        ld bc, UART_GetStatus           ; UART Tx port also gives the UART status when read
.readNextChar:          ld d, (hl)                      ; Read the next byte of the text to be sent
.waitNotBusy:           in a, (c)                       ; Read the UART status
                        and UART_mTX_BUSY               ; and check the busy bit (bit 1)
                        jr nz, .checkTimeout            ; If busy, keep trying until not busy
                        out (c), d                      ; Otherwise send the byte to the UART Tx port
                        inc hl                          ; Move to next byte of the text
                        dec e                           ; Check whether there are any more bytes of text
                        jp nz, .readNextChar            ; If there are, read and repeat
                        jp (hl)                         ; Otherwise we are now pointing at the byte after the macro
.checkTimeout:          call CheckESPTimeout
                        jp .waitNotBusy

ESPSendBufferProc:
                        call InitESPTimeout
                        ld bc, UART_GetStatus           ; UART Tx port also gives the UART status when read
.readNextChar:          ld d, (hl)                      ; Read the next byte of the text to be sent
.waitNotBusy:           in a, (c)                       ; Read the UART status
                        and UART_mTX_BUSY               ; and check the busy bit (bit 1)
                        jr nz, .checkTimeout            ; If busy, keep trying until not busy
                        out (c), d                      ; Otherwise send the byte to the UART Tx port
                        inc hl                          ; Move to next byte of the text
                        dec e                           ; Check whether there are any more bytes of text
                        jp nz, .readNextChar             ; If there are, read and repeat
                        ret
.checkTimeout:          call CheckESPTimeout
                        jp .waitNotBusy

ESPReceiveWaitOK:
                        call InitESPTimeout
                        xor a
                        ld (.state), a
                        ld hl, .firstChar
                        ld (.stateJump), hl
.notReady:              ld a, 255
                        ld(23692), a                    ; Turn off ULA scroll
                        ld a, high UART_GetStatus       ; Are there any characters waiting?
                        in a, (low UART_GetStatus)      ; This inputs from the 16-bit address UART_GetStatus
                        rrca                            ; Check UART_mRX_DATA_READY flag in bit 0
                        jp nc, .checkTimeout            ; If not, retry
                        ld a, high UART_RxD             ; Otherwise Read the byte
                        in a, (low UART_RxD)            ; from the UART Rx port
.stateJump+*:           jp SMC
.firstChar:             cp 'O'
                        jp z, .matchOK
                        cp 'E'
                        jp z, .matchError
                        cp 'S'
                        jp z, .matchSendFail
                        jp .print
.subsequentChar:        cp (hl)
                        jp z, .matchSubsequent
                        ld hl, .firstChar
                        ld (.stateJump), hl
.print:                 call CheckESPTimeout
.compare equ $+1:       ld de, SMC
                        push hl
                        CPHL de
                        pop hl
                        jp nz, .notReady
                        ld a, (.state)
                        cp 0
                        ret z
                        scf
                        ret
.matchSubsequent:       inc hl
                        jp .print
.matchOK:               ld hl, .subsequentChar
                        ld (.stateJump), hl
                        ld hl, .okEnd
                        ld (.compare), hl
                        ld hl, .ok
                        xor a
                        ld (.state), a
                        jp .print
.matchError:            ld hl, .subsequentChar
                        ld (.stateJump), hl
                        ld hl, .errorEnd
                        ld (.compare), hl
                        ld hl, .error
                        ld a, 1
                        ld (.state), a
                        jp .print
.matchSendFail:         ld hl, .subsequentChar
                        ld (.stateJump), hl
                        ld hl, .sendFailEnd
                        ld (.compare), hl
                        ld hl, .error
                        ld a, 2
                        ld (.state), a
                        jp .print
.checkTimeout:          call CheckESPTimeout
                        jp .notReady
.state:                 db 0
.ok:                    db "K", CR, LF
.okEnd:
.error:                 db "RROR", CR, LF
.errorEnd:
.sendFail:              db "END FAIL", CR, LF
.sendFailEnd:

ESPReceiveWaitPrompt:
                        call InitESPTimeout
.waitNotBusy:           ld a, high UART_GetStatus       ; Are there any characters waiting?
                        in a, (low UART_GetStatus)      ; This inputs from the 16-bit address UART_GetStatus
                        rrca                            ; Check UART_mRX_DATA_READY flag in bit 0
                        jp nc, .checkTimeout            ; If not, retry
                        ld a, high UART_RxD             ; Otherwise Read the byte
                        in a, (low UART_RxD)            ; from the UART Rx port
                        cp '>'
                        jp z, .success
.checkTimeout:          call CheckESPTimeout
                        jp .waitNotBusy
.success:               or a
                        ret

InitESPTimeout:
                        push hl
                        ld hl, ESPTimeout mod 65536     ; Timeout is a 32-bit value, so save the two LSBs first,
                        ld (CheckESPTimeout.Value), hl
                        ld hl, ESPTimeout / 65536       ; then the two MSBs.
                        ld (CheckESPTimeout.Value2), hl
                        pop hl
                        ret

CheckESPTimeout:
                        push hl
                        push af
CheckESPTimeout.Value+*:ld hl, SMC
                        dec hl
                        ld (CheckESPTimeout.Value), hl
                        ld a, h
                        or l
                        jr z, CheckESPTimeout.Rollover
CheckESPTimeout.Success:pop af
                        pop hl
                        ret
CheckESPTimeout.Failure:ld hl, Err.ESPTimeout           ; Ignore current stack depth, and just jump
CheckESPTimeout.HandleError:
                        push hl
                        call PrintRst16Error
                        pop hl
                        jp Return.WithCustomError       ; Straight to the error handing exit routine
CheckESPTimeout.Rollover:
CheckESPTimeout.Value2+*:ld hl, SMC                     ; Check the two upper values
                        ld a, h
                        or l
                        jr z, CheckESPTimeout.Failure   ; If we hit here, 32 bit value is $00000000
                        dec hl
                        ld (CheckESPTimeout.Value2), hl
                        ld hl, ESPTimeout mod 65536
                        ld (CheckESPTimeout.Value), hl
                        jr CheckESPTimeout.Success

CheckESPTimeout2:
                        push hl
                        push af
CheckESPTimeout2.Value+*:ld hl, SMC
                        dec hl
                        ld (CheckESPTimeout2.Value), hl
                        ld a, h
                        or l
                        jp z, CheckESPTimeout2.Rollover
CheckESPTimeout2.Success:
                        pop af
                        pop hl
                        or a
                        ret
CheckESPTimeout2.Failure:
                        pop af
                        pop hl
                        scf
                        ret
CheckESPTimeout2.Rollover:
CheckESPTimeout2.Value2+*:ld hl, SMC                    ; Check the two upper values
                        ld a, h
                        or l
                        jr z, CheckESPTimeout2.Failure  ; If we hit here, 32 bit value is $00000000
                        dec hl
                        ld (CheckESPTimeout2.Value2), hl
                        ld hl, ESPTimeout mod 65536
                        ld (CheckESPTimeout2.Value), hl
                        jr CheckESPTimeout2.Success


ESPReceiveBuffer:
                        ld hl, ESPTimeout2 mod 65536
                        ld (CheckESPTimeout2.Value), hl
                        ld hl, ESPTimeout2 / 65536
                        ld (CheckESPTimeout2.Value), hl
                        ld hl, Buffer
                        ld de, BufferLen
.readLoop:              ld a, high UART_GetStatus       ; Are there any characters waiting?
                        in a, (low UART_GetStatus)      ; This inputs from the 16-bit address UART_GetStatus
                        rrca                            ; Check UART_mRX_DATA_READY flag in bit 0
                        jp nc, .checkTimeout            ; Return immmediately if not ready (we call this in a tight loop)
                        ld a, high UART_RxD             ; Otherwise Read the byte
                        in a, (low UART_RxD)            ; from the UART Rx port
                        ld (hl), a
                        inc hl
                        dec de
                        ld a, d
                        or e
                        jp z, .finished
                        jp .readLoop
.checkTimeout:          call CheckESPTimeout2
                        jp nc, .readLoop
.finished:              ld hl, BufferLen
                        sbc hl, de
                        inc hl
                        ld (ResponseLen), hl
                        ret

ParseIPDPacket:
                        ld hl, Buffer
                        ld bc, (ResponseLen)
.searchAgain:           ld a, b
                        or a
                        jp m, .notFound                  ; If bc has gone negative then not found
                        or c
                        jp z, .notFound                  ; If bc is zero then not found
                        ld a, '+'
                        cpir
                        jp po, .notFound
                        ld a, (hl)
                        cp 'I'
                        jr nz, .searchAgain
                        inc hl
                        dec bc
                        ld a, (hl)
                        cp 'P'
                        jr nz, .searchAgain
                        inc hl
                        dec bc
                        ld a, (hl)
                        cp 'D'
                        jr nz, .searchAgain
                        inc hl
                        dec bc
                        ld a, (hl)
                        cp ','
                        jr nz, .searchAgain
                        inc hl
.parseNumber:           ld (.numStart), hl
                        ld bc, 0
.parseNumberLoop:       ld a, (hl)
                        cp ':'
                        jr z, .finishedNumber
                        cp '0'
                        jp c, .notFound
                        cp '9'+1
                        jp nc, .notFound
                        inc hl
                        inc bc
                        ld a, b
                        or c
                        cp 6
                        jp c, .parseNumberLoop
.finishedNumber:
                        inc hl
                        ld (ResponseStart), hl
                        push bc
                        ld hl, 5
                        or a
                        sbc hl, bc
                        ld b, h
                        ld c, l
                        ld hl, ParseIPDPacket.Zeroes
                        ld de, ParseIPDPacket.AsciiDec
                        ldir
.numStart+*:            ld hl, SMC
                        pop bc                          ; The five bytes at AsciiDec are now the zero prefixed
                        ldir                            ; ASCII decimal IPD packet count.
                        DECODEDECIMAL ParseIPDPacket.AsciiDec, 5 ; HL now equals the IPD packet count
                        ld (ResponseLen), hl
                        or a                            ; Clear carry, no error, response round
                        ret
.notFound:
                        scf                             ; Carry, response not found
                        ret
ParseIPDPacket.AsciiDec:ds 5
ParseIPDPacket.Zeroes:  db "00000"
