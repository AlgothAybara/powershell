#region ********** Header **********
#   - Script installs updates KB5001566 and KB5001567 to fix KB50008** errors
#endregion

# ----- Declarations -----
$module = "PSWindowsUpdate"
$alertCat = "03/13 Update Fix Error"
$message = ""

# ----- Functions -----

# Function creates alert and writes to terminal any error messages
function Message($message){
    Write-Host $message
    #Write-Host($message)
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
    Write-Host "Checking if system is Windows 10 and the Release ID"
    $winVer =  [Environment]::OSVersion.Version.Major
    #If OS is not on Windows 10, script will abort
    if ($winVer -eq 10){
        $CurrentVer = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").ReleaseId
        if ($CurrentVer -eq 2009){
            UninstallUpdate("19041.867")
        } 
        elseif ($CurrentVer -eq 2004){
            UninstallUpdate("19041.867")
        } 
        elseif ($CurrentVer -eq 1909 -or $CurrentVer -eq 1903){
            UninstallUpdate("18362.1440")                
        }
        elseif ($CurrentVer -eq 1809){17134.2087
            UninstallUpdate("17763.1817")                
        }elseif ($CurrentVer -eq 1809){
            UninstallUpdate("17134.2087")  
        } else {
            Write-Host "Windows Release ID is 1709 or older"
            exit 1
        }
    }
}

# Function uses PSWindowsUpdate module to update windows
function PatchUpdates($KBArticleID) {
    # CU KBs and DL links https://www.catalog.update.microsoft.com/Search.aspx?q=2021-03%20cumulative%20update
    #Optional Runtime Variable $AutoReboot False by default.
    "`$AutoReboot set to '$AutoReboot'"

    # Get Windows Version
    $winVer = Get-ItemProperty -Path "HKLM:SOFTWARE\Microsoft\Windows NT\CurrentVersion" |
        Select-Object -Property ReleaseID,@{
            n='Version'; e={[System.Version]('{0}.{1}.{2}' -f [int]$_.CurrentMajorVersionNumber,[int]$_CurrentMinorVersionNumber,[int]$_.CurrentBuildNumber)}}

    $kbs = @{
        # Server 2016
        '1607' = [PSCustomObject]@{ KB = 'KB5001633'; uri = 'http://download.windowsupdate.com/d/msdownload/update/software/updt/2021/03/windows10.0-kb5001633-x64_de4efdfb38b1229ba80d5f66689b9079a0871585.msu'}
        # Server 2019
        '1809' = [PSCustomObject]@{ KB = 'KB5001638'; uri = 'http://download.windowsupdate.com/d/msdownload/update/software/updt/2021/03/windows10.0-kb5001638-x64_64937e493ea9574759536d4b2695c05dfa5543e3.msu'}
        '1903' = [PSCustomObject]@{ KB = 'KB5001566'; uri = 'http://download.windowsupdate.com/d/msdownload/update/software/updt/2021/03/windows10.0-kb5001566-x64_b52b66b45562d5a620a6f1a5e903600693be1de0.msu'}
        '1909' = [PSCustomObject]@{ KB = 'KB5001648'; uri = 'http://download.windowsupdate.com/d/msdownload/update/software/updt/2021/03/windows10.0-kb5001648-x64_770175898c1bee1cfbcadc981fa47797c46f8b09.msu'}
        '2004' = [PSCustomObject]@{ KB = 'KB5001649'; uri = 'http://download.windowsupdate.com/d/msdownload/update/software/updt/2021/03/windows10.0-kb5001649-x64_aca549448414a5ad559c742c39e9342468a23eb5.msu'}
        '2009' = [PSCustomObject]@{ KB = 'KB5001649'; uri = 'http://download.windowsupdate.com/d/msdownload/update/software/updt/2021/03/windows10.0-kb5001649-x64_aca549448414a5ad559c742c39e9342468a23eb5.msu'}
    }

    $fileName = ($Kbs[$winVer.ReleaseId].KB + '.msu')
    $KbMsu = Join-Path -Path "$env:SystemRoot\temp" -ChildPath $fileName

    if ((Get-HotFix).HotFixID -notcontains $Kbs[$winVer.Releaseid].KB) {
        "Downloading $fileName"
        try {
            Start-BitsTransfer -Source $kbs[$winVer.Releaseid].uri -Destination $KbMsu -ErrorAction Stop
        }
        catch [System.Exception] {
            Write-Warning -Message $Error[0].Exception.Message
            $message += 'Please check your patch URL and try again'
            Message($message)
        }
        catch {
            $message += "Error Downloading MSU"
            Write-Warning -Message (($Error[0] | Select-Object -Property Exception | Out-String).trim() -split '\r')[-1].Trim()
            Message($message)
        }
        "Starting $filename install."
        $ArgList = "$KbMsu /quiet /norestart"
        if ($AutoReboot -match '\$?true|1|yes'){
            $ArgList = $ArgList.Replace(' /norestart','')
        }
        Start-Process -FilePath wusa -ArgumentList $ArgList -NoNewWindow
    } else {
        if (Test-Path -Path "$env:SystemRoot\temp\*.msu"){
            Remove-Item -Path "$env:SystemRoot\temp\*.msu"
        }
    }
}

function UninstallUpdate($BuildNum) {        
    
    write-host "Checking for $BuildNum on system"
    try{
        $SearchUpdates = dism /online /get-packages | findstr "Package_for"
        $SearchUpdates | Format-Table -AutoSize
        $PackageName = $SearchUpdates.replace("Package Identity : ", "") | findstr $BuildNum
        write-host $PackageName
    } catch {
        $message += "Failed to get update list. `n"
    }
    
    if ($PackageName -eq $null) {
        $message += "OS Build $BuildNum not present on target machine.`n"
    }
    
    Write-Host "Attempting to uninstall OS Build $BuildNum"
    try{
        DISM.exe /Online /Remove-Package /PackageName:$PackageName /quiet /norestart
        Write-Host "Update uninstalled. System restart required."
    } catch {
        $message += "Failed to uninstall update.`n"
    }

    PatchUpdates
}

function Main {
    UpdateWindows        
    exit 0
}

# ----- Script -----
Main
