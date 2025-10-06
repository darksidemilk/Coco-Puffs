$pinnedRelease=550; #change this to $null to update and test later versions after the bugs in release 570 are gone.
if ($null -ne $pinnedRelease) {
  $quadro = irm "https://gfwsl.geforce.com/services_toolkit/services/com/nvidia/services/AjaxDriverService.php?func=DriverManualLookup&psid=122&pfid=971&osID=135&languageCode=1033&beta=0&isWHQL=1&dltype=1&dch=1&upCRD=null&qnf=0&IsNewFeature=0&isFeaturePreview=0&ctk=null&sort1=1&numberOfResults=1&is64bit=1&release=$pinnedRelease"
} else {
  $quadro = irm "https://gfwsl.geforce.com/services_toolkit/services/com/nvidia/services/AjaxDriverService.php?func=DriverManualLookup&psid=122&pfid=971&osID=135&languageCode=1033&beta=0&isWHQL=1&dltype=1&dch=1&upCRD=null&qnf=0&IsNewFeature=0&isFeaturePreview=0&ctk=null&sort1=1&numberOfResults=1&IsNewest=1&is64bit=1"
}
#psuedo code
# get-filefromweb -url $quadro.ids.downloadinfo.downloadurl -filepath "nvidia-quadro-$(get-date -Format "yyMM").$($quadro.ids.downloadinfo.version).exe"

#release notes url
[System.Web.HttpUtility]::UrlDecode($quadro.ids.downloadinfo.othernotes)

#project source url = details url.
$quadro.ids.downloadinfo.DetailsURL

#version will be used in package and to check for updates
$quadro.ids.downloadinfo.Version

#download url
$quadro.ids.downloadinfo.DownloadURL

#release date
$quadro.ids.downloadinfo.ReleaseDate

#checksum
#when new package is being built, download the url and get the checksum
Get-ChocolateyWebFile -url $quadro.ids.downloadinfo.DownloadURL -packagename 'nvidia-quadro-driver' -fileFullPath "$env:TEMP\nvidia-quadro-driver.exe"
$hash = (Get-FileHash "$env:TEMP\nvidia-quadro-driver.exe" -Algorithm SHA256).Hash

#then extract it and get the hash of setup.exe for install
$unzipArgs = @{
  packageName    = 'nvidia-studio-driver'
  fileFullPath   = "$env:TEMP\nvidia-studio-driver.exe"
  destination    = "$env:TEMP\nvidia-studio-driver-$version"
}
Get-ChocolateyUnzip @unzipArgs
$installerHash = (Get-FileHash "$env:TEMP\nvidia-studio-driver-$version\setup.exe" -Algorithm SHA256).Hash


#check my version against $quadro.ids.downloadinfo.Version

#if newer avail get new version and new hashes

#update the download url

# update the version

# update the packagesourceurl with details url

# update description with bannerurl?

# update releasenotes with releasenotes url and date

