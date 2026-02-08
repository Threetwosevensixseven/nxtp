:: Set current directory and paths
::@echo off
C:
CD %~dp0
CD ..\

copy .\dot\NXTP. ..\tbblue\dot\NXTP
copy .\build\readme.txt  ..\tbblue\src\asm\nxtp\*.*
copy .\build\get*.??t  ..\tbblue\src\asm\nxtp\build\*.*
copy .\build\*.config  ..\tbblue\src\asm\nxtp\build\*.*
copy .\build\cspect*.bat  ..\tbblue\src\asm\nxtp\build\*.*
copy .\build\builddot.bat  ..\tbblue\src\asm\nxtp\build\*.*
copy .\build\*.bas  ..\tbblue\src\asm\nxtp\build\*.*
copy .\src\asm\*.asm  ..\tbblue\src\asm\nxtp\asm\*.*

pause