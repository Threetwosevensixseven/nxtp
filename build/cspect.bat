:: Set current directory
::@echo off
C:
CD %~dp0



pskill.exe -t cspect.exe
hdfmonkey.exe put C:\spec\cspect-next-2gb.img ..\dot\nxtp dot
cd C:\spec\CSpect2_9_2
CSpect.exe -w2 -zxnext -nextrom -basickeys -esc -com="COM5:115200" -mmc=..\cspect-next-2gb.img


::pause