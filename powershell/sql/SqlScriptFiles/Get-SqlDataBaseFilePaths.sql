SELECT
     db.name AS [DatabaseName],
    'Log File' AS [FileType],
    mf.physical_name AS [FilePath],
	mf.name AS [Name],
	mf.type_desc AS [Type]
FROM
    sys.master_files AS mf
    INNER JOIN sys.databases AS db
        ON mf.database_id = db.database_id
WHERE
    db.name = '<DatabaseName>' -- Replace with your database name
