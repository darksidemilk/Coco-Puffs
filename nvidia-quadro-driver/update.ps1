$pinnedRelease=550; #change this to $null to update and test later versions after the bugs in release 570 are gone.
if ($null -ne $pinnedRelease) {
  $quadro = irm "https://gfwsl.geforce.com/services_toolkit/services/com/nvidia/services/AjaxDriverService.php?func=DriverManualLookup&psid=122&pfid=971&osID=135&languageCode=1033&beta=0&isWHQL=1&dltype=1&dch=1&upCRD=null&qnf=0&IsNewFeature=0&isFeaturePreview=0&ctk=null&sort1=1&numberOfResults=1&is64bit=1&release=$pinnedRelease"
} else {
  $quadro = irm "https://gfwsl.geforce.com/services_toolkit/services/com/nvidia/services/AjaxDriverService.php?func=DriverManualLookup&psid=122&pfid=971&osID=135&languageCode=1033&beta=0&isWHQL=1&dltype=1&dch=1&upCRD=null&qnf=0&IsNewFeature=0&isFeaturePreview=0&ctk=null&sort1=1&numberOfResults=1&IsNewest=1&is64bit=1"
}
#psuedo code
# get-filefromweb -url $quadro.ids.downloadinfo.downloadurl -filepath "nvidia-quadro-$(get-date -Format "yyMM").$($quadro.ids.downloadinfo.version).exe"

