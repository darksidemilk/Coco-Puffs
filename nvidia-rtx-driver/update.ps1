$urlParams = @{
  func="DriverManualLookup"
  psid=122 # product series id 122 = Nvidia RTX Series (under Nvidia RTX Pro/ RTX / Quadro parent category)
  pfid=971 # product family id 971 = RTX A2000 12GB
  osID=135 # operating system id (135 = win11)
  languageID=1 # language id 1 = English
  languageCode=1033 # language code 1033 = English US
  beta=0 # not beta version
  isWHQL=1 # is WHQL certified
  release=550 #optionally specify a release branch to search for. i.e. 550 would get 55x.xx versions and isNewest would need to be 0
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


#psuedo code
# get-filefromweb -url $quadro.ids.downloadinfo.downloadurl -filepath "nvidia-quadro-$(get-date -Format "yyMM").$($quadro.ids.downloadinfo.version).exe"

#driver base name
$baseName = [System.Web.HttpUtility]::UrlDecode($quadro.ids.downloadinfo.name)

#display version
$displayVer = $quadro.ids.downloadinfo.DisplayVersion

#release notes url
[System.Web.HttpUtility]::UrlDecode($quadro.ids.downloadinfo.othernotes)

#project source url = details url.
$detailsURL = $quadro.ids.downloadinfo.DetailsURL

#version will be used in package and to check for updates
$version = $quadro.ids.downloadinfo.Version

#osname
$osName = [System.Web.HttpUtility]::UrlDecode($quadro.ids.downloadinfo.OSName)

#add release notes under the heading in the description. Will need to replace between start of description up to `## Overview`
$releaseNotes = [System.Web.HttpUtility]::UrlDecode($quadro.ids.downloadinfo.ReleaseNotes)

#inject release notes html as md under heading
install-module -name HtmlToMarkdown -force;
ipmo HtmlToMarkdown;
$md = Convert-HtmlToMarkdown -Html $releaseNotes;

#heading
"#[$baseName $displayVer | $osName]($detailsURL)"
"`n"
"$md"
"`n"
"---"
"`n"
"## Overview"




#download url
$quadro.ids.downloadinfo.DownloadURL

#release date
$quadro.ids.downloadinfo.ReleaseDateTime


#checksum
#when new package is being built, download the url and get the checksum
Get-ChocolateyWebFile -url $quadro.ids.downloadinfo.DownloadURL -packagename 'nvidia-rtx-driver' -fileFullPath "$env:TEMP\nvidia-rtx-driver.exe"
$hash = (Get-FileHash "$env:TEMP\nvidia-rtx-driver.exe" -Algorithm SHA256).Hash

#then extract it and get the hash of setup.exe for install
$unzipArgs = @{
  packageName    = 'nvidia-rtx-driver'
  fileFullPath   = "$env:TEMP\nvidia-rtx-driver.exe"
  destination    = "$env:TEMP\nvidia-rtx-driver-$version"
}
Get-ChocolateyUnzip @unzipArgs
$installerHash = (Get-FileHash "$env:TEMP\nvidia-rtx-driver-$version\setup.exe" -Algorithm SHA256).Hash


#check my version against $quadro.ids.downloadinfo.Version

#if newer avail get new version and new hashes

#update the download url

# update the version

# update the packagesourceurl with details url


# update releasenotes with display version, release date, and releasenotes url

