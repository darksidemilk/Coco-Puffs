function Get-NvidiaGPU {
    <#
    .SYNOPSIS
    Gets the nvidia gpu on the system if one exists using CIM

    .DESCRIPTION
    Gets the nvidia gpu on the system if one exists using CIM checking for the manufacturer first then checking for the known nvidia vendor id of PCI\VEN_10DE in the device ids
    #>
    [CmdletBinding()]
    param ( )
        
    process {
        $devices = Get-CimInstance -classname win32_PNPEntity;
        $displayDevices = $devices | Where-Object { 
            $_.PNPClass -match 'Display'
        }
        $nvidiaGpu = $displayDevices | Where-Object { $_.Manufacturer -match 'Nvidia'}
        if ($null -eq $nvidiaGpu) {
            Write-Verbose "No display devices show manufacturer as Nvidia, checking for vendor id of PCI\VEN_10DE in device ids"
            $nvidiaGPU = $displayDevices | Where-Object { 
                ($_.DeviceID.split("&"))[0] -match "PCI\\VEN_10DE"
            }
        }
        if ($null -eq $nvidiaGpu) {
            Write-Warning "No Nvidia GPU found! This package is only for systems with Nvidia GPUs!"
        }
        return $nvidiaGpu;
    }
}

function Test-NvidiaGPUInDeviceList {
    <#
    .SYNOPSIS
    Tests if the nvidia gpu on the system is in the list of compatible gpus for this driver version
    
    .DESCRIPTION
    Checks components of the device id against the ListDevices.txt file extracted from the nvidia driver package to see if the gpu is compatible with this driver version
    
    .PARAMETER extractPath
    The path to the extracted nvidia driver package

    #>
    [CmdletBinding()]
    param (
        $extractPath
    )
    
    process {
        $nvidiaGpu = Get-NvidiaGpu
        #after checking both the manufacturer and checking for the vendor id, if nvidiagpu is still null then return false as it is not an nvidia gpu
        if ($null -eq $nvidiaGpu) {
            "Not an nvidia gpu, returning null" | out-host;
            $deviceMatch = $null;
        } else {
            $modelID = ($nvidiaGpu.DeviceID.split("&"))[1] # e.g. "DEV_2571" which identifies the model of Nvidia A2000 12GB
            $modelID2 = ($nvidiaGpu.DeviceID.split("&"))[2] # e.g. "SUBSYS_161110DE" which identifies the more specific model of Nvidia A2000 12GB

            $listDevicesFile = "$extractPath\ListDevices.txt" # list of supported devices from nvidia extracted driver package
            $result = New-Object -TypeName System.collections.generic.List['system.object'] # list object
            
            # read the list devices file and add each line to the list object for simpler matching
            $content = Get-Content $listDevicesFile; 
            $content = $content.trim();
            $content.split("`n") | ForEach-Object {
                $result.add(($_.Trim()));
            }

            Write-Verbose "Checking if model id $modelID of the device id is compatible with this driver..."
            $deviceMatch = $result -match $modelID;
            if ($null -ne $deviceMatch) {
                if ($deviceMatch.count -gt 1) {
                    $deviceMatch = $deviceMatch -match $modelID2
                }
                $msg1 = "Compatible GPU found!`n"
                $line = "`n--------------------------------------------------------------------------------`n"
                $msg2 = "Your GPU is: $deviceMatch"
                $fontcolor = @{
                    BackgroundColor = "DarkGreen"
                    ForegroundColor = "Yellow"
                }
                Write-Host @fontcolor -Object ($msg1 + $line + $msg2 + $line)
            }
        }
        if ($null -eq $deviceMatch) {
            return $false;
        } else {
            return $true;
        }
    }
    
}

function Get-NvidiaDisplayDrivers {
    <#
    .SYNOPSIS
    Gets the nvidia display drivers installed on the system
    
    .DESCRIPTION
    Retrieves a list of all nvidia display drivers installed on the system based on the provider name of Nvidia and class name of Display
    #>
    [CmdletBinding()]
    param ( )
    
    process {
        $manufacturer = "NVIDIA"
        $className = "Display"
        $drivers = Get-WindowsDriver -Online | Where-Object {$_.ProviderName -match $manufacturer -and $_.ClassName -match $className };    
        return $drivers;
    }
    
}

function Get-OtherVersionsOfNvidiaDisplayDrivers {
    <#
    .SYNOPSIS
    Gets other versions of nvidia display drivers installed on the system
    
    .DESCRIPTION
    Retrieves a list of all other versions of nvidia display drivers installed on the system based
    on the provider name of Nvidia and class name of Display
    Compares the given version to the installed versions and returns all that do not match.
    Flattens the version first to compare correctly as nvidia driver versions in windows are in a differente format 
    within windows driver listings i.e. "31.0.15.5362" for the version "553.62".
    We flatten the normalized choco version given such as 553.62.0 to 55362 and check if that exists 
    in a flattened version of the installed driver version such as 3101535362 and then return the ones that don't match

    .PARAMETER drivers
    The list of nvidia display drivers to check, defaults to all nvidia display drivers on the system if not provided
    
    .PARAMETER version
    The choco package version of the nvidia driver to check against

    #>
    [CmdletBinding()]
    param (
        $drivers = (Get-NvidiaDisplayDrivers),
        $version = $env:chocolateyPackageVersion
    )
    
    process {
        "Finding other versions of nvidia display drivers not matching version $version" | out-host;
        #readd removed leading zeros to minor version for flattening correctly
        $semver = [system.version]$version
        if ($semver.minor -lt 10) {
            $nvidiaVerMinor = "0$($semver.minor)"
        } else {
            $nvidiaVerMinor = "$($semver.minor)"
        }
        $version = "$($semver.major).$nvidiaVerMinor.$($semver.build)"
        #get version without dots and without extra 0
        $flatver = $version.split(".")[0]+$version.split(".")[1]

        #nvidia driver versions in windows for 553.62 is "31.0.15.5362" need to flatten it to match against the other versions correctly as 553.62 is part of the build.revision portion at 15.5362
        $nonMatching = $drivers | Where-Object { 
            $ver = $_.Version.replace(".","");
            $ver -notmatch $flatver
        }
        "Found $($nonMatching.count) other versions of nvidia display drivers not matching version $version" | out-host;
        return $nonMatching;
        
    }
    
}

function Remove-OtherVersionsOfNvidiaDisplayDrivers {
    <#
    .SYNOPSIS
    Removes other versions of nvidia display drivers installed on the system
    
    .DESCRIPTION
    Removes other versions of nvidia display drivers installed on the system using pnputil.exe
    based on the provider name of Nvidia and class name of Display utilizes Get-OtherVersionsOfNvidiaDisplayDrivers
    
    .PARAMETER driversToRemove
    Mandatory param, get it with Get-OtherVersionsOfNvidiaDisplayDrivers -version <chocopackageversion>

    #>
    [CmdletBinding()]
    param (
        [parameter()]
        $driversToRemove
    )
    
    
    process {
        if ($null -eq $driversToRemove) {
            Write-Warning "no drivers to remove, not removing anything"
            return;
        } else { 
            $driversToRemove | ForEach-Object {
                $ver = $_.Version.replace(".","");
                "Removing driver version $($_.version) aka '$($ver.Substring(4,3)).$($ver.Substring(7,2))'" | out-host;
                try {
                    $result = pnputil /delete-driver $_.driver /uninstall;
                    $result2 = pnputil /delete-driver $_.driver /delete /force;
                    if (!($result -match 'Driver package deleted successfully.' -or $result2 -match 'Driver package deleted successfully.')) { # if neither command has a success message, throw an error
                        throw 'pnputil failed to delete'
                    }
                } catch {
                    Write-Warning "Failed to remove driver version $($_.version), you may need to manually remove it later"
                }
            }
        }
    }
    
}