
#region
# --------------- Header ---------------
#   - Based off of blog post found here: https://www.cyberdrain.com/monitoring-with-powershell-ups-status-apc-generic-and-dell/
#   - Script is designed to be ran with Task Scheduler. 
#   - Once started, task runs indefinitely. Tak scheduler just needs to start sript at run time.
#endregion

# ********** Functions *********
    function Availability($battery) {
        Switch ($battery.Availability) {
        1   { $Availability = "Other"; break}
        2   { $Availability = "Not using battery"; break}
        3   { $Availability = "Running or Full Power"; break}
        4   { $Availability = "Warning"; break}
        5   { $Availability = "In Test"; break}
        6   { $Availability = "Not Applicable"; break}
        7   { $Availability = "Power Off"; break}
        8   { $Availability = "Off Line"; break}
        9   { $Availability = "Off Duty"; break}
        10  { $Availability = "Degraded"; break}
        11  { $Availability = "Not Installed"; break}
        12  { $Availability = "Install Error"; break}
        13  { $Availability = "Power Save - Unknown"; break}
        14  { $Availability = "Power Save - Low Power Mode"; break}
        15  { $Availability = "Power Save - Standby"; break}
        16  { $Availability = "Power Cycle"; break}
        17  { $Availability = "Power Save - Warning"; break}
        }
        return $Availability
    }

    function CheckBattery {
        while ($true) {
            $battery = (get-wmiobject -class CIM_Battery -namespace "root\CIMV2")
            $batteryCharge = $battery.EstimatedChargeRemaining
        
            $Availability = Availability($battery)
            if ($battery.Availability -eq 2) {
                Start-Sleep -s 15
                continue
            }
            elseif (($batteryCharge -lt 99) -and ($battery.Availability -ne 2 )) {
                ShutDown
            }
        } 
    }

        function ShutDown {
            Try {
                $VMs = Get-VM | Where { $_.State -eq 'Running' }
                foreach ($VM in $VMs) {
                    Stop-VM -Name $VM.Name -Force
                }
                Get-Job | Wait-Job
                cmd.exe /c "shutdown /s /d u:6:12"
            } Catch {
                Get-VM | Where { $_.State -eq 'Running' } | Stop-VM
                Get-Job | Wait-Job
                cmd.exe /c "shutdown /s /d u:6:12"
            }
        }

    function Main {
        CheckBattery
    }

# ********** Script **********
Main
