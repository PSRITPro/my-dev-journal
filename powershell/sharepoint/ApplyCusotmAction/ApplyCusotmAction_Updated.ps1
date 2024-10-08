﻿<#
.SYNOPSIS
This PowerShell script automates the process of managing SharePoint site collections by adding owners, creating custom actions, and configuring lists in newly created site collections. The script generates a report summarizing the operations performed, including the status of custom actions and list configurations.

.DESCRIPTION
The script performs the following tasks:
1. Loads configuration settings from a JSON file, including tenant URLs, SMTP settings, and list names.
2. Connects to the SharePoint tenant and retrieves all site collections.
3. Compares the current list of site collections to a previous report to identify newly created sites.
4. For each new site:
   - Sets the site collection administrator.
   - Checks for the existence of a custom action and creates one if it does not exist.
   - Creates and configures a specified list with fields and permissions.
5. Collects the results of these operations into a daily report.
6. Sends an email with the report in HTML format to the specified recipients.

.PARAMETER SPSScriptRoot
The root directory for the script, where logs and configuration files are located.

.PARAMETER ConfigFile
The path to the configuration JSON file.

.PARAMETER CsvReportFile
The file path for the CSV report of daily actions performed.

.PARAMETER TransScriptFile
The file path for the PowerShell transcript log.

#>

Set-Location $PSScriptRoot
$TransScriptFile = ".\Logs\TransScript $(Get-Date -f yyyyMMdd-HHmmss).log"
$CsvReportFile = ".\Reports\CA_dailyreport_PROD_$(Get-Date -f yyyyMMdd-HHmmss).csv"
Start-Transcript $TransScriptFile

# Load configuration from JSON file
$ConfigFile = ".\Config.json"
$Config = Get-Content -Path $ConfigFile | ConvertFrom-Json

# Configuration Variables
$TenantAdminURL = $Config.tenantAdminUrl
$CustomActionTitle = $Config.customActionTitle
$SiteCollectionAdmin = $Config.siteCollectionAdmin
$ClientId = $Config.ClientId
$TeamSitesManagedPath = $Config.teamSitesManagedPath
$YourListName = $Config.listName  # Assuming this is in your config

# Email Parameters
$MailTo = $Config.smtpToTest
$MailFrom = $Config.smtpFrom
$MailServer = $Config.smtpServer
$MailSubject = $Config.smtpSubject

# Credential Management
$Cred = Import-Clixml -Path '.\creds.xml'

# Store all reports
$Global:DailyReport = @()

# Function to connect to a site
function Connect-ToSite {
    param ([string]$SiteURL)
    Connect-PnPOnline -Url $SiteURL -Credentials $Cred -ClientId $ClientId -ErrorAction Stop
}

# Function to check if custom action exists
function Check_CustomAction {
    param ([string]$SiteURL)

    Write-Host "Checking custom action for $SiteURL"
    Connect-ToSite -SiteURL $SiteURL

    $Web = Get-PnPSite
    $Ctx = Get-PnPContext
    $Ctx.Load($Web.UserCustomActions)
    $Ctx.ExecuteQuery()

    return $Web.UserCustomActions | Where-Object { $_.Title -eq $CustomActionTitle } -ne $null
}

# Function to create custom action
function Create_CustomAction {
    param ([string]$SiteURL)

    Write-Host "Creating custom action for $SiteURL"
    Connect-ToSite -SiteURL $SiteURL

    $Web = Get-PnPSite
    $UserCustomAction = $Web.UserCustomActions.Add()
    $UserCustomAction.Title = $CustomActionTitle
    $UserCustomAction.Location = "ScriptLink"
    $UserCustomAction.ScriptSrc = $ScriptSrc
    $UserCustomAction.Sequence = 1000
    $UserCustomAction.Update()

    $Ctx = Get-PnPContext
    $Ctx.ExecuteQuery()
}

# Function to create and configure the list
function Create_Configure_List {
    param (
        [string]$ListName,
        [string]$AdminUser
    )

    # Check if the list exists
    $listExists = Get-PnPList -Identity $ListName -ErrorAction SilentlyContinue

    if (-not $listExists) {
        Write-Host "List '$ListName' does not exist. Creating the list..." -ForegroundColor Yellow
        New-PnPList -Title $ListName -Template GenericList
        Write-Host "List '$ListName' created successfully." -ForegroundColor Green

        # Add fields to the list
        Add-PnPField -List $ListName -InternalName "WorkDescription" -DisplayName "Work Description" -Type Note -Required -AddToDefaultView
        Add-PnPField -List $ListName -InternalName "RequestNumber" -DisplayName "Request Number" -Type Text -Required -AddToDefaultView

        # Create and add a date field
        $DefaultDate = (Get-Date).ToString("MM/dd/yyyy")
        $DateFieldXml = @"
<Field Type='DateTime' Name='Date' StaticName='Date' DisplayName='Date' Format='DateOnly' Required='TRUE'>
    <Default>$DefaultDate</Default>
</Field>
"@
        Add-PnPFieldFromXml -List $ListName -FieldXml $DateFieldXml

        # Set permissions
        $SiteOwnersGroup = Get-PnPSiteGroup | Where-Object { $_.Title -like "*Full Control*" } | Select-Object -ExpandProperty Title
        Set-PnPList -Identity $ListName -BreakRoleInheritance
        Set-PnPListPermission -Identity $ListName -Group $SiteOwnersGroup -AddRole "Read"
        Set-PnPListPermission -Identity $ListName -User $AdminUser -AddRole "Full Control"

        Write-Host "Configuration for list '$ListName' completed successfully." -ForegroundColor Green
        $Global:DailyReport += [PSCustomObject]@{
            SiteURL = $ListName
            CustomActionStatus = "N/A"
            ListStatus = "List configured successfully."
        }
    } else {
        Write-Host "List '$ListName' already exists." -ForegroundColor Green
        $Global:DailyReport += [PSCustomObject]@{
            SiteURL = $ListName
            CustomActionStatus = "N/A"
            ListStatus = "List with name '$ListName' already exists."
        }
    }
}

# Entry point
Try {
    $TodayDate = (Get-Date).ToString("yyyyMMdd")
    $LastFile = (Get-ChildItem ".\CompareSites report" | Sort-Object LastWriteTime -Descending | Select-Object -First 1).Name
    $OldSitesReport = Import-Csv -Path ".\CompareSites report\$LastFile" | Select-Object -ExpandProperty "Url"

    Connect-PnPOnline -Url $TenantAdminURL -Credentials $Cred -ClientId $ClientId -ErrorAction Stop
    $AllSites = @()
    $AllSites += Get-PnPTenantSite | Select-Object Url
    Write-Host "$($AllSites.Count) -- Total sites fetched"

    #storing today result in csv
    $AllSites | Export-Csv -Path ".\CompareSites report\AllTenantSites_$TodayDate.csv" -NoTypeInformation

    # Compare reports and process new sites
    $NewSitesReport = Import-Csv -Path ".\CompareSites report\AllTenantSites_$TodayDate.csv" -NoTypeInformation
    $CompareReport = Compare-Object -ReferenceObject $OldSitesReport -DifferenceObject $NewSitesReport

    foreach ($SiteCollection in $CompareReport) {
        if ($SiteCollection.SideIndicator -eq "->") {
            $maxRetries = 3
            $retryCount = 0
            $success = $false

            while (-not $success -and $retryCount -lt $maxRetries) {
                Try {
                    Write-Host "Processing $($SiteCollection.InputObject)"

                    if ($SiteCollection.InputObject.StartsWith($TeamSitesManagedPath)) {
                        Set-PnPTenantSite -Url $SiteCollection.InputObject -Owners $SiteCollectionAdmin -ErrorAction Stop
                        Write-Host "Successfully added owners to $SiteCollectionAdmin" -ForegroundColor Green

                        # Check and create custom action
                        if (-not (Check_CustomAction -SiteURL $SiteCollection.InputObject)) {
                            Create_CustomAction -SiteURL $SiteCollection.InputObject
                            $Global:DailyReport += [PSCustomObject]@{
                                SiteURL = $SiteCollection.InputObject
                                CustomActionStatus = "Custom action created successfully."
                                ListStatus = "N/A"
                            }
                        } else {
                            Write-Host "Custom Action already exists in $($SiteCollection.InputObject)" -ForegroundColor Yellow
                            $Global:DailyReport += [PSCustomObject]@{
                                SiteURL = $SiteCollection.InputObject
                                CustomActionStatus = "Custom action already exists."
                                ListStatus = "N/A"
                            }
                        }

                        # Configure the list after creating custom action
                        Create_Configure_List -ListName $YourListName -AdminUser $SiteCollectionAdmin
                    }
                    break  # Exit the retry loop on success
                } Catch {
                    $retryCount++
                    Write-Host "Error processing $($SiteCollection.InputObject): $($_.Exception.Message)" -ForegroundColor Red
                    
                    if ($retryCount -ge $maxRetries) {
                        $Global:DailyReport += [PSCustomObject]@{
                            SiteURL = $SiteCollection.InputObject
                            CustomActionStatus = "Error after $maxRetries attempts."
                            ListStatus = "Error after $maxRetries attempts."
                        }
                    } else {
                        Write-Host "Retrying... ($retryCount of $maxRetries)"
                        Start-Sleep -Seconds 10  # Wait before retrying
                    }
                }
            }
        }
    }

} Catch {
    Write-Host "Overall error: $($_.Exception.Message)" -ForegroundColor Red
}

# Create a styled HTML email body
$BodyMail = @"
<html>
<head>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h2 { color: #4CAF50; }
        table { width: 100%; border-collapse: collapse; margin-top: 20px; }
        th, td { padding: 10px; border: 1px solid #ddd; text-align: left; }
        th { background-color: #f2f2f2; }
        .footer { margin-top: 20px; font-size: 12px; color: #999; }
    </style>
</head>
<body>
    <h2>Daily Site Collection Update</h2>
    <p>Using this task, we are adding global permissions to newly created site collections in Production using Custom Action.</p>
    <table>
        <tr>
            <th>Site URL</th>
            <th>Custom Action Status</th>
            <th>List Status</th>
        </tr>
"@

# Append daily report data to the email body
$Global:DailyReport | ForEach-Object {
    $BodyMail += "<tr><td>$($_.SiteURL)</td><td>$($_.CustomActionStatus)</td><td>$($_.ListStatus)</td></tr>"
}

$BodyMail += @"
    </table>
    <div class='footer'>
        <p>This is an automated message. Please do not reply.</p>
    </div>
</body>
</html>
"@

# Send the email with the styled body
Try {
    Send-MailMessage -From $MailFrom -To $MailTo -Subject $MailSubject -Body $BodyMail -SmtpServer $MailServer -BodyAsHtml -ErrorAction Stop
} Catch {
    Write-Host "Error while sending email: $($_.Exception.Message)" -ForegroundColor Red
}

Stop-Transcript
