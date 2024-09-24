# Connect to SharePoint
Connect-PnPOnline -Url "https://yourtenant.sharepoint.com/sites/yoursite" -UseWebLogin

# Get all HTML files from the Site Pages library
$htmlFiles = Get-PnPListItem -List "Site Pages" -Query "<View><Query><Where><Eq><FieldRef Name='File_x0020_Type'/><Value Type='Text'>html</Value></Eq></Where></Query></View>"

foreach ($file in $htmlFiles) {
    # Retrieve the file name and its content
    $fileName = $file.FieldValues["FileLeafRef"]
    $fileUrl = $file.FieldValues["FileRef"]
    
    # Download the HTML content
    $htmlContent = Get-PnPFile -Url $fileUrl -AsFile -Path "C:\temp" -FileName $fileName

    # Define the new ASPX page name
    $newPageName = [System.IO.Path]::ChangeExtension($fileName, "aspx")

    # Create a new ASPX page
    Add-PnPPage -Name $newPageName -LayoutType Article

    # Add HTML content to the new ASPX page
    Add-PnPPageTextPart -Page $newPageName -Text $htmlContent -Order 1

    # Publish the ASPX page
    Publish-PnPPage -Identity $newPageName

    Write-Host "Converted $fileName to $newPageName"
}

# Disconnect
Disconnect-PnPOnline
