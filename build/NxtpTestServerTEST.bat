:: Set current directory and paths
@echo off
C:
CD %~dp0
CD ..\src\core\NxtpClient\bin\Debug\netcoreapp3.0\

NxtpClient time.nxtel.org:12300 tEsT

PAUSE