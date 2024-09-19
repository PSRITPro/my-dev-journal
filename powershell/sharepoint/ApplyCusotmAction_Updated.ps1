Set-Location SPSScriptRoot
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
    param (
        [string]$SiteURL
    )
    Connect-PnPOnline -Url $SiteURL -Credentials $Cred -ClientId $ClientId -ErrorAction Stop
}

# Function to check if custom action exists
function Check_CustomAction {
    param (
        [string]$SiteURL
    )

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
    param (
        [string]$SiteURL
    )

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

# Function to add fields and set permissions for the list
# Function to add fields and set permissions for the list
function Configure-List {
    param (
        [string]$ListName,
        [string]$AdminUser
    )

    # Check if the list exists
    $listExists = Get-PnPList -Identity $ListName -ErrorAction SilentlyContinue

    if (-not $listExists) {
        # Create the list if it does not exist
        Write-Host "List '$ListName' does not exist. Creating the list..." -ForegroundColor Yellow
        New-PnPList -Title $ListName -Template GenericList
        Write-Host "List '$ListName' created successfully." -ForegroundColor Green
    } else {
        Write-Host "List '$ListName' already exists." -ForegroundColor Green
    }

    # Add a multiline text field
    Add-PnPField -List $ListName -InternalName "WorkDescription" -DisplayName "Work Description" -Type Note -Required -AddToDefaultView

    # Add a single line text field
    Add-PnPField -List $ListName -InternalName "RequestNumber" -DisplayName "Request Number" -Type Text -Required -AddToDefaultView

    # Create date field XML
    $DefaultDate = (Get-Date).ToString("MM/dd/yyyy")
    $DateFieldXml = @"
<Field Type='DateTime' Name='Date' StaticName='Date' DisplayName='Date' Format='DateOnly' Required='TRUE'>
    <Default>$DefaultDate</Default>
</Field>
"@

    # Add the date field from XML
    Add-PnPFieldFromXml -List $ListName -FieldXml $DateFieldXml

    # Get the Owners group
    $SiteOwnersGroup = Get-PnPSiteGroup | Where-Object { $_.Title -like "*Full Control*" } | Select-Object -ExpandProperty Title

    # Break role inheritance and set permissions
    Set-PnPList -Identity $ListName -BreakRoleInheritance
    Set-PnPListPermission -Identity $ListName -Group $SiteOwnersGroup -AddRole "Read"
    Set-PnPListPermission -Identity $ListName -User $AdminUser -AddRole "Full Control"

    Write-Host "Configuration for list '$ListName' completed successfully." -ForegroundColor Green
}


# Entry point
Try {
    $TodayDate = (Get-Date).ToString("yyyyMMdd")
    $LastFile = (Get-ChildItem ".\CompareSites report" | Sort-Object LastWriteTime -Descending | Select-Object -First 1).Name
    $OldSitesReport = Import-Csv -Path ".\CompareSites report\$LastFile" | Select-Object -ExpandProperty "Uri"

    Connect-PnPOnline -Url $TenantAdminURL -Credentials $Cred -ClientId $ClientId -ErrorAction Stop
    $AllSites = Get-PnPTenantSite | Select-Object Url
    Write-Host "$($AllSites.Count) -- Total sites fetched"

    # Compare reports and process new sites
    $NewSitesReport = $AllSites | Export-Csv -Path ".\CompareSites report\AllTenantSites_$TodayDate.csv" -NoTypeInformation
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
                                Status = "Custom action created successfully."
                            }
                    } else {
                        Write-Host "Custom Action already exists in $($SiteCollection.InputObject)" -ForegroundColor Yellow
                        $Global:DailyReport += [PSCustomObject]@{
                                SiteURL = $SiteCollection.InputObject
                                Status = "Custom action already exists."
                            }
                    }

                    # Configure the list after creating custom action
                    Configure-List -ListName $YourListName -AdminUser $SiteCollectionAdmin
                    $Global:DailyReport += [PSCustomObject]@{
                            SiteURL = $SiteCollection.InputObject
                            Status = "List configured successfully."
                        }
                }
                break  # Exit the retry loop on success
            } Catch {
                $retryCount++
                Write-Host "Error processing $($SiteCollection.InputObject): $($_.Exception.Message)" -ForegroundColor Red
                
                if ($retryCount -ge $maxRetries) {
                    $ErrorOccurredSites = New-Object PSObject
                    $ErrorOccurredSites | Add-Member -Type NoteProperty -Name "SiteURL" -Value $SiteCollection.InputObject
                    $ErrorOccurredSites | Add-Member -Type NoteProperty -Name "Status" -Value "Error after $maxRetries attempts"
                    $Global:DailyReport += $ErrorOccurredSites
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
            <th>Status</th>
        </tr>
"@

# Append daily report data to the email body
$Global:DailyReport | ForEach-Object {
    $BodyMail += "<tr><td>$($_.SiteURL)</td><td>$($_.Status)</td></tr>"
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
