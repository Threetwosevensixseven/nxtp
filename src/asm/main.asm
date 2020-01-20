 ; main.asm
                                                        ; Assembles with regular version of Zeus (not Next version),
zeusemulate             "48K", "RAW", "NOROM"           ; because that makes it easier to assemble dot commands
zoSupportStringEscapes  = true;                         ; Download Zeus.exe from http://www.desdes.com/products/oldfiles/
optionsize 5
CSpect optionbool 15, -15, "CSpect", false              ; Option in Zeus GUI to launch CSpect
RealESP optionbool 80, -15, "Real ESP", false           ; Launch CSpect with physical ESP in USB adaptor
UploadNext optionbool 160, -15, "Next", false           ; Copy dot command to Next FlashAir card
ErrDebug optionbool 212, -15, "Debug", false            ; Print errors onscreen and halt instead of returning to BASIC

org $2000                                               ; Dot commands always start at $2000.
Start:                  jp Main                         ; Entry point, jump to start of code.
                                                        ; This will be overwrtten when we load .date and .time.
                                                        ; Between $2000 and $2800, reserve 2KB of space to accommodate
org $2800                                               ; Loading .date and .time at $2000 co-resident with .nxtp.
Main                    proc
                        di
                        ld (Return.Stack1), sp          ; Save stack so we can always return without needing
                        ld (SavedArgs), hl              ; Save args for later

                        call InstallErrorHandler        ; Handle esxDOS and scroll errors

                        ld a, %0000 0001                ; Test for Next courtesy of Simon N Goodwin , thanks :)
                        MirrorA()                       ; Z80N-only opcode. If standard Z80 or successors, this
                        nop                             ; will be executed as benign opcodes that don't affect A.
                        nop
                        cp %1000 0000                   ; Test that A was mirrored as expected
                        ld hl, Err.NotNext              ; Error message to display
                        jp nz, Return.WithCustomError   ; Exit with error if not a Next

                        NextRegRead(Reg.MachineID)      ; If we passed that test we are safe to read machine ID.
                        cp 10                           ; 10 = ZX Spectrum Next
                        jp z, SetSpeed
                        cp 8                            ;  8 = Emulator
                        jp nz, Return.WithCustomError   ; Exit with error if not a Next. HL still points to message.
SetSpeed:
                        NextRegRead(Reg.CPUSpeed)       ; Read CPU speed
                        and %11                         ; Mask out everything but the current desired speed
                        ld (Return.CPU1), a             ; Save current speed so it
                        ld (Return.CPU2), a             ; can be restored on exit
                        nextreg Reg.CPUSpeed, %11       ; Set current desired speed to 28MHz

                        NextRegRead(Reg.CoreMSB)        ; Core Major/Minor version
                        ld h, a
                        NextRegRead(Reg.CoreLSB)        ; Core Sub version
                        ld l, a                         ; HL = version, should be >= $3004
                        ld de, CoreMinVersion
                        CpHL(de)
                        ErrorIfCarry(Err.CoreMin)       ; Raise minimum core error if < 3.00.04

SavedArgs equ $+1:      ld hl, SMC                      ; Restore args
                        ld a, h                         ; Check args length
                        or l
                        jp z, PrintHelp                 ; If hl was 0 then there are no args at all
                        ld (ArgsStart), hl              ; Save start of args
ParseArgs:
                        call FindColonOrCR              ; Find end of args
                        ld (ArgsEnd), hl                ; Save end of args
                        ld (ArgsLen), bc                ; Save length of args
                        ld hl, (ArgsStart)              ; Go to start of args
ParseHost:
                        call FindNonSpace               ; Find start of hostname
                        jp c, PrintHelp                 ; Print help if hostname not found
                        ld (HostStart), hl              ; Save start of hostname
                        call FindSpace                  ; Find end of hostname
                        ld (HostLen), bc
                        jp c, PrintHelp                 ; Print help if hostname not found
                        ld hl, MaxHostSize
                        CpHL(bc)
                        ErrorIfCarry(Err.HostLen)       ; Error if hostname is larger than buffer
ParsePort:
                        ld hl, (HostStart)
                        add hl, bc
                        call FindNonSpace               ; Find start of port
                        jp c, PrintHelp                 ; Print help if port not found
                        ld (PortStart), hl              ; Save start of port
                        call FindSpaceColonCR           ; Find end of hostname
                        jp c, PrintHelp                 ; Print help if port not found
                        ld (PortLen), bc                ; Save len of port
ParseZone:
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
                        CpHL(bc)
                        ErrorIfCarry(Err.ZoneLen)       ; Error if zone is larger than buffer
MakeCIPStart:
                        ld de, Buffer
                        WriteString(Cmd.CIPSTART1, Cmd.CIPSTART1Len)
                        WriteBuffer(HostStart, HostLen)
                        WriteString(Cmd.CIPSTART2, Cmd.CIPSTART2Len)
                        WriteBuffer(PortStart, PortLen)
                        WriteString(Cmd.Terminate, Cmd.TerminateLen)
InitialiseESP:
                        PrintMsg(Msg.InitESP)           ; "Initialising WiFi..."
                        PrintMsg(Msg.SetBaud1)          ; "Using 115200 baud, "
                        NextRegRead(Reg.VideoTiming)
                        and %111
                        push af
                        ld d, a
                        ld e, 5
                        mul
                        ex de, hl
                        add hl, Timings.Table
                        call PrintRst16                 ; "VGA0/../VGA6/HDMI"
                        PrintMsg(Msg.SetBaud2)          ; " timings"
                        pop af
                        add a,a
                        ld hl, Baud.Table
                        add hl, a
                        ld e, (hl)
                        inc hl
                        ld d, (hl)
                        ex de, hl                       ; HL now contains the prescalar baud value
                        ld (Prescaler), hl
                        ld a, %x0x1 x000                ; Choose ESP UART, and set most significant bits
                        ld (Prescaler+2), a             ; of the 17-bit prescalar baud to zero,
                        ld bc, UART_Sel                 ; by writing to port 0x143B.
                        out (c), a
                        dec b                           ; Set baud by writing twice to port 0x143B
                        out (c), l                      ; Doesn't matter which order they are written,
                        out (c), h                      ; because bit 7 ensures that it is interpreted correctly.
                        inc b                           ; Write to UART control port 0x153B

                        ld a, (Prescaler+2)             ; Print three bytes written for debug purposes
                        call PrintAHexNoSpace
                        ld a, (Prescaler+1)
                        call PrintAHexNoSpace
                        ld a, (Prescaler)
                        call PrintAHexNoSpace
                        ld a, CR
                        rst 16

                        ESPSend("ATE0")
                        ErrorIfCarry(Err.ESPComms1)     ; Raise ESP error if no response
                        call ESPReceiveWaitOK
                        ErrorIfCarry(Err.ESPComms2)     ; Raise ESP error if no response
                        ESPSend("AT+CIPCLOSE")          ; Don't raise error on CIPCLOSE
                        call ESPReceiveWaitOK           ; Because it might not be open
                        //ErrorIfCarry(Err.ESPComms)    ; We never normally want to raise an error after CLOSE
                        ESPSend("AT+CIPMUX=0")
                        ErrorIfCarry(Err.ESPComms3)     ; Raise ESP error if no response
                        call ESPReceiveWaitOK
                        ErrorIfCarry(Err.ESPComms4)     ; Raise ESP error if no response
Connect:
                        PrintMsg(Msg.Connect1)
                        PrintBuffer(HostStart, HostLen)
                        PrintMsg(Msg.Connect2)
                        ESPSendBuffer(Buffer)           ; This is AT+CIPSTART="TCP","<server>",<port>\r\n
                        ErrorIfCarry(Err.ESPConn1)      ; Raise ESP error if no connection
                        call ESPReceiveWaitOK
                        ErrorIfCarry(Err.ESPConn2)      ; Raise ESP error if no response
                        //PrintMsg(Msg.Connected)
PrintAnyZone:
                        ld hl, (ZoneStart)
                        ld a, h
                        or l
                        jp z, PrintNoZone
PrintHasZone:           PrintMsg(Msg.UsingTZ)
                        PrintBuffer(ZoneStart, ZoneLen)
                        PrintMsg(Msg.Connect2)
                        jp AfterPrintZone
PrintNoZone:            PrintMsg(Msg.UsingTZDef)
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
                        AddHL(3)
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
                        PrintMsg(Msg.Sending1)          ; This has to happen before MakeCIPSend
                        PrintBuffer(WordStart, WordLen) ; Because they both use MsgBuffer
                        PrintMsg(Msg.Sending2)*/
MakeCIPSend:
                        ld de, MsgBuffer
                        WriteString(Cmd.CIPSEND, Cmd.CIPSENDLen)
                        WriteBuffer(WordStart, WordLen)
                        WriteString(Cmd.Terminate, Cmd.TerminateLen)
SendRequest:
                        ESPSendBuffer(MsgBuffer)
                        call ESPReceiveWaitOK
                        ErrorIfCarry(Err.ESPComms5)     ; Raise wifi error if no response
                        call ESPReceiveWaitPrompt
                        ErrorIfCarry(Err.ESPComms6)     ; Raise wifi error if no prompt
                        ESPSendBufferLen(Buffer, RequestLen)
                        ErrorIfCarry(Err.ESPConn3)      ; Raise connection error
ReceiveResponse:
                        call ESPReceiveBuffer
                        call ParseIPDPacket
                        ErrorIfCarry(Err.ESPConn4)      ; Raise connection error if no IPD packet
ValidateResponse:
                        ld hl, (ResponseStart)          ; Start of response
                        ld a, (hl)                      ; Read protocol version
                        cp ProtoVersion
                        ErrorIfNonZero(Err.BadResp1)    ; Raise invalid response error if wrong protocol version
                        inc hl
                        ld a, (hl)                      ; Read date length
                        cp ProtoDateLen
                        ErrorIfNonZero(Err.BadResp2)    ; Raise invalid response error if not length of nn/nn/nnnn
                        inc hl
                        ld a, (hl)                      ; Read time length
                        cp ProtoTimeLen
                        ErrorIfNonZero(Err.BadResp3)    ; Raise invalid response error if not length of nn:nn:nn
ValidateDate:
                        inc hl
                        call ReadAndCheckDigit          ; Read Date digit 1
                        ErrorIfCarry(Err.BadResp4)      ; Raise invalid response error if not Date digit 1
                        inc hl
                        call ReadAndCheckDigit          ; Read Date digit 2
                        ErrorIfCarry(Err.BadResp5)      ; Raise invalid response error if not Date digit 2
                        inc hl
                        ld a, (hl)                      ; Read /
                        cp '/'
                        ErrorIfCarry(Err.BadResp6)      ; Raise invalid response error if not /
                        inc hl
                        call ReadAndCheckDigit          ; Read Month digit 1
                        ErrorIfCarry(Err.BadResp7)      ; Raise invalid response error if not Month digit 1
                        inc hl
                        call ReadAndCheckDigit          ; Read Month digit 2
                        ErrorIfCarry(Err.BadResp8)      ; Raise invalid response error if not Month digit 2
                        inc hl
                        ld a, (hl)                      ; Read /
                        cp '/'
                        ErrorIfCarry(Err.BadResp9)      ; Raise invalid response error if not /
                        inc hl
                        call ReadAndCheckDigit          ; Read Year digit 1
                        ErrorIfCarry(Err.BadResp10)     ; Raise invalid response error if not Year digit 1
                        inc hl
                        call ReadAndCheckDigit          ; Read Year digit 2
                        ErrorIfCarry(Err.BadResp11)     ; Raise invalid response error if not Year digit 2
                        inc hl
                        call ReadAndCheckDigit          ; Read Year digit 3
                        ErrorIfCarry(Err.BadResp12)     ; Raise invalid response error if not Year digit 3
                        inc hl
                        call ReadAndCheckDigit          ; Read Year digit 4
                        ErrorIfCarry(Err.BadResp13)     ; Raise invalid response error if not Year digit 4
ValidateTime:
                        inc hl
                        call ReadAndCheckDigit          ; Read Hours digit 1
                        ErrorIfCarry(Err.BadResp14)     ; Raise invalid response error if not Hours digit 1
                        inc hl
                        call ReadAndCheckDigit          ; Read Hours digit 2
                        ErrorIfCarry(Err.BadResp15)     ; Raise invalid response error if not Hours digit 2
                        inc hl
                        ld a, (hl)                      ; Read :
                        cp ':'
                        ErrorIfCarry(Err.BadResp16)     ; Raise invalid response error if not :
                        inc hl
                        call ReadAndCheckDigit          ; Read Mins digit 1
                        ErrorIfCarry(Err.BadResp17)     ; Raise invalid response error if not Mins digit 1
                        inc hl
                        call ReadAndCheckDigit          ; Read Mins digit 2
                        ErrorIfCarry(Err.BadResp18)     ; Raise invalid response error if not Mins digit 2
                        inc hl
                        ld a, (hl)                      ; Read :
                        cp ':'
                        ErrorIfCarry(Err.BadResp19)     ; Raise invalid response error if not :
                        inc hl
                        call ReadAndCheckDigit          ; Read Secs digit 1
                        ErrorIfCarry(Err.BadResp20)     ; Raise invalid response error if not Secs digit 1
                        inc hl
                        call ReadAndCheckDigit          ; Read Secs digit 2
                        ErrorIfCarry(Err.BadResp21)     ; Raise invalid response error if not Secs digit 2
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
                        PrintMsg(Msg.Received)
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
                        PrintMsg(Msg.Setting)
                        call esxDOS.GetSetDrive
                        ld hl, Files.Date               ; HL not IX because we are in a dot command
                        call esxDOS.fOpen               ; Open .date file
                        ErrorIfCarry(Err.DateNFF)       ; Raise missing .date error if not loaded
                        ld hl, $2000                    ; Read .date command file into $2000
                        ld bc, $800                     ; Maximum 2KB (it should be considerably smaller than 2KB)
                        call  esxDOS.fRead
                        ErrorIfCarry(Err.DateNFF)       ; Raise missing .date error if not loaded
                        ld hl, DateBuffer               ; Simulates the args passed into a dot command by NextZXOS
                        call $2000                      ; Call dot command entry point
CallDotTime:
                        ld hl, Files.Time               ; HL not IX because we are in a dot command
                        call esxDOS.fOpen               ; Open .time file
                        ErrorIfCarry(Err.TimeNFF)       ; Raise missing .date error if not loaded
                        ld hl, $2000                    ; Read .time command file into $2000
                        ld bc, $800                     ; Maximum 2KB (it should be considerably smaller than 2KB)
                        call  esxDOS.fRead
                        ErrorIfCarry(Err.TimeNFF)       ; Raise missing .time error if not loaded
                        ld hl, TimeBuffer               ; Simulates the args passed into a dot command by NextZXOS
                        call $2000                      ; Call dot command entry point

                        ; .date and .time don't throw any error messages or return to BASIC, so there is nothing to
                        ; to handle after they return. We can assume they printed info about success or failure for
                        ; the user, so if we got to this point we can return to the next BASIC line or the OK prompt.

                        jp Return.ToBasic
NoZone:
                        ld hl, 0
                        ld (ZoneStart), hl
                        ld (ZoneLen), hl
                        jp MakeCIPStart
pend

InstallErrorHandler     proc
                        ld hl, ErrorHandler
                        rst 8
                        noflow
                        db M_ERRH
                        ret
pend

ErrorHandler proc
                        ld hl, Err.Break
                        jp Return.WithCustomError
pend

Return                  proc
ToBasic:
CPU1 equ $+3:           nextreg Reg.CPUSpeed, SMC       ; Restore original CPU speed
                        xor a
Stack                   ld sp, SMC                      ; Unwind stack to original point
Stack1                  equ Stack+1
                        ei
                        ret                             ; Return to BASIC
WithCustomError:
CPU2 equ $+3:           nextreg Reg.CPUSpeed, SMC       ; Restore original CPU speed
                        xor a
                        scf                             ; Signal error, hl = custom error message
                        jp Stack                        ; (NextZXOS is not currently displaying standard error messages,
pend                                                    ;  with a>0 and carry cleared, so we use a custom message.)

                        include "constants.asm"         ; Global constants
                        include "macros.asm"            ; Zeus macros
                        include "parse.asm"             ; String and arg parsing routines
                        include "esp.asm"               ; ESP routines
                        include "esxDOS.asm"            ; ESXDOS routines
                        include "msg.asm"               ; Messaging and error routines
                        include "vars.asm"              ; Global variables

Length equ $-Start
zeusprinthex "Command size: ", Length

if zeusver >= 74
  zeuserror "Does not run on Zeus v4.00 (TEST ONLY) or above, Get v3.991 available at http://www.desdes.com/products/oldfiles/zeus.exe"
endif

if (Length > $2000)
  zeuserror "DOT command is too large to assemble!"
endif

output_bin "..\\..\\dot\\NXTP", Start, Length

if enabled UploadNext
  output_bin "R:\\dot\\NXTP", Start, Length
endif

if enabled CSpect
  if enabled RealESP
    zeusinvoke "..\\..\\build\\cspect.bat"
  else
    zeusinvoke "..\\..\\build\\cspect-emulate-esp.bat"
  endif
else
  zeusinvoke "..\\..\\build\\builddot.bat"
endif

