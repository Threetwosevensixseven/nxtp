# VSCode

## Build Tasks

VSCode will automatically pick up build tasks from the `.vscode` project subdirectory. `tasks.json` contains the following build tasks:

### make

This tasks builds the `test_client.dot` dot command. Change variable values in 
[makefile](https://github.com/Threetwosevensixseven/NextInstaller/blob/main/src/dotcmd/makefile) to match your environment.

### make emu

This tasks builds the `test_client.dot` dot command and launches [CSpect](https://dailly.blogspot.com/). Change variable values in 
[makefile](https://github.com/Threetwosevensixseven/NextInstaller/blob/main/src/dotcmd/makefile) to match your environment.

### make sync
This tasks builds the `test_client.dot` dot command and launches [NextSync](https://solhsa.com/specnext.html#NEXTSYNC). Change variable values in 
[makefile](https://github.com/Threetwosevensixseven/NextInstaller/blob/main/src/dotcmd/makefile) to match your environment.

[makefile](https://github.com/Threetwosevensixseven/NextInstaller/blob/main/src/dotcmd/makefile) is only tested with [GNU Make](https://www.gnu.org/software/make/) 3.81 for Windows.
Please let me know if other Windows MAKEs have issues. If you fix it up for linux or mac, please contribute your changes.

## Key Bindings

VSCode key bindings are specified globally for the current user, not by project. To use these bindings, copy `keybindings.json`
to your VSCode user settings. In Windows this is at `%APPDATA%\Code\User\keybindings.json`.

The following key bindings are provided:

### shift+ctrl+F8

Runs the `make emu` build task.

### shift+ctrl+F9

Runs the `make sync` build task.

### shift+ctrl+B

This binding is built into the VSCode defaults, so doesn't depend on the `keybindings.json` file. Runs the `make` build task.