# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository purpose

This repo holds the source for [darksidemilk's published Chocolatey packages](https://community.chocolatey.org/profiles/DarkSideMilk). Each top-level folder is one Chocolatey package (nuspec + `tools/` install scripts). A GitHub Actions workflow per package checks for new upstream releases on a schedule and, when found, packages and pushes a new version to the Chocolatey community feed. Publishing to chocolatey.org goes through Chocolatey's moderation/review process (see https://docs.chocolatey.org/en-us/community-repository/moderation/), so a merged update won't appear live immediately.

Packages present:
- `apollo/` — Apollo game streaming server, tracked from GitHub releases (`ClassicOldSong/Apollo`)
- `nvidia-rtx-driver/` — NVIDIA RTX/RTX Pro (formerly Quadro) driver, tracked from NVIDIA's driver lookup API
- `nvidia-studio-driver/` — NVIDIA Studio driver, tracked from the same NVIDIA API
- `puttie/` — PuTTie, a mostly-unfinished/manual package (see `puttie/puttie/TODO.txt`) not wired into any workflow

## Commands

There's no build/lint/test suite. Development happens by editing a package's `update.ps1` and/or `tools/chocolateyinstall.ps1`, then running the update script locally in PowerShell (7+/`pwsh`, Windows only — these scripts install/shell out to `choco.exe` and Windows-only cmdlets):

```powershell
cd <package-folder>
pwsh .\update.ps1             # normal update: check upstream, pack, commit, push to git + chocolatey.org
pwsh .\update.ps1 -republish  # nvidia-* packages only: re-pack/push the currently-checked-out version without a version bump
```

Pushing to the Chocolatey feed requires an API key (`$env:api_key`, provided by the `CHOCOLATEY` repo secret in CI). Locally, `choco apikey add -s "https://push.chocolatey.org/" -k=<key>` before running, or expect the push step to fail.

To validate a nuspec/install script change without publishing, use `choco pack <id>.nuspec` from the package folder and test-install the resulting `.nupkg` in a VM/test environment (chocolatey recommends https://github.com/chocolatey/chocolatey-test-environment) — don't push untested changes to the community feed.

Each package's workflow can also be triggered manually via `workflow_dispatch` from the Actions tab instead of waiting for the cron schedule.

## Architecture

### Per-package layout

Every package folder follows the same shape:
- `<id>.nuspec` — package metadata; `<version>` is the source of truth `update.ps1` compares against upstream to decide whether a new package is needed
- `tools/chocolateyinstall.ps1` — reads `$env:ChocolateyPackageName` / `$env:ChocolateyPackageVersion` (set by choco at install time), downloads/installs the software, using hardcoded checksum(s) that `update.ps1` rewrites on each version bump
- `tools/chocolateyuninstall.ps1` — reverses the install (apollo only; the nvidia driver packages have no uninstall since Windows handles driver removal)
- `update.ps1` — the automation entrypoint (see below)
- `README.MD` — per-package notes on what the automation does and any upstream-API quirks

### Update automation pattern (Chocolatey-AU)

All `update.ps1` scripts follow the same skeleton, built around the [Chocolatey-AU](https://github.com/chocolatey-community/chocolatey-au) PowerShell module (imported with `-Prefix au`, so its exports are called as `Get-auRemoteChecksum`, `Update-auPackage`, etc.):

1. `Test-NewVersionAvailable` — fetch the current upstream version and compare against the nuspec's `<version>`; exit early if no update.
2. If a new version exists: ensure `choco.exe` is installed, install/import `Chocolatey-AU` (and `HtmltoMarkdown` for the nvidia packages), `Set-Location $PSScriptRoot`.
3. `au_GetLatest` — global function returning a hashtable (`Version`, `URL`, checksums, etc.) that `Update-auPackage` consumes.
4. `au_SearchReplace` — global function returning a hashtable of `{file -> {regex -> replacement}}` describing which strings `Update-auPackage` rewrites in-place (checksums in `chocolateyinstall.ps1`, version/description/releaseNotes fields in the nuspec).
5. `Update-auPackage -ChecksumFor none -NoReadme` performs the rewrites, then the script `choco pack`s, `git add`/`commit`/`push`es the changed nuspec + install script back to this repo, and `choco push`es the resulting `.nupkg` to `https://push.chocolatey.org/`.

Where a package differs from this skeleton, it's because of upstream quirks — see below.

### Source-specific quirks

- **apollo**: version/checksum/release-notes come from the `gh` CLI against `ClassicOldSong/Apollo` releases (`GH_TOKEN` env var auth). `Set-NuspecReleaseNotes` pulls the GitHub release body into the nuspec `<releaseNotes>` before `Update-auPackage` runs. `apollo/update-prerelease.ps1` is a **separate, independent** script/workflow that publishes Chocolatey pre-release packages from GitHub pre-releases (e.g. `v0.4.7-alpha.1`), used by `update_apollo_prerelease.yml`. It never commits to git or touches the tracked nuspec/install script (it stages a copy in a temp dir instead), so it can't interfere with the stable-release automation.
- **nvidia-rtx-driver / nvidia-studio-driver**: version/download info comes from NVIDIA's undocumented driver-lookup API (`gfwsl.geforce.com/.../AjaxDriverService.php`), queried with a `psid`/`pfid`/`osID`/etc. parameter set hardcoded per-package (see each package's `README.MD` for how to find these IDs and what each param means). Because NVIDIA's driver version (e.g. `553.62`) isn't itself semver, these scripts append `.0` to form the Chocolatey package version, and `Test-NewVersionAvailable`/`au_SearchReplace` compare/rewrite `Major.Minor` only. The installer is a self-extracting archive: the scripts download it, unzip it with `Get-ChocolateyUnzip`, and hash the extracted `setup.exe` (not the outer download) for the install-time checksum via `Get-NvidiaChecksums`. `tools/helpers.psm1` (imported by `chocolateyinstall.ps1`) implements GPU-compatibility gating: `Get-NvidiaGPU`/`Test-NvidiaGPUInDeviceList` refuse to install on non-NVIDIA or unsupported-model hardware unless the `/SkipCompatCheck` package parameter is passed, and `Get-/Remove-OtherVersionsOfNvidiaDisplayDrivers` back the optional `/RemoveOtherVersions` parameter. These two packages also support a `-republish` switch on `update.ps1` (used by their own `republish_*.yml` workflows) to re-push the current version without requiring a new upstream release.
- **puttie**: still has an unfilled nuspec template (`__REPLACE__` placeholders, see `TODO.txt`) and no `update.ps1` — not part of the automated flow yet.

### GitHub Actions workflows (`.github/workflows/`)

One `update_<package>.yml` per automated package: `workflow_dispatch` + a daily `cron`, running on `windows-latest` (required — these scripts use Windows-only cmdlets and `choco.exe`) with `GH_TOKEN: ${{ github.token }}`, `api_key: ${{ secrets.CHOCOLATEY }}`, and `packageName: <id>` env vars, checking out the repo and running `pwsh .\update.ps1` from the package folder. The nvidia packages additionally have a `republish_<package>.yml` (`workflow_dispatch`-only) running `update.ps1 -republish`.

When adding a new automated package, mirror an existing workflow file exactly (env var names, `windows-latest`, checkout + `cd` + `pwsh .\update.ps1`) and add its status badge to the root `README.md`.
