#   Copyright 2019-2026 Robin Verhagen-Guest
# 
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
# 
#      http://www.apache.org/licenses/LICENSE-2.0
# 
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.

# Makefile for NextInstaller.dot command.
# Only tested with GNU MAKE 3.81 for Windows: https://gnuwin32.sourceforge.net/packages/make.htm
# If you fix this up for linux or mac, please contribute your changes.
# Use sjasmplus v1.21.1 or higher, from https://github.com/z00m128/sjasmplus
# Use ZXVersion v1.6.0.89bf069 or higher, from https://github.com/Threetwosevensixseven/ZXVersion/releases/latest
# Use hdfmonkey v0.5.7 jjjs or higher, from https://www.specnext.com/forum/viewtopic.php?p=16374#p16032
# Use NextSync v1.2 or higher, from https://solhsa.com/specnext.html#NEXTSYNC
# With CSpect, use UARTReplacement v1.8 or higher, from https://github.com/Threetwosevensixseven/CSpectPlugins/releases/latest
# With CSpect, use NextZXOS 2.09 or later SD image, from https://zxnext.uk/hosted/

# Change these variables to suit your own environment
SRCDIR = .
BINDIR = ..\..\dot
BASDIR = ..\..\basic
SJASMPLUS = ..\..\tools\sjasmplus
HDFMONKEY = ..\..\tools\hdfmonkey
ZXVERSION = ..\..\tools\zxversion
EMUDIR = C:\spec\CSpect3_0_2_1
EMUSD = C:\spec\sd209\cspect-next-2gb.img
SYNCDIR = C:\spec\sync\ON
EMPTY =
PATHSEP = \$(EMPTY)
RM = del /F /Q
MD = md
CP = copy /Y
KILL = taskkill /F /IM
PY = python3.13.exe
TOUCH = ..\..\tools\busybox.exe touch -c

# Default target is to build the dot command from source
build: 
	$(ZXVERSION)
	$(SJASMPLUS) --sym=main.sym --lst=main.lst $(SRCDIR)/main.asm

# Removes all build-generated files
clean:
	-$(RM) "$(BINDIR)/main.dot"
	-$(RM) "$(SRCDIR)/main.sym"
	-$(RM) "$(SRCDIR)/main.lst"

# Builds, injects built dot and autoexec into CSpect SD image, and starts CSpect asynchronously.
cspect: build
	-$(HDFMONKEY) mkdir $(EMUSD) dot
	$(HDFMONKEY) put $(EMUSD) $(BINDIR)/NXTP. dot/NXTP.
	$(HDFMONKEY) put $(EMUSD) $(BASDIR)\autoexec.bas NextZXOS                     
#   Uncomment this to get the current autoexec.bas/.txt in the image back into the project:
#	$(HDFMONKEY) get $(EMUSD) /NextZXOS/autoexec.bas $(BASDIR)\autoexec.bas
#	$(HDFMONKEY) get $(EMUSD) /NextZXOS/autoexec.txt $(BASDIR)\autoexec.txt
	-$(KILL) cspect.exe 
	CMD /C start /d $(EMUDIR) cspect -w3 -zxnext -nextrom -basickeys -exit -brk -tv -emu -mmc=$(EMUSD)

# Builds, copies dot and autoexec to NextSync sync directory, and starts starts the server asynchronously.
# WHen you F4, autoexec will skip running .sync (because CSpect defaults to core version 4.0.0), then run the dot command.
# The first time you make sync, run .sync manually to get the files.
sync: build
	-$(MD) "$(SYNCDIR)\dot"
	copy "$(BINDIR)\NXTP." "$(SYNCDIR)\dot\*.*"
	-$(MD) "$(SYNCDIR)\NextZXOS"
	copy "$(BASDIR)\autoexec.bas" "$(SYNCDIR)\NextZXOS\*.*"
	$(TOUCH) "$(SYNCDIR)\NextZXOS\autoexec.bas"
# Warning: kills all running python processes
# Remove these two lines and start the server manually if that bothers you
	-$(KILL) $(PY)
	cd "$(SYNCDIR)" && CMD /C start /d "$(SYNCDIR)" nextsync.py
