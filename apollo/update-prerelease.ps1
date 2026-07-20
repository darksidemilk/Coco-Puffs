function Test-VersionAlreadyPushed {
  [CmdletBinding()]
  param([string]$Version)
  "Checking if $($global:packageName) $Version has already been pushed to Chocolatey" | Out-Host;
  $uri = "https://community.chocolatey.org/api/v2/Packages(Id='$($global:packageName)',Version='$Version')"
  try {
    Invoke-RestMethod -Uri $uri -Method Get -ErrorAction Stop | Out-Null
    return $true
  } catch {
    if ($_.Exception.Response -and [int]$_.Exception.Response.StatusCode -eq 404) {
      return $false
    }
    throw
  }
}

function Test-NewVersionAvailable {
  [CmdletBinding()]
  param()
  "Checking GitHub for the latest pre-release" | Out-Host;
  $releases = gh release list -R ClassicOldSong/Apollo --json tagName,isPrerelease,publishedAt -L 30 | ConvertFrom-Json
  $latestPre = $releases | Where-Object { $_.isPrerelease } | Sort-Object -Property publishedAt -Descending | Select-Object -First 1
  if ($null -eq $latestPre) {
    "No pre-release found on GitHub" | Out-Host;
    return $false
  }

  $global:latestPrereleaseTag = $latestPre.tagName
  $global:latestVersion = $latestPre.tagName.TrimStart('v').Trim()
  "Latest pre-release found on GitHub: $($global:latestVersion)" | Out-Host;

  if (Test-VersionAlreadyPushed -Version $global:latestVersion) {
    "Pre-release version $($global:latestVersion) has already been pushed to Chocolatey" | Out-Host;
    return $false
  }

  return $true
}

function global:New-PrereleasePackage {
  [CmdletBinding()]
  param(
    [string]$Tag,
    [string]$Version
  )

  "Building pre-release package for $($global:packageName) version $Version" | Out-Host;

  $assets = (gh release view $Tag -R ClassicOldSong/Apollo --json assets | ConvertFrom-Json).assets
  $installerAsset = $assets | Where-Object { $_.name -eq "Apollo-$Version.exe" }
  if ($null -eq $installerAsset) {
    throw "Could not find installer asset Apollo-$Version.exe on release $Tag"
  }

  $checksum = Get-auRemoteChecksum -url $installerAsset.url -Algorithm 'sha256'
  $releaseNotes = (gh release view $Tag -R ClassicOldSong/Apollo --json body | ConvertFrom-Json).body

  # Stage a copy of the package files so packaging a pre-release never touches
  # the git-tracked nuspec/tools that the stable update workflow relies on.
  $stagingDir = Join-Path ([System.IO.Path]::GetTempPath()) "$($global:packageName)-prerelease-$Version"
  if (Test-Path $stagingDir) { Remove-Item $stagingDir -Recurse -Force }
  New-Item -ItemType Directory -Path $stagingDir | Out-Null
  Copy-Item -Path ".\tools" -Destination $stagingDir -Recurse
  Copy-Item -Path ".\$($global:packageName).nuspec" -Destination $stagingDir

  $nuspecPath = Join-Path $stagingDir "$($global:packageName).nuspec"
  [xml]$nuspecXml = Get-Content $nuspecPath
  $nuspecXml.package.metadata.version = $Version
  $releaseNotesNode = $nuspecXml.package.metadata.SelectSingleNode('releaseNotes')
  $releaseNotesNode.RemoveAll()
  $releaseNotesNode.AppendChild($nuspecXml.CreateCDataSection("`n$releaseNotes`n")) | Out-Null
  $nuspecXml.Save($nuspecPath)

  $installScriptPath = Join-Path $stagingDir "tools\chocolateyinstall.ps1"
  (Get-Content $installScriptPath -Raw) -replace '(\$checksum\s*=\s*)(".*"|''.*'')', "`$1`"$checksum`"" | Set-Content $installScriptPath

  Push-Location $stagingDir
  try {
    choco pack "$($global:packageName).nuspec"
    "Pushing pre-release package to choco community repository" | Out-Host;
    choco apikey add -s "https://push.chocolatey.org/" -k="$env:api_key"
    choco push "$($global:packageName).$Version.nupkg" --source https://push.chocolatey.org/
  } finally {
    Pop-Location
    Remove-Item $stagingDir -Recurse -Force
  }
}

$global:packageName = 'apollo';
if (Test-NewVersionAvailable) {
  $ver = $global:latestVersion;
  "New pre-release version available: creating package for version $($ver)" | Out-Host;

  if (!(Get-command choco.exe -ErrorAction SilentlyContinue)) {
    "Installing choco" | Out-Host;
    #taken from https://chocolatey.org/install#individual
    Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
  }

  "Installing and importing Chocolatey-AU module" | Out-Host;
  try {
    Install-PSResource -Name Chocolatey-AU -TrustRepository -Scope CurrentUser -AcceptLicense -ea stop;
  } catch {
    install-module Chocolatey-AU -Repository PSGallery -AllowClobber -force;
  }
  import-module Chocolatey-AU -Prefix au

  Set-Location $PSScriptRoot;
  "Building pre-release from working directory: $($pwd)" | Out-Host;

  New-PrereleasePackage -Tag $global:latestPrereleaseTag -Version $ver
} else {
  "No new pre-release version available, exiting update script." | Out-Host;
  exit;
}
