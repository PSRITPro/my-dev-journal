# Install and import PnP PowerShell if not already installed
Install-Module -Name PnP.PowerShell -Force -AllowClobber

# Load parameters from JSON file
$jsonFilePath = "parameters.json"
$jsonContent = Get-Content -Path $jsonFilePath | ConvertFrom-Json

# Define SharePoint Online URLs from JSON
$adminUrl = $jsonContent.AdminSiteUrl
$oneDriveSiteUrl = $jsonContent.OneDriveSiteUrl  # Added OneDrive site URL

# Define the list name and file types
$listName = "Documents"
$fileTypes = @(".docx", ".xlsx", ".pptx")
$batchSize = 500

# Connect to SharePoint Online Admin Center
Connect-PnPOnline -Url $adminUrl -UseWebLogin

# Connect to the OneDrive site
Connect-PnPOnline -Url $oneDriveSiteUrl -UseWebLogin  # Use OneDrive site URL here

# Create a CAML query string with multiple file type conditions
$fileTypeConditions = $fileTypes | ForEach-Object { "<Value Type='Text'>$_</Value>" } -join "`n"
$query = @"
<View>
  <Query>
    <Where>
      <In>
        <FieldRef Name='File_x0020_Type' />
        <Values>
          $fileTypeConditions
        </Values>
      </In>
    </Where>
    <OrderBy>
      <FieldRef Name='FileLeafRef' />
    </OrderBy>
  </Query>
  <RowLimit>$batchSize</RowLimit>
</View>
"@

# Execute the query and retrieve items in batches
$position = $null
do {
    # Retrieve items using the CAML query
    $items = Get-PnPListItem -List $listName -Query $query -PageSize $batchSize -ListItemCollectionPosition $position

    foreach ($item in $items) {
        Write-Output "File: $($item.FieldValues['FileLeafRef']) found in site: $oneDriveSiteUrl"
    }

    # Update the position for the next batch
    $position = $items.ListItemCollectionPosition
} while ($null -ne $position)

# Disconnect from the site
Disconnect-PnPOnline