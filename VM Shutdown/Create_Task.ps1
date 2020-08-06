#region --------------- Header ---------------
#   - Script builds a task that runs file at c:\temp\VM_Shutdown.ps1
#   - Task begins at system Start Up
#endregion

function CreateTask {
    $taskName = "VM Shutdown"
    $Action = New-ScheduledTaskAction -Execute "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -Argument "-File `"C:\temp\VM_Shutdown.ps1`""
    $Trigger = New-ScheduledTaskTrigger -AtStartup 
    $Principal = New-ScheduledTaskPrincipal -RunLevel Highest -UserID "NT AUTHORITY\SYSTEM" -LogonType ServiceAccount
    $Settings = New-ScheduledTaskSettingsSet -DontStopOnIdleEnd -RestartCount 10 -RestartInterval (New-TimeSpan -Minutes 1) -ExecutionTimeLimit (New-TimeSpan) -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -WakeToRun 
    $Task = New-ScheduledTask -Action $Action -Principal $Principal -Trigger $Trigger -Settings $Settings
    Register-ScheduledTask -InputObject $Task -Force -TaskName $taskName

    Start-ScheduledTask -TaskName $taskName
}

try { 
    CreateTask 
} Catch { 
    Write-Host "Could not create new task."
}

