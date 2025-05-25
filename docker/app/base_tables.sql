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

-- Create the historic nightly table
PRINT("Create historic_nightly");
DROP TABLE IF EXISTS dbo.historic_nightly;
GO
CREATE TABLE dbo.historic_nightly (
    service_date NVARCHAR(255), -- service_date
    Volunteers_Total INT, -- How many volunteers were on that night
    Volunteer_Hours INT, -- Hours that night, based on 7 delivery hours
    Patients_Treated INT, -- Number of inspections identified
    Treatment_Time_Mins_ INT, -- Total time spent on inspections
    Obs INT,
    -- gender
    Male INT,
    Female INT,
    TG INT, -- No longer a valid answer
    TG_1 INT, -- not used but data includes it
    GenderOther INT, -- My addition
    GenderNull INT, -- My addition
    -- Counts if found alone
    found_alone_yes INT,
    found_alone_no INT,
    Male_Alone INT,
    Female_Alone INT,
    TG_Alone INT,
    -- age_range
    age_under_16 INT,
    age_17_18 INT, -- older data had this as 17-18; we will convert to 16-17
    age_19_24 INT, -- older data had this as 19-24; we will convert to 18-24
    age_25_34 INT,
    age_35_45 INT,
    age_46_plus INT,
    age_unknown INT,
    -- residency
    Local INT,
    Student INT,
    Tourist_Holiday INT,
    Visiting INT,
    Homeless INT,
    -- where_do_they_study
    EDI_Uni INT,
    HW_Uni INT,
    QMU INT,
    Napier INT,
    -- Data expects this INT, even though no examples
    EDI_College INT,
    Academic_Other INT,
    -- referred_by
    General_Public INT,
    Street_Pastor INT,
    Street_Assist INT,
    Partner_Friend INT,
    -- This can match either "Police" or "Transport Police" INT, but we bundle together anyway
    Police_BTP INT,
    Pub_Club INT,
    Self_Refer INT,
    Taxi_Marshall INT,
    Ambulance INT,
    Lothian_Buses INT,
    Com_Safety INT,
    CCTV_Control INT,
    Referred_Other INT,
    -- job_category
    Alcohol INT,
    Drugs INT,
    Phone_Charge INT,
    Distressed INT,
    Lost INT,
    Lost_Friends INT,
    Mental_Health INT,
    Getting_Home INT,
    Friendly_Ear INT,
    First_Aid INT,
    Assault INT,
    Sexual_Assault INT,
    Hate_Crime INT,
    Domestic_Abu_Ass INT,
    Condition_Other INT,
    -- job_outcome
    Left_on_Own INT,
    Left_on_Own_Taxi INT, -- Sum of left on own and taxi home; not separated in early data
    Home_by_SA INT,
    Home_by_Family INT,
    Home_by_Friend INT,
    Phone_Charged INT,
    Refused_Treat INT,
    SAS_to_ERI INT,
    SA_to_ERI INT,
    REH INT,
    Police_Care INT,
    Taxi_Home INT,
    Taxi_to_ERI INT,
    Stood_Down INT,
    Arrested INT,
    Outcome_Unknown INT, -- Not actually used anywhere, but in the data
    -- client_provisions
    First_Aid_2 INT,
    Phone_Charge_3 INT,
    Safe_Route_Home INT,
    Contact_Family INT,
    Contact_Friend INT,
    Emotional_Support INT,
    Advice INT,
    Shelter INT,
    Water_Tea INT,
    Provision_Other INT,
    -- Fields that never seem to be used, but storing in table; leaving headers as they were
    LIVE_REPORT_DATA_Condition_Other INT,
    LIVE_REPORT_DATA_Geographic_Unknown INT,
    LIVE_REPORT_DATA_Outcome_Unknown INT,
    LIVE_REPORT_DATA_Cuts INT,
    LIVE_REPORT_DATA_Bruising INT,
    LIVE_REPORT_DATA_Blood_Sugar INT,
    LIVE_REPORT_DATA_First_Aid_ADV_ INT,
    LIVE_REPORT_DATA_First_Aid_Other INT,
    LIVE_REPORT_DATA_Stood_Down INT
);
GO
