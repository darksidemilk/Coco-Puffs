# Apollo Game Streaming Server Chocolatey Package

This package will be an automatically maintained package for the latest release of the Apollo game streaming server.
The first release is manual to ensure the initial things are working correctly.

## Dependencies Embedded

Running just /S on the installer doesn't always run all install scripts so they are re-run in the chocolateyinstall script from the install path. 
Install script source: 

- https://github.com/ClassicOldSong/Apollo/tree/master/src_assets/windows/misc
- https://github.com/ClassicOldSong/Apollo/tree/master/src_assets/windows/drivers/sudovda

They are installed to C:\Program Files\Apollo in the scripts and drivers subdirs respectively.

The dependencies installed are:

- ViGEmBus - Virtual Gamepad Emulation Framework - https://vigembus.com/
- SudoVDA - Virtual Display Adapter with HDR support - https://github.com/SudoMaker/SudoVDA
- Adds Apollo to system PATH
- Configures Apollo service to auto start
- Adds firewall rules for Apollo
