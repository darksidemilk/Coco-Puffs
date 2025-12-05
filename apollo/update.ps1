function Test-NewVersionAvailable {
  [CmdletBinding()]
  param()
  "Testing if new version is available" | out-host;
  [system.version]$global:latestVersion = (gh release list -R ClassicOldSong/Apollo --json name,isLatest -q "map(select(.isLatest))" | convertfrom-json).name.trimstart("v").trim()
  
  $nuspec = Get-ChildItem -filter "$($global:packageName).nuspec"
  [xml]$nuspecXml = Get-Content $nuspec.FullName
  [system.version]$nuspecVersion = $nuspecXml.package.metadata.version;
  if (($global:latestVersion -gt $nuspecVersion)) {
    return $true
  } else {
    return $false
  }
}

function global:Set-NuspecReleaseNotes {
  [CmdletBinding()]
  param()

  "Setting nuspec release notes with release notes" | out-host;
  $body = gh release view -R ClassicOldSong/Apollo --json body;

  $nuspec = Get-ChildItem -filter "$($global:packageName).nuspec"
  [xml]$nuspecXml = Get-Content $nuspec.FullName
  $nuspecXml.package.metadata.releaseNotes = "<![CDATA[`n"+$body+"`n]]>";
  $nuspecXml.Save($nuspec.FullName);
}

function global:au_GetLatest {
  #this is defined as global function above that would be in the update.ps1 script.
  # $global:quadro = global:Get-NvidiaDriverInfo;

#   [system.version]$global:latestVersion = (gh release list -R ClassicOldSong/Apollo --json name,isLatest -q "map(select(.isLatest))" | convertfrom-json).name.trimstart("v").trim()

  $assets = (gh release view -R ClassicOldSong/Apollo --json assets | convertfrom-json).assets;
  $installerUrl = ($assets | Where-Object { $_.name -eq "Apollo-$global:latestVersion.exe" }).url;
  
  $checksum = Get-auRemoteChecksum -url $installerUrl -Algorithm 'sha256'
  # if release notes markdown doesn't work, will change to a link to the latest release page 
  #$releaseNotesNuspec = (gh release view -R ClassicOldSong/Apollo --json url | convertfrom-json).url

  return @{ 
    Version = $global:latestVersion; 
    # URL = $installerUrl;
    checksum = $checksum;
    # releaseNotesNuspec = $releaseNotesNuspec;
  }
}

function global:au_SearchReplace {
  @{
    ".\tools\chocolateyinstall.ps1" = @{
      '(\$checksum\s*=\s*)(".*"|''.*'')'    = "`$1`"$($Latest.checksum)`""
    }
    # "$($Latest.PackageName).nuspec" = @{
    #   "(\<releaseNotes\>).*?(\</releaseNotes\>)" = "`${1}$($Latest.releaseNotesNuspec)`$2"
    # }
  }
} 
$global:packageName = 'apollo';
if (Test-NewVersionAvailable) {
  $ver = $global:latestVersion;
  "New Version is available: creating package for version $($ver)" | out-host;
  if (!(Get-command choco.exe)) {
    "Installing choco" | out-host;
    #taken from https://chocolatey.org/install#individual
    Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
  }

  "Installing and importing Chocolatey-AU module" | out-host;
  try {
    Install-PSResource -Name Chocolatey-AU -TrustRepository -Scope CurrentUser -AcceptLicense -ea stop;
  } catch {
    install-module Chocolatey-AU -Repository PSGallery -AllowClobber -force;
  }
  import-module Chocolatey-AU -Prefix au

  Set-Location $PSScriptRoot;
  "Updating package from working directory: $($pwd)" | out-host;
  
  Set-NuspecReleaseNotes;
  "Updating package with chocolatey-au" | out-host;
  Update-auPackage -ChecksumFor none -NoReadme;
  "Committing and pushing changes to git repository $(get-childitem)" | out-host;
  if (!(Test-Path "$global:packageName.$ver.nupkg")) {
    choco pack $global:packageName.nuspec;
  }
  git add "$global:packageName.nuspec";
  git add ".\tools\chocolateyinstall.ps1";
  git commit -m "updated and pushed $global:packageName version $($ver)";
  git push;
  "Pushing package to choco community repository" | out-host;
  # try {
  #   Push-auPackage -ea stop;
  # } catch {
    choco apikey add -s "https://push.chocolatey.org/" -k="$env:api_key"
    choco push "$global:packageName.$ver.nupkg" --source https://push.chocolatey.org/
  # }
} else {
  "No new version available, exiting update script." | out-host;
  exit;
}
