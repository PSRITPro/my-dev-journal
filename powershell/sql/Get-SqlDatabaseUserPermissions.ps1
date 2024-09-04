# Set location path
Set-Location -Path $PSScriptRoot

# Define script file name and timestamp for transcript
$scriptFileName = [System.IO.Path]::GetFileNameWithoutExtension($MyInvocation.MyCommand.Path)
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$transcriptFile = ".\logs\$($scriptFileName)_Transcript_$($timestamp).txt"

# Start transcription
Start-Transcript -Path $transcriptFile

# Define file paths and variables
$inputFile = "SqlConfigFileToRestoreDatabase.csv"
$outputFile = ".\logs\SqlConfigFileToApplyUserPermissions_$($timestamp).csv"
$daysAgo = 2

If (Test-Path -Path $inputFile) {
    $sqlDbs = Import-Csv -LiteralPath $inputFile | Where-Object {-not [string]::IsNullOrWhiteSpace($_.RestoreDBServerInstance) -and                                                            
                                                            -not [string]::IsNullOrWhiteSpace($_.RestoreDatabaseName) -and
                                                            -not [string]::IsNullOrWhiteSpace($_.DatabaseBackUpFile)}
    # Check if the SQL databases were imported
    If ($sqlDbs){
        ForEach($sql in $sqlDbs){           
            Try {                
                # Read SQL query from the file and replace placeholders
                If($sql.Port){
                    $SqlDBServerInstance = "$($sql.RestoreDBServerInstance),$($Sql.Port)"
                }
                Else{
                    $SqlDBServerInstance = $sql.RestoreDBServerInstance
                }
                $sqlQueryToGetFilePaths = Get-Content -Path ".\SqlScriptFiles\Get-SqlDataBaseFilePaths.sql" -Raw
                $sqlQueryToGetFilePaths = $sqlQueryToGetFilePaths -replace '<DatabaseName>', $sql.RestoreDatabaseName
                $sqlFiles = Invoke-Sqlcmd -ServerInstance $SqlDBServerInstance -Query $sqlQueryToGetFilePaths -Verbose -OutputSqlErrors $true
                $dbDataFilePath = Invoke-Sqlcmd -ServerInstance $SqlDBServerInstance -Query "SELECT SERVERPROPERTY('InstanceDefaultDataPath') AS DefaultDataPath"
                $dbLogFilePath = Invoke-Sqlcmd -ServerInstance $SqlDBServerInstance -Query "SELECT SERVERPROPERTY('InstanceDefaultLogPath') AS DefaultLogPath"
                
                $sqlQueryToGetPermissions = Get-Content -Path ".\SqlScriptFiles\Get-SqlDatabaseUserPermissions.sql" -Raw
                $sqlQueryToGetPermissions = $sqlQueryToGetPermissions -replace '<DatabaseName>', $sql.RestoreDatabaseName
                # Execute SQL query  
                
                # Define file paths for SQL results and create  output file in logs folder
                $dbUserPermissionsSqlFile = ".\logs\$($sql.RestoreDatabaseName)_UserPermissions_$timestamp.sql"                                           
                $result = Invoke-Sqlcmd -ServerInstance $SqlDBServerInstance -Query $sqlQueryToGetPermissions -OutputAs DataTables -Verbose -OutputSqlErrors $true
                If ($result -and $result.Tables.Count -gt 0) {
                    # Export result to SQL file
                    $result | Select-Object -ExpandProperty $result.Columns[0].ColumnName | Out-File -FilePath $dbUserPermissionsSqlFile -Force
                    
                    # Log result details to CSV
                    $logEntry = [PSCustomObject]@{
                        RestoreDBServerInstance = $sql.RestoreDBServerInstance
                        Port = $sql.Port
                        RestoreDatabaseName = $sql.RestoreDatabaseName
                        DatabaseUserPermissonsSqlFile = $dbUserPermissionsSqlFile
                        DatabaseBackUpFile = $sql.DatabaseBackUpFile 
                    }
                    $logEntry | Export-Csv -Path $outputFile -Append -NoTypeInformation -Force
                }
                Else {
                    Write-Host "Users permissions are empty for this Database - $($sql.RestoreDatabaseName)" -ForegroundColor Yellow
                    Exit
                }
            }
            Catch {
                Write-Host "An error occurred while getting the user permissions for the database - $($sql.RestoreDatabaseName) - $_" -ForegroundColor Red
            }
        }
    }
    Else {
        Write-Host "Check the import file has valid data, and then re-run." -ForegroundColor Yellow
    }
    
    # Remove files older than 30 days
    $filesToRemove = Get-ChildItem -Path ".\logs\" -File | Where-Object { ((Get-Date) - $_.LastWriteTime).Days -gt $daysAgo }
    If($filesToRemove){
        ForEach($file in $filesToRemove){
            Remove-Item -Path $file.FullName -Force
            Write-Output "Deleted: $($file.FullName)"
        }
    }
    Else{
        Write-Host "No old files to remove" -ForegroundColor Yellow
    }
}
Else {
    Write-Host "Input file - $inputFile - is not valid. Please check and re-run." -ForegroundColor Yellow
}
# Stop transcription
Stop-Transcript