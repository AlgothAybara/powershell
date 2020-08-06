#region ------------ Header --------------
#    -  Variable $key needs to be changed
#    -  If used with an MSP, assign $key with a custom field at runtime if supported
#    -  If used with an MSP, add an alert to the Message() function if supported
#endregion

#****************** Variables ******************
    # Install-WebRoot Variables
    $downloadURL = "http://anywhere.webrootcloudav.com/zerol/wsasme.msi"
    $localInstaller = "c:\Temp\wsasme.msi"
    $key = "1234-ABCD-1234-ABCD-1234"
    
    # Get-InstalledApps Variables
    $tempdir = Get-Location
    $tempdir = $tempdir.tostring()
    $appToMatch1 = '*WebRoot*'
    $appToMatch2 = 'WRSA'

    # Error Messages
    $downloadError = "Encountered an error while downloading Webroot."
    $powershellError = "The powershell version on this asset is too old to work with this script.`n Please update powershell and try again."

# ******************  Functions  ****************** #
    # Function generates an error message and creates an alert
    function Message($message) {
        Write-Host $message
        Exit 1
    }

    # Function Checks for program installation
    function Get-InstalledApps
    {
        if ([IntPtr]::Size -eq 4) {
            $regpath = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*'
        }
        else {
            $regpath = @(
                'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*'
                'HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
            )
        }
        Get-ItemProperty $regpath | .{process{if($_.DisplayName -and $_.UninstallString) { $_ } }} | Select DisplayName, Publisher, InstallDate, DisplayVersion, UninstallString |Sort DisplayName
    }

    # Function catches results from installation checker and returns true/false if program present
    function ReadResults
    {
        $result1 = Get-InstalledApps | where {$_.DisplayName -like $appToMatch1}
        $result2 = Get-InstalledApps | where {$_.DisplayName -like $appToMatch2}

        if($result1 -eq $null -and $result2 -eq $null){ return $false }
        else {return $true}
    }

    # Function downloads and installs WebRoot
    function Install-WebRoot {
        # checks for installer and downloads webroot
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
        
        #attempts to install webroot
        if (Test-Path $localInstaller) {
            Write-Host "Starting Install..."
            try {
                start -filepath $localInstaller -ArgumentList "GUILIC=$key CMDLINE=SME,quiet /qn"
            }catch{
                $message = "Encountered an error while installing Webroot."
                Message($message)
            }
            
            # Prevents early termination of program
            do {
                write-host "Installation in Progress..."
                $install = get-process | where {$_.Name -eq "wsasme"}
                Sleep 5
            } while ($install -ne $null)                
        } else {
            Message($downloadError)
        }  
    }

# ******************  Main  ****************** #
function Main {
    # Creates Directory
    if (!(Test-Path "C:\Temp")) {
        mkdir "C:\Temp";
    }

    # Checks the Powershell version for compatability
    if (3 -gt $PSVersionTable.PSVersion.Major){
        Message($powershellError)
        Write-Host "Current Verion:"
        $PSVersionTable.PSVersion.Major
    }

    #Checks for webroot, downloads and installs webroot
    $result = ReadResults

    If ($result -eq $false) {
        Write-Host "Webroot Not Installed. Attempting Now."
        Install-WebRoot
    } else {
        $result
        Write-Host "Program Already Installed."
        #Exit 0
    }

    #Verifies webroot was installed after program finishes. 
    $result = ReadResults
    If ($result -eq $false) {
        $message = "Script Failed. Webroot Not Installed."
        Message($message)
    } else {
        Write-Host "Webroot Installed"
    }
} 

Main
