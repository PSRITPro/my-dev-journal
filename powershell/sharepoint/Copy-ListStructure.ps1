# Define parameters
param(
    [string]$SourceList = "SourceList",
    [string]$DestinationList = "DestinationList"
)

# Load parameters from JSON file
$jsonFilePath = "parameters.json"
$jsonContent = Get-Content -Path $jsonFilePath | ConvertFrom-Json

# Define SharePoint URLs from JSON
$sourceSiteUrl = $jsonContent.SourceSiteUrl
$destinationSiteUrl = $jsonContent.DestinationSiteUrl

# Set location path
Set-Location -Path $PSScriptRoot

# Connect to source SharePoint site
Connect-PnPOnline -Url $sourceSiteUrl -UseWebLogin

# Get the source list
$sourceList = Get-PnPList -Identity $SourceList

# Get fields and views from the source list
$sourceListFields = Get-PnPField -List $SourceList
$sourceListViews = Get-PnPView -List $SourceList

# Connect to destination SharePoint site
Connect-PnPOnline -Url $destinationSiteUrl -UseWebLogin

# Check if the list exists
$list = Get-PnPList -Identity $DestinationList -ErrorAction SilentlyContinue

if (-not $list) {
    # Create the list if it doesn't exist
    New-PnPList -Title $DestinationList -Template GenericList
}

# Add fields to the destination list
foreach ($field in $sourceListFields) {
    switch ($field.TypeDisplayName) {
        "Text" {
            Add-PnPField -List $DestinationList -DisplayName $field.Title -InternalName $field.InternalName -Type Text
        }
        "Multiple lines of text" {
            Add-PnPField -List $DestinationList -DisplayName $field.Title -InternalName $field.InternalName -Type Note `
                -RichText $field.RichText -AllowHyperlink $field.AllowHyperlink -AppendOnly $field.AppendOnly
        }
        "Choice" {
            $choices = $field.Choices -split ';'  # Choices are usually provided as a CSV string
            Add-PnPField -List $DestinationList -DisplayName $field.Title -InternalName $field.InternalName -Type Choice -Choices $choices
        }
        "Number" {
            Add-PnPField -List $DestinationList -DisplayName $field.Title -InternalName $field.InternalName -Type Number -MinValue $field.MinValue -MaxValue $field.MaxValue
        }
        "Currency" {
            Add-PnPField -List $DestinationList -DisplayName $field.Title -InternalName $field.InternalName -Type Currency -CurrencyLocale $field.CurrencyLocale -DecimalPlaces $field.DecimalPlaces
        }
        "Date and Time" {
            Add-PnPField -List $DestinationList -DisplayName $field.Title -InternalName $field.InternalName -Type DateTime -DisplayFormat $field.DisplayFormat
        }
        "Lookup" {
            Add-PnPField -List $DestinationList -DisplayName $field.Title -InternalName $field.InternalName -Type Lookup -LookupList $field.LookupList -LookupField $field.LookupField
        }
        "Boolean" {
            Add-PnPField -List $DestinationList -DisplayName $field.Title -InternalName $field.InternalName -Type Boolean
        }
        "User" {
            Add-PnPField -List $DestinationList -DisplayName $field.Title -InternalName $field.InternalName -Type User
        }
        "URL" {
            Add-PnPField -List $DestinationList -DisplayName $field.Title -InternalName $field.InternalName -Type Url -Format $field.Format
        }
        # Add additional cases for other field types
    }
}

# Create views in the destination list
foreach ($view in $sourceListViews) {
    # Define parameters for the new view
    $viewTitle = $view.Title
    $viewFields = $view.ViewFields -split ','  # Convert fields from CSV to an array
    $viewQuery = $view.ViewQuery
    $viewType = $view.ViewType

    # Check if view already exists to avoid duplicates
    $existingView = Get-PnPView -List $DestinationList -Identity $viewTitle -ErrorAction SilentlyContinue
    if (-not $existingView) {
        # Create the view in the destination list
        Add-PnPView -List $DestinationList -Title $viewTitle -Fields $viewFields -Query $viewQuery -ViewType $viewType
        Write-Output "View '$viewTitle' created in destination list."
    } else {
        Write-Output "View '$viewTitle' already exists in the destination list."
        # If you want to update the existing view, you would typically have to delete and recreate it
        # or handle the update logic if possible (not directly supported by `Set-PnPView`)
    }
}

# Disconnect from SharePoint Online
Disconnect-PnPOnline
