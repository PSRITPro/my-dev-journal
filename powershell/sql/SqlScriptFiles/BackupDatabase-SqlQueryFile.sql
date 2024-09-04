BACKUP DATABASE [{DatabaseName}]
TO DISK = N'{BackupFilePath}'
WITH FORMAT, -- Initializes the backup media    
    NAME = N'{DatabaseName}-Full Database Backup', -- Description of the backup
    SKIP, -- Skips the verification if the backup set already exists
    NOREWIND, -- Keeps the tape drive in the current position
    NOUNLOAD, -- Keeps the tape in the drive
    STATS = 10, -- Displays progress every 10%
    CHECKSUM, -- Verifies data integrity during the backup process
    COMPRESSION; -- Compresses the backup file
GO

--BACKUP DATABASE [{{DatabaseName}}]
--TO DISK = N'{{BackupFilePath}}'
--WITH NOFORMAT, NOINIT,
--NAME = N'{{DatabaseName}}-Full Database Backup',
--SKIP, NOREWIND, NOUNLOAD, STATS = 10;
--GO