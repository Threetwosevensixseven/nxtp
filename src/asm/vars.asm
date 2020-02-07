; vars.asm

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

ArgsStart:              dw $0000
ArgsEnd:                dw $0000
ArgsLen:                dw $0000
HostStart:              dw $0000
HostLen:                dw $0000
PortStart:              dw $0000
PortLen:                dw $0000
ZoneStart:              dw $0000
ZoneLen:                dw $0000
RequestLen:             dw $0000
WordStart:              ds 5
WordLen:                dw $0000
ResponseStart:          dw $0000
ResponseLen:            dw $0000
Prescaler:              ds 3
Buffer:                 ds 256
BufferLen               equ $-Buffer
MsgBuffer:              ds 256
MsgBufferLen            equ $-MsgBuffer
DateBuffer              db "\"00/00/0000\"", 0
DateBufferInt           equ DateBuffer+1
TimeBuffer              db "\"00:00:00\"", 0
TimeBufferInt           equ TimeBuffer+1

