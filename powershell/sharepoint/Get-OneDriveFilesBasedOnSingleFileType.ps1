# Set location path
Set-Location -Path $PSScriptRoot

# Load parameters from JSON file
$jsonFilePath = "parameters.json"
$jsonContent = Get-Content -Path $jsonFilePath | ConvertFrom-Json

# Define SharePoint Online URLs from JSON
$adminUrl = $jsonContent.AdminSiteUrl
$oneDriveUrl = $jsonContent.OneDriveSiteUrl

# Define the list name and file type
$listName = "Documents"
$fileType = ".docx"
$batchSize = 500

# Connect to SharePoint Online Admin Center
Connect-PnPOnline -Url $adminUrl -UseWebLogin

# Connect to the OneDrive site
Connect-PnPOnline -Url $oneDriveUrl -UseWebLogin

# Initialize position for batch retrieval
$position = $null

do {
    # Define CAML query to search for specific file type
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

    # Retrieve items in batches using CAML query
    $items = Get-PnPListItem -List $listName -Query $camlQuery

    foreach ($item in $items) {
        Write-Output "File: $($item.FieldValues['FileLeafRef']) found in site: $oneDriveUrl"
    }

    # Update position for the next batch
    $position = $items.ListItemCollectionPositionNext
} while ($null -ne $position)

# Disconnect from the site
Disconnect-PnPOnline
