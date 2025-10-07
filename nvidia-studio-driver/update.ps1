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

$studio = Invoke-RestMethod "https://gfwsl.geforce.com/services_toolkit/services/com/nvidia/services/AjaxDriverService.php?$queryStr"
#psuedo code
# get-filefromweb -url $quadro.ids.downloadinfo.downloadurl -filepath "nvidia-quadro-$(get-date -Format "yyMM").$($quadro.ids.downloadinfo.version).exe"

#driver base name
$baseName = [System.Web.HttpUtility]::UrlDecode($studio.ids.downloadinfo.name)

#release id
$releaseId = $studio.ids.downloadinfo.Release

#osname
$osName = [System.Web.HttpUtility]::UrlDecode($studio.ids.downloadinfo.OSName)

#project source url = details url.
$detailsURL = $studio.ids.downloadinfo.DetailsURL

#version will be used in package and to check for updates
$version = $studio.ids.downloadinfo.Version

#inject release notes html as md under heading
$str = [System.Web.HttpUtility]::UrlDecode($studio.ids.downloadinfo.ReleaseNotes)
install-module -name HtmlToMarkdown -force;
ipmo HtmlToMarkdown;
$md = Convert-HtmlToMarkdown -Html $str;

#heading
"#[$baseName R$releaseId ($version) | $osName]($detailsURL)"
"`n"
"$md"
"`n"
"---"
"`n"
"## Overview"

#release notes url is within this encoded url, will need to be extracted/parsed
[System.Web.HttpUtility]::UrlDecode($studio.ids.downloadinfo.othernotes)

#download url
$studio.ids.downloadinfo.DownloadURL

#release date to put in release notes with release notes url
$studio.ids.downloadinfo.ReleaseDate


#checksum
#when new package is being built, download the url and get the checksum
Get-ChocolateyWebFile -url $studio.ids.downloadinfo.DownloadURL -packagename 'nvidia-studio-driver' -fileFullPath "$env:TEMP\nvidia-studio-driver.exe"
$hash = (Get-FileHash "$env:TEMP\nvidia-studio-driver-$version.exe" -Algorithm SHA256).Hash

#then extract it and get the hash of setup.exe for install
$unzipArgs = @{
  packageName    = 'nvidia-studio-driver'
  fileFullPath   = "$env:TEMP\nvidia-studio-driver.exe"
  destination    = "$env:TEMP\nvidia-studio-driver-$version"
}
Get-ChocolateyUnzip @unzipArgs
$installerHash = (Get-FileHash "$env:TEMP\nvidia-studio-driver-$version\setup.exe" -Algorithm SHA256).Hash

#check my version against $studio.ids.downloadinfo.Version

#if newer avail get new version and new hash

#update the download url

# update the version

# update the packagesourceurl with details url

# update description with bannerurl?

#update releasenotes with releasenotes url and date

# update the checksum with new hash