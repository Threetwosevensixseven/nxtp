; esxDOS.asm

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

; NOTE: File paths use the slash character ('/') as directory separator (UNIX style)

esxDOS:

esxDOS.M_GETSETDRV      equ $89
esxDOS.F_OPEN           equ $9a
esxDOS.F_CLOSE          equ $9b
esxDOS.F_READ           equ $9d
esxDOS.F_WRITE          equ $9e
esxDOS.F_SEEK           equ $9f
esxDOS.F_GET_DIR        equ $a8
esxDOS.F_SET_DIR        equ $a9
esxDOS.F_SYNC           equ $9c

esxDOS.FA_READ          equ $01
esxDOS.FA_APPEND        equ $06
esxDOS.FA_OVERWRITE     equ $0C

esxDOS.M_GETDATE        equ $8E

esxDOS.esx_seek_set     equ $00         ; set the fileposition to BCDE
esxDOS.esx_seek_fwd     equ $01         ; add BCDE to the fileposition
esxDOS.esx_seek_bwd     equ $02         ; subtract BCDE from the fileposition

esxDOS.DefaultDrive     db '$'          ; Because we're only opening dot commands, pre-load default as system drive
esxDOS.Handle           db 255

; Function:             Open file
; In:                   HL = pointer to file name (ASCIIZ) (IX for non-dot commands)
;                       B  = open mode
;                       A  = Drive
; Out:                  A  = file handle
;                       On error: Carry set
;                         A = 5   File not found
;                         A = 7   Name error - not 8.3?
;                         A = 11  Drive not found
;
esxDOS.fOpen:
                        ld a, (esxDOS.DefaultDrive)     ; get drive we're on
                        ld b, esxDOS.FA_READ            ; b = open mode
                        RST8 esxDOS.F_OPEN              ; open read mode
                        ld (esxDOS.Handle), a
                        ret                             ; Returns a file handler in 'A' register.

; Function:             Read bytes from a file
; In:                   A  = file handle
;                       HL = address to load into (IX for non-dot commands)
;                       BC = number of bytes to read
; Out:                  Carry flag is set if read fails.
esxDOS.fRead:
                        ld a, (esxDOS.Handle)           ; file handle
                        RST8 esxDOS.F_READ              ; read file
                        ret

; Function:             Close file
; In:                   A  = file handle
; Out:                  Carry flag active if error when closing
esxDOS.fClose:
                        ld a, (esxDOS.Handle)
                        RST8 esxDOS.F_CLOSE             ; close file
                        ret
