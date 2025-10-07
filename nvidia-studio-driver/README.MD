# Nvidia Studio Driver

This is a package that will update you to the latest studio driver (aka Creator Ready Driver).

The automations will do the following for each package

  - Update the Download URL to the latest version
  - Update the version to match the latest version, nuspec version will be normalized to semantic versioning by appending .0
  - Update the checksum of the downloaded installer
  - Update the checksum of the setup.exe extracted from the installer
  - Update the releasenotes url
  - Update the docs url with a link to the control panel quick start guide
  - Update the nuspec description with the main heading linking to nvidia's driver page and release notes from the latest nvidia driver. i.e. 
  
```
"#[$baseName R$releaseId ($version) | $osName]($detailsURL)"

[System.Web.HttpUtility]::UrlDecode($studio.ids.downloadinfo.ReleaseNotes)
```
  - Update the ProjectSourceUrl in the nuspec to the details url (version specific download page)



## Notes

This will be an automatic package just getting my initial things into the repo for now. 

See also https://github.com/ZenitH-AT/nvidia-data?tab=readme-ov-file and https://github.com/ZenitH-AT/nvidia-update for where information on the nvidia driver search apis were found.
You can get the psid and pfid from here https://www.nvidia.com/Download/API/lookupValueSearch.aspx?TypeID=2 and here https://www.nvidia.com/Download/API/lookupValueSearch.aspx?TypeID=3 the second link does include both pfid and psid, the first link gets you the definition of psid (product series ID) as it shows in the manual driver search.
We are searching with an RTX 5070 in this script. WHQL=0 is set, but the studio drivers are whql when reviewing their listing page, but the json result shows it as 0. The studio drivers are also never "newest" because they compare that 'newest' with the 'game ready' drivers which are released more frequently. So isNewest will always show 0.
"https://gfwsl.geforce.com/services_toolkit/services/com/nvidia/services/AjaxDriverService.php?func=DriverManualLookup&psid=131&pfid=1068&osID=135&languageCode=1033&beta=0&isWHQL=0&dltype=1&dch=1&upCRD=1&qnf=0&ctk=null&sort1=1&numberOfResults=1&is64bit=1"

### Request Properties Available

```
downloadID                                                   : null
pfid                                                         : 971
psid                                                         : 122
deviceID                                                     : null
osID                                                         : 135
osCode                                                       : null
is64bit                                                      : 1
languageID                                                   : 1
languageCode                                                 : 1033
dltype                                                       : 1
isArchive                                                    : null
beta                                                         : 0
includebeta                                                  : null
gtversion                                                    : null
version                                                      : null
release                                                      : null
isWHQL                                                       : 1
isNewest                                                     : 1
locationID                                                   : null
sort1                                                        : 1
sort2                                                        : null
numberOfResults                                              : 1
isNewFeature                                                 : null
gfeExclusive                                                 : 0
webExclusive                                                 : 0
null,null,null,null,null,null,null,null,null,null,null,null, : 
cudaToolkitID                                                : null
theSystemIsDc                                                : 1
theUserRequestedCRD                                          : 0
```