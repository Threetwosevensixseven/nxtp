; version.asm
;
; Auto-generated by ZXVersion.exe
; On 27 Jan 2020 at 19:18

BuildNo                 macro()
                        db "61"
mend

BuildNoValue            equ "61"
BuildNoWidth            equ 0 + FW6 + FW1



BuildDate               macro()
                        db "27 Jan 2020"
mend

BuildDateValue          equ "27 Jan 2020"
BuildDateWidth          equ 0 + FW2 + FW7 + FWSpace + FWJ + FWa + FWn + FWSpace + FW2 + FW0 + FW2 + FW0



BuildTime               macro()
                        db "19:18"
mend

BuildTimeValue          equ "19:18"
BuildTimeWidth          equ 0 + FW1 + FW9 + FWColon + FW1 + FW8



BuildTimeSecs           macro()
                        db "19:18:14"
mend

BuildTimeSecsValue      equ "19:18:14"
BuildTimeSecsWidth      equ 0 + FW1 + FW9 + FWColon + FW1 + FW8 + FWColon + FW1 + FW4
