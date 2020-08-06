#Vairables injected by Syncro:
$open_time = 0800
$close_time = 1500

#script for Syncro:

#region --------------- Header -------------
#   -  open_time: input in 24hr format
#   -  cose_time: input value between 0-59
#   -  when scheduling script in Syncro, 24hr format must be used.
#   -  Example: 1:43PM becomes -->
#   -  $current_time = 01:43
#endregion 

# ********** Variables *********
    $open_time = 0000
    $close_time = 0000
    $current_hr = (get-date).hour
    $current_min = (get-date).minute
    $time = "$($current_hr)$($current_min)"
    $time = $time -as [int]

# ********* Functons **********

    function validateTimes {
        # Gets inputted values as strings
        $open_string = $open_time.ToString()
        $close_string = $close_time.ToString()

        # Cuts off the last 2 numbers of a string and set it to integer
        $open_min = $open_string.Substring($open_string.Length - 2) -as [int]
        $close_min = $close_string.Substring($close_string.Length - 2) -as [int]
        
        # Sets boolean values if minutes are greater than 59 or value of input is greater than 2359
        $min_check = (($open_min -gt 59) -or ($close_min -gt 59))
        $size_check = (($open_time -gt 2359) -or ($close_time -gt 2359))

        if ($size_check -or $min_check) {
            Write-Host "One of the entered constraints are an invalid time."
            Exit 1
        }
    }
    
    function displayTimes {
        Write-Host "Current time is:  $($time)"
        Write-Host "After hours are:  $($close_time) to $($open_time)"
    }
        
    function compareTimes {
        if ($time -gt $close_time -or $time -lt $open_time)
        {
            Write-Host "Attempting to restart computer."
            try {
                Stop-Computer -Force
            } catch {
                Write-Host "Restart Failed."
                Exit 1
            }
            Exit 0
        }
        else {
            Write-Host "It is too late to run this script."
            Exit 1
        }
    }

function Main {
    validateTimes
    displayTimes
    compareTimes
}

# ********** Script **********
    Main
