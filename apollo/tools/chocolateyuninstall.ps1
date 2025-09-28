$ErrorActionPreference = 'Stop';

$installDir = "$env:ProgramFiles\Apollo"
$scripts = "$installDir\scripts"
$drivers = "$installDir\drivers"

Set-Location $installDir;

$configDir = "$env:USERPROFILE\Documents\Apollo"
if (!(Test-Path $configDir)) {
    mkdir $configDir -ea 0;
}

$dateTimeConfigDir = "$configDir\apollo-config-backup\$(Get-Date -Format 'yyyy_MM_dd-HH_mm')"
if (!(Test-Path $dateTimeConfigDir)) {
    mkdir $dateTimeConfigDir -ea 0;
}

"Backing up existing configuration files to your documents directory in a new apollo-config-backup directory $($dateTimeConfigDir)..." | Out-Host
Write-Warning "You can manually restore this $($dateTimeConfigDir) directory back to $installDir\config if you want to restore your previous configuration upon reinstalling."
Copy-Item "$installDir\config\*" $dateTimeConfigDir -Recurse -Force -ea 0;

#firewall rule
"UnConfiguring firewall rule..." | Out-Host
& "$scripts\delete-firewall-rule.bat"

#vigembus
"Uninstalling ViGEmBus driver..." | Out-Host
if ($null -ne (Get-process -name "*vigembus_installer.exe*")) {
  Stop-Process -Name "*vigembus_installer.exe*" -Force
}
& "$scripts\uninstall-gamepad.ps1"

#config service
"uninstalling Apollo service..." | Out-Host
try {
    & "$scripts\uninstall-service.bat" #attempts to delete sunshinesvc but fails if it doesn't exist, which it wouldn't if you've only used apollo.
} catch {
    if ($null -ne (Get-service sunshinesvc -ea 0)) {
        Stop-service sunshinesvc -Force -ea 0;
        sc.exe delete sunshinesvc;
    }
    if ($null -ne (Get-service ApolloService -ea 0)) {
        Stop-service ApolloService -Force -ea 0;
        sc.exe delete ApolloService;
    }
}

#update env path
"Updating system PATH..." | Out-Host
& "$scripts\update-path.bat" remove

#uninstall sudovda virtual display driver
"Uninstalling SudoVDA virtual display driver..." | Out-Host
# & "$drivers\sudovda\uninstall.bat" # this has a pause in it
& "$drivers\sudovda\nefconc.exe" --remove-device-node --hardware-id root\sudomaker\sudovda --class-guid "4D36E968-E325-11CE-BFC1-08002BE10318"

Set-Location $home;

& "$installDir\uninstall.exe" /S

if (Test-Path $installDir) {
    Write-Warning "$installDir still exists, removing it now.";
    Remove-Item $installDir -Recurse -Force -ea 0;
}