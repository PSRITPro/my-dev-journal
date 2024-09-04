# Set location path
Set-Location -Path $PSScriptRoot
# Load the JSON file
$jsonFilePath = "parameters.json"
$jsonContent = Get-Content -Path $jsonFilePath | ConvertFrom-Json

# Connect to the SharePoint Online Admin site
Connect-PnPOnline -Url $jsonContent.AdminSiteUrl -UseWebLogin

# Connect to the site where we will add the app catalog
Connect-PnPOnline -Url $jsonContent.SiteUrl -UseWebLogin

# Add the site collection app catalog to the specified site
Add-PnPSiteCollectionAppCatalog -Site $jsonContent.SiteUrl
Write-Output "Added site collection app catalog to: $($jsonContent.SiteUrl)"

# Remove the site collection app catalog from the specified site
Remove-PnPSiteCollectionAppCatalog -Site $jsonContent.SiteUrl
Write-Output "Removed site collection app catalog from: $($jsonContent.SiteUrl)"

# Disconnect from SharePoint Online
Disconnect-PnPOnline
