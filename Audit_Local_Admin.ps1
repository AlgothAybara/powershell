#region --------------- Header ---------------
#   -  Script compares current admins to a list of old ones saved in a text file.
#   -  If computer is part of a domain, it compares the current Admin SIDs to a list of SIDs
#   -  Compares SIDs due to false positives when connection to domain controller was down
#   -  If connection to domain controller is down, script attempts to repair connection.
#endregion

# ********** Declarations **********
    $oldFile = "C:\temp\a-old.txt"
    $newFile = "C:\temp\a-new.txt"
    $diffFile = "C:\temp\diff.txt"
    $oldFilePresent = Test-Path -Path $oldFile
    $newFilePresent = Test-Path -Path $newFile
    $partOfDomain = $false

# ********** Functions **********
    # --- Function creates and edits directories ---
    function Directories() {
        if(!(test-path C:\temp)){
            mkdir C:\temp
        }
        if($oldFilePresent -And $newFilePresent){
            Write-Host "Both files present" 
            del $oldFile
            mv $newFile $oldFile
        }     
    }

    # --- Function checks if part of domain and attempts to connect to domain ---
    function CheckDomain($partOfDomain){
        $check = $operating -like "*Server*"
        if ((gwmi win32_computersystem).partofdomain -eq $true -and $check -eq $false) {
                Write-Host "Computer is part of a domain" 
                if(Test-ComputerSecureChannel) {return $true}
                else{
                Write-Host "Computer is not connected to domain controller. Will attempt to repair connection"
                for($i=3;$i-gt0;$i--){
                    Try{
                        else{Test-ComputerSecureChannel -Repair -verbose}
                    }
                    Catch{
                        $j = $i-1
                        if ($j -gt 0){
                            if(Test-ComputerSecureChannel) {return $true}
                            Write-Host "Repair failed. Attempting to repair $j more times."
                        } elseif ($j -eq 0){
                        Write-Host "Failed to establish a connection. Aborting Script"
                        Exit 1
                        }
                    }   
                }
            }
        } elseif ($check) { 
            Write-Host "Target device is a server"
        }
    }

    # --- Function builds new txt file ---
    function BuildNew(){
        # collects admin usernames and sids and creates 2 arrays
        $obj_group = [ADSI]"WinNT://localhost/Administrators,group"
        $member_names= @($obj_group.psbase.Invoke("Members")) | foreach{([ADSI]$_).InvokeGet("Name")}
        
        $outText = "Current local Administrators: $member_names" 
        if ($partOfDomain -eq $true) {
            $i = 0
            do {    # script will not produce all admin SIDs. This loop checks length of arrays to protect against false positives.
                $member_SIDs = @()
                foreach($admin in $member_names){
                    $admin_string = Out-String -InputObject $admin
                    if ($admin_string -like "S-1-*") {
                        $member_SIDs += $admin
                    } else {
                        $member_SIDs += gwmi win32_useraccount -Filter "name='$admin'" | select -ExpandProperty sid 
                    }
                }  
                $sidAdmins = "`nCurrent Administrator SIDs: $member_SIDs"
                if ($member_names.length -eq $member_SIDs) { $check = $true }
                $i++
            } while (($check -eq $false) -or ($i -lt 5))
        }
        $outText += $sidAdmins
        return $outText
    }

    # --- Function reads new and old files into variables and compares them ---
    function OldPresent($num){
        Write-Host "Old File Present"
        $Delimiter = " "
        $outText = BuildNew
        $outText | Out-File -filepath $newFile 
        $obj_newFile = get-content $newFile | Select-Object -Index $num
        $obj_oldFile = get-content $oldFile | Select-Object -Index $num
        $ArrayOld = $obj_oldFile -Split $Delimiter
        $ArrayNew = $obj_newFile -Split $Delimiter 
        Write-Host "Doing Comparison"
        $comparison = compare-object $ArrayOld $ArrayNew
        FirstTime($ArrayOld[2])
        FirstTimeB($ArrayOld[3])
        return $comparison
    }

    # --- function checks if first time running new script ---
    function FirstTime($checkMe){
        Write-Host "Checking if first time running new script"
        if($partOfDomain -eq $true -and -not $checkMe -eq "SIDs:"){
            Write-Host "1. First Time running script. Comparison Aborted"
            NewPrep
        } elseif ($partOfDomain -eq $false -and $checkMe -eq "SIDs:") {
            Write-Host "2. First Time running script. Comparison Aborted"
            NewPrep
        } else {
            return
        }
    }

    function FirstTimeB($checkMe) {
        if ($checkMe -eq "SIDs:") {
            Write-Host "3. First Time running script. Comparison Aborted"
            NewPrep
        }else {
            return
        }
    }

    # --- Function reads comparison and prints results ---
    function Comparison($partOfDomain) {
        if($partOfDomain) {
            $comparison = OldPresent(1)
            $comparison2 = OldPresent(0)
        } else {
            $comparison = OldPresent(0)
        }
        
        Write-Host "Checking Comparison"
        
        if ($comparison -and $comparison2) {
            Alert($comparison2)
        } elseif($comparison -and (!($partOfDomain))) {
            Alert($comparison)
        } else {
            Write-Host "No admins have changed."
        }      
    }

    # --- Function writes message to terminal and raises alert ---
    function Alert($comparison) {
        Write-Host "Files differ"
        write-host "Comparison Key `n New file: => `n Old File: <="
        $comparison | out-file $diffFile
        $comparison = get-content C:\temp\diff.txt
        $comparison
        Exit 1
    }

    # --- Function preps computer for next run of script ---
    function NewPrep{
        $outText = BuildNew
        $outText | Out-File -filepath $newFile     
        cp $newFile $oldFile
        Exit 0
    }

    # --- Main Function ---
    function Main(){
        Directories
        $partofDomain = CheckDomain($partOfDomain)
        if($oldFilePresent){Comparison($partofDomain)}
        else{
            Write-Host "Both Files missing"
            NewPrep
        }
    }

# ********* Main **********
    Main
