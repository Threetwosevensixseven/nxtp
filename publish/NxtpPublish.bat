:: Set current directory and paths
@echo off
C:
CD %~dp0

:: Prepare NxtpServer for publishing
PATH=%PATH%;C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\MSBuild\Current\Bin
CD ..\src\core\NxtpServer

:: Publish NxtpServer
msbuild NxtpServer.csproj /p:Configuration="Release" /p:Platform="AnyCPU"

:: Deploy NxtpServer
DEL  /F /Q /S Publish\netcoreapp3.0\*.pdb
XCOPY /Y "Publish\netcoreapp3.0\*.*" "%USERPROFILE%\Documents\Visual Studio 2015\Projects\NXtelDeploy\NxtpServer\"

:: Stage and commit deployment changes for the server
for /F "tokens=2" %%i in ('date /t') do set mydate=%%i
cd "%USERPROFILE%\Documents\Visual Studio 2015\Projects\NXtelDeploy\NxtpServer\"
git add *
git commit -a -m "Autocommit %mydate% %time% from build script."
git push

PAUSE