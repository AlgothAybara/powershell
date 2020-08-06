#region --------------- Header ---------------
#   -  Variable $identifier is from main MSP/Parent identifier in Threatlocker. Be sure to change it.
#   -  Variable $groupName represents group in threatlocker. Be sure to update to current groups.
#   -  On line XX $groupName is changed if a server. Update group
#   -  Variable $organizationName represents organization used in ThreatLocker. Be sure to update it.
#endregion

# *************** Variables ****************
    $organizationName = "Example Organization"
    $groupName = "Example Group";
    $identifier = "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"
    $localInstaller = "C:\Temp\ThreatLockerStub.exe"

# *************** Functions ****************
    # Outputs fail messages
    function Message($message){
    Write-Host($message)
    Exit 1
    }

    # Checks the Powershell version for compatability
    function CheckPowershell(){
        if (2 -ge $PSVersionTable.PSVersion.Major){
            $PSVersionTable.PSVersion
            $message = "The powershell version on this asset is too old to work with this script.`n Please update powershell and try again."
            Message($message)
        }
    }

    # Function checks for ThreatLocker and starts it if present and not running
    function CheckForThreatLocker(){
        # Check if service exists and is running
        $service = Get-Service -Name ThreatLockerService -ErrorAction SilentlyContinue;

        if ($service.Name -eq "ThreatLockerService" -and $service.Status -ne "Running") {
            # If service exists and is not running, start the service, exit script
            $message = "This script had to restart the ThreatLocker Service."
            Start-Service ThreatLockerService;
            Message($message)
        } elseif ($service.Name -eq "ThreatLockerService" -and $service.Status -eq "Running") {
        # If the service is running, exit the script
        Write-Output "Threatlocker already present and running";
        Exit 0;
        } else {
            Write-Host "ThreatLocker not present"
        }
    }

    # Function preps information for script
    function PrepScript($groupName){
        # Verify Identifier is added
        if ($identifier -eq "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX") {
            $message = "Identifier required"
            Message($message)
        }

        # Check if C:\Temp directory exists and create if not
        if (!(Test-Path "C:\Temp")) {
            mkdir "C:\Temp";
        }

        # Check the OS type
        $osInfo = Get-CimInstance -ClassName Win32_OperatingSystem
        
        if ($osInfo.ProductType -ne 1) {
            # If not a workstations, change the group name
            $groupName = "Example Server Group";
        }   
        return $groupName
    }

    # Function attempts to get the group id
    function GenerateGroupID(){
        try {
            $url = 'https://api.threatlocker.com/getgroupkey.ashx'; 
            $headers = @{'Authorization'=$identifier;'OrganizationName'=$organizationName;'GroupName'=$groupName}; 
            $response = (Invoke-RestMethod -Method 'Post' -uri $url -Headers $headers -Body ''); 
            $groupId = $response.split([Environment]::NewLine)[0].split(':')[1].trim();
        }
        catch {
            $message = "Failed to get GroupId"
            Message($message)
        }

        # verifies groupID is proper length
        if($groupId.Length -ne 24){
            $message = "Unable to get correct group id"
            Message($message)
        }
        return $groupId
    }

    function DownloadThreatlocker(){
        # Check the OS architecture and download the correct installer
        try {
            if ([Environment]::Is64BitOperatingSystem) {
                $downloadURL = "https://api.threatlocker.com/installers/threatlockerstubx64.exe";
            }
            else {
                $downloadURL = "https://api.threatlocker.com/installers/threatlockerstubx86.exe";
            }
            Invoke-WebRequest -Uri $downloadURL -OutFile $localInstaller;
        }
        catch {
            $message = "Failed to download the installer"
            Message($Message)
        }
    }

    # Function attempts to download and install ThreatLocker
    function InstallThreatLocker($groupId) {
        # Attempt install
        try {
            & $localInstaller InstallKey=$groupId;
        }
        catch {
            $message = "Installation Failed"
            Message($message)
        }
    }

    # Function verifies ThreatLocker was properly installed
    function VerifyInstallation(){
        $service = Get-Service -Name ThreatLockerService -ErrorAction SilentlyContinue;

        if ($service.Name -eq "ThreatLockerService" -and $service.Status -eq "Running") {
            Write-Output "Installation successful";
            Exit 0;
        } else {
            if ($osInfo.ProductType -ne 1) {
                $message = "Installation Failed"
                Message($message)
            }
        }
    }

# *************** Main ****************    
    function Main(){
        CheckPowershell
        CheckForThreatLocker
        $groupName = PrepScript($groupName)
        $groupID = GenerateGroupID
        DownloadThreatlocker
        InstallThreatLocker($groupID)
        VerifyInstallation
    }

    Main
