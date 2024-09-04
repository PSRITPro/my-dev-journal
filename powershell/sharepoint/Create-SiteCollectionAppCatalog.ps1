Connect-PnPOnline -Url "https://sptrains-admin.sharepoint.com" -UseWebLogin
Set-PnPTenantSite -Url "https://sptrains.sharepoint.com/sites/TestSite" -DenyAddAndCustomizePages:$True

Get-PnPTenantSite -Url "https://sptrains.sharepoint.com/sites/TestSite" | Select-Object DenyAddAndCustomizePages

Disconnect-PnPOnline
Connect-PnPOnline -Url "https://sptrains.sharepoint.com/sites/CommunicationSite2" -UseWebLogin
Add-PnPSiteCollectionAppCatalog -Site "https://sptrains.sharepoint.com/sites/CommunicationSite2"

Remove-PnPSiteCollectionAppCatalog -Site "https://sptrains.sharepoint.com/sites/TestSite"