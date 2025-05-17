-- sqlcmd -b -S ${SERVER} -d ${DB} -U ${ADMINUSER} -P ${ADMINPWD} -i update_tables.sql
-- Rip out PII
UPDATE dbo.inspection_items
SET response = 'REDACTED'
WHERE (
    item_id = 'c5fdc387-cd95-4d04-b278-2c482775062c' -- Client name
    OR item_id = '3c4c2a04-e72f-434a-a61e-efc4f250a5d6' -- SU address
    OR item_id = '44e7be75-c35b-491c-8326-d35857f4172f' -- Full name
    OR item_id = '7b62a613-236c-4558-a4f1-eda056125881' -- Job Narrative (often contains PII)
) AND response != 'REDACTED';
GO

-- Add and provision a service date column, that we can then index; note the 12 hour adjustment.
IF NOT EXISTS (
    SELECT *
    FROM sys.columns
    WHERE Name = N'service_date'
    AND Object_ID = Object_ID(N'dbo.inspections')
)
BEGIN
    ALTER TABLE dbo.inspections
    ADD service_date DATE;
END
GO

UPDATE dbo.inspections
SET service_date = CONVERT(date, DATEADD(hour, -12, conducted_on))
WHERE service_date IS NULL AND conducted_on IS NOT NULL;
GO

-- Create the places table
DROP TABLE IF EXISTS dbo.places;
GO
CREATE TABLE dbo.places (
        name NVARCHAR(255) NOT NULL,
        name_google NVARCHAR(255),
        address NVARCHAR(255),
        latitude DECIMAL(12,8), -- latitude
        longitude DECIMAL(12,8), -- longitude
        place_id NVARCHAR(255),
        icon NVARCHAR(255),
        icon_hex NVARCHAR(255)
);
GO

-- Create the historic WelfareChecks table, manually uploaded from earlier data
DROP TABLE IF EXISTS dbo.historic_welfare_checks;
GO
CREATE TABLE dbo.historic_welfare_checks (
        audit_id NVARCHAR(255) NOT NULL PRIMARY KEY,
        service_date NVARCHAR(255) NOT NULL,
        gender NVARCHAR(255),
        location NVARCHAR(255),
        check_type NVARCHAR(255)
);
GO
