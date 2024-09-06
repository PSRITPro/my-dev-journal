param(
    [Parameter(Mandatory = $true)]
    [string]$SiteUrl,

    [Parameter(Mandatory = $true)]
    [string]$ClientId,

    [Parameter(Mandatory = $true)]
    [string]$ClientSecret
)

# Output the parameters to verify they were received correctly
Write-Output "Site URL: $SiteUrl"
Write-Output "Client ID: $ClientId"
Write-Output "Client Secret: $ClientSecret"

# Install the PnP PowerShell module if not already installed
if (-not (Get-Module -ListAvailable -Name PnP.PowerShell)) {
    Install-Module -Name PnP.PowerShell -Force -AllowClobber
}

# Connect to SharePoint Online using PnP PowerShell with App-Only Authentication
try {
    Connect-PnPOnline -Url $SiteUrl -ClientId $ClientId -ClientSecret $ClientSecret -Tenant "yourtenant.onmicrosoft.com"

    Write-Output "Connected to SharePoint Online at $SiteUrl"
    
    # Example command: Get the title of the SharePoint site
    $site = Get-PnPTenantSite -Identity $SiteUrl
    Write-Output "Site Title: $($site.Title)"
}
catch {
    Write-Error "Failed to connect to SharePoint Online. Error: $_"
}
