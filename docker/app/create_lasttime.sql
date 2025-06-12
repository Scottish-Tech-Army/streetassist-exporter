-- Make sure table exists, creating if not
IF OBJECT_ID('dbo.JobTimestamp', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.JobTimestamp (
        LastRunTime DATETIME NOT NULL
    );
    INSERT INTO dbo.JobTimestamp (LastRunTime) VALUES ('1900-01-01 00:00:00');
END;
-- Completion Timestamp is when the job was completed, as opposed to when it was run.
IF OBJECT_ID('dbo.CompletionTimestamp', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.CompletionTimestamp (
        LastCompletion DATETIME NOT NULL
    );
    INSERT INTO dbo.CompletionTimestamp (LastCompletion) VALUES ('1900-01-01 00:00:00');
END;
