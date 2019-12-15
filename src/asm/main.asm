; main.asm
                                                        ; Assembles with regular version of Zeus (not Next version),
zeusemulate             "48K", "RAW", "NOROM"           ; because that makes it easier to assemble dot commands
zoSupportStringEscapes  = true;                         ; Download Zeus.exe from http://www.desdes.com/products/oldfiles/
optionsize 5
CSpect optionbool 15, -15, "CSpect", false              ; Option in Zeus GUI to launch CSpect
RealESP optionbool 80, -15, "Real ESP", true            ; Launch CSpect with physical ESP in USB adaptor
UploadNext optionbool 160, -15, "Next", false           ; Copy dot command to Next FlashAir card

org $2000                                               ; Dot commands always start at $2000
Start:                  jp Main                         ; Entry point, jump to start of code
                        include "vars.asm"              ; Keep global vars fixed here for easy debugging

Main                    proc
                        di
                        ld (Return.Stack1), sp          ; Save stack so we can always return without needing
                        ld (Return.Stack2), sp          ; to unwind any nested calls if there is an error.
                        ld (SavedArgs), hl              ; Save args for later

                        ld a, %0000 0001                ; Test for Next courtesy of Simon N Goodwin, thanks :)
                        MirrorA()                       ; Z80N-only opcode. If standard Z80 or successors, this
                        nop                             ; will be executed as benign opcodes that don't affect A.
                        nop
                        cp %1000 0000                   ; Test that A was mirrored as expected
                        ld hl, Errors.NotNext           ; Error message to display
                        jp nz, Return.WithError         ; Exit with error if not a Next

                        NextRegRead(Reg.MachineID)      ; If we passed that test we are safe to read machine ID.
                        cp 10                           ; 10 = ZX Spectrum Next
                        jp z, SetSpeed
                        cp 8                            ;  8 = Emulator
                        jp nz, Return.WithError         ; Exit with error if not a Next. HL still points to message.
SetSpeed:
                        NextRegRead(Reg.CPUSpeed)       ; Read CPU speed
                        and %11                         ; Mask out everything but the current desired speed
                        ld (Return.CPU1), a             ; Save current speed
                        ld (Return.CPU2), a             ; So it can be restored on exit
                        nextreg Reg.CPUSpeed, %11       ; Set current desired speed to 14MHz

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
                        ErrorIfCarry(Errors.ESPComms)   ; Raise ESP error if no response
                        call ESPReceiveWaitOK
                        ErrorIfCarry(Errors.ESPComms)   ; Raise ESP error if no response
                        ESPSend("AT+CIPCLOSE")          ; Don't raise error on CIPCLOSE
                        call ESPReceiveWaitOK           ; Because it might not be open
                        ESPSend("AT+CIPMUX=0")
                        ErrorIfCarry(Errors.ESPComms)   ; Raise ESP error if no response
                        call ESPReceiveWaitOK
                        ErrorIfCarry(Errors.ESPComms)   ; Raise ESP error if no response
Connect:
                        PrintMsg(Messages.Connect1)
                        PrintBuffer(HostStart, HostLen)
                        PrintMsg(Messages.Connect2)
                        ESPSendBuffer(Buffer)
                        ErrorIfCarry(Errors.ESPConn)    ; Raise ESP error if no connection
                        call ESPReceiveWaitOK
                        ErrorIfCarry(Errors.ESPConn)    ; Raise ESP error if no response
                        PrintMsg(Messages.Connected)
PrintAnyZone:
                        ld a, (ZoneStart)
                        or a
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
                        ldir
                        ld hl, (ZoneLen)                ; Calculate request len (inc checksum)
                        AddHL(3)
                        ld (RequestLen), hl
                        //dec hl                          ; Number of bytes to checksum (one less)
                        //dec hl
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
                        //inc hl
                        //ld (hl), CR
                        //inc hl
                        //ld (hl), LF
CalcPacketLength:
                        ld hl, (RequestLen)
                        call ConvertWordToAsc
PrintCIPSend:
                        PrintMsg(Messages.Sending1)     ; This has to happen before MakeCIPSend
                        PrintBuffer(WordStart, WordLen) ; Because they both use MsgBuffer
                        PrintMsg(Messages.Sending2)
MakeCIPSend:
                        ld de, MsgBuffer
                        WriteString(Commands.CIPSEND, Commands.CIPSENDLen)
                        WriteBuffer(WordStart, WordLen)
                        WriteString(Commands.Terminate, Commands.TerminateLen)
SendRequest:
                        ESPSendBuffer(MsgBuffer)
                        call ESPReceiveWaitOK
                        ErrorIfCarry(Errors.ESPComms)   ; Raise wifi error if no response
                        call ESPReceiveWaitPrompt
                        ErrorIfCarry(Errors.ESPComms)   ; Raise wifi error if no prompt
                        ld de, Buffer
                        ESPSendBufferLen(Buffer, RequestLen)
                        ErrorIfCarry(Errors.ESPConn)    ; Raise connection error

                        call ESPReceiveBuffer
                        call ParseIPDPacket
                        ErrorIfCarry(Errors.ESPConn)    ; Raise connection error if no IPD packet

                        //ld hl, Buffer
                        //CSBreak()

Freeze:                 ei:Freeze(1, 4)

                        jp Return.ToBasic
NoZone:
                        ld hl, 0
                        ld (ZoneStart), hl
                        ld (ZoneLen), hl
                        jp MakeCIPStart
pend

Return                  proc
ToBasic:
CPU1 equ $+3:           nextreg Reg.CPUSpeed, SMC       ; Restore original CPU speed
                        xor a
Stack1 equ $+1:         ld sp, SMC                      ; Unwind stack to original point
                        ei
                        ret                             ; Return to BASIC
WithError:
CPU2 equ $+3:           nextreg Reg.CPUSpeed, SMC       ; Restore original CPU speed
                        xor a
                        scf                             ; Signal error, hl = custom error message
Stack2 equ $+1:         ld sp, SMC                      ; Unwind stack to original point
                        ei
                        ret                             ; Return to BASIC
pend

                        include "constants.asm"         ; Global constants
                        include "macros.asm"            ; Zeus macros
                        include "parse.asm"             ; String and arg parsing routines
                        include "esp.asm"               ; ESP routines
                        include "msg.asm"               ; Messaging and error routines

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

