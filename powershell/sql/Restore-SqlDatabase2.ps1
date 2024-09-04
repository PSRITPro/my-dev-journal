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
    $sqlFiles = Import-Csv -Path $inputFile.FullName
    ForEach($sql in $sqlFiles){  
        $sqlQueryToRestoreDataabase = Get-Content -Path ".\SqlScriptFiles\SQLQueryFile-Restore.sql" -Raw
        $sqlQueryToRestoreDataabase = $sqlQueryToRestoreDataabase -replace '<DatabaseName>', $sql.RestoreDatabaseName `
                                                                    -replace '<DatabaseName>', $sql.RestoreDatabaseName
        $SqlDBServerInstance = "$($sql.RestoreDBServerInstance),$($Sql.Port)"
        $RelocateData = New-Object Microsoft.SqlServer.Management.Smo.RelocateFile("MainDB_Data", "E:\DBFiles\MainDB.mdf")
        $RelocateLog = New-Object Microsoft.SqlServer.Management.Smo.RelocateFile("MainDB_Log", "E:\DBFiles\MainDB.ldf")
        Restore-SqlDatabase -ServerInstance $Sql.RestoreDBServerInstance -Database $sql.RestoreDatabaseName -BackupFile $sql.DatabaseBackUpFile -RelocateFile @($RelocateData,$RelocateLog)
    }
    
       
    
}
Catch {
    Write-Host "Error while getting SQL files from the logs folder - $_" -ForegroundColor Red
}

# Stop transcription
Stop-Transcript