# Set the current location to the script's directory
Set-Location $PSScriptRoot

# Generate a unique transcript file name with date and time
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$transcriptPath = ".\Transcript_$timestamp.log"

# Start a transcript to log output
Start-Transcript -Path $transcriptPath

# Check for pending reboot conditions
$PendingReboot = (
    (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing' -ErrorAction SilentlyContinue | 
    Select-Object -ExpandProperty RebootPending -ErrorAction SilentlyContinue) -eq $true) -or
    (Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager' -Name 'PendingFileRenameOperations' -ErrorAction SilentlyContinue) -or
    ((Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Updates' -Name 'UpdateExeVolatile' -ErrorAction SilentlyContinue).UpdateExeVolatile -ne 0) -or
    (Get-WmiObject -Namespace 'ROOT\ccm\ClientSDK' -Class 'CCM_ClientUtilities' -ErrorAction SilentlyContinue)

# Output the result
if ($PendingReboot) {
    Write-Host "System is pending for a reboot." -ForegroundColor Yellow
} else {
    Write-Host "System does not require a reboot." -ForegroundColor Green
}

# Stop the transcript
Stop-Transcript
