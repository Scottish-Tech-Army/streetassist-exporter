-- sqlcmd -b -S ${SERVER} -d ${DB} -U ${ADMINUSER} -P ${ADMINPWD} -i create_powerbi_warnings.sql
--
-- Create tables of anomalies
PRINT("Create Locations not in Places table - locations that are in inspections but not in the places table");
GO
DROP TABLE IF EXISTS dbo.WarningLocationsNotInPlaces;
GO
DROP TABLE IF EXISTS dbo.WarningLocationsUsedNotInPlaces;
GO
CREATE TABLE dbo.WarningLocationsUsedNotInPlaces (
    audit_id NVARCHAR(255),
    service_date DATE,
    location NVARCHAR(255),
    location_manual NVARCHAR(255),
    form_id NVARCHAR(255),
    type NVARCHAR(255)
);
GO

PRINT("Copy anomalous digital SUF job location data into tables");
GO
INSERT INTO dbo.WarningLocationsUsedNotInPlaces
(
    audit_id,
    service_date,
    location,
    location_manual,
    form_id,
    type
)
SELECT
    i.auditID AS audit_id,
    i.servicedelivery_date AS service_date,
    i.venue_name AS location,
    v.job_location_manual AS location_manual,
    i.form_id AS form_id,
    'SUFLocation' AS type
FROM [dbo].[AllDigitalSUF] i
LEFT JOIN inspectionview v ON i.auditID = v.audit_id
LEFT JOIN places p ON i.venue_name = p.name
WHERE p.name IS NULL AND i.servicedelivery_date >= '2024-01-01';
GO

PRINT("Copy anomalous digital SUF last venue data into tables");
GO
INSERT INTO dbo.WarningLocationsUsedNotInPlaces
(
    audit_id,
    service_date,
    location,
    location_manual,
    form_id,
    type
)
SELECT
    i.auditID AS audit_id,
    i.servicedelivery_date AS service_date,
    i.last_venue_visited AS location,
    v.last_venue_visited_manual AS location_manual,
    i.form_id AS form_id,
    'SUFLastVenue' AS type
FROM [dbo].[AllDigitalSUF] i
LEFT JOIN inspectionview v ON i.auditID = v.audit_id
LEFT JOIN places p ON i.last_venue_visited = p.name
WHERE p.name IS NULL AND i.servicedelivery_date >= '2024-01-01';
GO

PRINT("Copy anomalous Welfare Check data into tables");
GO
INSERT INTO dbo.WarningLocationsUsedNotInPlaces
(
    audit_id,
    service_date,
    location,
    location_manual,
    form_id,
    type
)
SELECT
    i.auditID AS audit_id,
    i.Conducted AS service_date,
    i.location AS location,
    v.location_manual AS location_manual,
    i.form_id AS form_id,
    'WelfareCheck' AS type
FROM [dbo].[WelfareChecks] i
LEFT JOIN welfarecheckview v ON i.auditID = v.audit_id
LEFT JOIN places p ON i.location = p.name
WHERE p.name IS NULL AND v.audit_id IS NOT NULL;
GO

PRINT("Copy anomalous Observation location data into tables");
GO
INSERT INTO dbo.WarningLocationsUsedNotInPlaces
(
    audit_id,
    service_date,
    location,
    location_manual,
    form_id,
    type
)
SELECT
    o.audit_id AS audit_id,
    o.service_date AS service_date,
    o.location_from_dropdown AS location,
    o.location_manual AS location_manual,
    o.form_id AS form_id,
    'Observation' AS type
FROM [dbo].[observationview] o
LEFT JOIN places p ON o.location = p.name
WHERE p.name IS NULL AND o.audit_id IS NOT NULL;
GO

-- Now create a table showing all locations that are in the valid_locations table not the places table
PRINT("Create Valid Locations not in Places table - valid locations that are in valid_locations but not in the places table");
GO
DROP TABLE IF EXISTS dbo.WarningValidLocationsNotInPlaces;
GO
CREATE TABLE dbo.WarningValidLocationsNotInPlaces (
    name NVARCHAR(255)
);
GO
INSERT INTO dbo.WarningValidLocationsNotInPlaces
(
    name
)
SELECT
    vl.name
FROM [dbo].[valid_locations] vl
LEFT JOIN places p ON vl.name = p.name
WHERE p.name IS NULL and vl.name not like 'Not On List%';
GO