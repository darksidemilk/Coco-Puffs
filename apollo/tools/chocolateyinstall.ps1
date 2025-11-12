$ErrorActionPreference = 'Stop';

$toolsDir     = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
# $fileLocation = ''
# $version = "0.4.6"
$version = $env:ChocolateyPackageVersion
$filename = "Apollo-$version.exe"
$installDir = "$env:ProgramFiles\Apollo"
$scripts = "$installDir\scripts"
$drivers = "$installDir\drivers"
$checksum = "42B2AEFAACB3474511517A56B96EE9F0517F30AC38B5DD2FDA9FD5B478F5021A"

$packageArgs = @{
  packageName   = $env:ChocolateyPackageName
  softwareName  = 'apollo*'
  fileType      = 'exe'
  silentArgs    = "/S"
  validExitCodes= @(0)
  url           = "https://github.com/ClassicOldSong/Apollo/releases/download/v$version/$filename"
  checksum      = $checksum
  checksumType  = 'sha256'
  destination   = $toolsDir
  #installDir   = "" # passed when you want to override install directory - requires licensed editions
}

Install-ChocolateyPackage @packageArgs

Write-Host -BackgroundColor Green -ForegroundColor Blue -Object @"

Ensuring dependencies and drivers are installed via embedded scripts...

"@

Set-Location $installDir;

#firewall rule
"Configuring firewall rule..." | Out-Host
& "$scripts\add-firewall-rule.bat"

#vigembus
"Installing ViGEmBus driver..." | Out-Host
if ($null -ne (Get-process -name "*vigembus_installer.exe*")) {
  "Stopping existing ViGEmBus installer process..." | Out-Host
  Stop-Process -Name "*vigembus_installer.exe*" -Force
}
& "$scripts\install-gamepad.ps1"

#config service
"Configuring Apollo service to auto start..." | Out-Host
& "$scripts\autostart-service.bat"

#update env path
"Updating system PATH..." | Out-Host
& "$scripts\update-path.bat" add

#install sudovda virtual display driver
"Installing SudoVDA virtual display driver..." | Out-Host
& "$drivers\sudovda\install.bat"

"Restarting Apollo service after re-running scripts..." | Out-Host
get-service ApolloService | restart-service

Write-Host -BackgroundColor Yellow -ForegroundColor Blue -Object @"

Apollo has been installed/upgraded!
Go to https://localhost:47990 to access your web interface.
"@


Write-Host -BackgroundColor Yellow -ForegroundColor Black -Object @"

NOTE: There will be a privacy warning if you haven't trusted the self-signed cert or added your own previously.
You can get past this with "Advanced" -> "Proceed to localhost (unsafe)" in most browsers.

You'll be prompted to setup a password on first access.
If this was an upgrade all your previous settings should be intact and you're ready to stream!
"@