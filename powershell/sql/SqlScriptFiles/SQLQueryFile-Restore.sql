USE [master];
GO

Declare @DefaultDataPath NVARCHAR(128)
Declare @DefaultLogPath NVARCHAR(128)
Declare @DatabaseName NVARCHAR(128)
DECLARE @DataFileName NVARCHAR(128);
DECLARE @LogFileName NVARCHAR(128);

SELECT @DefaultDataPath = CONVERT(NVARCHAR(255), SERVERPROPERTY('InstanceDefaultDataPath'));
SELECT @DefaultLogPath =  CONVERT(NVARCHAR(255), SERVERPROPERTY('InstanceDefaultLogPath'));

SELECT @DataFileName = mf.name
FROM sys.master_files mf
JOIN sys.databases db ON mf.database_id = db.database_id
WHERE db.name = <DatabaseName> AND mf.type_desc = 'ROWS';

SELECT @LogFileName = mf.name
FROM sys.master_files mf
JOIN sys.databases db ON mf.database_id = db.database_id
WHERE db.name = <DatabaseName> AND mf.type_desc = 'LOG';


-- Ensure the database is not in use
ALTER DATABASE <DatabaseName> SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
GO
ALTER DATABASE <DatabaseName> SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
RESTORE DATABASE <DatabaseName> FROM DISK = '<DabatabaseBackupFilePath>'
WITH REPLACE, 
MOVE '@DataFileName' TO '@DefaultDataPath\<DatabaseName>_Data.mdf',
MOVE '@LogFileName' TO '@DefaultLogPath\<DatabaseName>_Log.ldf'

GO

-- Set the database back to multi-user mode
ALTER DATABASE @DatabaseName SET MULTI_USER;
GO