# SQL and PowerShell Scripts

This repository contains a set of SQL and PowerShell scripts for managing SQL Server databases. The scripts cover various tasks such as backup and restore operations, retrieving database file paths, and managing user permissions.

## Directory Structure

- **SqlScriptFiles/**
  - `BackupDatabase-SqlQueryFile.sql`: SQL script for backing up a database.
  - `Get-SqlDataBaseFilePaths.sql`: SQL script for retrieving file paths of SQL Server databases.
  - `Get-SqlDatabaseUserPermissions.sql`: SQL script for getting user permissions on SQL Server databases.
  - `SQLQueryFile-Restore.sql`: SQL script for restoring a database from a backup.
  
- **PowerShellScripts/**
  - `Backup-SqlDatabase.ps1`: PowerShell script for automating SQL Server database backups.
  - `Get-SqlDatabaseUserPermissions.ps1`: PowerShell script to retrieve SQL Server database user permissions.
  - `Restore-SqlDatabase.ps1`: PowerShell script for restoring a SQL Server database from a backup.
  - `Restore-SqlDatabase2.ps1`: Another PowerShell script for restoring a SQL Server database with additional functionality.
  - `Set-SqlDatabaseUserPermissions.ps1`: PowerShell script to set or modify SQL Server database user permissions.

- **SqlConfigFileToRestoreDatabase**
  - Contains configuration files used by the restore scripts to manage database restoration.

## Usage

### SQL Scripts

1. **BackupDatabase-SqlQueryFile.sql**  
   This script creates a backup of a specified SQL Server database. Run this script from SQL Server Management Studio (SSMS) or any other SQL client tool.

2. **Get-SqlDataBaseFilePaths.sql**  
   Retrieves the file paths of the SQL Server databases. Useful for identifying where the database files are located.

3. **Get-SqlDatabaseUserPermissions.sql**  
   Retrieves user permissions for SQL Server databases. Helps in auditing and reviewing user access.

4. **SQLQueryFile-Restore.sql**  
   Used for restoring a SQL Server database from a backup file. Run this script after a backup is completed.

### PowerShell Scripts

1. **Backup-SqlDatabase.ps1**  
   Automates the backup process of SQL Server databases. Modify the script to specify the database and backup location.

2. **Get-SqlDatabaseUserPermissions.ps1**  
   Retrieves and reports user permissions for SQL Server databases. Adjust the script to target specific databases or users.

3. **Restore-SqlDatabase.ps1**  
   Restores a SQL Server database from a backup file. Configure the script with the necessary details such as backup file path and target database name.

4. **Restore-SqlDatabase2.ps1**  
   Another version of the restore script with potentially additional features or different handling. Ensure to review the script for specific functionalities.

5. **Set-SqlDatabaseUserPermissions.ps1**  
   Sets or updates user permissions on SQL Server databases. Configure according to your permission management needs.

## Configuration

For scripts that require configuration files, refer to the `SqlConfigFileToRestoreDatabase` directory. Make sure to adjust the configuration files with the correct details such as server names, database names, and file paths.

## Running the Scripts

1. **SQL Scripts**: Open SQL Server Management Studio (SSMS) or a similar SQL client and execute the scripts as needed.

2. **PowerShell Scripts**: Run the PowerShell scripts from a PowerShell prompt or include them in scheduled tasks for automation. Ensure you have the necessary permissions and that the SQL Server PowerShell module is installed.

## Notes

- Ensure that you have the appropriate backups before running any restore operations.
- Review and modify scripts as needed to fit your specific environment and requirements.
- For any issues or questions, please refer to the script comments or seek assistance from your database administrator.