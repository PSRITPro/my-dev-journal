<# 
    Runs daily at 2pm from task scheduler
    Last Updated 9/3/2019
#>
# Set location path
Set-Location -Path $PSScriptRoot
#Location of Backup Files
# Define the backup path
#BackupPath = "C:\mount\SQLData1\SQLbackups"
$BackupPath = "E:\GitHub\sptrains\PowerShell\Windows\FileStorage"
$textFilePath = "E:\GitHub\sptrains\PowerShell\Windows\Logs\BackupSizeReport.txt"

# Calculate total size of all files
$totalSize = (Get-ChildItem -Path $BackupPath -File | Measure-Object -Property Length -Sum).Sum
# Display total size in GB
$totalSizeInGB = [math]::round($totalSize / 1GB, 2)
Write-Host "$totlaSize GB"
# Create the content to append

$NewContent = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Total Backup Size: $totalSizeInGB GB"

# Overwrite the text file with the new content
Set-Content -Path $textFilePath -Value $NewContent
# Append the content to the text file
#Add-Content -Path $TextFilePath -Value $Content

#fsutil file createNew ".\FileStorage\test.txt" 104857600000