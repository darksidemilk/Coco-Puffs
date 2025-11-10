function global:Get-NvidiaDriverInfo {
  [cmdletBinding()]
  param()
  "Getting driver info from Nvidia API" | out-host;
  $urlParams = @{
    func="DriverManualLookup"
    psid=131 # product series id 131 = Nvidia GeForce RTX 50 Series
    pfid=1068 # product family id 1068 = NVIDIA GeForce RTX 5070 Ti
    osID=135 # operating system id (135 = win11)
    languageID=1 # language id 1 = English
    languageCode=1033 # language code 1033 = English US
    beta=0 # not beta version
    isWHQL=0 # is WHQL certified needs to be 0 for studio drivers to return a result, they are whql though as is seen in the response and in the details url
    #release=550 #optionally specify a release branch to search for. i.e. 550 would get 55x.xx versions and isNewest would need to be 0
    dltype=1 # download type, not sure of available types, 1 is default and what gets the driver download
    dch=1 # DCH driver (Declarative Componentized Hardware supported apps, universal standard for windows 10+)
    upCRD=1 #request creator ready driver (what makes it a studio driver)
    isNewFeature=0 # quadro new feature 
    # ctk="null" # cuda toolkit id, only a response param
    sort1=1 # sort mode (1 = by most recent? doesn't matter only getting 1 result)
    numberOfResults=1 # number of results to return
    isNewest=0 # don't get newest version as studio drivers are typically not newest for geForce, game ready drivers are always newest
    is64bit=1 # 64 bit OS
  }
  $queryStr = ""; 
  $urlParams.keys | ForEach-Object { 
    $queryStr+="&"; 
    $queryStr+=$_; 
    $queryStr+="=$($urlParams[$_])" 
  }

  $global:studio = Invoke-RestMethod "https://gfwsl.geforce.com/services_toolkit/services/com/nvidia/services/AjaxDriverService.php?$queryStr"
  return $global:studio

}

function global:Test-NewVersionAvailable {
  [CmdletBinding()]
  param()
  "Testing if new version is available" | out-host;
  [system.version]$version = $global:studio.ids.downloadinfo.Version
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
  $detailsURL = $global:studio.ids.downloadinfo.DetailsURL

  $version = $global:studio.ids.downloadinfo.Version
  $nuspec = Get-ChildItem -filter "$($global:packageName).nuspec"
  [xml]$nuspecXml = Get-Content $nuspec.FullName
  $indexOfBreak = $nuspecXml.package.metadata.description.indexof("---")
  $description = $nuspecXml.package.metadata.description.Remove(0,$indexOfBreak);

  $str = [System.Web.HttpUtility]::UrlDecode($global:studio.ids.downloadinfo.ReleaseNotes)
  $md = Convert-HtmlToMarkdown -Html $str;
  $osName = [System.Web.HttpUtility]::UrlDecode($global:studio.ids.downloadinfo.OSName)
  $baseName = [System.Web.HttpUtility]::UrlDecode($global:studio.ids.downloadinfo.name)
  $releaseId = $global:studio.ids.downloadinfo.Release
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
  $url = $global:studio.ids.downloadinfo.DownloadURL
  $version = $global:studio.ids.downloadinfo.Version
  $checksums.DownloadHash = Get-auRemoteChecksum -url $url -Algorithm 'SHA256';

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
  
  return $checksums;
}

function global:au_GetLatest {
  #this is defined as global function above that would be in the update.ps1 script.
  # $global:studio = global:Get-NvidiaDriverInfo;

  $detailsURL = $global:studio.ids.downloadinfo.DetailsURL
  $othernotes = [System.Web.HttpUtility]::UrlDecode($global:studio.ids.downloadinfo.othernotes)
  $docsurl = $otherNotes.split("`"") | Where-Object { $_ -match 'quick-start-guide.pdf'}
  $releaseNotesUrl = $otherNotes.split("`"") | Where-Object { $_ -match 'release-notes.pdf'}
  $releaseDate = $global:studio.ids.downloadinfo.ReleaseDateTime
  $releaseNoteLink = "$releaseDate - $releaseNotesUrl"


  $version = $global:studio.ids.downloadinfo.Version
  $url = $global:studio.ids.downloadinfo.DownloadURL
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
      '(\$downloadHash\s*=\s*)(".*")'    = "`$1'$($Latest.downloadHash)'"
      '(\$installerHash\s*=\s*)(".*")'    = "`$1'$($Latest.installerHash)'"
      '(\$downloadURL\s*=\s*)(".*")'     = "`$1'$($Latest.URL)'"
    }
    "$($Latest.PackageName).nuspec" = @{
      "(\<releaseNotes\>).*?(\</releaseNotes\>)" = "`${1}$($Latest.releaseNotesNuspec)`$2"
      "(\<projectSourceURL\>).*?(\</projectSourceURL\>)" = "`${1}$($Latest.projectSourceURL)`$2"
      "(\<docsUrl\>).*?(\</docsUrl\>)" = "`${1}$($Latest.docsURL)`$2"
    }
  }
} 
$global:packageName = 'nvidia-studio-driver';
$global:studio = global:Get-NvidiaDriverInfo;
if (global:Test-NewVersionAvailable) {
  $version = $global:studio.ids.downloadinfo.Version;
  "New Version is available: creating package for version $($version)" | out-host;
  if (!(Get-command choco.exe)) {
    "Installing choco" | out-host;
    #taken from https://chocolatey.org/install#individual
    Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
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
  Update-auPackage -ChecksumFor none -NoReadme -NoCheckChocoVersion -NoCheckUrl;
  "Committing and pushing changes to git repository $(get-childitem)" | out-host;
  if (!(Test-Path "$global:packageName.$version.nupkg")) {
    choco pack $global:packageName.nuspec;
  }
  git add "$global:packageName.nuspec";
  git add ".\tools\chocolateyinstall.ps1";
  git commit -m "updated and pushed $global:packageName version $($studio.ids.downloadinfo.Version)";
  git push;
  "Pushing package to choco community repository" | out-host;
  try {
    Push-auPackage -ea stop;
  } catch {
    choco apikey add -s "https://push.chocolatey.org/" -k="$env:api_key"
    choco push "$global:packageName.$version.nupkg" --source https://push.chocolatey.org/
  }
} else {
  exit;
}


# $latest = global:au_GetLatest;
# global:au_SearchReplace;

# #psuedo code
# # get-filefromweb -url $quadro.ids.downloadinfo.downloadurl -filepath "nvidia-quadro-$(get-date -Format "yyMM").$($quadro.ids.downloadinfo.version).exe"

# #driver base name
# $baseName = [System.Web.HttpUtility]::UrlDecode($global:studio.ids.downloadinfo.name)

# #release id
# $releaseId = $global:studio.ids.downloadinfo.Release

# #osname
# $osName = [System.Web.HttpUtility]::UrlDecode($global:studio.ids.downloadinfo.OSName)

# #project source url = details url.
# $detailsURL = $global:studio.ids.downloadinfo.DetailsURL

# #version will be used in package and to check for updates
# $version = $global:studio.ids.downloadinfo.Version

# #inject release notes html as md under heading
# $str = [System.Web.HttpUtility]::UrlDecode($global:studio.ids.downloadinfo.ReleaseNotes)

# $md = Convert-HtmlToMarkdown -Html $str;

# #heading
# "#[$baseName R$releaseId ($version) | $osName]($detailsURL)"
# "`n"
# "$md"
# "`n"
# "---"
# "`n"  
# "## Overview"

# #release notes url is within this encoded url, will need to be extracted/parsed
# $othernotes = [System.Web.HttpUtility]::UrlDecode($global:studio.ids.downloadinfo.othernotes)
# $docsurl = $otherNotes.split("`"") | ? { $_ -match 'quick-start-guide.pdf'}
# $releaseNotesUrl = $otherNotes.split("`"") | ? { $_ -match 'release-notes.pdf'}
# #download url
# $global:studio.ids.downloadinfo.DownloadURL

# #release date to put in release notes with release notes url
# $global:studio.ids.downloadinfo.ReleaseDateTime


# #checksum
# #when new package is being built, download the url and get the checksum
# Get-ChocolateyWebFile -url $global:studio.ids.downloadinfo.DownloadURL -packagename 'nvidia-studio-driver' -fileFullPath "$env:TEMP\nvidia-studio-driver.exe"
# $hash = (Get-FileHash "$env:TEMP\nvidia-studio-driver-$version.exe" -Algorithm SHA256).Hash

# #then extract it and get the hash of setup.exe for install
# $unzipArgs = @{
#   packageName    = 'nvidia-studio-driver'
#   fileFullPath   = "$env:TEMP\nvidia-studio-driver.exe"
#   destination    = "$env:TEMP\nvidia-studio-driver-$version"
# }
# Get-ChocolateyUnzip @unzipArgs
# $installerHash = (Get-FileHash "$env:TEMP\nvidia-studio-driver-$version\setup.exe" -Algorithm SHA256).Hash

# #check my version against $global:studio.ids.downloadinfo.Version

# #if newer avail get new version and new hash

# #update the download url

# # update the version

# # update the projectsourceurl with details url

# #update releasenotes with releasenotes url and date

# # update the checksum with new hash