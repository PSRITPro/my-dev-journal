Connect-PnPOnline -Url "https://sptrains.sharepoint.com/sites/CommunicationSite2" -UseWebLogin
#Get-PnPSiteDesign
Get-PnPSiteTemplate -Out ".\logs\template_ContentTypes.json" -Handlers ContentTypes


Get-Pnpbu -Identity 00000000-0000-0000-0000-000000000000

Set-PnPTraceLog -On -LogFile log.txt
Get-PnPSiteTemplate
Set-PnPTraceLog -Off

$cId ="2f6dde73-eb69-4089-bc4e-6ef06b828c0e"
$csId = "aab2f3f4-471b-444a-bcaf-03cfc87eaf23"
$tId = "c518f592-d3fe-405a-b17d-456bcf93a271"



$redirectUrl = "https://portal.azure.com/#blade/Microsoft_AAD_RegisteredApps/ApplicationMenuBlade/Authentication/appId/2f6dde73-eb69-4089-bc4e-6ef06b828c0e"

Connect-MgGraph -ClientId $cId -TenantId $tId -Scopes "Sites.FullControl.All"

Get-MgContext

$siteUrl = "https://sptrains.sharepoint.com/sites/CommunicationSite2"
Get-MgSite -Filter "WebUrl eq '$siteUrl'"

$siteId = "sptrains.sharepoint.com:/sites/CommunicationSite2"
Get-MgSite -SiteId $siteId


Get-MgSite -All -Debug

Get-MgSite -All | Select-Object *

$allSites = Get-MgSite -All

Get-MgSite -Property "siteCollection,webUrl"


$siteUrl = "https://sptrains.sharepoint.com/sites/CommunicationSite2"
$allSites = Get-MgSite -All
$filteredSite = $allSites | Where-Object { $_.webUrl -eq $siteUrl }


Disconnect-MgGraph

#https://portal.azure.com/#blade/Microsoft_AAD_RegisteredApps/ApplicationMenuBlade/Authentication/appId/2f6dde73-eb69-4089-bc4e-6ef06b828c0e