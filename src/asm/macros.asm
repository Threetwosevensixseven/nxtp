; macros.asm


Border                  macro(Colour)
                        if Colour=0
                          xor a
                        else
                          ld a, Colour
                        endif
                        out (ULA_PORT), a
                        if Colour=0
                          xor a
                        else
                          ld a, Colour*8
                        endif
                        ld (23624), a
mend



Freeze                  macro(Colour1, Colour2)
Loop:                   Border(Colour1)
                        Border(Colour2)
                        jr Loop
mend
