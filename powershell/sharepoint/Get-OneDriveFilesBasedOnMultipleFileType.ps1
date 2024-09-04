# Install and import PnP PowerShell if not already installed
Install-Module -Name PnP.PowerShell -Force -AllowClobber

# Connect to SharePoint Online Admin Center
Connect-PnPOnline -Url "https://yourtenant-admin.sharepoint.com" -UseWebLogin

# Define the OneDrive site URL and list name
$siteUrl = "https://yourtenant-my.sharepoint.com/personal/username_domain_com"
$listName = "Documents"

# Define the file types you want to search for
$fileTypes = @(".docx", ".xlsx", ".pptx")

# Define batch size and initial query parameters
$batchSize = 500
$position = $null

# Connect to the OneDrive site
Connect-PnPOnline -Url $siteUrl -UseWebLogin

<Query>
    <Where>
        <Or>
            <Or>
                <Eq>
                    <FieldRef Name='FileLeafRef'/>
                    <Value Type='Text'>docx</Value>
                </Eq>
                <Eq>
                    <FieldRef Name='FileLeafRef'/>
                    <Value Type='Text'>xlsx</Value>
                </Eq>
            </Or>
            <Eq>
                <FieldRef Name='FileLeafRef'/>
                <Value Type='Text'>pptx</Value>
            </Eq>
        </Or>
    </Where>
    <View>
        <RowLimit>$batchSize</RowLimit>
    </View>
</Query>

# Execute the query
$camlQuery = New-PnPQuery -Query $query
# Create the CAML query string with multiple file type conditions
do {
    # Retrieve items in batches using the CAML query
    $items = Get-PnPListItem -List $listName -Query $camlQuery

    foreach ($item in $items) {
        Write-Output "File: $($item.FieldValues['FileLeafRef']) found in site: $siteUrl"
    }
    # Update the position for the next batch
    $position = $items.ListItemCollectionPositionNext
} while($position -ne $null)

# Disconnect from the site
Disconnect-PnPOnline