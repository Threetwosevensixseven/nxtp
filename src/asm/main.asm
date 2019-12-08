; main.asm

zeusemulate             "48K", "RAW", "NOROM"
zoSupportStringEscapes  = true;
optionsize 5
CSpect optionbool 15, -15, "CSpect", false

org $2000
Start:
                        di
Freeze:
                        Freeze(1, 2)

                        include "constants.asm"         ; Global constants
                        include "macros.asm"            ; Zeus macros


Length equ $-Start

if zeusver >= 74
  zeuserror "Does not run on Zeus v4.00 (TEST ONLY) or above, Get v3.991 available at http://www.desdes.com/products/oldfiles/zeus.exe"
endif

output_bin "..\\..\\dot\\NXTP", Start, Length

if enabled CSpect
  zeusinvoke "..\\..\\build\\cspect.bat"
endif

