# Install and import PnP PowerShell if not already installed
Install-Module -Name PnP.PowerShell -Force -AllowClobber

# Connect to SharePoint Online Admin Center
Connect-PnPOnline -Url "https://yourtenant-admin.sharepoint.com" -UseWebLogin

# Define the site URL and list name
$siteUrl = "https://yourtenant-my.sharepoint.com/personal/username_domain_com"
$listName = "Documents"

# Define the file type you want to search for
$fileType = ".docx"

# Define batch size and initial query parameters
$batchSize = 500
$position = $null

# Connect to the OneDrive site
Connect-PnPOnline -Url $siteUrl -UseWebLogin

do {
    # Retrieve items in batches using a CAML query
    $camlQuery = @"
    <Query>
        <Where>
            <Eq>
                <FieldRef Name='FileLeafRef'/>
                <Value Type='Text'>$fileType</Value>
            </Eq>
        </Where>
    </Query>
    <View>
        <RowLimit>$batchSize</RowLimit>
        <QueryOptions>
            <Paging ListItemCollectionPositionNext='$position'/>
        </QueryOptions>
    </View>
"@

    $items = Get-PnPListItem -List $listName -Query $camlQuery

    foreach ($item in $items) {
        Write-Output "File: $($item.FieldValues['FileLeafRef']) found in site: $siteUrl"
    }

    # Update the position for the next batch
    $position = $items.ListItemCollectionPositionNext
} while ($position -ne $null)

# Disconnect from the site
Disconnect-PnPOnline
