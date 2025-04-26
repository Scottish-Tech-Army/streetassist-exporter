-- Make sure table exists, creating if not
IF OBJECT_ID('dbo.JobTimestamp', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.JobTimestamp (
        LastRunTime DATETIME NOT NULL
    );
    INSERT INTO dbo.JobTimestamp (LastRunTime) VALUES ('1900-01-01 00:00:00');
END;