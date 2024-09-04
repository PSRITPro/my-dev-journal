# Set location path
Set-Location -Path $PSScriptRoot

# Define script file name and timestamp for transcript
$scriptFileName = [System.IO.Path]::GetFileNameWithoutExtension($MyInvocation.MyCommand.Path)
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$transcriptFile = ".\logs\$($scriptFileName)_Transcript_$($timestamp).txt"

# Start transcription
Start-Transcript -Path $transcriptFile
Try{
    # Get the most recent CSV file from the logs folder
    $inputFile = Get-ChildItem -Path ".\logs\" -File -Filter "*.csv" | Sort-Object LastWriteTime -Descending | Select-Object -First 1

    If ($inputFile) {
        # Import the CSV file content
        $sqlFiles = Import-Csv -Path $inputFile.FullName       
        ForEach ($sql in $sqlFiles) {
            Try {
                If($sql.Port){
                $SqlDBServerInstance = "$($sql.RestoreDBServerInstance),$($Sql.Port)"
                }
                Else{
                    $SqlDBServerInstance = $sql.RestoreDBServerInstance
                }
                    # Log the SQL file execution
                Write-Host "Executing SQL file - $($sql.DatabaseUserPermissonsSqlFile) for the database - $($sql.RestoreDatabaseName) on server - $($sqlFile.RestoreDBServerInstance)" -ForegroundColor Green
                                  
                # Read SQL query from the file
                $sqlQuery = Get-Content -Path $sql.DatabaseUserPermissonsSqlFile -Raw
                    
                # Execute the SQL query
                Invoke-Sqlcmd -ServerInstance $SqlDBServerInstance -Query $sqlQuery -Verbose -OutputSqlErrors $true -ErrorAction Stop
                    
                Write-Host "Applied permission to the database - $($sql.RestoreDatabaseName) - by using the Sql file - $($sql.DatabaseUserPermissonsSqlFile)" -ForegroundColor Green
            }
            Catch {
                Write-Host "Error occurred while executing the SQL query to apply permission on the database $($sql.RestoreDatabaseName) - sql file - $($sql.DatabaseUserPermissonsSqlFile) - $_" -ForegroundColor Red
            }
        }
        
    }
    Else {
        Write-Host "No CSV files found in the logs folder." -ForegroundColor Yellow
    }
}
Catch {
    Write-Host "Error while getting SQL files from the logs folder - $_" -ForegroundColor Red
}
# Stop transcription
Stop-Transcript