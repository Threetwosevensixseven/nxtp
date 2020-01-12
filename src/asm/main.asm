; main.asm
                                                        ; Assembles with regular version of Zeus (not Next version),
zeusemulate             "48K", "RAW", "NOROM"           ; because that makes it easier to assemble dot commands
zoSupportStringEscapes  = true;                         ; Download Zeus.exe from http://www.desdes.com/products/oldfiles/
optionsize 5
CSpect optionbool 15, -15, "CSpect", false              ; Option in Zeus GUI to launch CSpect
RealESP optionbool 80, -15, "Real ESP", true            ; Launch CSpect with physical ESP in USB adaptor
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

                        ld a, %0000 0001                ; Test for Next courtesy of Simon N Goodwin, thanks :)
                        MirrorA()                       ; Z80N-only opcode. If standard Z80 or successors, this
                        nop                             ; will be executed as benign opcodes that don't affect A.
                        nop
                        cp %1000 0000                   ; Test that A was mirrored as expected
                        ld hl, Errors.NotNext           ; Error message to display
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
                        nextreg Reg.CPUSpeed, %11       ; Set current desired speed to 14MHz

                        //scf
                        //ErrorIfCarry(Errors.ESPComms1)  ; Check longest error message

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
                        ErrorIfCarry(Errors.HostLen)    ; Error if hostname is larger than buffer
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
                        ErrorIfCarry(Errors.ZoneLen)    ; Error if zone is larger than buffer
MakeCIPStart:
                        ld de, Buffer
                        WriteString(Commands.CIPSTART1, Commands.CIPSTART1Len)
                        WriteBuffer(HostStart, HostLen)
                        WriteString(Commands.CIPSTART2, Commands.CIPSTART2Len)
                        WriteBuffer(PortStart, PortLen)
                        WriteString(Commands.Terminate, Commands.TerminateLen)
InitialiseESP:
                        PrintMsg(Messages.InitESP)
                        ESPSend("ATE0")
                        ErrorIfCarry(Errors.ESPComms1)  ; Raise ESP error if no response
                        call ESPReceiveWaitOK
                        ErrorIfCarry(Errors.ESPComms2)  ; Raise ESP error if no response
                        ESPSend("AT+CIPCLOSE")          ; Don't raise error on CIPCLOSE
                        call ESPReceiveWaitOK           ; Because it might not be open
                        //ErrorIfCarry(Errors.ESPComms) ; We never normally want to raise an error after CLOSE
                        ESPSend("AT+CIPMUX=0")
                        ErrorIfCarry(Errors.ESPComms3)  ; Raise ESP error if no response
                        call ESPReceiveWaitOK
                        ErrorIfCarry(Errors.ESPComms4)  ; Raise ESP error if no response
Connect:
                        PrintMsg(Messages.Connect1)
                        PrintBuffer(HostStart, HostLen)
                        PrintMsg(Messages.Connect2)
                        ESPSendBuffer(Buffer)           ; This is AT+CIPSTART="TCP","<server>",<port>\r\n
                        ErrorIfCarry(Errors.ESPConn1)   ; Raise ESP error if no connection
                        call ESPReceiveWaitOK
                        ErrorIfCarry(Errors.ESPConn2)   ; Raise ESP error if no response
                        //PrintMsg(Messages.Connected)
PrintAnyZone:
                        ld hl, (ZoneStart)
                        ld a, h
                        or l
                        jp z, PrintNoZone
PrintHasZone:           PrintMsg(Messages.UsingTZ)
                        PrintBuffer(ZoneStart, ZoneLen)
                        PrintMsg(Messages.Connect2)
                        jp AfterPrintZone
PrintNoZone:            PrintMsg(Messages.UsingTZDef)
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
                        PrintMsg(Messages.Sending1)     ; This has to happen before MakeCIPSend
                        PrintBuffer(WordStart, WordLen) ; Because they both use MsgBuffer
                        PrintMsg(Messages.Sending2)*/
MakeCIPSend:
                        ld de, MsgBuffer
                        WriteString(Commands.CIPSEND, Commands.CIPSENDLen)
                        WriteBuffer(WordStart, WordLen)
                        WriteString(Commands.Terminate, Commands.TerminateLen)
SendRequest:
                        ESPSendBuffer(MsgBuffer)
                        call ESPReceiveWaitOK
                        ErrorIfCarry(Errors.ESPComms5)  ; Raise wifi error if no response
                        call ESPReceiveWaitPrompt
                        ErrorIfCarry(Errors.ESPComms6)  ; Raise wifi error if no prompt
                        ESPSendBufferLen(Buffer, RequestLen)
                        ErrorIfCarry(Errors.ESPConn3)   ; Raise connection error
ReceiveResponse:
                        call ESPReceiveBuffer
                        call ParseIPDPacket
                        ErrorIfCarry(Errors.ESPConn4)   ; Raise connection error if no IPD packet
ValidateResponse:
                        ld hl, (ResponseStart)          ; Start of response
                        ld a, (hl)                      ; Read protocol version
                        cp ProtoVersion
                        ErrorIfNonZero(Errors.BadResp1) ; Raise invalid response error if wrong protocol version
                        inc hl
                        ld a, (hl)                      ; Read date length
                        cp ProtoDateLen
                        ErrorIfNonZero(Errors.BadResp2) ; Raise invalid response error if not length of nn/nn/nnnn
                        inc hl
                        ld a, (hl)                      ; Read time length
                        cp ProtoTimeLen
                        ErrorIfNonZero(Errors.BadResp3) ; Raise invalid response error if not length of nn:nn:nn
ValidateDate:
                        inc hl
                        call ReadAndCheckDigit          ; Read Date digit 1
                        ErrorIfCarry(Errors.BadResp4)   ; Raise invalid response error if not Date digit 1
                        inc hl
                        call ReadAndCheckDigit          ; Read Date digit 2
                        ErrorIfCarry(Errors.BadResp5)   ; Raise invalid response error if not Date digit 2
                        inc hl
                        ld a, (hl)                      ; Read /
                        cp '/'
                        ErrorIfCarry(Errors.BadResp6)   ; Raise invalid response error if not /
                        inc hl
                        call ReadAndCheckDigit          ; Read Month digit 1
                        ErrorIfCarry(Errors.BadResp7)   ; Raise invalid response error if not Month digit 1
                        inc hl
                        call ReadAndCheckDigit          ; Read Month digit 2
                        ErrorIfCarry(Errors.BadResp8)   ; Raise invalid response error if not Month digit 2
                        inc hl
                        ld a, (hl)                      ; Read /
                        cp '/'
                        ErrorIfCarry(Errors.BadResp9)   ; Raise invalid response error if not /
                        inc hl
                        call ReadAndCheckDigit          ; Read Year digit 1
                        ErrorIfCarry(Errors.BadResp10)  ; Raise invalid response error if not Year digit 1
                        inc hl
                        call ReadAndCheckDigit          ; Read Year digit 2
                        ErrorIfCarry(Errors.BadResp11)  ; Raise invalid response error if not Year digit 2
                        inc hl
                        call ReadAndCheckDigit          ; Read Year digit 3
                        ErrorIfCarry(Errors.BadResp12)  ; Raise invalid response error if not Year digit 3
                        inc hl
                        call ReadAndCheckDigit          ; Read Year digit 4
                        ErrorIfCarry(Errors.BadResp13)  ; Raise invalid response error if not Year digit 4
ValidateTime:
                        inc hl
                        call ReadAndCheckDigit          ; Read Hours digit 1
                        ErrorIfCarry(Errors.BadResp14)  ; Raise invalid response error if not Hours digit 1
                        inc hl
                        call ReadAndCheckDigit          ; Read Hours digit 2
                        ErrorIfCarry(Errors.BadResp15)  ; Raise invalid response error if not Hours digit 2
                        inc hl
                        ld a, (hl)                      ; Read :
                        cp ':'
                        ErrorIfCarry(Errors.BadResp16)  ; Raise invalid response error if not :
                        inc hl
                        call ReadAndCheckDigit          ; Read Mins digit 1
                        ErrorIfCarry(Errors.BadResp17)  ; Raise invalid response error if not Mins digit 1
                        inc hl
                        call ReadAndCheckDigit          ; Read Mins digit 2
                        ErrorIfCarry(Errors.BadResp18)  ; Raise invalid response error if not Mins digit 2
                        inc hl
                        ld a, (hl)                      ; Read :
                        cp ':'
                        ErrorIfCarry(Errors.BadResp19)  ; Raise invalid response error if not :
                        inc hl
                        call ReadAndCheckDigit          ; Read Secs digit 1
                        ErrorIfCarry(Errors.BadResp20)  ; Raise invalid response error if not Secs digit 1
                        inc hl
                        call ReadAndCheckDigit          ; Read Secs digit 2
                        ErrorIfCarry(Errors.BadResp21)  ; Raise invalid response error if not Secs digit 2
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
                        PrintMsg(Messages.Received)
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
                        PrintMsg(Messages.Setting)
                        call esxDOS.GetSetDrive
                        ld hl, Files.Date               ; HL not IX because we are in a dot command
                        call esxDOS.fOpen               ; Open .date file
                        ErrorIfCarry(Errors.DateNFF)    ; Raise missing .date error if not loaded
                        ld hl, $2000                    ; Read .date command file into $2000
                        ld bc, $800                     ; Maximum 2KB (it should be considerably smaller than 2KB)
                        call  esxDOS.fRead
                        ErrorIfCarry(Errors.DateNFF)    ; Raise missing .date error if not loaded
                        ld hl, DateBuffer               ; Simulates the args passed into a dot command by NextZXOS
                        call $2000                      ; Call dot command entry point
CallDotTime:
                        ld hl, Files.Time               ; HL not IX because we are in a dot command
                        call esxDOS.fOpen               ; Open .time file
                        ErrorIfCarry(Errors.TimeNFF)    ; Raise missing .date error if not loaded
                        ld hl, $2000                    ; Read .time command file into $2000
                        ld bc, $800                     ; Maximum 2KB (it should be considerably smaller than 2KB)
                        call  esxDOS.fRead
                        ErrorIfCarry(Errors.TimeNFF)    ; Raise missing .time error if not loaded
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
                        ld hl, Errors.Break
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
                        jp Stack
pend

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

