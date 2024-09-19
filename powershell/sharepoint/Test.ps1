# Connect to SharePoint Online
Connect-PnPOnline -Url "https://yourtenant.sharepoint.com/sites/yoursite" -UseWebLogin

# Define the path to your CSV file
$csvFilePath = "C:\path\to\your\data.csv"

# Define the name of the lookup list
$lookupListName = "Lookup List Name"

# Import data from the CSV file
$csvData = Import-Csv -Path $csvFilePath

# Function to get the ID of a lookup item by title
function Get-LookupIdByTitle {
    param (
        [string]$title
    )
    $lookupItem = Get-PnPListItem -List $lookupListName -Query "<View><Query><Where><Eq><FieldRef Name='Title'/><Value Type='Text'>$title</Value></Eq></Where></Query></View>"
    return $lookupItem.Id
}

# Loop through each row in the CSV file
foreach ($row in $csvData) {
    # Prepare the values for each field
    $hyperlinkValue = $row.HyperlinkField -split ','  # Split URL and Description
    $multiChoiceValues = $row.MultiChoiceField -split ';'  # Split multiple choices
    $singleChoiceValue = $row.SingleChoiceField  # Single choice value
    $lookupId = Get-LookupIdByTitle -title $row.LookupField  # Get the ID of the lookup item

    # Add the item to the SharePoint list
    Add-PnPListItem -List "Your List Name" -Values @{
        "Title" = $row.Title
        "HyperlinkField" = @{
            "Url" = $hyperlinkValue[0]
            "Description" = $hyperlinkValue[1]
        }
        "MultiChoiceField" = $multiChoiceValues
        "SingleChoiceField" = $singleChoiceValue
        "LookupField" = $lookupId  # Set the lookup field to the ID
    }
}
