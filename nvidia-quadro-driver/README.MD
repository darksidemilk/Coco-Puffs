# Nvidia Quadro Driver

This is a package that will update you to the latest quadro driver.

The automations will do the following for each package

  - Update the Download URL to the latest version
  - Update the version to match the latest version, nuspec version will be normalized to semantic versioning by appending .0
  - Update the checksum of the downloaded installer
  - Update the checksum of the setup.exe extracted from the installer
  - Update the releasenotes url
  - Update the docs url with a link to the control panel quick start guide
  - Update the nuspec description with the main heading linking to nvidia's driver page and release notes from the latest nvidia driver. i.e. 
  
```
"#[$baseName $displayVer | $osName]($detailsURL)"

[System.Web.HttpUtility]::UrlDecode($quadro.ids.downloadinfo.ReleaseNotes)
```
  - Update the ProjectSourceUrl in the nuspec to the details url (version specific download page)



## Notes

This will be an automatic package just getting my initial things into the repo for now. Publishing an older version of the driver first 553.62 as I know of some known issues with dental industry cad programs where versions past this aren't supported, and I want to be sure this known working version is available. Will then jump to releasing the latest version via testing the auto update methods.

See also https://github.com/ZenitH-AT/nvidia-data?tab=readme-ov-file and https://github.com/ZenitH-AT/nvidia-update for where information on the nvidia driver search apis were found.
You can get the psid and pfid from here https://www.nvidia.com/Download/API/lookupValueSearch.aspx?TypeID=2 and here https://www.nvidia.com/Download/API/lookupValueSearch.aspx?TypeID=3 the second link does include both pfid and psid, the first link gets you the definition of psid (product series ID) as it shows in the manual driver search.
Using a quadro a2000 12GB on windows 11 in the example
https://gfwsl.geforce.com/services_toolkit/services/com/nvidia/services/AjaxDriverService.php?&languageID=1&is64bit=1&beta=0&upCRD=0&dltype=1&isWHQL=1&func=DriverManualLookup&languageCode=1033&isNewest=1&osID=135&isNewFeature=0&numberOfResults=1&dch=1&pfid=971&sort1=1&psid=122

### Request Properties Available

```
downloadID             : null #driver specific id
pfid                   : 971 # product family ID from https://www.nvidia.com/Download/API/lookupValueSearch.aspx?TypeID=2
psid                   : 122 #product series ID from https://www.nvidia.com/Download/API/lookupValueSearch.aspx?TypeID=3
deviceID               : null # device specific ID
osID                   : 135 #OS ID from https://www.nvidia.com/Download/API/lookupValueSearch.aspx?TypeID=4 
osCode                 : null #OS code from https://www.nvidia.com/Download/API/lookupValueSearch.aspx?TypeID=4
is64bit                : 1 #use 64 bit, only option now for latest drivers
languageID             : 1 # english US from from https://www.nvidia.com/Download/API/lookupValueSearch.aspx?TypeID=5
languageCode           : 1033 #english US
dltype                 : 1 # download type, defaults to 1, needs to be 1
isArchive              : null #archived/legacy driver
beta                   : 0 #get beta drivers only
includebeta            : null #include beta drivers in results
gtversion              : null #
version                : null
release                : null
isWHQL                 : 1
isNewest               : 1
locationID             : null
sort1                  : 1
sort2                  : null
numberOfResults        : 1
isNewFeature           : null
gfeExclusive           : 0
webExclusive           : 0
cudaToolkitID          : null
theSystemIsDc          : 1 #set automatically, always seems to be 1, signifies data center ready gpu driver
theUserRequestedCRD    : 0 #set by
```

