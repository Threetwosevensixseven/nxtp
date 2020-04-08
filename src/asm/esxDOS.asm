; esxDOS.asm

;  Copyright 2019-2020 Robin Verhagen-Guest
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

; NOTE: File paths use the slash character (‘/’) as directory separator (UNIX style)

esxDOS proc

M_GETSETDRV             equ $89
F_OPEN                  equ $9a
F_CLOSE                 equ $9b
F_READ                  equ $9d
F_WRITE                 equ $9e
F_SEEK                  equ $9f
F_GET_DIR               equ $a8
F_SET_DIR               equ $a9
F_SYNC                  equ $9c

FA_READ                 equ $01
FA_APPEND               equ $06
FA_OVERWRITE            equ $0C

M_GETDATE               equ $8E

esx_seek_set            equ $00         ; set the fileposition to BCDE
esx_seek_fwd            equ $01         ; add BCDE to the fileposition
esx_seek_bwd            equ $02         ; subtract BCDE from the fileposition

DefaultDrive            db '$'          ; Because we're only opening dot commands, pre-load default as system drive
Handle                  db 255

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
fOpen:
                        ld a, (DefaultDrive)            ; get drive we're on
                        ld b, FA_READ                   ; b = open mode
                        Rst8(esxDOS.F_OPEN)             ; open read mode
                        ld (Handle), a
                        ret                             ; Returns a file handler in 'A' register.

; Function:             Read bytes from a file
; In:                   A  = file handle
;                       HL = address to load into (IX for non-dot commands)
;                       BC = number of bytes to read
; Out:                  Carry flag is set if read fails.
fRead:
                        ld a, (Handle)                  ; file handle
                        Rst8(esxDOS.F_READ)             ; read file
                        ret

; Function:             Close file
; In:                   A  = file handle
; Out:                  Carry flag active if error when closing
fClose:
                        ld a, (Handle)
                        Rst8(esxDOS.F_CLOSE)            ; close file
                        ret
pend

