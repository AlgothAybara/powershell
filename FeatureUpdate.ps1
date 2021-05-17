#region ********** Header **********
#   - Script installs a feature update
#   - If currnet windows version is greater than $WindowsVer, no upate occurs
#   - Downloads and runs the Microsoft Upgrade Assistant and passes commandline parameters
#   - Script will ALWAYS restart the system after it is finished.
#   - Update $WindowsVer to the minimum version allowed to persist on machines
#endregion

# ----- Declarations -----
    Import-Module $env:SyncroModule

    $module = "PSWindowsUpdate"
    $alertCat = "Windows Update Error"
    $url = 'https://go.microsoft.com/fwlink/?LinkID=799445'
    $dir = 'C:\temp\_Windows_Feature'
    $WindowsVer = 2004

# ----- Functions -----
    # Function Checks used directory and creates it if it does not exist
    function Directories {
        if(!(test-path $dir)){
            mkdir $dir
        }        
    }

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
        Rmm-Alert -Category $alertCat -Body $message
        Write-Host($message)
        Exit 1
    }

    #Function Checks system environment to determine if ptches or feature update is needed
    function UpdateWindows {
        $CurrentVer = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").ReleaseId
        $winVer = [System.Environment]::OSVersion.Version.Major
        Write-host "Current Version: $CurrentVer"
        Write-host "Windows Version: $winVer"

        #If OS is not on Windows 10, script will abort
        if ($winVer -eq 10){            
            if(([int]$CurrentVer -lt [int]$WindowsVer)){
                FeatureUpdate
            } elseif ([int]$CurrentVer -eq [int]$WindowsVer){
                Write-Host "Windows is already on a current version."
                exit 0
            } else {
                $message = "Operating System not upgraded to Windows 10."
                Message($message)
            }               
        }
    }

    # Function downloads Windows Update Assistant and starts install
    function FeatureUpdate {
            $file = "$($dir)\Win10Upgrade.exe"
            
            #Tests for updater application
            if (!(test-path $file)){                
                try {
                    #Obtains install file from Microsoft
                    $webClient = New-Object System.Net.WebClient
                    Write-Host "Downloading Windows Update Assistant"
                    $webClient.DownloadFile($url,$file) 
                    Write-Host "Windows Update Assistant downloaded"
                } catch {
                    $message = "Failed to download Windows Update Assistant"
                    Message($message)
                }
            } else {
                Write-Host "Windows Update Assistant already downloaded"
            }
            
            try{
                #Starts the Windows Update Assistant
                Write-Host "Starting Windows Update Assistant"
                Start-Process -FilePath $file -ArgumentList '/quietinstall /skipeula $dir'
                Write-Host "Beginning Feature Update"
            } catch {
                $message = "Failed to start Windows Update Assistant"
                Message($message)
            }
        
    }

    function Main {
        Directories
        PowershellChecker
        UpdateWindows
        exit 0
    }

# ----- Script -----
    Main
