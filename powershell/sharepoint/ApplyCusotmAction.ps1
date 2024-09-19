Set-Location SPSScriptRoot
$TransScriptFile = ".\Logs\TransScript $(Get-Date -f yyyyMMdd-HHmmss).log"
$CsvReportFile = ".\Reports\CA_dailyreport_PROD_$(Get-Date -f yyyyMMdd-HHmmss).csv"
Start-Transcript $TransScriptFile

# Define the path of the configuration file
$ConfigFile = ".\Config.json"

# Load configuration from JSON file
$Config = Get-Content -Path $ConfigFile | ConvertFrom-Json

# Configuration Variables
$TenantAdminURL = $Config.tenantAdminUrl
$CustomActionTitle = $Config.customActionTitle
$SiteCollectionAdmin = $Config.siteCollectionAdmin
$ClientId = $Config.ClientId
$TeamSitesManagedPath = $Config.teamSitesManagedPath

# Email Parameters
$MailTo = $Config.smtpToTest
$MailFrom = $Config.smtpFrom
$MailServer = $Config.smtpServer
$MailSubject = $Config.smtpSubject

# Credential Management
$Cred = Import-Clixml -Path '.\creds.xml'

# Store all reports
$Global:DailyReport = @()

# Function to check if custom action exists
function Check_CustomAction {
    param (
        [string]$SiteURL,
        [PSCredential]$Cred,
        [string]$ClientId
    )

    Write-Host "-------------****************"
    $IsAvailable = $false
    Write-Host "Working for $SiteURL"

    # Connecting to the site collection
    Connect-PnPOnline -Url $SiteURL -Credentials $Cred -ClientId $ClientId
    Write-Host "Connection successful to $SiteURL"

    $Web = Get-PnPSite
    $Ctx = Get-PnPContext
    $Ctx.Load($Web.UserCustomActions)
    $Ctx.ExecuteQuery()

    # Check if the Custom Action Exists already
    $CustomAction = $Web.UserCustomActions | Where-Object { $_.Title -eq $CustomActionTitle }

    if ($CustomAction -eq $null) {
        Write-Host "Custom Action not available in $SiteURL"
    } else {
        $IsAvailable = $true
        Write-Host -ForegroundColor Yellow "Custom Action already exists in $($Web.Url)"

        # Prepare applied sites report
        $AppliedSites = New-Object PSObject
        $AppliedSites | Add-Member -Type NoteProperty -Name "SiteURL" -Value $SiteURL
        $AppliedSites | Add-Member -Type NoteProperty -Name "Status" -Value "Already Exists"

        $Global:DailyReport += $AppliedSites
    }

    return $IsAvailable
}

function Create_CustomAction_PropertyBag {
    param (
        [string]$SiteURL,
        [PSCredential]$Cred,
        [string]$ClientId
    )

    Write-Host "#########################################"
    Write-Host "Adding custom action" -ForegroundColor Green
    Write-Host "Working for $SiteURL"

    # Connecting to the site collection
    Connect-PnPOnline -Url $SiteURL -Credentials $Cred -ClientId $ClientId
    Write-Host "Connection successful to $SiteURL"

    $Web = Get-PnPSite
    $Ctx = Get-PnPContext
    $Ctx.Load($Web.UserCustomActions)
    $Ctx.ExecuteQuery()

    # Add custom action
    $UserCustomAction = $Web.UserCustomActions.Add()
    $UserCustomAction.Title = $CustomActionTitle
    $UserCustomAction.Location = "ScriptLink"
    $UserCustomAction.ScriptSrc = $ScriptSrc
    $UserCustomAction.Sequence = 1000
    $UserCustomAction.Update()
    $Ctx.ExecuteQuery()

    Write-Host -ForegroundColor Green "Custom Action added successfully for $($Web.Url)"
    Write-Host "#########################################"
    
    Write-Host "Setting PropertyBag value" -ForegroundColor Green
    Set-PnPPropertyBagValue -Key "CustomAction" -Value "Added" -Indexed
    Write-Host "PropertyBag value added" -ForegroundColor Green
    Write-Host "#########################################"

    # Prepare newly applied sites report
    $NewlyAppliedSites = New-Object PSObject
    $NewlyAppliedSites | Add-Member -Type NoteProperty -Name "SiteUrl" -Value $SiteURL
    $NewlyAppliedSites | Add-Member -Type NoteProperty -Name "Status" -Value "Applied Successfully"

    $Global:DailyReport += $NewlyAppliedSites
}
# Function to enable custom script for the site
function Enable_CustomScript_SC {
    param (
        [string]$SiteURL,
        [PSCredential]$Cred,
        [string]$ClientId
    )

    Write-Host "#########################################"
    Write-Host "Enabling custom script" -ForegroundColor Green

    Set-PnPTenantSite -Identity $SiteURL -DenyAddAndCustomizePages $false
    Write-Host "Custom script enabled" -ForegroundColor Green
    Write-Host "#########################################"
}

# Function to disable custom script for the site once applied
function Disable_CustomScript_SC {
    param (
        [string]$SiteURL,
        [PSCredential]$Cred,
        [string]$ClientId
    )

    Write-Host "#########################################"
    Write-Host "Disabling custom script" -ForegroundColor Green

    Set-PnPTenantSite -Identity $SiteURL -DenyAddAndCustomizePages $true
    Write-Host "Custom script disabled" -ForegroundColor Green
    Write-Host "#########################################"
}
# Entry point
Try {
    # Get and store today's date as short date format
    $TodayDate = (Get-Date).ToShortDateString().Replace('/', '')
    $LastFile = (Get-ChildItem ".\CompareSites report" | Sort-Object -Descending Property LastWriteTime | Select-Object -First 1).Name

    # Get the previous day report for comparison
    $OldSitesReport = Import-Csv -Path ".\CompareSites report\$LastFile" | Select-Object -ExpandProperty "Uri"

    # Connect to tenant and store the connection string
    $Global:ReturnConn = Connect-PnPOnline -Url $TenantAdminURL -Credentials $Cred -ClientId $ClientId -ErrorAction Stop

    # Store all URLs inside array
    Write-Host "Fetching all sites from Tenant" -ForegroundColor Yellow
    $AllSites = Get-PnPTenantSite | Select-Object Url # Performance fix
    Write-Host "$($AllSites.Count) -- Total sites fetched" -ForegroundColor Yellow
    Write-Host "#########***********#####################"

    # Storing today's result in a new CSV
    $AllSites | Export-Csv -Path ".\CompareSites report\AllTenantSites_$TodayDate.csv" -NoTypeInformation

    # Fetching today's CSV and URL column for comparison
    $NewSitesReport = Import-Csv -Path ".\CompareSites report\AllTenantSites_$TodayDate.csv" | Select-Object -ExpandProperty "Url"

    # Getting the difference between two CSVs and find out URLs newly created
    $CompareReport = Compare-Object -ReferenceObject $OldSitesReport -DifferenceObject $NewSitesReport

    if ($CompareReport.Count -gt 0) {
        Write-Host "$($CompareReport.Count) new site collections found!"

        foreach ($SiteCollection in $CompareReport) {
            # Below if loop is to avoid error for sites which are deleted from tenant and show up in the compare report
            if ($SiteCollection.SideIndicator -eq "->") {
                Write-Host
                Write-Host "Processing $($SiteCollection.InputObject)"
                Try {
                    if ($SiteCollection.InputObject.StartsWith($TeamSitesManagedPath)) {
                        Write-Host "Adding group to $($SiteCollection.InputObject)"
                        Set-PnPTenantSite -Url $SiteCollection.InputObject -Owners $SiteCollectionAdmin
                        Write-Host "Successfully added to $SiteCollectionAdmin" -ForegroundColor Green
                        Start-Sleep -Seconds 10

                        Connect-PnPOnline -Url $SiteCollection.InputObject -Credentials $Cred -ClientId $ClientId -ErrorAction Stop
                        $Admins = Get-PnPSiteCollectionAdmin -ErrorAction Stop
                    }
                } Catch {
                    Write-Host "Error for: $($_.Exception.Message)" -ForegroundColor Red
                    Try {
                        Write-Host "Adding group to $($SiteCollection.InputObject)"
                        Set-PnPTenantSite -Url $SiteCollection.InputObject -Owners $SiteCollectionAdmin -ErrorAction Stop
                        Write-Host "Successfully added to $SiteCollectionAdmin" -ForegroundColor Green
                        Start-Sleep -Seconds 10
                    } Catch {
                        Write-Host "Error adding to $($SiteCollection.InputObject): $($_.Exception.Message)" -ForegroundColor Red
                    }
                }

                Try {
                    # Calling the function to check if custom action is present
                    $IsAvailable = Check-CustomAction -SiteURL $SiteCollection.InputObject -Cred $Cred -ClientId $ClientId
                    
                    if ($IsAvailable) {
                        # Custom action exists
                    } else {
                        Enable+_CustomScript_SC -SiteURL $SiteCollection.InputObject -Cred $Cred -ClientId $ClientId
                        Create_CustomAction_PropertyBag -SiteURL $SiteCollection.InputObject -Cred $Cred -ClientId $ClientId
                        Disable_CustomScript_SC -SiteURL $SiteCollection.InputObject -Cred $Cred -ClientId $ClientId
                    }
                } Catch {
                    Write-Host "Error for: $($SiteCollection.InputObject) - $($_.Exception.Message)" -ForegroundColor Red
                    $ErrorOccurredSites = New-Object PSObject
                    $ErrorOccurredSites | Add-Member -Type NoteProperty -Name "SiteURL" -Value $SiteCollection.InputObject
                    $ErrorOccurredSites | Add-Member -Type NoteProperty -Name "Status" -Value "Error occurred"
                    $Global:DailyReport += $ErrorOccurredSites
                }
            }
        }
    } else {
        Write-Host "No new site collections found!"
        $NoNewSites = New-Object PSObject
        $NoNewSites | Add-Member -Type NoteProperty -Name "SiteURL" -Value "No new site collections found!"
        $NoNewSites | Add-Member -Type NoteProperty -Name "Status" -Value "No new sites"
        $Global:DailyReport += $NoNewSites
    }
} Catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
}
# Export daily report to CSV
$Global:DailyReport | Export-Csv -Path $csvReportFile -NoTypeInformation

# Convert daily report to HTML fragment
$BodyMailHtml = $Global:DailyReport | ConvertTo-Html -Fragment

# Prepare the email message
$BodyMail = @"
Using this task, we are adding global permissions to newly created site collections in Production using Custom Action.
"@

Try {
    Send-MailMessage -From $MailFrom -To $MailTo -Subject $MailSubject -Body ($BodyMail + $BodyMailHtml | Out-String) -SmtpServer $MailServer -BodyAsHtml -ErrorAction Stop
} Catch {
    Write-Host "Error while sending email:" -ForegroundColor Red "$($_.Exception.Message)"
}

Stop-Transcript

