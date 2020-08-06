#region --------------- Header ---------------
#   - Script tires logging into local accounts to check for weak passwords
#   - To add passwords to check, add them to the array $defaultPass
#endregion 

# ********** Declarations **********
    Import-Module $env:SyncroModule
    $users = Get-LocalUser | Select-Object name, enabled
    $defaultPass = "", "password", "Password", "password1", "Password1"
    $computer = $env:COMPUTERNAME
    $message = ""

# ********** Functions **********

    function CheckDomain{
        $check = $operating -like "*Server*"
        if ((gwmi win32_computersystem).partofdomain -eq $true -and $check -eq $false) {
            Write-Host "Target Device is part of a domain" 
            # exit 0
        } elseif ($check) { 
            Write-Host "Target device is a server"
            # exit 0
        } else {
            Write-Host "Target device is not connected to a domain."
        }
    }

    # Function loops through both passwords and users and passes possible credentials to another function
    
    function PasswordLoop ($message) {
        for ($i=0; $i -lt $defaultPass.length; $i++){
            foreach ($user in $users) {
                if ($user.enabled -eq $true){
                    $name = $user.name
                    $message = PasswordChecker $name $defaultPass[$i] $message
                }
            }
        }
        if ($message.length -gt 0) {
            Message($message)
        }
    }

    # Function writes any error messages to the terminal
    function Message($message){
        Write-Host($message)
        # Exit 1
    } 

    # Funtion creates a machine object and attempts to login to local accounts with default passwords
    function PasswordChecker($username, $password, $message) {
        try {
            Add-Type -AssemblyName System.DirectoryServices.AccountManagement
            $DS = New-Object System.DirectoryServices.AccountManagement.PrincipalContext('machine',$computer)
            $test = $DS.ValidateCredentials($username, $password)
            if ($test -eq $true) {
                $message += "User $name's password needs changed.`n"
            }
        } catch [System.Management.Automation.MethodInvocationException]{
            $message += "User $name's password needs changed.`n"
        } catch {
            Write-Host "Unknown error occured."
        }
        return $message
    }
    
    # Function is the main module of the script.
    function Main {
        CheckDomain
        PasswordLoop $message
        # Exit 0
    }

# ********** Script *********
    Main
