# Nvidia Studio Driver

This is a package that will update you to the latest studio driver (aka Creator Ready Driver).

## Notes

This will be an automatic package just getting my initial things into the repo for now. 

See also https://github.com/ZenitH-AT/nvidia-data?tab=readme-ov-file 
You can get the psid and pfid from here https://www.nvidia.com/Download/API/lookupValueSearch.aspx?TypeID=2 and here https://www.nvidia.com/Download/API/lookupValueSearch.aspx?TypeID=3 
We are searching with an RTX 5070 in this script. WHQL=0 is set, but the studio drivers are whql when reviewing their listing page, but the json result shows it as 0. The studio drivers are also never "newest" because they compare that 'newest' with the 'game ready' drivers which are released more frequently. So isNewest will always show 0.
"https://gfwsl.geforce.com/services_toolkit/services/com/nvidia/services/AjaxDriverService.php?func=DriverManualLookup&psid=131&pfid=1068&osID=135&languageCode=1033&beta=0&isWHQL=0&dltype=1&dch=1&upCRD=1&qnf=0&ctk=null&sort1=1&numberOfResults=1&is64bit=1"
