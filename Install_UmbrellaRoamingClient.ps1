#region ---------- Header ----------
#   - Script checks for and installs Umbrella Roaming Client
#   - Change variables $userID, $orgID, and $orgFingerprint to match values found in your Umbrella Portal
#endregion

# ***** Variables *****
    $software = "Umbrella Roaming Client"
    $localInstaller = "C:\temp\setup.msi"
    $downloadURL = "http://shared.opendns.com/roaming/enterprise/release/win/production/Setup.msi"
    $orgFingerprint = "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
    $orgID = 0123456
    $userID = 0123456

# ***** Error Messages *****
    $failError = "$software failed to install."
    $downloadError = "Encountered an error while downloading $software."
    $powershellError = "The powershell version on this asset is too old to work with this script.`n Please update powershell and try again."

# ***** Functions *****
    # Function Writes message to output
    function Message($message) {
        Write-Host $message
        Exit 1
    }

    # Function Looks for Installed application
    function Get-InstalledApps ($software) {
        if ([IntPtr]::Size -eq 4) {
            $regpath = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*'
        }
        else {
            $regpath = @(
                'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*'
                'HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
            )
        }
        return Get-ItemProperty $regpath | .{process{if($_.DisplayName -and $_.UninstallString) { $_ } }} | Select DisplayName | where {$_.DisplayName -like $software}
    }

    # Function Downloads Umbrella Installer
    function Download_Installer {
        if (!(Test-Path $localInstaller)) {
            Write-Host "Installer not downloaded."
            try {
                    Write-Host "Starting Download..."
                    Invoke-WebRequest -Uri $downloadURL -OutFile $localInstaller -ErrorAction Stop
            } catch {
                Message($downloadError)
            }
        } else {
            Write-Host "Installer already downloaded."
        }
    }

    # Function Installs Umbrella
    function Install-Umbrella {
        if (($orgfingerprint.length -gt 0) -and (($orgID).tostring().length -gt 0)){
            try {
                Write-Host "Installing $software..."
                msiexec.exe /i $localInstaller /qn ORG_ID=$orgID ORG_FINGERPRINT=$orgFingerprint USER_ID=$userID HIDE_UI=1 HIDE_ARP=1
            } catch {
                Message($failError)
            }
        } else {
            $message = "Either the Fingerprint or ID is blank. Please fix and try again."
            Message($message)
        }
    }

    # Function ensures powershell is compatible with script
    function CheckPowershell {
        if (3 -gt $PSVersionTable.PSVersion.Major){
            Message($powershellError)
            Write-Host "Current Verion:"
            $PSVersionTable.PSVersion.Major
        }
    }

    function Main {
        # Creates Directory
        if (!(Test-Path "C:\Temp")) {
            mkdir "C:\Temp";
        }
        CheckPowershell
        $check = Get-InstalledApps($software)
        if (!($check)) {
            Write-Host "$software not installed."
            Download_Installer
            Install-Umbrella
        } else {
            Write-Host "$software is already installed."
            Exit 0
        }
        $check = Get-InstalledApps($software)
        if ($check){
            Write-Host "$software successfully installed"
            Exit 0
        } else {
            Message($failError) 
        }
    }

# ***** Script *****
    Main
