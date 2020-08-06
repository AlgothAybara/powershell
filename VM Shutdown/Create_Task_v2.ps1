#region --------------- Header ---------------
#   - Script to be ran with VM_Shutdown.ps1 script
#   - Creates a task using the above script located in c:\temp. Change path if file is saved elsewhere.
#   - Created task runs at startup as system. Paired script does not end and checks battery status every 15 seconds.
#endregion

# ********** Declarations **********
    $taskName = "VM Shutdown"
    
# ********** Functions **********
    # Function creates alert and writes to terminal any error messages
    function Message($message){
        Write-Host($message)
        Exit 1
    }

    # Function checks if task exists and returns the task object
    function Check {
        try {
            $taskExists = Get-ScheduledTask -TaskName $taskName
        } catch {
            $taskExists = $false
        }
        return $taskExists
    }

    # Function creates task
    function CreateTask($taskName) {
        "Attempting to create task"
        $Action = New-ScheduledTaskAction -Execute "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -Argument "-File `"C:\temp\VM_Shutdown.ps1`""
        $Trigger = New-ScheduledTaskTrigger -AtStartup #-RepetitionInterval (New-TimeSpan -Hours 1) -RepetitionDuration ([System.TimeSpan]::MaxValue) -ExecutionTimeLimit ([System.TimeSpan]::MaxValue) 
        $Principal = New-ScheduledTaskPrincipal -RunLevel Highest -UserID "NT AUTHORITY\SYSTEM" -LogonType ServiceAccount
        $Settings = New-ScheduledTaskSettingsSet -DontStopOnIdleEnd -RestartCount 10 -RestartInterval (New-TimeSpan -Minutes 1) -ExecutionTimeLimit (New-TimeSpan) -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -WakeToRun 
        $Task = New-ScheduledTask -Action $Action -Principal $Principal -Trigger $Trigger -Settings $Settings
        try { 
            Register-ScheduledTask -InputObject $Task -Force -TaskName $taskName
        } Catch { 
            $message = "Could not create new task."
            Message($message)
        }
    }

    # Function Starts Task
    function StartTask($taskName, $taskExists) {
        if ($taskExists -ne $false) {
            try{
                Write-Host "Attempting to start task"
                Start-ScheduledTask -TaskName $taskName
            } catch {
                Unregister-ScheduledTask -TaskName $taskName -Confirm:$False
                CreateTask($taskName)
                $message = "Could not start task. Please try again."
                Message($message)
            }
            Get-Job | Wait-Job
            $taskExists = Check
            if ($taskExists.State -eq "Running") {
                Write-Host "Successfully Started task."
                Exit 0            
            }  
        } else {
            $message = "Could not verify that task exists."
            Message($message)
        }
    }

    # Main Module of current powershel file.
    function Main($taskName, $taskExists) {
        if(!(test-path "C:\temp\VM_Shutdown.ps1")){
            $message = "Required powershell file failed to download."
            Message($message)
        }

        $taskExists = Check

        if (!($taskExists)) {
            CreateTask($taskName)
            StartTask $taskName $taskExists
        } elseif ($taskExists.State -ne "Running") {
            StartTask $taskName $taskExists
        } else {
            Write-Host "Task exists and is running."
            Exit 0
        }
    }

# ********** Script **********
    Main $taskName $taskExists 
