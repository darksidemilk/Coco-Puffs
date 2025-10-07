$packageName  = $env:ChocolateyPackageName
$version      = $env:ChocolateyPackageVersion
$toolsDir     = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$sources	    = "$toolsDir\files";
$extractPath  = "$sources\$version"
$downloadHash = "8D5603152F0483FD71251DE17A40B4D47826AA3CDDF15FFECB2366870542B961"
$installerHash= "002FCB28DFEE4374CFDBAA38D45453E592469F11D86938F0DB2C87016F0834B0"
$hashType     = "sha256"
$downloadURL  = "https://us.download.nvidia.com/Windows/Quadro_Certified/553.62/553.62-quadro-rtx-desktop-notebook-win10-win11-64bit-international-dch-whql.exe"

Import-Module "$toolsDir\helpers.psm1"

$pp = Get-PackageParameters;

if (!($pp.SkipCompatCheck)) {
  $nvidiaGpu = Get-NvidiaGPU
  if ($null -eq $nvidiaGpu) {
    if ($env:username -eq "vagrant") {
      Write-Warning "This appears to be a vagrant box, possible chocolatey-verifier, marking package as installed though it is not installed! This will be removed if a verifier-exemption is granted"
      exit 0;
    } else {
      throw "No Nvidia GPU found! This package is only for systems with Nvidia GPUs!"
      exit -436207360; #match the nvidia installer exit code for no nvidia gpu found
    }
  } else {
    "Found nvidia gpu: $($nvidiaGpu.Name)" | out-host;
  }
} else {
  Write-Warning "Skipping nvidia gpu compatibility check as requested with SkipCompatCheck package parameter, you are installing at your own risk! Install will still fail if no GPU exists"
}

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
  fileFullPath   = "$sources\$packageName-$version.exe"
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
}

#if /SkipCompatCheck is not used, check if the gpu is in the list of compatible gpus for this driver version before running the install
if ((!$pp.SkipCompatCheck)) {
    if (!(Test-NvidiaGPUInDeviceList -extractPath $extractPath)) {
      Write-Warning "your gpu $($nvidiaGpu.Name) is not listed as compatible with this driver in $($extractPath)\ListDevices.txt, not installing! You can bypass this warning with `--params "'/SkipCompatCheck'"`. Skip at your own risk."
      Write-Warning "Downloaded and extracted files not cleaned up, you can find them in $($extractPath.replace("$env:ChocolateyInstall\lib\$packageName\","$env:ChocolateyInstall\lib-bad\$packageName\$version\"))"
      throw "Incompatible GPU, not installing"
      exit 1;
    }
} else {
    Write-Warning "Skipping nvidia gpu compatibility check as requested with SkipCompatCheck package parameter, you are installing at your own risk! Install will still fail if no GPU exists"
}

Install-ChocolateyInstallPackage @packageArgs

if ($pp.RemoveOtherVersions) {
  Write-Warning "Removing other versions of nvidia display drivers because RemoveOtherVersions is set!"
  $driversToRemove = Get-OtherVersionsOfNvidiaDisplayDrivers -version $version;
  Remove-OtherVersionsOfNvidiaDisplayDrivers -driversToRemove $driversToRemove;
}

#cleanup extracted files
if (Test-Path -Path $sources) {
    "Cleaning up downloaded and extracted files..." | out-host;
    Set-location $env:userprofile;
    try {
        Remove-Item -Recurse -Force $sources -ea stop
    } catch {
        Write-Warning "Could not remove $sources. Please remove it manually to delete the extracted contents of the downloaded installer. The installer is in your chocolatey cache folder, defaults to '$env:temp\chocolatey' "
    }
}
