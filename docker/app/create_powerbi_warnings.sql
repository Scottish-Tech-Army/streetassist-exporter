-- sqlcmd -b -S ${SERVER} -d ${DB} -U ${ADMINUSER} -P ${ADMINPWD} -i create_powerbi_warnings.sql
--
-- Create a table of anomalies
PRINT("Create Locations not in Places table - locations that are in inspections but not in the places table");
GO
DROP TABLE IF EXISTS dbo.LocationsNotInPlaces;
GO
CREATE TABLE dbo.LocationsNotInPlaces (
    audit_id NVARCHAR(255),
    service_date DATE,
    location NVARCHAR(255),
    form_id NVARCHAR(255),
    type NVARCHAR(255)
);
GO

PRINT("Copy anomalous digital SUF data into tables");
GO
INSERT INTO dbo.LocationsNotInPlaces
(
    audit_id,
    service_date,
    location,
    form_id,
    type
)
SELECT
    i.auditID AS audit_id,
    i.servicedelivery_date AS service_date,
    i.venue_name AS location,
    i.form_id AS form_id,
    'SUF' AS type
FROM [dbo].[AllDigitalSUF] i
LEFT JOIN places p ON i.venue_name = p.name
WHERE p.name IS NULL AND i.servicedelivery_date >= '2024-01-01';
GO

PRINT("Copy anomalous Welfare Check data into tables");
GO
INSERT INTO dbo.LocationsNotInPlaces
(
    audit_id,
    service_date,
    location,
    form_id,
    type
)
SELECT
    i.auditID AS audit_id,
    i.Conducted AS service_date,
    i.location AS location,
    i.form_id AS form_id,
    'WelfareCheck' AS type
FROM [dbo].[WelfareChecks] i
LEFT JOIN places p ON i.location = p.name
WHERE p.name IS NULL;
GO
