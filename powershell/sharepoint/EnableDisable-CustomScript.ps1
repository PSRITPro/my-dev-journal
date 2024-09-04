# Set location path
Set-Location -Path $PSScriptRoot

# Define script file name and timestamp for transcript
$scriptFileName = [System.IO.Path]::GetFileNameWithoutExtension($MyInvocation.MyCommand.Path)
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$transcriptFile = ".\logs\$($scriptFileName)_Transcript_$($timestamp).txt"

# Start transcription
Start-Transcript -Path $transcriptFile

# Load parameters from JSON file
$jsonFilePath = "parameters.json"
$jsonContent = Get-Content -Path $jsonFilePath | ConvertFrom-Json

# Define SharePoint Online URLs from parameters
$spoAdminUrl = $jsonContent.AdminSiteUrl
$spoSiteColUrl = $jsonContent.DestinationSiteUrl

Try {
    # Connect to SharePoint Online using PnP PowerShell
    Connect-PnPOnline -Url $spoAdminUrl -UseWebLogin -ErrorAction Stop

    Try {
        # Get SharePoint Online tenant site details
        $denyAddAndCustomizePages = Get-PnPTenantSite -Url $spoSiteColUrl | Select -ExpandProperty DenyAddAndCustomizePages -ErrorAction Stop

        If ($denyAddAndCustomizePages -eq "Disabled") {
            Write-Host "Custom script is enabled for this site - $spoSiteColUrl" -ForegroundColor Yellow
            $disableResponse = Read-Host "Do you want to disable it? (Y/N)"
            If ($disableResponse -eq "Y") {
                Try {
                    Set-PnPTenantSite -Url $spoSiteColUrl -DenyAddAndCustomizePages:$true -ErrorAction Stop
                    Write-Host "Custom script has been disabled for the site - $spoSiteColUrl" -ForegroundColor Green
                }
                Catch {
                    Write-Host "Error while disabling the custom script for the SPO site - $spoSiteColUrl - " $_ -ForegroundColor Red
                }
            }
        }
        Else {
            Write-Host "Custom script is disabled for this site - $spoSiteColUrl" -ForegroundColor Yellow
            $enableResponse = Read-Host "Do you want to enable it? (Y/N)"
            If ($enableResponse -eq "Y") {
                Try {
                    Set-PnPTenantSite -Url $spoSiteColUrl -DenyAddAndCustomizePages:$false -ErrorAction Stop
                    Write-Host "Custom script has been enabled for the site - $spoSiteColUrl" -ForegroundColor Green
                }
                Catch {
                    Write-Host "Error while enabling the custom script for the SPO site - $spoSiteColUrl - " $_ -ForegroundColor Red
                }
            }
        }
    }
    Catch {
        Write-Host "Error while getting the SPO tenant site - $spoSiteColUrl - " $_ -ForegroundColor Red
    }
}
Catch {
    Write-Host "Error while connecting to the SPO tenant admin - $spoAdminUrl - " $_ -ForegroundColor Red
}
# Stop transcription
Stop-Transcript
