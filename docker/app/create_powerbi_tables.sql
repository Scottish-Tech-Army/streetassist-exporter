-- sqlcmd -b -S ${SERVER} -d ${DB} -U ${ADMINUSER} -P ${ADMINPWD} -i create_powerbi_tables.sql
--
DROP TABLE IF EXISTS dbo.WelfareChecks;
GO
CREATE TABLE dbo.WelfareChecks (
    auditID NVARCHAR(255) NOT NULL PRIMARY KEY, -- audit_id
    Conducted DATE NOT NULL, -- service_date
    Gender NVARCHAR(255),
    Location NVARCHAR(255),
    Type NVARCHAR(255)
);
GO

-- Copy the contents of the WelfareChecks table in.
INSERT INTO dbo.WelfareChecks (auditID, Conducted, Gender, Location, Type)
SELECT
    audit_id,
    CAST(service_date AS DATE) AS Conducted,
    gender,
    location,
    check_type
FROM dbo.historic_welfare_checks;
GO

-- Copy in the data from the view, but not if there's already a record in the table.
INSERT INTO dbo.WelfareChecks (auditID, Conducted, Gender, Location, Type)
SELECT
    v.audit_id,
    v.service_date,
    v.gender,
    v.location,
    v.check_type
FROM dbo.welfarecheckview v
WHERE NOT EXISTS (
    SELECT 1
    FROM dbo.WelfareChecks w
    WHERE w.auditID = v.audit_id
);
GO
