<# 
    Runs daily at 2pm from task scheduler
    Last Updated 9/3/2019
#>

# Set location path
Set-Location -Path $PSScriptRoot

# Load configuration from JSON
$configFilePath = Join-Path -Path $PSScriptRoot -ChildPath "config.json"
$config = Get-Content -Path $configFilePath | ConvertFrom-Json

# Access settings from the JSON configuration
$BackupPath = $config.BackupSettings.BackupPath
$textFilePath = $config.BackupSettings.TextFilePath

# Calculate total size of all files
$totalSize = (Get-ChildItem -Path $BackupPath -File | Measure-Object -Property Length -Sum).Sum

# Display total size in GB
$totalSizeInGB = [math]::round($totalSize / 1GB, 2)
Write-Host "$totalSizeInGB GB"

# Create the content to append
$NewContent = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Total Backup Size: $totalSizeInGB GB"

# Overwrite the text file with the new content
Set-Content -Path $textFilePath -Value $NewContent

# Append the content to the text file (optional)
# Add-Content -Path $textFilePath -Value $NewContent

# Example usage of fsutil to create a file (uncomment if needed)
# fsutil file createNew ".\FileStorage\test.txt" 104857600000
