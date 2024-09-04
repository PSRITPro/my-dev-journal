# Define parameters
param(
    [string]$TermStoreName = "Managed Metadata Service",
    [string]$TermGroupName = "TermGroup",
    [string]$TermSetName = "TermSet",
    [string]$TermName = "TermName",
    [string]$NewTermName = "UpdatedTermName"
)

# Load parameters from JSON file
$jsonFilePath = "parameters.json"
$jsonContent = Get-Content -Path $jsonFilePath | ConvertFrom-Json

# Define SharePoint URLs from JSON
$siteUrl = $jsonContent.SiteUrl

# Get credentials from Azure Automation variables
$ClientId = Get-AutomationVariable -Name 'ClientId'
$ClientSecret = Get-AutomationVariable -Name 'ClientSecret'
$TenantId = Get-AutomationVariable -Name 'TenantId'

# Install the PnP PowerShell module if not already installed
if (-not (Get-Module -ListAvailable -Name "PnP.PowerShell")) {
    Install-Module -Name "PnP.PowerShell" -Force -AllowClobber
}

# Connect to SharePoint Online using Client ID and Secret
Connect-PnPOnline -Url $siteUrl -ClientId $ClientId -ClientSecret $ClientSecret -Tenant $TenantId

# Load the Term Store Management Shell
$termStore = Get-PnPTermStore -Identity $TermStoreName

# Retrieve the Term Group
$termGroup = $termStore.Groups | Where-Object { $_.Name -eq $TermGroupName }

# Retrieve the Term Set
$termSet = $termGroup.TermSets | Where-Object { $_.Name -eq $TermSetName }

# Check if the term already exists
$existingTerm = $termSet.Terms | Where-Object { $_.Name -eq $TermName }

if ($existingTerm) {
    # Update the existing term name
    Set-PnPTerm -Identity $existingTerm.Id -Name $NewTermName
    Write-Output "Term updated successfully."
} else {
    # Create a new term in the Term Set
    New-PnPTerm -TermSet $termSet -Name $NewTermName
    Write-Output "New term created successfully."
}

# Disconnect from SharePoint Online
Disconnect-PnPOnline
