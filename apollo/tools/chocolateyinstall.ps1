$ErrorActionPreference = 'Stop';

$toolsDir     = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
# $fileLocation = ''

$packageArgs = @{
  packageName   = $env:ChocolateyPackageName
  softwareName  = 'apollo*'
  fileType      = 'exe'
  silentArgs    = "/S"
  validExitCodes= @(0)
  url           = "https://github.com/ClassicOldSong/Apollo/releases/download/v0.4.6/Apollo-0.4.6.exe"
  checksum      = '42B2AEFAACB3474511517A56B96EE9F0517F30AC38B5DD2FDA9FD5B478F5021A'
  checksumType  = 'sha256'
  destination   = $toolsDir
  #installDir   = "" # passed when you want to override install directory - requires licensed editions
}

Install-ChocolateyPackage @packageArgs

Write-Host -BackgroundColor Green -ForegroundColor Blue -Object @"

Apollo has been installed/upgraded!
Go to https://localhost:47990 to access your web interface.

NOTE: There will be a privacy warning if you haven't trusted the self-signed cert or added your own previously.
You can get past this with "Advanced" -> "Proceed to localhost (unsafe)" in most browsers.

You'll be prompted to setup a password on first access.
If this was an upgrade all your previous settings should be intact and you're ready to stream!
"@