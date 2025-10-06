
$studio = irm "https://gfwsl.geforce.com/services_toolkit/services/com/nvidia/services/AjaxDriverService.php?func=DriverManualLookup&psid=131&pfid=1068&osID=135&languageCode=1033&beta=0&isWHQL=0&dltype=1&dch=1&upCRD=1&qnf=0&ctk=null&sort1=1&numberOfResults=1&is64bit=1"
#psuedo code
# get-filefromweb -url $quadro.ids.downloadinfo.downloadurl -filepath "nvidia-quadro-$(get-date -Format "yyMM").$($quadro.ids.downloadinfo.version).exe"

#release notes url is within this encoded url, will need to be extracted/parsed
[System.Web.HttpUtility]::UrlDecode($studio.ids.downloadinfo.othernotes)

#project source url = details url.
$studio.ids.downloadinfo.DetailsURL

#version will be used in package and to check for updates
$studio.ids.downloadinfo.Version

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