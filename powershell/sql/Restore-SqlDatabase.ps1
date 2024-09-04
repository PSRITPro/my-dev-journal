#Restoring a SQL Server database from a backup file when the destination paths for the data and log files are different from the original paths in the backup requires the use of the WITH MOVE option. Here's a PowerShell script to automate this process:
# Set location path
Set-Location -Path $PSScriptRoot

# Define script file name and timestamp for transcript
$scriptFileName = [System.IO.Path]::GetFileNameWithoutExtension($MyInvocation.MyCommand.Path)
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$transcriptFile = ".\logs\$($scriptFileName)_Transcript_$($timestamp).txt"

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
            $backupFilePath = $sql.DatabaseBackUpFile
            $destinationDatabaseName = $sql.RestoreDatabaseName
            #$sqlServerInstance = $sql.RestoreDBServerInstance

            #Retrieve default data and log file locations
            $dataFilePath = Invoke-Sqlcmd -ServerInstance $SqlDBServerInstance -Query "SELECT SERVERPROPERTY('InstanceDefaultDataPath') AS DefaultDataPath"
            $logFilePath = Invoke-Sqlcmd -ServerInstance $SqlDBServerInstance -Query "SELECT SERVERPROPERTY('InstanceDefaultLogPath') AS DefaultLogPath"

            #Execute RESTORE FILELISTONLY to get file details
            $query = "RESTORE FILELISTONLY FROM DISK = N'$backupFilePath'"
            $fileList = Invoke-Sqlcmd -ServerInstance $SqlDBServerInstance -Query $query

            # Initialize the RESTORE DATABASE command
            $restoreQuery = "RESTORE DATABASE [$destinationDatabaseName] FROM DISK = N'$backupFilePath' WITH REPLACE"

            # Loop through each file in the backup and generate the MOVE options
            foreach ($file in $fileList) {
                $logicalName = $file.LogicalName
                $physicalName = $file.PhysicalName
                $fileType = $file.Type
                IF($fileType -eq "D") {
                        $newFileName = "$($dataFilePath.DefaultDataPath)$($destinationDatabaseName)_Data.mdf"
                    } 
                ElseIf ($fileType -eq "L") {
                    $newFileName = "$($logFilePath.DefaultLogPath)$($destinationDatabaseName)_Log.ldf"
                }

            $restoreQuery += ", MOVE N'$logicalName' TO N'$newFileName'"
            }
            Try{
                # Execute the RESTORE DATABASE command
                Invoke-Sqlcmd -ServerInstance $sqlServerInstance -Query $restoreQuery -Verbose -ErrorAction Stop              
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