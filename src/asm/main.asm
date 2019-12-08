; main.asm

zeusemulate             "48K", "RAW", "NOROM"
zoSupportStringEscapes  = true;
optionsize 5
CSpect optionbool 15, -15, "CSpect", false

org $2000
Start:
                        ld a, h
                        or l
                        jp z, PrintHelp                ; If hl was 0 then there are no args at all
                        ld (ArgsStart), hl              ; Save start of args
ParseArgs:
                        call FindColonOrCR              ; Find end of args
                        ld (ArgsEnd), hl                ; Save end of args
                        ld (ArgsLen), bc                ; Save length of args
                        ld hl, (ArgsStart)              ; Go to start of args
                        call FindNonSpace               ; Find first non-space

                        //CSBreak()

Freeze:
                        //Freeze(1, 2)


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

zeusprinthex ArgsStart

ArgsStart:              dw $0000
ArgsEnd:                dw $0000
ArgsLen:                dw $0000



ReturnToBasic           proc
Return:                 xor a                           ; Clear error
                        ret                             ; Return to BASIC
pend



PrintHelp               proc
                        ld hl, Msg
                        call PrintRst16
                        jp ReturnToBasic
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



PrintRst16              proc
                        ld a, (hl)
                        inc hl
                        or a
                        ret z
                        rst 16
                        jr PrintRst16
pend






                        include "constants.asm"         ; Global constants
                        include "macros.asm"            ; Zeus macros

Length equ $-Start

if zeusver >= 74
  zeuserror "Does not run on Zeus v4.00 (TEST ONLY) or above, Get v3.991 available at http://www.desdes.com/products/oldfiles/zeus.exe"
endif

if (Length > $2000)
  zeuserror "DOT command is too large to assemble!"
endif

output_bin "..\\..\\dot\\NXTP", Start, Length

if enabled CSpect
  zeusinvoke "..\\..\\build\\cspect.bat"
endif

