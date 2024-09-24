# Set location to the script's directory
Set-Location -Path $PSScriptRoot

# Define log folder using $PSScriptRoot
$logFolder = Join-Path -Path $PSScriptRoot -ChildPath "logs"
# Create log folder if it doesn't exist
if (-not (Test-Path -Path $logFolder)) {
    New-Item -Path $logFolder -ItemType Directory | Out-Null
}

# Create a timestamp variable for use in the transcript file name
$timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'

# Create transcript file name based on the script name
$scriptName = [System.IO.Path]::GetFileNameWithoutExtension($MyInvocation.MyCommand.Name)
$transcriptPath = Join-Path -Path $logFolder -ChildPath "$scriptName-$timestamp.log"

# Start transcript to log the session
Start-Transcript -Path $transcriptPath -Append

# Connect to Microsoft 365 services
try {
    Connect-AzureAD -UserPrincipalName admin@example.com
    Connect-ExchangeOnline -UserPrincipalName admin@example.com
    Write-Host "Successfully connected to Microsoft 365 services."
} catch {
    Write-Host "Error connecting to Microsoft 365 services: $_"
    Stop-Transcript
    exit
}

# Path to the CSV file
$csvPath = Join-Path -Path $PSScriptRoot -ChildPath "users.csv"  # Update if the CSV file is in a different location

# Import users from CSV
try {
    $users = Import-Csv -Path $csvPath
    Write-Host "Successfully imported users from $csvPath."
} catch {
    Write-Host "Error importing CSV: $_"
    Stop-Transcript
    exit
}

foreach ($user in $users) {
    # Define user details from CSV
    $newUserEmail = $user.UserPrincipalName
    $licenseSku = $user.LicenseSku

    # Assign license
    try {
        $userObject = Get-AzureADUser -ObjectId $newUserEmail
        Set-AzureADUserLicense -ObjectId $userObject.ObjectId -AssignedLicenses @{AddLicenses=$licenseSku}
        Write-Host "License assigned to $newUserEmail."
    } catch {
        Write-Host "Error assigning license to $newUserEmail : $_"
    }

    # Add user to default groups
    $defaultGroups = @("Group1", "Group2")  # Replace with actual group names or IDs

    foreach ($group in $defaultGroups) {
        try {
            $groupObject = Get-AzureADGroup -SearchString $group
            Add-AzureADGroupMember -ObjectId $groupObject.ObjectId -RefObjectId $userObject.ObjectId
            Write-Host "$newUserEmail added to group $group."
        } catch {
            Write-Host "Error adding $newUserEmail to group $group : $_"
        }
    }

    # Enable litigation hold
    try {
        Set-Mailbox -Identity $newUserEmail -LitigationHoldEnabled $true
        Write-Host "Litigation hold enabled for $newUserEmail."
    } catch {
        Write-Host "Error enabling litigation hold for $newUserEmail : $_"
    }

    # Enable mailbox archive
    try {
        Enable-Mailbox -Identity $newUserEmail -Archive
        Write-Host "Mailbox archive enabled for $newUserEmail."
    } catch {
        Write-Host "Error enabling mailbox archive for $newUserEmail : $_"
    }

    # Set archive policy to 2 years
    try {
        Set-Mailbox -Identity $newUserEmail -ArchiveRetentionPolicy "Default MRM Policy"  # Replace with your custom policy if necessary
        Write-Host "Archive policy set to 2 years for $newUserEmail."
    } catch {
        Write-Host "Error setting archive policy for $newUserEmail : $_"
    }
}

# Disconnect from services
try {
    Disconnect-ExchangeOnline -Confirm:$false
    Write-Host "Disconnected from Exchange Online."
} catch {
    Write-Host "Error disconnecting from Exchange Online: $_"
}

# Stop transcript
Stop-Transcript
