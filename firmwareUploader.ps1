#User Information - Please Fill-In
$User = ""
$Password = ""
$IPArr = @("","","")



#FirmwareUpdate Map
$UpdateMap = @{
    C3560 = "c3560cx-universalk9-mz.152-7.E5.bin";
    C38XX = "cat3k_caa-universalk9.16.12.07.SPA.bin";
    C44XX = "isr4400-universalk9.16.12.07.SPA.bin";
    C43XX = "isr4300-universalk9.16.12.07.SPA.bin";
    C9XXX = "cat9k_iosxe.16.12.07.SPA.bin";
    C11XX = "c1100-universalk9.16.12.07.SPA.bin";
    NEX = "nxos.9.3.9.bin";
}

# SSH Process Define
$sshd = New-Object System.Diagnostics.ProcessStartInfo
$sshd.FileName = "ssh.exe"
$sshd.RedirectStandardInput = $true
$sshd.RedirectStandardOutput = $true
$sshd.UseShellExecute = $false

#CMD process define... Used to call SCP in standardinput.writeline()
$scpd = New-Object System.Diagnostics.ProcessStartInfo
$scpd.FileName = "cmd.exe"
$scpd.RedirectStandardInput = $true
$scpd.RedirectStandardOutput = $false
$scpd.UseShellExecute = $false


foreach($ip in $IPArr)
{

        # Variable Definitions - Do not fill-in
    $Output = ""
    $CurentDevice = ""
    $Firmware = ""

    # Define current IP for ssh in Loop
    $sshd.Arguments = "-o StrictHostKeyChecking=no $User@$ip"

    #SSH Process Start
    $sshp = [System.Diagnostics.Process]::Start($sshd)

    #System Sleep in-case distant end has latency
    Start-Sleep -s 8

    #Send Keys for Password
    [System.Windows.Forms.SendKeys]::SendWait($Password)
    [System.Windows.Forms.SendKeys]::SendWait("{ENTER}")

    #Allow distant end to load
    Start-Sleep -s 2

    # Remove terminal length to avoid stdout being stuck at --More--
    $sshp.StandardInput.Writeline("term len 0")
    # Check Device model
    Write-Host "Checking device model"
    $sshp.StandardInput.Writeline("show inventory")

    # Capture Output from show inventory command
    while (!$output.Contains("DESCR")) {
        $output = $sshp.StandardOutput.Readline()
    }

    #Capture Device Name
    $CurrentDevice = $output.Split(":")[2]

    # Firmware Choice Logic
    switch -Regex ($CurrentDevice) {
        '38[a-zA-Z0-9]{2}' {$Firmware = $UpdateMap.C38XX; Break}
        '44[a-zA-Z0-9]{2}' {$Firmware = $UpdateMap.C44XX; Break}
        '9[a-zA-Z0-9]{3}' {$Firmware = $UpdateMap.C9XXX; Break}
        '35[a-zA-Z0-9]{2}' {$Firmware = $UpdateMap.C3560; Break}
        '43[a-zA-Z0-9]{2}' {$Firmware = $UpdateMap.C43XX; Break}
        '11[a-zA-Z0-9]{2}' {$Firmware = $UpdateMap.C11XX; Break}
        'nex' {$Firmware = $UpdateMap.NEX; Break}
    }

    # Verify if distant-end has correct firmware
    $sshp.StandardInput.Writeline("dir")
    Write-Host "Checking for firmware"
    Write-Host $Firmware
    Write-Host $CurrentDevice
    Write-Host "Searching..."
    while (!$Output.Contains('bytes free')) {
        $Output = $sshp.StandardOutput.Readline()
        if ($output.Contains($Firmware) -eq $true) {
            #Correct firmware found
            Write-Host "Found!"
            Break;
        }
        
        
    }

    # Output filter
    if ($output.Contains($Firmware)) {
        Write-Host "Device already updated"
        $sshp.StandardInput.Writeline("exit")
    } else {
        Write-Host "Up-to-date firmware not found."
        Write-Host "Device needs to be updated."
        Write-Host "Updating now..."
        Write-Host $Firmware
        $sshp.StandardInput.Writeline("exit")

        #Get full path of firmware file from Documents folder
        $FullFilePath = Get-ChildItem -Path $env:USERPROFILE\Documents -Filter $Firmware | %{$_.FullName}
        #Define SCP arguments
        $scpd.Arguments = ""
        $scpp = [System.Diagnostics.Process]::Start($scpd)
        $scpp.StandardInput.Writeline("scp $FullFilePath $User@$ip`:flash`:/$Firmware")

        #Allow distant end to load if latent
        Start-Sleep -s 8

        # Send password to authenticate
        [System.Windows.Forms.SendKeys]::SendWait($Password)
        [System.Windows.Forms.SendKeys]::SendWait("{ENTER}")

    }

}