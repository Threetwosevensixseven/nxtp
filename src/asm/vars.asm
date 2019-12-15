; vars.asm

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
Buffer:                 ds 256
BufferLen               equ $-Buffer
MsgBuffer:              ds 256
MsgBufferLen            equ $-MsgBuffer

