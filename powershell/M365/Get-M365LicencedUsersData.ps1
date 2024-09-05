# Set the working directory to the location of the script
Set-Location -Path $PSScriptRoot

# Connect to Microsoft Graph with required permissions
Connect-MgGraph -Scopes "User.Read.All", "Directory.Read.All" -NoWelcome

# Define the date range for the last month
$startDate = (Get-Date).AddMonths(-1).ToString("yyyy-MM-ddTHH:mm:ssZ")

# Initialize an array to store the results
$results = @()

# Initialize variables for pagination
$top = 999
$hasMorePages = $true
$nextPageUrl = "https://graph.microsoft.com/v1.0/users?`$top=$top"

# Loop through all pages
while ($hasMorePages) {
    # Get users
    $response = Invoke-MgGraphRequest -Method GET -Uri $nextPageUrl
    
    foreach ($user in $response.value) {
        # Get detailed license information
        $licenseDetails = Get-MgUserLicenseDetail -UserId $user.Id
        
        foreach ($licenseDetail in $licenseDetails) {
            foreach ($servicePlan in $licenseDetail.ServicePlans) {
                if ($servicePlan.ProvisioningStatus -eq "Success") {
                #if ($servicePlan.ProvisioningStatus -eq "Success" -and $servicePlan.AssignedDate -gt [datetime]::Parse($startDate)) {
                        $results += [PSCustomObject]@{
                        DisplayName = $user.DisplayName
                        UserPrincipalName = $user.UserPrincipalName
                         ServicePlanName= $servicePlan.ServicePlanName
                        License = $servicePlan.ServicePlanId                       
                        AssignedDate = $servicePlan.AssignedDate
                    }
                    break
                }
            }
        }
    }
    
    # Check if there is another page
    $nextPageUrl = $response.'@odata.nextLink'
    $hasMorePages = $null -ne $nextPageUrl
}

# Output the results to a CSV file
$results | Export-Csv -Path "LicensedUsersLastMonth.csv" -NoTypeInformation

# Disconnect from Microsoft Graph
Disconnect-MgGraph
