#region --------------- Header ---------------
#   -  Script relies on module DeviceManagement to restart a driver type
#   -  To change driver type, change the $driverDescrip to a word in the drivers you wish to restart
#   -  Script Downloads a zip, unpacks it to the module folder, installs the unpacked zip, and deletes the original zip.
#endregion

#region ********** Variables **********
$downloadURL = "https://gallery.technet.microsoft.com/Device-Management-7fad2388/file/65051/2/DeviceManagement.zip";
$moduleDestination = "C:\Program Files\WindowsPowerShell\Modules\DeviceManagement"
$fileLocation = "C:\temp\DeviceManagement.zip"
$module = "DeviceManagement"
$driverDescrip = "*graphic*"

#endregion
#region ********** Functions **********
#Function prints out error message
function Message($message){
    Write-Host($message)
    Exit 1
}

#Function Checks the powershell version. Some cmdlets require at least v.5 to run (Invoke-WebRequest)
function PowershellChecker(){
    Write-Host "--- Checking Powershell Version ---"
    if (5 -gt $PSVersionTable.PSVersion.Major){
        $message = "Powershell Version is too old to run this script. Please update and try again.`n"
        $message += "Current Verion:`n"
        $message += $PSVersionTable.PSVersion.Major
        Message($message)
    }
}

#Function Checks for module and imports it. If it is not found, it calls the InstallModule function
function ModuleCheck($module){
    Write-Host "--- Checking for $module ---"
    if (Get-Module -ListAvailable -Name $module) {
        Write-Host "$module is Installed"
        Import-Module -Name $module
    } 
    else {
        Write-Host "$module is not installed."
        InstallModule
        try {
            Write-Host "--- Attempting to install $module ---"
            Import-Module -Name $module
            }
        catch {
            $message = "Manually install $module"
            Message($message)
        }
        Write-Host "$module has been installed"
    }
}

#Function downloads .zip of module, expands it, and installs it.
function InstallModule(){
    try {       
        if(!(Test-Path -Path $fileLocation)){            
            Invoke-WebRequest -Uri $downloadURL -OutFile $fileLocation;
        }
        Unblock-File -path $fileLocation
        Expand-Archive -LiteralPath $fileLocation -DestinationPath $moduleDestination
        Install-Module -Name $module -Force
        del $fileLocation
    }
    catch {
        del $fileLocation
        $message = "Failed to install the module"
        Message($Message)
    }
}

#Using the DeviceManagement module, this function disables and reenables all drivers containing the word "graphic"
function RestartDrivers {
    $drivers = Get-Device | Where-Object -Property Name -like $driverDescrip
    foreach($driver in $drivers){
        Disable-Device -TargetDevice $driver
        Enable-Device -TargetDevice $driver
    }
}

#Main function directs the flow of the script
function Main {
    PowershellChecker
    ModuleCheck($module)
    RestartDrivers
}
#endregion

#region ********** Script **********
Main
#endregion