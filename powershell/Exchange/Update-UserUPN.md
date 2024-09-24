# Update-UserUPN PowerShell Script

## Overview

The `Update-UserUPN.ps1` script is designed to update a user's User Principal Name (UPN) in Active Directory while preserving the old UPN in a custom attribute. This is particularly useful in scenarios involving user account migration, domain changes, user renaming, audit compliance, and support for legacy systems.

## Use Cases

### 1. User Account Migration
- **Scenario**: A company undergoes a merger and needs to migrate user accounts from one domain to another.
- **Action**: The script updates the UPN of each user while keeping the old UPN for reference, ensuring that any old email addresses still function if needed.

### 2. Domain Change
- **Scenario**: An organization changes its email domain (e.g., from `@oldcompany.com` to `@newcompany.com`).
- **Action**: Use the script to update UPNs to the new domain while retaining the old UPNs for continuity, helping with email forwarding and access to previous accounts during the transition.

### 3. User Renaming
- **Scenario**: A user changes their name and requires their UPN to reflect that change.
- **Action**: The script updates the UPN while preserving the old one, which may be referenced by applications or services.

### 4. Audit and Compliance
- **Scenario**: An organization needs to keep track of changes in user identities for compliance.
- **Action**: By storing the old UPN in a custom attribute, the organization maintains a record of previous UPNs for auditing purposes.

### 5. Legacy System Support
- **Scenario**: Some legacy systems may rely on old UPNs for authentication.
- **Action**: The script allows for seamless updates while retaining the ability to authenticate users based on their previous UPNs.

## Benefits

- **Seamless Transition**: Users continue to receive emails and access resources associated with their old UPNs during the transition.
- **Minimal Disruption**: Users do not need to change their credentials immediately, minimizing disruption.
- **Data Retention**: Preserving the old UPN ensures data integrity across systems and services that may reference it.

## Usage

1. **Prerequisites**: Ensure you have the Active Directory module installed and necessary permissions to update user attributes.

2. **Script Execution**:
   - Open PowerShell as an Administrator.
   - Modify the values of `$oldUPN` and `$newUPN` in the script to reflect the appropriate user accounts.
   - Run the script using the following command:
     ```powershell
     .\Update-UserUPN.ps1
     ```

## Conclusion

This script is a valuable tool for any environment where user account details need updating while ensuring continuity and traceability. Whether dealing with domain changes, mergers, or organizational restructuring, this script helps manage UPN updates while retaining old identifiers for a smooth transition.