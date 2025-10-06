$packageName  = $env:ChocolateyPackageName
$version      = $env:ChocolateyPackageVersion
$toolsDir     = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$sources	  = "$toolsDir\files";
$extractPath  = "$sources\$version"
$downloadHash = "002E46DAFFED8C89F09325397839739D49F12594260A0990BC601FBEB3155CB4"
$installerHash= "6C2433AB59433BB5A31E51008C74C33808F00659BFEB363D40A0EFE185B2E8AB"
$hashType     = "sha256"
$downloadURL  = "https://us.download.nvidia.com/Windows/581.29/581.29-desktop-win10-win11-64bit-international-nsd-dch-whql.exe"

#create extract path
if (!(Test-Path -Path $sources)) {
    New-Item -ItemType Directory -Path $sources | Out-Null
}
if (!(Test-Path -Path $extractPath)) {
    New-Item -ItemType Directory -Path $extractPath | Out-Null
}

# download the driver and extract to get the setup.exe for cleaner silent install
$downloadArgs = @{
  packageName    = $packageName
  url            = $downloadURL
  checksum       = $downloadHash
  checksumType   = $hashType
  fileFullPath   = "$sources\nvidia-studio-driver-$version.exe"
}

Get-ChocolateyWebFile @downloadArgs

$unzipArgs = @{
  packageName    = $packageName
  fileFullPath   = $downloadArgs.fileFullPath
  destination    = $extractPath
}

Get-ChocolateyUnzip @unzipArgs

# Install-ChocolateyZipPackage @downloadExtractArgs

# $hash = (Get-FileHash "$extractPath\setup.exe" -Algorithm SHA256).hash

$packageArgs = @{
  packageName   = $packageName
  softwareName  = 'NVIDIA-Studio*'
  fileType      = 'exe'
  silentArgs    = "/s /noreboot"
  validExitCodes= @(0)
  file         = "$extractPath\setup.exe"
  checksum      = $installerHash
  checksumType  = $hashType
  destination   = $toolsDir
  #installDir   = "" # passed when you want to override install directory - requires licensed editions
}

Install-ChocolateyInstallPackage @packageArgs

#cleanup extracted files
if (Test-Path -Path $sources) {
    Set-location $env:userprofile;
    try {
        Remove-Item -Recurse -Force $sources -ea stop
    } catch {
        Write-Warning "Could not remove $sources. Please remove it manually to delete the downloaded installer and extracted contents"
    }
}