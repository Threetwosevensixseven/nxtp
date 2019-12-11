; main.asm
                                                        ; Assembles with regular version of Zeus not Next version,
zeusemulate             "48K", "RAW", "NOROM"           ; because that makes it easier to assemble dot commands
zoSupportStringEscapes  = true;
optionsize 5                                            ; Option to launch CSpect in Zeus GUI
CSpect optionbool 15, -15, "CSpect", false

org $2000                                               ; Dot commands always start at $2000
Start:                  jp Main                         ; Entry point, jump to start of code
                        include "vars.asm"              ; Keep global vars fixed here for easy debugging

Main                    proc
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
                        call FindSpace                  ; Find end of zone
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
                        dec hl                          ; Number of bytes to checksum (one less)
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
                        ErrorIfCarry(Errors.ESPComms)   ; Raise ESP error if no response
                        call ESPReceiveWaitPrompt
                        ErrorIfCarry(Errors.ESPComms)   ; Raise ESP error if no response
                        ld de, Buffer
                        ESPSendBufferLen(Buffer, RequestLen)
                        ErrorIfCarry(Errors.ESPConn)    ; Raise ESP error if no connection
GetResponse:
                        //call ESPReceiveIPDInit
MainLoop:               //call ESPReceiveIPD

                        ld hl, Buffer
                        CSBreak()

Freeze:
                        Freeze(1, 4)
NoZone:
                        ld hl, 0
                        ld (ZoneStart), hl
                        ld (ZoneLen), hl
                        jp MakeCIPStart
pend

ReturnToBasic           proc
Return:                 xor a
                        ret                             ; Return to BASIC
pend

ReturnWithError         proc
                        CSBreak()
                        xor a
                        scf                             ; Signal error, hl = custom error message
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

if enabled CSpect
  zeusinvoke "..\\..\\build\\cspect.bat"
else
  zeusinvoke "..\\..\\build\\builddot.bat"
endif

