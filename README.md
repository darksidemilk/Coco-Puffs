# Coco-Puffs

I'm coo coo for chocolatey packages!

Repository for my [published chocolatey packages](https://community.chocolatey.org/profiles/DarkSideMilk).

## Structuring

There's a sub-folder for each chocolatey community repo package maintained here (with the exception of powershell modules that publish their choco package as part of their own CI/CD that also publishes to the PSGallery)
Github actions will be used for CI/CD to auto publish packages as new versions are relased, likely utilizing chocolatey-AU
Publishing on the repo is subject to the Chocolatey review process (see also https://docs.chocolatey.org/en-us/community-repository/moderation/) which can take time for the final human review managed by volunteers.
Please be patient if a new version isn't published right away. 

## Status of automatic updates for packages

* [![Update NVIDIA RTX Driver Package](https://github.com/darksidemilk/Coco-Puffs/actions/workflows/update_nvidia-rtx-driver.yml/badge.svg)](https://github.com/darksidemilk/Coco-Puffs/actions/workflows/update_nvidia-rtx-driver.yml)
* [![Update NVIDIA Studio Driver Package](https://github.com/darksidemilk/Coco-Puffs/actions/workflows/update_nvidia-studio-driver.yml/badge.svg)](https://github.com/darksidemilk/Coco-Puffs/actions/workflows/update_nvidia-studio-driver.yml)
