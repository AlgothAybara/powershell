#region ********** Header **********
#   - Script installs updates based off of inputted variables
#   - $Categoy (String) is the type of windows update to install
#   - $Category should be set to one of the following options (List does not contain all possible categories)
#       - "Updates"
#       - "Windows 10, version 1903 and later"
#       - "Update Rollups"
#       - "Windows 10"
#       - "Windows 10 LTSB"
#       - "Drivers"
#       - "Security Updates"
#       - "Definition Updates"
#       - "Microsoft Defender Antivirus"
#       - "Critical Updates"
#   - $SpecificUpdate (Bool) is whether you want to install indicidual updates by KB ID or not. 
#   - $KBArticleID (String) is a list of KB IDs to install when $SpecificUpdate is yes, separated by commas (i.e. KB0000001, KB00000002, etc.)
#   - $NotKBArticleID (String) is a list of KB IDs not to install when $SpecificUpdate is no, separated by commas (i.e. KB0000001, KB00000002, etc.)
#   - $NotTitle (String) is a list of keywords in the name of updates you do not want to install, separated by commas (i.e. OneDrive, Silverlight, Cumulative, etc)
#endregion

# ----- Declarations -----
    $module = "PSWindowsUpdate"
    $Category = "Updates"
    $SpecificUpdate = $true
    $KBArticleID = "KB0000001"
    $NotKBArticleID = "KB0000001"
    $NotTitle = "Microsoft"

# ----- Functions -----

    # Powershell must be v5 or later for this script to run.Function checks current PS version.
    function PowershellChecker(){
        Write-Host "Checking Powershell Version"
        if (5 -gt $PSVersionTable.PSVersion.Major){
            $message = "Powershell Version is too old to run this script. Please update and try again.`n"
            $message += "Current Verion:`n"
            $message += $PSVersionTable.PSVersion.Major
            Message($message)
        }
    }

    # Function creates alert and writes to terminal any error messages
    function Message($message){
        Write-Host($message)
        Exit 1
    }
        
    # Function installs NuGet (required for powershell modules)
    function Install-NuGet {
        Write-Host "Installing NuGet"
        try {
            Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force  
        } Catch {
            $message = "Issue installing NuGet. Please try again."
            Message($message)
        }
    }
    
    # Function installs the module name declared in the $module var
    function ModuleCheck($module){
        Write-Host "Checking for $module"
        
        #Module is already installed, continue with script 
        if (Get-Module -ListAvailable -Name $module) {
            Write-Host "$module is Installed"
            Import-Module -Name $module
        } 
        #Module is not installed and will attempt to install
        else {
            Write-Host "$module is not installed."
            try {
                Install-NuGet
                Write-Host "Attempting to install $module"
                Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted
                Install-Module -Name $module -Force
                Set-PSRepository -Name 'PSGallery' -InstallationPolicy Untrusted
                Import-Module -Name $module
                }
            catch {
                $message = "Manually install $module"
                Message($message)
            }
            Write-Host "$module has been installed"
        }
    }

    #Function Checks system environment to ensure system is windows 10
    function UpdateWindows {
        Write-Host "Checking if system is on Windows 10"
        $winVer =  [Environment]::OSVersion.Version.Major
        #If OS is not on Windows 10, script will abort
        if ($winVer -eq 10){
            PatchUpdates                
        }
    }

    # Function uses PSWindowsUpdate module to update windows
    function PatchUpdates {
        ModuleCheck($module)
        
        Write-Host "Checking for updates."
        #Gets pending windows patches and displays them
        $updates = get-windowsupdate -MicrosoftUpdate
        foreach($update in $updates){
            Write-host $update.title
        }

        #Installs all outstanding updates and shows each step
        
        if ($SpecificUpdate){
            Write-Host "Installing $KBArticleID"
            try {
               Install-WindowsUpdate -MicrosoftUpdate -KBArticleID $KBArticleID -AcceptAll -IgnoreReboot -Verbose
            } catch {
               $message = "Failed to install specific updates."
               Message($message)
            }
        }
        elseif ($updates.Count -gt 0){
            Write-Host "Installing Updates"
            $Parameters = ""
            
            if ($Category.length -gt 0){
                $Parameters += '-Category "' + $Category + '" '
            }
            if ($NotTitle.length -gt 0){
                $Parameters += '-NotTitle "' +$NotTitle + '" '
            }
            if ($NotKBArticleID.length -gt 0){
                $Parameters += "-NotKBArticleID $NotKBArticleID "
            }
            
            $Parameters
            $command = "Install-WindowsUpdate -MicrosoftUpdate $Parameters -AcceptAll -IgnoreReboot -verbose "
            $command
            
            if($Parameters.length -gt 0){            
                try {
                    Invoke-Expression $command      
                } catch {
                    $message = "Failed to install patch updates"
                    Message($message)
                }
            } else {
                try {
                    Invoke-Expression $command      
                } catch {
                    $message = "Failed to install patch updates"
                    Message($message)
                }
            }
            
        #If no patches install, will return false
        } else {
            Write-Host "No patch updates available."
            return $false
        }
        #If patches were installed, will return true
        Write-Host "Patches installed"
        return $true
    }

    function Main {
       # PowershellChecker
        UpdateWindows        
        exit 0
    }

# ----- Script -----
    Main
