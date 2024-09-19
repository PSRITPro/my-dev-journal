# Set the current location to the script's directory
Set-Location $PSScriptRoot

# Generate a unique transcript file name with date and time
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$transcriptPath = ".\Transcript_$timestamp.log"

# Start a transcript to log output
Start-Transcript -Path $transcriptPath

# Initialize the pending reboot flag
$PendingReboot = $false

# Check for pending reboot conditions
try {
    $RebootPending = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing' -ErrorAction Stop | 
                     Select-Object -ExpandProperty RebootPending -ErrorAction Stop
    if ($RebootPending) {
        $PendingReboot = $true
    }
} catch {
    Write-Host "Error checking Component Based Servicing: $_" -ForegroundColor Red
}

try {
    $PendingFileRenameOperations = Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager' -Name 'PendingFileRenameOperations' -ErrorAction Stop
    if ($PendingFileRenameOperations) {
        $PendingReboot = $true
    }
} catch {
    Write-Host "Error checking PendingFileRenameOperations: $_" -ForegroundColor Red
}

try {
    $WindowsUpdates = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Updates' -Name 'UpdateExeVolatile' -ErrorAction Stop
    if ($WindowsUpdates -and $WindowsUpdates.UpdateExeVolatile -ne 0) {
        $PendingReboot = $true
    }
} catch {
    Write-Host "Error checking UpdateExeVolatile: $_" -ForegroundColor Red
}

try {
    $PendingWindowsUpdates = Get-WmiObject -Namespace 'ROOT\ccm\ClientSDK' -Class 'CCM_ClientUtilities' -ErrorAction Stop
    if ($PendingWindowsUpdates) {
        $PendingReboot = $true
    }
} catch {
    Write-Host "Error checking pending Windows Updates: $_" -ForegroundColor Red
}

# Output the result
if ($PendingReboot) {
    Write-Host "System is pending for a reboot." -ForegroundColor Yellow
} else {
    Write-Host "System does not require a reboot." -ForegroundColor Green
}

# Stop the transcript
Stop-Transcript
