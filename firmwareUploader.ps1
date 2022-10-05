$User = ""
$Password = ""
$IP = ""
$output = ""
$CurentDevice
$Firmware = ""
$Truncate = ""

$UpdateMap = @{
    C3560 = "c3560cx-universalk9-mz.152-7.E5.bin";
    C38XX = "cat3k_caa-universalk9.16.12.07.SPA.bin";
    C44XX = "isr4400-universalk9.16.12.07.SPA.bin";
    C43XX = "isr4300-universalk9.16.12.07.SPA.bin";
    C9XXX = "cat9k_iosxe.16.12.07.SPA.bin";
    C11XX = "c1100-universalk9.16.12.07.SPA.bin";
    NEX = "nxos.9.3.9.bin";
}

$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = "ssh.exe"
$psi.RedirectStandardInput = $true
$psi.RedirectStandardOutput = $true
$psi.UseShellExecute = $false
$psi.Arguments = "-o StrictHostKeyChecking=no $User@$IP"

$p = [System.Diagnostics.Process]::Start($psi)

Start-Sleep -s 8

[System.Windows.Forms.SendKeys]::SendWait($Password)
[System.Windows.Forms.SendKeys]::SendWait("{ENTER}")

Start-Sleep -s 3

$p.StandardInput.Writeline("show inventory")

while (!$output.Contains("DESCR")) {
    $output = $p.StandardOutput.Readline()
}

$CurrentDevice = $output.Split(":")[2]

switch -Regex ($CurrentDevice) {
    '38[a-zA-Z0-9]{2}' {$Firmware = $UpdateMap.C38XX; Break}
    '44[a-zA-Z0-9]{2}' {$Firmware = $UpdateMap.C44XX; Break}
    '9[a-zA-Z0-9]{3}' {$Firmware = $UpdateMap.C9XXX; Break}
    '35[a-zA-Z0-9]{2}' {$Firmware = $UpdateMap.C3560; Break}
    '43[a-zA-Z0-9]{2}' {$Firmware = $UpdateMap.C43XX; Break}
    '11[a-zA-Z0-9]{2}' {$Firmware = $UpdateMap.C11XX; Break}
    'nex' {$Firmware = $UpdateMap.NEX; Break}
}

$Truncate = $Firmware.SubString(0,5)

$p.StandardInput.Writeline("dir | i $Truncate")
Write-Host "Checking for firmware"
while (!$output.Contains('#')) {
    $output.StandardOutput.Readline()
    if ($output.Contains($Firmware) -eq $true) {
        Break;
    }
    Write-Host $output
}

if ($output.Contains($Firmware)) {
    Write-Host "Device already updated"
} else {
    Write-Host "Device needs updated"
}

$p.StandardInput.Writeline("exit")