#Restoring a SQL Server database from a backup file when the destination paths for the data and log files are different from the original paths in the backup requires the use of the WITH MOVE option. Here's a PowerShell script to automate this process:
# Set location path
$scriptDirectory = $PSScriptRoot
Set-Location -Path $scriptDirectory

# Define script file name and timestamp for transcript
$scriptFileName = [System.IO.Path]::GetFileNameWithoutExtension($MyInvocation.MyCommand.Path)
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$transcriptFile = ".\logs\$($scriptFileName)_Transcript_$($timestamp).txt"

# Path to the SQL template file
$sqlDatabaseBackupTemplateFilePath = ".\SqlScriptFiles\BackupDatabase-SqlQueryFile.sql" # Replace with the full path to your SQL template file


# Start transcription
Start-Transcript -Path $transcriptFile
# Define variables
Try {
    # Get the most recent CSV file from the logs folder
    $inputFile = Get-ChildItem -Path ".\logs\" -File -Filter "*.csv" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    If ($inputFile)
    {
        $sqlFiles = Import-Csv -Path $inputFile.FullName
        ForEach($sql in $sqlFiles)
        {
            If($sql.Port){
                $SqlDBServerInstance = "$($sql.RestoreDBServerInstance),$($Sql.Port)"
            }
            Else{
                $SqlDBServerInstance = $sql.RestoreDBServerInstance
            }
            $destinationDatabaseName = $sql.RestoreDatabaseName
            $backupFilePath = "$($scriptDirectory)\$($destinationDatabaseName)_$($timestamp).bak"

            ## Read the content of the SQL template file
            $sqlDatabaseBackupQuery = Get-Content -Path $sqlDatabaseBackupTemplateFilePath -Raw
            $sqlDatabaseBackupQuery = $sqlDatabaseBackupQuery -replace "{DatabaseName}", $destinationDatabaseName `
                                                             -replace "{BackupFilePath}", $backupFilePath
            Try{
                #Execute the RESTORE DATABASE command
                Invoke-Sqlcmd -ServerInstance $sqlServerInstance -Query $sqlDatabaseBackupQuery -Verbose -ErrorAction Stop              
            }
            Catch{
                Write-Host "Database [$destinationDatabaseName] restored failed to [$sqlServerInstance] - $_" -ForegroundColor Red
            }

            Write-Host "Database [$destinationDatabaseName] restored successfully to $sqlServerInstance."
        }
    }
}
Catch {
    Write-Host "Error while getting SQL files from the logs folder - $_" -ForegroundColor Red
}

# Stop transcription
Stop-Transcript