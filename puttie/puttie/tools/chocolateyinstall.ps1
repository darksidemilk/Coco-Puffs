$ErrorActionPreference = 'Stop';


$toolsDir     = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"

#Based on Custom
$packageArgs = @{
  packageName   = $env:ChocolateyPackageName
  softwareName  = 'puttie*'
  fileType      = 'zip'
  silentArgs    = ""
  validExitCodes= @(0)
  url           = "https://github.com/lalbornoz/PuTTie/releases/download/PuTTie-registry-Release-7604753a/PuTTie-registry-Release-7604753a.zip"
  checksum      = 'CC8746001CC3A8444C7A730E359AB0EBE6D3D5A26B213A9AB8786DE2368E7362'
  checksumType  = 'sha256'
  url64bit      = ""
  checksum64    = ''
  checksumType64= 'sha256'
  destination   = $toolsDir
}

Install-ChocolateyZipPackage @packageArgs

