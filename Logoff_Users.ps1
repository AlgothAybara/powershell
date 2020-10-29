#region --------------- Header ---------------
#   -  Script loops through all active users on target system and signs them off.
#   -  Used on systems that allows multiple concurrent users via ThinStuff or similar applications
#endregion

# ********** Functions **********
    #Function loops through an array of users, logs them out, and writes out their username once logged off
    function EndSession($user){
        foreach($user in $users){
            try {
                write-host $user.Username
                logoff $user.SessionID
            } catch { 
                $Error[0].Exception.GetType().FullName
                Write-Warning $Error[0]
                logoff $user.Username
            }
        }
    }

    # Script gets an array of users and sends them to different functions
    function GetUsers {
        $users = Get-Process -IncludeUserName | Select-Object UserName,SessionId | Where-Object { $_.UserName -ne $null } |  `
        Where-Object {$_.UserName -notlike "*Font*"} |  Where-Object {$_.UserName -notlike "*Authority*"} | Where-Object {$_.UserName -notlike "*Window*"} |  `
        Sort-Object UserName -Unique
        if ($users.count -gt 0){
            return $users
        } else {
            Write-Host "No active users were found."
            exit 1
        }    
    }

    # Script prints out all signed in users
    function ShowUsers {
        Write-Host "Users currently signed in:"
        query user
    }

    # Main script that calls EndSession and gives it the output of the GetUsers function
    function Main {
        ShowUsers
        EndSession(GetUsers)
        ShowUsers
    }

# ********** Script **********
Main
