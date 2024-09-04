# SharePoint PowerShell Scripts

This repository contains a collection of PowerShell scripts designed to manage and automate various SharePoint tasks. The scripts cover a range of functionalities, including site collection management, term store updates, custom script handling, and OneDrive file operations.

## Scripts and Their Purpose

- **`AppOnlyPermission.ps1`**: Configures app-only permissions for accessing SharePoint Online. This script is useful for setting up applications that require elevated permissions.

- **`Copy-ListStructure.ps1`**: Copies the structure of a SharePoint list from one site to another. This script helps in replicating list configurations without transferring data.

- **`Create-SiteCollectionAppCatalog.ps1`**: Creates a new site collection specifically for an App Catalog in SharePoint. Useful for organizing and managing SharePoint apps.

- **`CreateAndUpdateTermStore.ps1`**: Creates and updates term stores in SharePoint. This script is essential for managing term sets used in metadata and taxonomy.

- **`Enable-Disable-CustomScript.ps1`**: Enables or disables custom scripts on a SharePoint site. Custom scripts are often used to enhance site functionality but can be restricted for security reasons.

- **`Get-OneDriveFilesBasedOnMultipleFileType.ps1`**: Retrieves files from OneDrive based on multiple file types. This script is useful for filtering files in OneDrive based on specific extensions.

- **`Get-OneDriveFilesBasedOnSingleFileType.ps1`**: Retrieves files from OneDrive based on a single file type. This script helps in searching for files of a specific type within OneDrive.