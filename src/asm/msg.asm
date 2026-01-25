; msg.asm

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

Msg.Startup:            db "NXTP v1."
                        BuildNo
                        db CR, Copyright, " 2019-2020 Robin Verhagen-Guest", CR, CR, 0
Msg.InitESP:            db "Initialising WiFi...", CR, 0
Msg.InitDone:           db "Initialised", CR, 0
Msg.Connect1:           db "Connecting to ", 0
Msg.Connect2:           db "...", CR, 0
Msg.Connected:          db "Connected", CR, 0
Msg.UsingTZ:            db "Getting ", 0
Msg.UsingTZDef:         db "Getting default zone (GMT)...", CR, 0
Msg.Sending1:           db "Sending ", 0
Msg.Sending2:           db " chars...", CR, 0
Msg.Received:           db "Received ", 0
Msg.Setting:            db "Setting date and time...", CR, 0
Msg.SetBaud1:           db "Using 115200 baud, ", 0
Msg.SetBaud2:           db " timings", CR, 0

                        ;  "<-Longest valid erro>", 'r'|128
Err.HostLen:            db "1 HOSTNAME too lon",    'g'|128
Err.ESPComms1:          db "2 WiFi comms erro",     'r'|128
Err.ESPComms2:          db "3 WiFi comms erro",     'r'|128
Err.ESPComms3:          db "4 WiFi comms erro",     'r'|128
Err.ESPComms4:          db "5 WiFi comms erro",     'r'|128
Err.ESPComms5:          db "6 WiFi comms erro",     'r'|128
Err.ESPComms6:          db "7 WiFi comms erro",     'r'|128
Err.ESPConn1:           db "8 Server conn erro",    'r'|128
Err.ESPConn2:           db "9 Server conn erro",    'r'|128
Err.ESPConn3:           db "A Server conn erro",    'r'|128
Err.ESPConn4:           db "B Server conn erro",    'r'|128
Err.ZoneLen:            db "C ZONE too lon",        'g'|128
Err.Break:              db "D BREAK - CONT repeat", 's'|128
Err.NotNext:            db "E Next require",        'd'|128
Err.ESPTimeout:         db "F WiFi/server timeou",  't'|128
Err.DateNFF:            db "G Missing .date cm",    'd'|128
Err.TimeNFF:            db "H Missing .time cm",    'd'|128
Err.BadResp1:           db "I Invalid respons",     'e'|128
Err.BadResp2:           db "J Invalid respons",     'e'|128
Err.BadResp3:           db "K Invalid respons",     'e'|128
Err.BadResp4:           db "L Invalid respons",     'e'|128
Err.BadResp5:           db "M Invalid respons",     'e'|128
Err.BadResp6:           db "N Invalid respons",     'e'|128
Err.BadResp7:           db "O Invalid respons",     'e'|128
Err.BadResp8:           db "P Invalid respons",     'e'|128
Err.BadResp9:           db "Q Invalid respons",     'e'|128
Err.BadResp10:          db "R Invalid respons",     'e'|128
Err.BadResp11:          db "S Invalid respons",     'e'|128
Err.BadResp12:          db "T Invalid respons",     'e'|128
Err.BadResp13:          db "U Invalid respons",     'e'|128
Err.BadResp14:          db "V Invalid respons",     'e'|128
Err.BadResp15:          db "W Invalid respons",     'e'|128
Err.BadResp16:          db "X Invalid respons",     'e'|128
Err.BadResp17:          db "Y Invalid respons",     'e'|128
Err.BadResp18:          db "Z Invalid respons",     'e'|128
Err.BadResp19:          db "a Invalid respons",     'e'|128
Err.BadResp20:          db "b Invalid respons",     'e'|128
Err.BadResp21:          db "c Invalid respons",     'e'|128
Err.CoreMin:            db "Core 3.00.04 require",  'd'|128


Files.Date:             db "/dot/date", 0
Files.Time:             db "/dot/time", 0

Timings.Table:
  ;   Text   Index  Notes
  db "VGA0", 0 ; 0  Timing 0
  db "VGA1", 0 ; 1  Timing 1
  db "VGA2", 0 ; 2  Timing 2
  db "VGA3", 0 ; 3  Timing 3
  db "VGA4", 0 ; 4  Timing 4
  db "VGA5", 0 ; 5  Timing 5
  db "VGA6", 0 ; 6  Timing 6
  db "HDMI", 0 ; 7  Timing 7

PrintRst16:
                        ei
.loop:                  ld a, (hl)
                        inc hl
                        or a
                        jr z, .return
                        rst 16
                        jr .loop
.return:                di
                        ret

PrintRst16Error:
                        ei
.loop:                  ld a, (hl)
                        ld b, a
                        and %1'0000000
                        ld a, b
                        jp nz, .lastChar
                        inc hl
                        rst 16
                        jr .loop
.return:                di
                        ret
.lastChar               and %0'1111111
                        rst 16
                        jr .return

PrintHelp:
                        ld hl, .helpMsg
                        call PrintRst16
                        jp Return.ToBasic
.helpMsg:               db "NXTP", CR
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
                        db "NXTP v1.", BuildNoValue, " ", BuildDateValue, " ", BuildTimeSecsValue, CR
                        db Copyright, " 2019 Robin Verhagen-Guest", CR
                        db 0

PrintBufferProc:
                        ld de, MsgBuffer
                        ldir
                        xor a
                        ld (de), a
                        inc de
                        ld hl, MsgBuffer
                        call PrintRst16
                        ret

PrintBufferLen:
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

PrintAHexNoSpace:
                        //SafePrintStart()
                        ld b, a
                        //if DisableScroll
                          //ld a, 24                      ; Set upper screen to not scroll
                          //ld (SCR_CT), a                ; for another 24 rows of printing
                          //ld a, b
                        //endif
                        and $F0
                        swapnib
                        call .print
                        ld a, b
                        and $0F
                        call .print
                        //SafePrintEnd()
                        ret
.print:                 cp 10
                        ld c, '0'
                        jr c, .add
                        ld c, 'A'-10
.add:                   add a, c
                        rst 16
                        ret
