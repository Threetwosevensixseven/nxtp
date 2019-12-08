; constants.asm



; General
SMC                     equ 0
CR                      equ 13
Space                   equ 32
Copyright               equ 127



; Screen
SCREEN                  equ $4000                       ; Start of screen bitmap
ATTRS_8x8               equ $5800                       ; Start of 8x8 attributes
ATTRS_8x8_END           equ $5B00                       ; End of 8x8 attributes
ATTRS_8x8_COUNT         equ ATTRS_8x8_END-ATTRS_8x8     ; 768
SCREEN_LEN              equ ATTRS_8x8_END-SCREEN
PIXELS_COUNT            equ ATTRS_8x8-SCREEN
FRAMES                  equ 23672                       ; Frame counter
BORDCR                  equ 23624                       ; Border colour system variable
ULA_PORT                equ $FE                         ; out (254), a
STIMEOUT                equ $5C81                       ; Screensaver control sysvar



; Font
FWSpace                 equ 2
FWColon                 equ 4
FWFullStop              equ 3
FW0                     equ 4
FW1                     equ 4
FW2                     equ 4
FW3                     equ 4
FW4                     equ 4
FW5                     equ 4
FW6                     equ 4
FW7                     equ 4
FW8                     equ 4
FW9                     equ 4
FWA                     equ 4
FWB                     equ 4
FWC                     equ 4
FWD                     equ 4
FWE                     equ 4
FWF                     equ 4
FWG                     equ 4
FWH                     equ 4
FWI                     equ 4
FWJ                     equ 4
FWK                     equ 4
FWL                     equ 4
FWM                     equ 6
FWN                     equ 4
FWO                     equ 4
FWP                     equ 4
FWQ                     equ 4
FWR                     equ 4
FWS                     equ 4
FWT                     equ 4
FWU                     equ 4
FWV                     equ 4
FWW                     equ 6
FWX                     equ 4
FWY                     equ 4
FWZ                     equ 4
FWa                     equ 4
FWb                     equ 4
FWc                     equ 4
FWd                     equ 4
FWe                     equ 4
FWf                     equ 4
FWg                     equ 4
FWh                     equ 4
FWi                     equ 4
FWj                     equ 4
FWk                     equ 4
FWl                     equ 4
FWm                     equ 6
FWn                     equ 4
FWo                     equ 4
FWp                     equ 4
FWq                     equ 4
FWr                     equ 4
FWs                     equ 4
FWt                     equ 4
FWu                     equ 4
FWv                     equ 4
FWw                     equ 6
FWx                     equ 4
FWy                     equ 4
FWz                     equ 4

