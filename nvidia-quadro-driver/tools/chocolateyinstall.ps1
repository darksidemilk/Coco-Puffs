$packageName  = $env:ChocolateyPackageName
$version      = $env:ChocolateyPackageVersion
$toolsDir     = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$sources	  = "$toolsDir\files";
$extractPath  = "$sources\$version"
$downloadHash = "8D5603152F0483FD71251DE17A40B4D47826AA3CDDF15FFECB2366870542B961"
$installerHash= "002FCB28DFEE4374CFDBAA38D45453E592469F11D86938F0DB2C87016F0834B0"
$hashType     = "sha256"
$downloadURL = "https://us.download.nvidia.com/Windows/Quadro_Certified/553.62/553.62-quadro-rtx-desktop-notebook-win10-win11-64bit-international-dch-whql.exe"

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

$packageArgs = @{
  packageName   = $packageName
  softwareName  = 'NVIDIA-Quadro*'
  fileType      = 'exe'
  silentArgs    = "/s /noreboot"
  validExitCodes= @(0)
  file          = "$extractPath\setup.exe"
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
        Write-Warning "Could not remove $sources. Please remove it manually to delete the extracted contents of the downloaded installer. The installer is in your chocolatey cache folder, defaults to '$env:temp\chocolatey' "
    }
}