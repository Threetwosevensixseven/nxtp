:: Set current directory
::@echo off
C:
CD %~dp0


::ZXVersion.exe
pskill.exe -t cspect.exe
hdfmonkey.exe put C:\spec\sd209\cspect-next-2gb.img ..\dot\nxtp dot
hdfmonkey.exe put C:\spec\sd209\cspect-next-2gb.img autoexec.bas nextzxos\autoexec.bas
cd C:\spec\CSpect3_0_15_2
CSpect.exe -w3 -zxnext -nextrom -basickeys -exit -brk -tv -emu -mmc=..\sd209\cspect-next-2gb.img

::pause