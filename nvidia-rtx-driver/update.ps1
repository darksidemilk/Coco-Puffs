[CmdletBinding()]
param(
  [switch]$republish
)

function global:Get-NvidiaDriverInfo {
  [cmdletBinding()]
  param()
  "Getting driver info from Nvidia API" | out-host;
  $urlParams = @{
    func="DriverManualLookup"
    psid=122 # product series id 122 = Nvidia RTX Series (under Nvidia RTX Pro/ RTX / Quadro parent category)
    pfid=971 # product family id 971 = RTX A2000 12GB
    osID=135 # operating system id (135 = win11)
    languageID=1 # language id 1 = English
    languageCode=1033 # language code 1033 = English US
    beta=0 # not beta version
    isWHQL=1 # is WHQL certified
    # release=550 #optionally specify a release branch to search for. i.e. 550 would get 55x.xx versions and isNewest would need to be 0
    dltype=1 # download type, not sure of available types, 1 is default and what gets the driver download
    dch=1 # DCH driver (Declarative Componentized Hardware supported apps, universal standard for windows 10+)
    upCRD=0 #request creator ready driver (null for quadro)
    isNewFeature=0 # quadro new feature 
    # ctk="null" # cuda toolkit id, only a response param
    sort1=1 # sort mode (1 = by most recent? doesn't matter only getting 1 result)
    numberOfResults=1 # number of results to return
    isNewest=1 # get newest version
    is64bit=1 # 64 bit OS
  }
  $queryStr = ""; 
  $urlParams.keys | ForEach-Object { 
    $queryStr+="&"; 
    $queryStr+=$_; 
    $queryStr+="=$($urlParams[$_])" 
  }
  $quadro = Invoke-RestMethod "https://gfwsl.geforce.com/services_toolkit/services/com/nvidia/services/AjaxDriverService.php?$queryStr"
  #in the result of this there is a Request property that gives all the params sent in the request and some others that are availble for a request
  return $quadro;
}

function global:Test-NewVersionAvailable {
  [CmdletBinding()]
  param()
  "Testing if new version is available" | out-host;
  [system.version]$version = $global:quadro.ids.downloadinfo.Version
  $nuspec = Get-ChildItem -filter "$($global:packageName).nuspec"
  [xml]$nuspecXml = Get-Content $nuspec.FullName
  [system.version]$nuspecVersion = $nuspecXml.package.metadata.version;
  if (($version.Major -gt $nuspecVersion.Major) -or ($version.Minor -gt $nuspecVersion.Minor)) {
    return $true
  } else {
    return $false
  }
}

function global:Set-NuspecDescription {
  [CmdletBinding()]
  param()

  "Setting nuspec description with release notes" | out-host;
  $detailsURL = $global:quadro.ids.downloadinfo.DetailsURL

  $version = $global:quadro.ids.downloadinfo.Version
  $nuspec = Get-ChildItem -filter "$($global:packageName).nuspec"
  [xml]$nuspecXml = Get-Content $nuspec.FullName
  $indexOfBreak = $nuspecXml.package.metadata.description.indexof("---")
  $description = $nuspecXml.package.metadata.description.Remove(0,$indexOfBreak);

  $str = [System.Web.HttpUtility]::UrlDecode($global:quadro.ids.downloadinfo.ReleaseNotes)
  $md = Convert-HtmlToMarkdown -Html $str;
  $osName = [System.Web.HttpUtility]::UrlDecode($global:quadro.ids.downloadinfo.OSName)
  $baseName = [System.Web.HttpUtility]::UrlDecode($global:quadro.ids.downloadinfo.name)
  $releaseId = $global:quadro.ids.downloadinfo.Release
  $NewDescription = @"
# [$baseName R$releaseId ($version) | $osName]($detailsURL)

$md

"@
  $NewDescription += "`n$description";

  $nuspecXml.package.metadata.description = "`n$NewDescription"
  $nuspecXml.Save($nuspec.FullName);
}

function global:Get-NvidiaChecksums {
  [CmdletBinding()]
  param( )
  "Getting download and installer checksums" | out-host;
  $checksums = [PSCustomObject]@{
    DownloadHash = $null;
    InstallerHash = $null;
  }

  Get-Childitem C:\programdata\chocolatey\helpers\*.ps* | ForEach-Object { import-module $_.FullName -ea 0 -wa 0 }
  $url = $global:quadro.ids.downloadinfo.DownloadURL
  $version = $global:quadro.ids.downloadinfo.Version
  $checksums.DownloadHash = Get-auRemoteChecksum -url $url -Algorithm 'SHA256';
  $checksums.DownloadHash = $checksums.DownloadHash.ToUpper();

  Get-ChocolateyWebFile -url $url -packageName $global:packageName -fileFullPath "$env:TEMP\$global:PackageName.exe" -checksum $checksums.DownloadHash -checksumType 'sha256' -ea 0 -wa 0
  # $checksums.DownloadHash = (Get-FileHash "$env:TEMP\$global:PackageName.exe" -Algorithm SHA256).Hash

  #then extract it and get the hash of setup.exe for install
  $unzipArgs = @{
    packageName    = $global:packageName
    fileFullPath   = "$env:TEMP\$global:PackageName.exe"
    destination    = "$env:TEMP\$global:PackageName-$version"
  }
  Get-ChocolateyUnzip @unzipArgs -ea 0 -wa 0
  # pause;
  $checksums.InstallerHash = (Get-FileHash "$env:TEMP\$global:packageName-$version\setup.exe" -Algorithm SHA256).Hash
  $checksums.InstallerHash = $checksums.InstallerHash.ToUpper();
  return $checksums;
}

function global:au_GetLatest {
  #this is defined as global function above that would be in the update.ps1 script.
  # $global:quadro = global:Get-NvidiaDriverInfo;

  $detailsURL = $global:quadro.ids.downloadinfo.DetailsURL
  $othernotes = [System.Web.HttpUtility]::UrlDecode($global:quadro.ids.downloadinfo.othernotes)
  $docsurl = $otherNotes.split("`"") | Where-Object { $_ -match 'quick-start-guide.pdf'}
  $releaseNotesUrl = $otherNotes.split("`"") | Where-Object { $_ -match 'release-notes.pdf'}
  $releaseDate = $global:quadro.ids.downloadinfo.ReleaseDateTime
  $releaseNoteLink = "$releaseDate - $releaseNotesUrl"


  $version = $global:quadro.ids.downloadinfo.Version
  $url = $global:quadro.ids.downloadinfo.DownloadURL
  # global:Set-NuspecDescription;
  $version = "$version.0" #append .0 to match semantic versioning scheme

  return @{ 
    Version = $version; 
    URL = $url;
    docsURL = $docsurl;
    releaseNotesNuspec = $releaseNoteLink;
    projectSourceURL = $detailsURL;
    downloadHash = $global:checksums.DownloadHash;
    installerHash = $global:checksums.InstallerHash;
  }
}

function global:au_SearchReplace {
  @{
    ".\tools\chocolateyinstall.ps1" = @{
      '(\$downloadHash\s*=\s*)(".*"|''.*'')'    = "`$1`"$($Latest.downloadHash)`""
      '(\$installerHash\s*=\s*)(".*"|''.*'')'    = "`$1`"$($Latest.installerHash)`""
      '(\$downloadURL\s*=\s*)(".*"|''.*'')'     = "`$1`"$($Latest.URL)`""
    }
    "$($Latest.PackageName).nuspec" = @{
      "(\<releaseNotes\>).*?(\</releaseNotes\>)" = "`${1}$($Latest.releaseNotesNuspec)`$2"
      "(\<projectSourceURL\>).*?(\</projectSourceURL\>)" = "`${1}$($Latest.projectSourceURL)`$2"
      "(\<docsUrl\>).*?(\</docsUrl\>)" = "`${1}$($Latest.docsURL)`$2"
    }
  }
} 



$global:packageName = 'nvidia-rtx-driver';
$global:quadro = Get-NvidiaDriverInfo;
if ((Test-NewVersionAvailable)) {
  $ver = $global:quadro.ids.downloadinfo.Version;
  "New Version is available: creating package for version $($ver)" | out-host;
  if (!(Get-command choco.exe)) {
    "Installing choco" | out-host;
    #taken from https://chocolatey.org/install#individual
    Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
  }

  "Installing and importing Chocolatey-AU and htmltomarkdown modules" | out-host;
  try {
    Install-PSResource -Name Chocolatey-AU -TrustRepository -Scope CurrentUser -AcceptLicense -ea stop;
  } catch {
    install-module Chocolatey-AU -Repository PSGallery -AllowClobber -force;
  }
  import-module Chocolatey-AU -Prefix au

  try {
    Install-PSResource -name HtmlToMarkdown -TrustRepository -Scope CurrentUser -AcceptLicense -ea stop;
  } catch {
    install-module -name HtmlToMarkdown -Repository PSGallery -force;
  }
  Import-Module HtmlToMarkdown;

  Set-Location $PSScriptRoot;
  "Updating package from working directory: $($pwd)" | out-host;
  
  Set-NuspecDescription
  $global:checksums = Get-NvidiaChecksums -ea 0 -wa 0;
  "Updating package with chocolatey-au" | out-host;
  Update-auPackage -ChecksumFor none -NoReadme;
  "Committing and pushing changes to git repository $(get-childitem)" | out-host;
  if (!(Test-Path "$global:packageName.$ver.0.nupkg")) {
    choco pack $global:packageName.nuspec;
  }
  if (!(Test-Path "$global:packageName.$ver.0.nupkg")) {
    $pkg = get-item "$global:packageName.*.nupkg"
    $pkg = $pkg.FullName;
  } else {
    $Pkg = "$global:packageName.$ver.0.nupkg"
  }
  if (!(Test-Path $pkg)) {
    throw "Package $pkg not found, choco pack may have failed!"
  }
  git add "$global:packageName.nuspec";
  git add ".\tools\chocolateyinstall.ps1";
  git commit -m "updated and pushed $global:packageName version $($ver).0";
  git push;
  "Pushing package to choco community repository" | out-host;
  # try {
  #   Push-auPackage -ea stop;
  # } catch {
    choco apikey add -s "https://push.chocolatey.org/" -k="$env:api_key"
    choco push "$pkg" --source https://push.chocolatey.org/
  # }
} elseif($republish) {
  Set-Location $PSScriptRoot;
  "Updating package from working directory: $($pwd)" | out-host;
  choco pack $global:packageName.nuspec;
  choco apikey add -s "https://push.chocolatey.org/" -k="$env:api_key"
  $ver = $global:quadro.ids.downloadinfo.Version;
  if (!(Test-Path "$global:packageName.$ver.0.nupkg")) {
    $pkg = get-item "$global:packageName.*.nupkg"
    $pkg = $pkg.FullName;
  } else {
    $Pkg = "$global:packageName.$ver.0.nupkg"
  }
  if (!(Test-Path $pkg)) {
    throw "Package $pkg not found, choco pack may have failed!"
  }
  choco push "$pkg" --source https://push.chocolatey.org/
} else {
  "No new version available, exiting update script." | out-host;
  exit;
}



#psuedo code
# get-filefromweb -url $quadro.ids.downloadinfo.downloadurl -filepath "nvidia-quadro-$(get-date -Format "yyMM").$($quadro.ids.downloadinfo.version).exe"

#driver base name
# $baseName = [System.Web.HttpUtility]::UrlDecode($quadro.ids.downloadinfo.name)

# #display version
# $displayVer = $quadro.ids.downloadinfo.DisplayVersion

# #release notes url
# [System.Web.HttpUtility]::UrlDecode($quadro.ids.downloadinfo.othernotes)

# #project source url = details url.
# $detailsURL = $quadro.ids.downloadinfo.DetailsURL

# #version will be used in package and to check for updates
# $version = $quadro.ids.downloadinfo.Version

# #osname
# $osName = [System.Web.HttpUtility]::UrlDecode($quadro.ids.downloadinfo.OSName)

# #add release notes under the heading in the description. Will need to replace between start of description up to `## Overview`
# $releaseNotes = [System.Web.HttpUtility]::UrlDecode($quadro.ids.downloadinfo.ReleaseNotes)

# #inject release notes html as md under heading
# install-module -name HtmlToMarkdown -force;
# ipmo HtmlToMarkdown;
# $md = Convert-HtmlToMarkdown -Html $releaseNotes;

# #heading
# "#[$baseName $displayVer | $osName]($detailsURL)"
# "`n"
# "$md"
# "`n"
# "---"
# "`n"
# "## Overview"




# #download url
# $quadro.ids.downloadinfo.DownloadURL

# #release date
# $quadro.ids.downloadinfo.ReleaseDateTime


# #checksum
# #when new package is being built, download the url and get the checksum
# Get-ChocolateyWebFile -url $quadro.ids.downloadinfo.DownloadURL -packagename 'nvidia-rtx-driver' -fileFullPath "$env:TEMP\nvidia-rtx-driver.exe"
# $hash = (Get-FileHash "$env:TEMP\nvidia-rtx-driver.exe" -Algorithm SHA256).Hash

# #then extract it and get the hash of setup.exe for install
# $unzipArgs = @{
#   packageName    = 'nvidia-rtx-driver'
#   fileFullPath   = "$env:TEMP\nvidia-rtx-driver.exe"
#   destination    = "$env:TEMP\nvidia-rtx-driver-$version"
# }
# Get-ChocolateyUnzip @unzipArgs
# $installerHash = (Get-FileHash "$env:TEMP\nvidia-rtx-driver-$version\setup.exe" -Algorithm SHA256).Hash


#check my version against $quadro.ids.downloadinfo.Version

#if newer avail get new version and new hashes

#update the download url

# update the version

# update the packagesourceurl with details url


# update releasenotes with display version, release date, and releasenotes url

