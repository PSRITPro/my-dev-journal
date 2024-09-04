$siteUrl = "https://abc.sharepoint.com/sites/CommunicationSite2"
$cId = "2f6dde73-eb69-4089-bc4e-6ef06b828c0e"
$sId = "FGs8Q~cb2fw3OTXc~D8N6SToQB53MIqqlkgaabtg"

Connect-PnPOnline -Url $siteUrl -ClientId $cId -ClientSecret $sId

Get-PnPWeb
                    
