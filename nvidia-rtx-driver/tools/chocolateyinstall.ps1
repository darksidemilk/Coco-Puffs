$packageName  = $env:ChocolateyPackageName
$version      = $env:ChocolateyPackageVersion
$toolsDir     = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$sources	    = "$toolsDir\files";
$extractPath  = "$sources\$version"
$downloadHash = "86F19350C6C3B22670B5FDE876E1DC0AC02453B24ACD5D3624DB9BB61B46AA4D"
$installerHash= "90FEF2E648A97AC670E959CC6464B463ADE08C73CFB6CA97531005A576E6E1AB"
$hashType     = "sha256"
$downloadURL  = "https://us.download.nvidia.com/Windows/Quadro_Certified/582.16/582.16-quadro-rtx-desktop-notebook-win10-win11-64bit-international-dch-whql.exe"

Import-Module "$toolsDir\helpers.psm1"

$pp = Get-PackageParameters;

if (!($pp.SkipCompatCheck)) {
  $nvidiaGpu = Get-NvidiaGPU
  if ($null -eq $nvidiaGpu) {
    throw "No Nvidia GPU found! This package is only for systems with Nvidia GPUs!"
    exit -436207360; #match the nvidia installer exit code for no nvidia gpu found
  } else {
    "Found nvidia gpu: $($nvidiaGpu.Name)" | out-host;
  }
  If ( [System.Environment]::OSVersion.Version.Major -ne '10' ) {
    throw "This package only supports Windows 10 and 11, previous versions are not supported by Nvidia"
    exit 1;
  }
} else {
  Write-Warning "Skipping nvidia gpu compatibility and OS check as requested with SkipCompatCheck package parameter, you are installing at your own risk! Install will still fail if no GPU exists"
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
  softwareName  = 'NVIDIA-RTX*'
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
  Remove-OtherVersionsOfNvidiaDisplayDrivers -driversToRemove $driversToRemove -ErrorAction SilentlyContinue;
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
