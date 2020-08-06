#region --------------- Header ---------------
#   -  Script relies on modle "Posh-SSH" to reboot access points. 
#   -  Script relies on feature OpenSSH to run. 
#   -  Script can be modified to run othre cmdlets in the Posh-SSH module.
#   -  Script used to automate reboot of various ssh-accessable points wthout the use of cronjobs
#   -  Can be used with an MSP to automate reboos. Some MSPs powershell does not support cmdlet "Install-Module"
#   -  Variables $user; $hostname; and $pass must all be changed for this script to work properly.
#endregion

# ********** Variables **********
    $user = "example"
    $hostname = "192.168.255.255"
    $pass = "example"

# ********** Functions **********
    # Powershell must be v5 or later for this script to run.Function checks current PS version.
    function PowershellChecker(){
        Write-Host "--- Checking Powershell Version ---"
        if (5 -gt $PSVersionTable.PSVersion.Major){
            Write-Host "Powershell Version is too old to run this script. Please update and try again."
            Write-Host "Current Verion:"
            $PSVersionTable.PSVersion.Major
            Exit 1
        }
    }
        
    # In order for this to run successfully you need to install the Posh-SSH module. Function checks for and installs Posh-SSH
    function ModuleCheck($module){
        Write-Host "--- Checking for $module ---"
    if (Get-Module -ListAvailable -Name $module) {
        Write-Host "$module is Installed"
        Import-Module -Name $module
    } 
    else {
        Write-Host "$module is not installed."
        try {
            Write-Host "--- Attempting to install $module ---"
            Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force  
            Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted
            Install-Module -Name $module -Force
            Set-PSRepository -Name 'PSGallery' -InstallationPolicy Untrusted
            Import-Module -Name $module
            }
        catch {
            Write-Host "Manually install $module"
            Exit 1
        }
    }
    }

    # Function Logs into SSH and Reboots WAP
    function SSHRebooter(){
        #Converting the password so it can be used with PSCredential 
        $secpasswd = ConvertTo-SecureString "$pass" -AsPlainText -Force 
        #Creating the PSCredential object with username and password. Using this method to avoid the Get-Credential pop-up 
        $mycreds = New-Object System.Management.Automation.PSCredential ("$user", $secpasswd) 
        Write-Host "---Attempting to connect to router---" 
        #Creating the SSH connection 
        try{ New-SSHSession -ComputerName "$hostname" -Credential $mycreds -Force}
        catch{ 
            Write-Host "SSH connection failed. Please rerun script."
            Exit 1
        }
        # Rebooting the SSH connection 
        Write-Host "---Rebooting router---" 
        Invoke-SSHCommand -Index 0 -Command "reboot" 
        # Disconnecting the SSH connection 
        Write-Host "---Disconnecting router---" 
        Remove-SSHSession -SessionId 0
        Exit 0
    }

# ********** Main **********
# Main function calls all other functons.
    function Main(){
        PowershellChecker
        ModuleCheck("Posh-SSH")
        SSHRebooter
    }

    Main
