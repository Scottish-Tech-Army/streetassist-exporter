-- sqlcmd -b -S ${SERVER} -d ${DB} -U ${ADMINUSER} -P ${ADMINPWD} -i update_tables.sql
-- Rip out PII
PRINT("Removing PII from inspection_items");
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
PRINT("Add a service date column to inspection");
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
PRINT("Create the places table");
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
PRINT("Create the historic WelfareChecks table");
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

-- Create the historic AllDigitalSUF table, manually uploaded from earlier data
-- Some of these do not have an audit_id, as they are old legacy records
PRINT("Create the historic all_suf table");
DROP TABLE IF EXISTS dbo.historic_all_suf
GO
CREATE TABLE dbo.historic_all_suf (
        audit_id NVARCHAR(255),
        servicedelivery_date DATE NOT NULL,
        form_id NVARCHAR(255),
        -- job categories
        alcohol INT,
        assault INT,
        drugs INT,
        phone_charge INT,
        distressed INT,
        lost_friends INT,
        mental_health INT,
        getting_home INT,
        friendly_ear INT,
        first_aid INT,
        sexual INT,
        hate_crime INT,
        domestic_abuse_assault INT,
        category_other INT,
        -- client provisions
        client_provisions NVARCHAR(255),
        advice INT,
        first_aid2 INT,
        phone_charge3 INT,
        contact_family INT,
        contact_friend INT,
        emotional_support INT,
        safe_route_home INT,
        shelter INT,
        water_tea INT,
        provisions_other INT,
        -- general
        venue_name NVARCHAR(255),
        referred_by NVARCHAR(255),
        total_job_minutes INT,
        -- about the service user
        age_range NVARCHAR(255),
        gender NVARCHAR(255),
        nationality NVARCHAR(255),
        residency NVARCHAR(255),
        where_do_they_study NVARCHAR(255),
        found_alone NVARCHAR(255),
        alcohol_consumed NVARCHAR(255),
        drugs_consumed NVARCHAR(255),
        injuries NVARCHAR(255),
        observations NVARCHAR(255),
        -- results
        job_outcome NVARCHAR(255),
        -- Ambulance
        ambulance_requested NVARCHAR(255),
        ambulance_requested_how NVARCHAR(255),
        ambulance_requested_who NVARCHAR(255),
        ambulance_cancelled NVARCHAR(255),
        ambulance_cancelled_who NVARCHAR(255),
        -- Police
        police_involved NVARCHAR(255),
        police_requested NVARCHAR(255),
        police_requested_how NVARCHAR(255), -- values from list
        police_requested_how_other NVARCHAR(255), -- freeform values
        police_requested_who NVARCHAR(255), -- values from list
        police_requested_who_other NVARCHAR(255), -- freeform values
        police_involvement_type NVARCHAR(255),
        police_cancelled NVARCHAR(255),
        police_cancelled_who NVARCHAR(255)
);
GO
