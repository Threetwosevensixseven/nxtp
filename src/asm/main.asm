; main.asm

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

; Assembles with sjasmplus v1.21.1 or higher, from https://github.com/z00m128/sjasmplus
; To build (win only, sorry): cd src/asm then make
; To build and run in CSpect: make emu
; To build, sync to hardware Next and run: make sync then F4
; See additional notes in makefile
                           
                        opt reset --syntax=abfw \
                            --zxnext=cspect             ; Tighten up syntax and warnings
                        device ZXSPECTRUMNEXT           ; Make sjasmplus aware of Next memory map
                        include constants.asm           ; Define labels and constant values
                        include macros.asm              ; Define helper macros

                        org $2000                       ; Dot commands load into divMMC RAM and execute from $2000
Start:
                        jr .begin
                        db "NXTPv1."                    ; Put a signature and version in the file, in case we ever need
                        BuildNo                         ; to detect it programmatically (max 30 without terminator)                 
                        db 0                            ; Terminate signature string
.begin:                 jp Main
                        org $2800
Main:            
                        di                              ; We run with interrupts off apart from printing, input and halts
                        ld (Return.Stack1), sp          ; Save stack so we can always return without needing
                        ld (SavedArgs), hl              ; Save args for later

                        call InstallErrorHandler        ; Handle esxDOS and scroll errors
                        PRINTMSG Msg.Startup            ; "NXTP v1.x"

                        ld a, %0000'0001                ; Test for Next courtesy of Simon N Goodwin , thanks :)
                        mirror                          ; Z80N-only opcode. If standard Z80 or successors, this
                        nop                             ; will be executed as benign opcodes that don't affect A.
                        nop
                        cp %1000'0000                   ; Test that A was mirrored as expected
                        ld hl, Err.NotNext              ; Error message to display
                        jp nz, Return.WithCustomError   ; Exit with error if not a Next

                        NEXTREGREAD Reg.MachineID       ; If we passed that test we are safe to read machine ID.
                        and %0000'1111                  ; Only look at bottom four bits, to allow for Next clones
                        cp 10                           ; 10 = ZX Spectrum Next
                        jp z, .setSpeed
                        cp 8                            ;  8 = Emulator
                        jp nz, Return.WithCustomError   ; Exit with error if not a Next. HL still points to message.
.setSpeed:
                        NEXTREGREAD Reg.CPUSpeed        ; Read CPU speed
                        and %11                         ; Mask out everything but the current desired speed
                        ld (Return.CPU1), a             ; Save current speed so it
                        ld (Return.CPU2), a             ; can be restored on exit
                        nextreg Reg.CPUSpeed, %11       ; Set current desired speed to 28MHz

                        NEXTREGREAD Reg.CoreMSB         ; Core Major/Minor version
                        ld h, a
                        NEXTREGREAD Reg.CoreLSB         ; Core Sub version
                        ld l, a                         ; HL = version, should be >= $3004
                        ld de, CoreMinVersion
                        CPHL de
                        ERRORIFCARRY Err.CoreMin        ; Raise minimum core error if < 3.00.04
                        
SavedArgs+*:            ld hl, SMC                      ; Restore args
                        ld a, h                         ; Check args length
                        or l
                        jp z, PrintHelp                 ; If hl was 0 then there are no args at all
                        ld (ArgsStart), hl              ; Save start of args
.parseArgs:
                        call FindColonOrCR              ; Find end of args
                        ld (ArgsEnd), hl                ; Save end of args
                        ld (ArgsLen), bc                ; Save length of args
                        ld hl, (ArgsStart)              ; Go to start of args
.parseHost:
                        call FindNonSpace               ; Find start of hostname
                        jp c, PrintHelp                 ; Print help if hostname not found
                        ld (HostStart), hl              ; Save start of hostname
                        call FindSpace                  ; Find end of hostname
                        ld (HostLen), bc
                        jp c, PrintHelp                 ; Print help if hostname not found
                        ld hl, MaxHostSize
                        CPHL bc
                        ERRORIFCARRY Err.HostLen        ; Error if hostname is larger than buffer
.parsePort:
                        ld hl, (HostStart)
                        add hl, bc
                        call FindNonSpace               ; Find start of port
                        jp c, PrintHelp                 ; Print help if port not found
                        ld (PortStart), hl              ; Save start of port
                        call FindSpaceColonCR           ; Find end of hostname
                        jp c, PrintHelp                 ; Print help if port not found
                        ld (PortLen), bc                ; Save len of port
.parseZone:
                        ld hl, (PortStart)
                        add hl, bc
                        call FindNonSpace               ; Find start of zone
                        jp c, NoZone                    ; Skip if no zone
                        ld a, (hl)
                        cp '-'
                        jp nz, NoZone                   ; Skip if no zone
                        inc hl
                        ld a, (hl)
                        cp 'z'
                        jp nz, NoZone                   ; Skip if no zone
                        inc hl
                        ld a, (hl)
                        cp '='
                        jp nz, NoZone                   ; Skip if no zone
                        inc hl
                        ld (ZoneStart), hl              ; Save start of zone
                        call FindSpaceColonCR           ; Find end of zone
                        ld (ZoneLen), bc
                        jp c, NoZone                    ; Skip if no zone
                        ld hl, MaxZoneSize
                        CPHL bc
                        ERRORIFCARRY Err.ZoneLen        ; Error if zone is larger than buffer
MakeCIPStart:
                        ld de, Buffer
                        WRITESTRING Cmd.CIPSTART1, Cmd.CIPSTART1Len
                        WRITEBUFFER HostStart, HostLen
                        WRITESTRING Cmd.CIPSTART2, Cmd.CIPSTART2Len
                        WRITEBUFFER PortStart, PortLen
                        WRITESTRING Cmd.Terminate, Cmd.TerminateLen
InitialiseESP:
                        PRINTMSG Msg.InitESP            ; "Initialising WiFi..."
                        PRINTMSG Msg.SetBaud1           ; "Using 115200 baud, "
                        NEXTREGREAD Reg.VideoTiming
                        and %111
                        push af
                        ld d, a
                        ld e, 5
                        mul de
                        ex de, hl
                        add hl, Timings.Table
                        call PrintRst16                 ; "VGA0/../VGA6/HDMI"
                        PRINTMSG Msg.SetBaud2           ; " timings"
                        pop af
                        add a,a
                        ld hl, Baud.Table
                        add hl, a
                        ld e, (hl)
                        inc hl
                        ld d, (hl)
                        ex de, hl                       ; HL now contains the prescalar baud value
                        ld (Prescaler), hl
                        ld a, %00010000                 ; Choose ESP UART, and set most significant bits
                        ld (Prescaler+2), a             ; of the 17-bit prescalar baud to zero,
                        ld bc, UART_Sel                 ; by writing to port 0x143B.
                        out (c), a
                        dec b                           ; Set baud by writing twice to port 0x143B
                        out (c), l                      ; Doesn't matter which order they are written,
                        out (c), h                      ; because bit 7 ensures that it is interpreted correctly.
                        inc b                           ; Write to UART control port 0x153B

                        /*ld a, (Prescaler+2)           ; Print three bytes written for debug purposes
                        call PrintAHexNoSpace
                        ld a, (Prescaler+1)
                        call PrintAHexNoSpace
                        ld a, (Prescaler)
                        call PrintAHexNoSpace
                        ld a, CR
                        rst 16*/

                        ESPSEND "ATE0"                  ; * Until we have absolute frame-based timeouts, send first AT
                        call ESPReceiveWaitOK           ; * cmd twice to give it longer to respond to one of them.
                        ESPSEND "ATE0"
                        ERRORIFCARRY Err.ESPComms1      ; Raise ESP error if no response
                        call ESPReceiveWaitOK
                        ERRORIFCARRY Err.ESPComms2      ; Raise ESP error if no response
                                                        ; * However... the UART buffer probably needs flushing here now!
                        ESPSEND "AT+CIPCLOSE"           ; Don't raise error on CIPCLOSE
                        call ESPReceiveWaitOK           ; Because it might not be open
                        //ERRORIFCARRY Err.ESPComms     ; We never normally want to raise an error after CLOSE
                        ESPSEND "AT+CIPMUX=0"
                        ERRORIFCARRY Err.ESPComms3      ; Raise ESP error if no response
                        call ESPReceiveWaitOK
                        ERRORIFCARRY Err.ESPComms4      ; Raise ESP error if no response
Connect:
                        PRINTMSG Msg.Connect1
                        PRINTBUFFER HostStart, HostLen
                        PRINTMSG Msg.Connect2
                        ESPSENDBUFFER Buffer            ; This is AT+CIPSTART="TCP","<server>",<port>\r\n
                        ERRORIFCARRY Err.ESPConn1       ; Raise ESP error if no connection
                        call ESPReceiveWaitOK
                        ERRORIFCARRY Err.ESPConn2       ; Raise ESP error if no response
                        //PRINTMSG Msg.Connected
PrintAnyZone:
                        ld hl, (ZoneStart)
                        ld a, h
                        or l
                        jp z, PrintNoZone
PrintHasZone:           PRINTMSG Msg.UsingTZ
                        PRINTBUFFER ZoneStart, ZoneLen
                        PRINTMSG Msg.Connect2
                        jp AfterPrintZone
PrintNoZone:            PRINTMSG Msg.UsingTZDef
AfterPrintZone:

MakeRequest:
                        ld hl, Buffer
                        ld (hl), ProtocolVersion        ; Write protocol version byte
                        inc hl
                        ld bc, (ZoneLen)                ; Read zone length word
                        ld (hl), c                      ; Write zone length byte (LSB only)
                        inc hl
                        ex de, hl
                        ld hl, (ZoneStart)              ; Copy zone
                        ld a, h
                        or l
                        jp z, RequestNoZone
                        ldir
RequestNoZone:          ld hl, (ZoneLen)                ; Calculate request len (inc checksum)
                        add hl, 3
                        ld (RequestLen), hl
                        dec hl
                        ex de, hl
                        ld hl, Buffer
                        ld a, ChecksumSeed
ChecksumLoop:           xor (hl)                        ; Calculate checksum
                        inc hl                          ; Move to next byte
                        dec e                           ; Reduce count
                        ld d, a
                        ld a, e                         ; Check
                        or a                            ; for zero
                        ld a, d
                        jr nz, ChecksumLoop             ; otherwise process next byte
                        ld (hl), a                      ; Write checksum as final byte
CalcPacketLength:
                        ld hl, (RequestLen)
                        call ConvertWordToAsc
/*PrintCIPSend:
                        PRINTMSG Msg.Sending1           ; This has to happen before MakeCIPSend
                        PRINTBUFFER WordStart, WordLen  ; Because they both use MsgBuffer
                        PRINTMSG Msg.Sending2*/
MakeCIPSend:
                        ld de, MsgBuffer
                        WRITESTRING Cmd.CIPSEND, Cmd.CIPSENDLen
                        WRITEBUFFER WordStart, WordLen
                        WRITESTRING Cmd.Terminate, Cmd.TerminateLen
SendRequest:
                        ESPSENDBUFFER MsgBuffer
                        call ESPReceiveWaitOK
                        ERRORIFCARRY Err.ESPComms5      ; Raise wifi error if no response
                        call ESPReceiveWaitPrompt
                        ERRORIFCARRY Err.ESPComms6      ; Raise wifi error if no prompt
                        ESPSENDBUFFERLEN Buffer, RequestLen
                        ERRORIFCARRY Err.ESPConn3       ; Raise connection error
ReceiveResponse:
                        call ESPReceiveBuffer
                        call ParseIPDPacket
                        ERRORIFCARRY Err.ESPConn4       ; Raise connection error if no IPD packet
ValidateResponse:
                        ld hl, (ResponseStart)          ; Start of response
                        ld a, (hl)                      ; Read protocol version
                        cp ProtoVersion
                        ERRORIFNONZERO Err.BadResp1     ; Raise invalid response error if wrong protocol version
                        inc hl
                        ld a, (hl)                      ; Read date length
                        cp ProtoDateLen
                        ERRORIFNONZERO Err.BadResp2     ; Raise invalid response error if not length of nn/nn/nnnn
                        inc hl
                        ld a, (hl)                      ; Read time length
                        cp ProtoTimeLen
                        ERRORIFNONZERO Err.BadResp3     ; Raise invalid response error if not length of nn:nn:nn
ValidateDate:
                        inc hl
                        call ReadAndCheckDigit          ; Read Date digit 1
                        ERRORIFCARRY Err.BadResp4       ; Raise invalid response error if not Date digit 1
                        inc hl
                        call ReadAndCheckDigit          ; Read Date digit 2
                        ERRORIFCARRY Err.BadResp5       ; Raise invalid response error if not Date digit 2
                        inc hl
                        ld a, (hl)                      ; Read /
                        cp '/'
                        ERRORIFCARRY Err.BadResp6       ; Raise invalid response error if not /
                        inc hl
                        call ReadAndCheckDigit          ; Read Month digit 1
                        ERRORIFCARRY Err.BadResp7       ; Raise invalid response error if not Month digit 1
                        inc hl
                        call ReadAndCheckDigit          ; Read Month digit 2
                        ERRORIFCARRY Err.BadResp8       ; Raise invalid response error if not Month digit 2
                        inc hl
                        ld a, (hl)                      ; Read /
                        cp '/'
                        ERRORIFCARRY Err.BadResp9       ; Raise invalid response error if not /
                        inc hl
                        call ReadAndCheckDigit          ; Read Year digit 1
                        ERRORIFCARRY Err.BadResp10      ; Raise invalid response error if not Year digit 1
                        inc hl
                        call ReadAndCheckDigit          ; Read Year digit 2
                        ERRORIFCARRY Err.BadResp11      ; Raise invalid response error if not Year digit 2
                        inc hl
                        call ReadAndCheckDigit          ; Read Year digit 3
                        ERRORIFCARRY Err.BadResp12      ; Raise invalid response error if not Year digit 3
                        inc hl
                        call ReadAndCheckDigit          ; Read Year digit 4
                        ERRORIFCARRY Err.BadResp13      ; Raise invalid response error if not Year digit 4
ValidateTime:
                        inc hl
                        call ReadAndCheckDigit          ; Read Hours digit 1
                        ERRORIFCARRY Err.BadResp14      ; Raise invalid response error if not Hours digit 1
                        inc hl
                        call ReadAndCheckDigit          ; Read Hours digit 2
                        ERRORIFCARRY Err.BadResp15      ; Raise invalid response error if not Hours digit 2
                        inc hl
                        ld a, (hl)                      ; Read :
                        cp ':'
                        ERRORIFCARRY Err.BadResp16      ; Raise invalid response error if not :
                        inc hl
                        call ReadAndCheckDigit          ; Read Mins digit 1
                        ERRORIFCARRY Err.BadResp17      ; Raise invalid response error if not Mins digit 1
                        inc hl
                        call ReadAndCheckDigit          ; Read Mins digit 2
                        ERRORIFCARRY Err.BadResp18      ; Raise invalid response error if not Mins digit 2
                        inc hl
                        ld a, (hl)                      ; Read :
                        cp ':'
                        ERRORIFCARRY Err.BadResp19      ; Raise invalid response error if not :
                        inc hl
                        call ReadAndCheckDigit          ; Read Secs digit 1
                        ERRORIFCARRY Err.BadResp20      ; Raise invalid response error if not Secs digit 1
                        inc hl
                        call ReadAndCheckDigit          ; Read Secs digit 2
                        ERRORIFCARRY Err.BadResp21      ; Raise invalid response error if not Secs digit 2
SaveDateTime:
                        ld hl, (ResponseStart)          ; Copy date into a buffer suitable for .date command,
                        ld bc, 3                        ; with enclosing quotes and terminating zero.
                        add hl, bc
                        ld de, DateBufferInt
                        ld bc, ProtoDateLen
                        ldir
                        ld hl, (ResponseStart)          ; Copy date into a buffer suitable for .date command,
                        ld bc, 13                       ; with enclosing quotes and terminating zero.
                        add hl, bc
                        ld de, TimeBufferInt
                        ld bc, ProtoTimeLen
                        ldir
PrintDateTime:
                        PRINTMSG Msg.Received
                        ld hl, DateBufferInt
                        ld bc, ProtoDateLen
                        call PrintBufferLen
                        ld a, ' '
                        rst 16
                        ld hl, TimeBufferInt
                        ld bc, ProtoTimeLen
                        call PrintBufferLen
                        ld a, CR
                        rst 16
CallDotDate:
                        PRINTMSG Msg.Setting
                        ld hl, Files.Date               ; HL not IX because we are in a dot command
                        call esxDOS.fOpen               ; Open .date file
                        ERRORIFCARRY Err.DateNFF        ; Raise missing .date error if not loaded
                        ld hl, $2000                    ; Read .date command file into $2000
                        ld bc, $800                     ; Maximum 2KB (it should be considerably smaller than 2KB)
                        call  esxDOS.fRead
                        ERRORIFCARRY Err.DateNFF        ; Raise missing .date error if not loaded
                        ld hl, DateBuffer               ; Simulates the args passed into a dot command by NextZXOS
                        call $2000                      ; Call dot command entry point
CallDotTime:
                        ld hl, Files.Time               ; HL not IX because we are in a dot command
                        call esxDOS.fOpen               ; Open .time file
                        ERRORIFCARRY Err.TimeNFF        ; Raise missing .date error if not loaded
                        ld hl, $2000                    ; Read .time command file into $2000
                        ld bc, $800                     ; Maximum 2KB (it should be considerably smaller than 2KB)
                        call  esxDOS.fRead
                        ERRORIFCARRY Err.TimeNFF        ; Raise missing .time error if not loaded
                        ld hl, TimeBuffer               ; Simulates the args passed into a dot command by NextZXOS
                        call $2000                      ; Call dot command entry point

                        ; .date and .time don't throw any error messages or return to BASIC, so there is nothing to
                        ; to handle after they return. We can assume they printed info about success or failure for
                        ; the user, so if we got to this point we can return to the next BASIC line or the OK prompt.

                        ; This is the official "success" exit point of the program which restores
                        ; all the settings and exits to BASIC cleanly.
                        jp Return.ToBasic
NoZone:
                        ld hl, 0
                        ld (ZoneStart), hl
                        ld (ZoneLen), hl
                        jp MakeCIPStart
InstallErrorHandler:
                        ld hl, ErrorHandler
                        rst 8
                        db M_ERRH
                        ret
ErrorHandler:
                        ld hl, Err.Break
                        jp Return.WithCustomError
Return:
Return.ToBasic:
Return.CPU1+*:          nextreg Reg.CPUSpeed, SMC       ; Restore original CPU speed
                        xor a
Return.Stack:                                 
Return.Stack1+*:        ld sp, SMC                      ; Unwind stack to original point
                        ei
                        ret                             ; Return to BASIC
Return.WithCustomError:
Return.CPU2+*:          nextreg Reg.CPUSpeed, SMC       ; Restore original CPU speed
                        xor a
                        scf                             ; Signal error, hl = custom error message
                        jp Return.Stack                 ; (NextZXOS is not currently displaying standard error messages,
                                                        ; with a>0 and carry cleared, so we use a custom message.)

                        include "parse.asm"             ; String and arg parsing routines
                        include "esp.asm"               ; ESP routines
                        include "esxDOS.asm"            ; ESXDOS routines
                        include "msg.asm"               ; Messaging and error routines
                        include "vars.asm"              ; Global variables

End                     equ $                           ; End of the dot command
Length                  equ End-Start                   ; Length of the dot command
                        display "Dot length=",Length
                        assert Length<=$2000, "Dot length cannot be larger than $2000!"

                        savebin "../../dot/NXTP.", \
                            Start, Length               ; Output the assembled dot command binary
