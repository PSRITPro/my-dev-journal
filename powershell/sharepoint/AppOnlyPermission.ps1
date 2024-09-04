# Load parameters from JSON file
$jsonFilePath = "config.json"
$jsonContent = Get-Content -Path $jsonFilePath | ConvertFrom-Json

# Define SharePoint connection parameters from JSON
$siteUrl = $jsonContent.SiteUrl
$cId = $jsonContent.ClientId
$sId = $jsonContent.ClientSecret

# Connect to SharePoint Online using Client ID and Secret
Connect-PnPOnline -Url $siteUrl -ClientId $cId -ClientSecret $sId

# Retrieve and display web information
$web = Get-PnPWeb
Write-Output "Connected to SharePoint site: $($web.Url)"

# Disconnect from SharePoint Online
Disconnect-PnPOnline
