$ErrorActionPreference = 'Stop';

$installDir = "$env:ProgramFiles\Apollo"
$scripts = "$installDir\scripts"
$drivers = "$installDir\drivers"

Set-Location $installDir;

#firewall rule
"UnConfiguring firewall rule..." | Out-Host
& "$scripts\delete-firewall-rule.bat"

#vigembus
"Uninstalling ViGEmBus driver..." | Out-Host
& "$scripts\uninstall-gamepad.ps1"

#config service
"uninstalling Apollo service to auto start..." | Out-Host
& "$scripts\uninstall-service.bat"

#update env path
"Updating system PATH..." | Out-Host
& "$scripts\update-envpath.bat" remove

#uninstall sudovda virtual display driver
"Uninstalling SudoVDA virtual display driver..." | Out-Host
& "$drivers\sudovda\uninstall.bat"

& "$installDir\uninstall.exe" /S