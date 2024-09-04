<# 
    Runs daily at 2pm from task scheduler
    Last Updated 9/3/2019
#>
#Location of Backup Files
$BackupPath = "C:\mount\SQLData1\SQLbackups"
try {
	Stop-Transcript | Out-Null
} catch [System.InvalidOperationException]{}
if ((Get-host).name -eq 'ConsoleHost') {
	Start-Transcript -Path 'C:\Scripts\Sql-Cleanup.log' -Append | Out-Null
}

Write-Host "$(Get-Date) - Starting Cleanup"

#Get-ChildItem $BackupPath -Recurse -Include *bak | where {$_.creationtime -lt $DeleteFileDt} | SELECT FullName
Function Remove-Logfiles {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [String] $BackupPath,

        [Parameter(Mandatory=$true)]
        [String] $Extension,

        [Parameter(Mandatory=$true)]
        [Int] $DaysBack,
        [switch]$Commit
    )

    Write-Verbose "$(Get-Date) [*** Searching `'$($BackupPath)`' for [$($Extension)] Files ***]"
    $FilesInScope = Get-ChildItem -Path $BackupPath -Recurse -Filter "*.$($Extension)" -File
    Write-Verbose "$(Get-Date) --> Found [$($FilesInScope.Count)] total files of type $($Extension)"
    $FilesToRemove = $FilesInScope | Where-Object {$_.LastWriteTime -lt (Get-Date).AddDays(-$($DaysBack))}
    Write-Verbose "$(Get-Date) --> Found [$($FilesToRemove.count)] Files of type $($Extension) older than $($DaysBack) days to remove"
    if ($Commit) {
        Write-Verbose "$(Get-Date) ---> Removing [$($Extension)] Files"
        $FilesToRemove | remove-item -force
        Write-Verbose "$(Get-Date) ---> Done Removing [$($Extension)] Files"
    } else {
        Write-Verbose "$(Get-Date) ---> Skipping Deletion, Specify -Commit to actually remove"
    }
    Write-Verbose ''
}

Remove-Logfiles -BackupPath $BackupPath -Extension 'BAK'      -DaysBack 1 -Verbose -Commit
Remove-Logfiles -BackupPath $BackupPath -Extension 'TRN'      -DaysBack 8 -Verbose -Commit
Remove-Logfiles -BackupPath $BackupPath -Extension 'LOG'      -DaysBack 10 -Verbose -Commit
Remove-Logfiles -BackupPath $BackupPath -Extension 'TXT'      -DaysBack 10 -Verbose -Commit
Remove-Logfiles -BackupPath $BackupPath -Extension '1D_BAK'   -DaysBack 1 -Verbose -Commit
Remove-Logfiles -BackupPath $BackupPath -Extension '2D_BAK'   -DaysBack 2 -Verbose -Commit
Remove-Logfiles -BackupPath $BackupPath -Extension '3D_BAK'   -DaysBack 3 -Verbose -Commit
Remove-Logfiles -BackupPath $BackupPath -Extension '7D_BAK'   -DaysBack 7 -Verbose -Commit
Remove-Logfiles -BackupPath $BackupPath -Extension '7DFF_BAK' -DaysBack 7 -Verbose -Commit

$emptydirs = get-childitem -Path $BackupPath -Directory -Recurse| Where-Object { ($_.GetFileSystemInfos().Count -eq 0) -and ($_.name -notin ('Compressed','NonCompressed')) }
Write-Output "Found $($emptydirs.count) empty directories to be removed."
$emptydirs | Remove-Item 

Write-Host "$(Get-Date) - Cleanup Done"

try {
	Stop-Transcript | Out-Null
} catch [System.InvalidOperationException]{}