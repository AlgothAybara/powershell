#region -------------------------- Header --------------------------
#   - Script monitors ethernet connection speeds. Good for finding bad cables.
#   - Change threshold constant in Checker function to needed threshold.
#     i.e. ($THRESHOLD = 100 * Mb) = 100 Mb connection
#endregion

# ********** Declaration **********
$Gb = 1000000000       # 1 Gb speed
$Mb = 1000000          # 1 Mb speed
$Kb = 1000             # 1 Kb speed
$THRESHOLD = 100 * $Mb # Change to expected speeds

# ********** Functions **********
    # Function gets the list of current connections and evaluates the connection speed of Ethernet connections.
        function Connections {
            $connections = Get-NetConnectionProfile | Select -ExpandProperty InterfaceAlias
            Write-Host "Current connections:`n", $connections
        }

    # Function checks array of connections for ethernet and tests its speed.
        function Checker($connections){
            foreach ($connection in $connections){
                if ($connection -like "*ethernet*") {
                    $var = Get-NetAdapter -Name $connection | Select -ExpandProperty LinkSpeed
                    write-host $connection, ":", $var
                    $var = $var.Split(" ")
                    $ary = ($var[0] -as [int]), $var[1]
                    Switch -Exact ($var[1]) {
                        "Gbps" {$speed = $ary[0] * $Gb}
                        "Mbps" {$speed = $ary[0] * $Mb}
                        "Kbps" {$speed = $ary[0] * $Kb}
                    }
                    if ($speed -lt $THRESHOLD) {
                        $message = "Ethernet speeds are below the Gb threshold. Current speed: $($var). Please diagnose the connection."
                        Message($message)
                    } 
                }
            }
        }

    # Function raises alert when triggered.
        function Message($message){
            Write-Host($message)
            Exit 1
        }

    # Main Module
        function Main {
            $connections = Connections
            Checker($connections)
        }

# ********** Script **********
    Main
