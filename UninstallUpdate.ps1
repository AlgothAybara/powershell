#region ********** Header **********
#   - Script uninstalls patch wih specified build number
#   - Script uses DISM.exe to uninstall patches
#   - Script cannot uninstall Permenant Patches
#   - If Build number is not found, script will exit with an error and raise an alert
#   - For $BuildNum, search the KB number to uninstall and set to the OS Build number
#endregion

# ----- Declarations -----
    $module = "PSWindowsUpdate"
    $BuildNum = 19042.867

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

    # Function finds specified update via OS build number and attempt to uninstall it.
    function UninstallUpdate() {        
        
        write-host "Checking for $BuildNum on system"
        try{
            $SearchUpdates = dism /online /get-packages | findstr "Package_for"
            $SearchUpdates | Format-Table -AutoSize
            $PackageName = $SearchUpdates.replace("Package Identity : ", "") | findstr $BuildNum
            write-host $PackageName
        } catch {
            $message = "Failed to get update"
            Message($message)
        }
        
        if ($PackageName -eq $null) {
            $message = "OS Build $BuildNum not present on target machine."
            Message($message)
        }
        
        Write-Host "Attempting to uninstall OS Build $BuildNum"
        try{
            DISM.exe /Online /Remove-Package /PackageName:$PackageName /quiet /norestart
            Write-Host "Update uninstalled. System restart required."
        } catch {
            $message = "Failed to uninstall update."
            Message($message)
        }
    }

    function Main() {
        PowershellChecker
        UninstallUpdate
        exit 0
    }

# ----- Script -----
  Main
