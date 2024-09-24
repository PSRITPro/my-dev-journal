# Import Active Directory module
Import-Module ActiveDirectory

# Define the old and new UPNs
$oldUPN = "olduser@example.com"
$newUPN = "newuser@example.com"

# Function to update user UPN
function Update-UserUPN {
    param (
        [string]$oldUPN,
        [string]$newUPN
    )

    # Retrieve the user object for the old UPN
    $user = Get-ADUser -Filter { UserPrincipalName -eq $oldUPN } -ErrorAction SilentlyContinue

    if ($user) {
        try {
            # Store the old UPN in a custom attribute (e.g., extensionAttribute1)
            Set-ADUser -Identity $user -Add @{extensionAttribute1=$oldUPN}
            
            # Change UPN to the new one
            Set-ADUser -Identity $user -UserPrincipalName $newUPN
            
            Write-Host "Successfully updated UPN from $oldUPN to $newUPN while preserving the old UPN."
        } catch {
            Write-Host "An error occurred while updating the user: $_"
        }
    } else {
        Write-Host "User with UPN $oldUPN not found."
    }
}

# Call the function
Update-UserUPN -oldUPN $oldUPN -newUPN $newUPN
