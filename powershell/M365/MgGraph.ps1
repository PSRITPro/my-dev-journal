# Import the Microsoft.Graph module
Import-Module Microsoft.Graph
Import-Module Microsoft.Graph.Sites
Import-Module Microsoft.Graph.Authentication

# Connect to Microsoft Graph
Connect-MgGraph -Scopes "User.Read", "Sites.ReadWrite.All" -NoWelcome
Get-MgSite

# Check if the connection is successful
if (-not $?) {
    Write-Error "Failed to connect to Microsoft Graph."
    exit
}

# Get the current user's context
$ctx = Get-MgContext

# Get the current user's UPN
$currentUserUPN = $ctx.Account

# Fetch the current user's information using the UPN
$user = Get-MgUser -Filter "userPrincipalName eq '$currentUserUPN'"

# Check if user info was retrieved successfully
if ($user) {
    Write-Host "User Info: $($user.DisplayName) ($($user.UserPrincipalName))"
} else {
    Write-Error "Failed to retrieve user information."
}

Get-MgSite

# Function to get recently accessed documents
function Get-ViewedDocuments {
    # Fetch insights using Graph API
    $insights = Invoke-MgGraphRequest -Uri "https://graph.microsoft.com/v1.0/me/insights/used" -Method GET

    # Filter for documents and select relevant details
    $viewedDocuments = $insights.value | Where-Object { $_.resourceVisualization -and $_.resourceVisualization.containerType -eq "Drive" }

    # Display the viewed documents
    $viewedDocuments | Select-Object name, lastAccessed, webUrl | Format-Table -AutoSize
}

# Call the function to get viewed documents
Get-ViewedDocuments

# Disconnect from Microsoft Graph
Disconnect-MgGraph
