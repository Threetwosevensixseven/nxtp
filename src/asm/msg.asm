; msg.asm

Messages                proc
  InitESP:              db "Initialising WiFi...", CR, 0
  InitDone:             db "Initialised", CR, 0
  Connect1:             db "Connecting to ", 0
  Connect2:             db "...", CR, 0
  Connected:            db "Connected", CR, 0
  UsingTZ:              db "Getting ", 0
  UsingTZDef:           db "Getting default zone (GMT)...", CR, 0
  Sending1:             db "Sending ", 0
  Sending2:             db " chars...", CR, 0
  Received:             db "Received ", 0
pend

Errors                  proc
  HostLen:              db "HOSTNAME too lon", 'g'|128, 0
  ESPComms:             db "WiFi communication erro", 'r'|128, 0
  ESPConn:              db "Server connection erro", 'r'|128, 0
  ZoneLen:              db "ZONE too lon", 'g'|128, 0
  NotNext:              db "Next require", 'd'|128, 0
  ESPTimeout:           db "WiFi or server timeou", 't'|128, 0
  Break:                db "D BREAK - CONT repeat", 's'|128, 0
  BadResp:              db "Invalid server respons", 'e'|128, 0
pend

Commands                proc
  CIPSTART1:            db "AT+CIPSTART=\"TCP\",\""
                        CIPSTART1Len equ $-CIPSTART1
  CIPSTART2:            db "\","
                        CIPSTART2Len equ $-CIPSTART2
  Terminate:            db CR, LF, 0
                        TerminateLen equ $-Terminate
  CIPSEND:              db "AT+CIPSEND="
                        CIPSENDLen equ $-CIPSEND
pend

PrintRst16              proc
                        ei
Loop:                   ld a, (hl)
                        inc hl
                        or a
                        jr z, Return
                        rst 16
                        jr Loop
Return:                 di
                        ret
pend

PrintRst16Error         proc
                        ei
Loop:                   ld a, (hl)
                        ld b, a
                        and %1 0000000
                        ld a, b
                        jp nz, LastChar
                        inc hl
                        rst 16
                        jr Loop
Return:                 di
                        ret
LastChar                and %0 1111111
                        rst 16
                        jr Return
pend

PrintHelp               proc
                        ld hl, Msg
                        call PrintRst16
                        jp Return.ToBasic
Msg:                    db "NXTP", CR
                        db "Set date/time from internet", CR, CR
                        db "nxtp", CR
                        db "Show help", CR, CR
                        db "nxtp SERVER PORT [OPTIONS [...]]", CR
                        db "Lookup and set current date/time", CR, CR
                        db "SERVER", CR
                        db "Hostname or IP of time server", CR
                        db "List of public servers at:", CR
                        db "https://tinyurl.com/nxtpsrv", CR, CR
                        db "PORT", CR
                        db "Network port of time server", CR, CR
                        db "OPTIONS", CR
                        db "  -z=TIMEZONECODE", CR
                        db "  Your current timezone code", CR
                        db "  If omitted, uses UK time", CR
                        db "  List of timezone codes at:", CR
                        db "  https://tinyurl.com/tznxtp", CR, CR
                        db "NXTP v1.", BuildNoValue, " ", BuildDateValue, CR
                        db Copyright, " 2019 Robin Verhagen-Guest", CR
                        db 0
pend

PrintBufferProc         proc
                        ld de, MsgBuffer
                        ldir
                        xor a
                        ld (de), a
                        inc de
                        ld hl, MsgBuffer
                        call PrintRst16
                        ret
pend

PrintBufferLen          proc
                        ld a, (hl)
                        ei
                        rst 16
                        di
                        inc hl
                        dec bc
                        ld a, b
                        or c
                        jr nz, PrintBufferLen
                        ret
pend

