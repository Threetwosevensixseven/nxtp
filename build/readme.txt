;  Copyright 2019-2020 Robin Verhagen-Guest
;
; Licensed under the Apache License, Version 2.0 (the "License");
; you may not use this file except in compliance with the License.
; You may obtain a copy of the License at
;
;     http://www.apache.org/licenses/LICENSE-2.0
;
; Unless required by applicable law or agreed to in writing, software
; distributed under the License is distributed on an "AS IS" BASIS,
; WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
; See the License for the specific language governing permissions and
; limitations under the License.

To build NXTP on Windows 10 from source you obtained from the ZX Spectrum Next™ distro or gitlab repository:

DO THIS ONCE:
=============
Browse to the "build" directory.
Doubleclick on "get-tools.bat".
Wait while four tools are downloaded. The last, "zeustest.exe" is large, so be patient.
When prompted "Press any key to continue", press a key.

DO THIS EVERY TIME YOU WANT TO BUILD:
=====================================
Browse to the "build" directory.
Doubleclick on "zeustest.exe".
Do File >> Open, then browse to the "src\asm" directory.
Select "main.asm" and click the Open button.
In Zeus, on the "Zeus (assembler)" tab, click the Assemble button.
The dot command will be build in the "dot" folder as "NXTP".
Copy this file to the dot folder on your Next SD card.

INFO
====
The latest full source and build tools for NXTP are always available at:
https://github.com/Threetwosevensixseven/nxtp

NXTP is © 2019-2020 Robin Verhagen-Guest, and licensed under Apache 2.0
(https://github.com/Threetwosevensixseven/nxtp/blob/master/LICENSE)
ZX Spectrum Next is a trademark of SpecNext Ltd.
