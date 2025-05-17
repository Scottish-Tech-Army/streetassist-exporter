-- sqlcmd -b -S ${SERVER} -d ${DB} -U ${ADMINUSER} -P ${ADMINPWD} -i create_powerbi_tables.sql
--
PRINT("Create WelfareChecks");
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
PRINT("Insert historic WelfareChecks");
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
PRINT("Insert WelfareChecks from view");
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

-- Create the AllDigitalSUF table
PRINT("Create AllDigitalSUF");
DROP TABLE IF EXISTS dbo.AllDigitalSUF;
GO
CREATE TABLE dbo.AllDigitalSUF (
    auditID NVARCHAR(255),
    servicedelivery_date DATE,
    Weekday NVARCHAR(255),
    volunteer_creating_form NVARCHAR(255),
    form_id NVARCHAR(255),
    -- Job Categories
    job_category NVARCHAR(255),
    Assault INT,
    Alcohol INT,
    Drugs INT,
    Phone_Charge INT,
    Distressed INT,
    Lost_Friends INT,
    Mental_Health INT,
    Getting_Home INT,
    Friendly_Ear INT,
    First_Aid INT,
    Sexual INT,
    Hate_Crime INT,
    Domestic_Abu_Ass INT,
    Other INT,
    -- Provisions
    client_provisions NVARCHAR(255),
    Contact_Family NVARCHAR(255),
    Contact_Friend INT,
    Emotional_Support INT,
    First_Aid2 INT,
    Phone_Charge3 INT,
    Water_Tea INT,
    Advice INT,
    Safe_Route_Home INT,
    Shelter INT,
    Other4 INT,
    provisions_other INT,
    -- General
    venue_name NVARCHAR(255),
    Calcd_TreatmentTime_Mins_ INT, -- total_job_minutes
    has_the_client_sustained_any_injuries NVARCHAR(255), -- injuries
    does_the_client_require_observations NVARCHAR(255), -- observations
    found_alone NVARCHAR(255),
    type_of_involvement NVARCHAR(255), -- police_involvement_type
    age_range NVARCHAR(255),
    gender NVARCHAR(255),
    nationality NVARCHAR(255),
    residency NVARCHAR(255),
    where_do_they_study NVARCHAR(255),
    has_the_client_drank_alcohol NVARCHAR(255), --alcohol_consumed
    have_drugs_been_consumed NVARCHAR(255), -- drugs_consume
    referred_by NVARCHAR(255),
    job_outcome NVARCHAR(255),
    -- Ambulance
    was_ambulance_requested NVARCHAR(255), -- ambulance_requested
    how_requested_ambulance NVARCHAR(255), -- ambulance_requested_how
    who_requested_ambulance NVARCHAR(255), -- ambulance_requested_who
    ambulance_cancelled NVARCHAR(255), -- ambulance_cancelled
    who_cancelled_ambulance NVARCHAR(255), -- ambulance_cancelled_who
    -- Police
    was_police_involved NVARCHAR(255), -- police_involved
    were_police_called NVARCHAR(255), -- police_requested
    how_requested_police NVARCHAR(255), -- police_requested_how
    who_requested_police NVARCHAR(255), -- police_requested_who
    police_cancelled NVARCHAR(255), -- police_cancelled
    who_cancelled_police NVARCHAR(255) -- police_cancelled_who
);
GO

-- Copy the historic data in.
PRINT("Copy historic data into AllDigitalSUF");
INSERT INTO dbo.AllDigitalSUF
(
    auditID,
    servicedelivery_date,
    Weekday,
    volunteer_creating_form,
    form_id,
    job_category,
    Assault,
    Alcohol,
    Drugs,
    Phone_Charge,
    Distressed,
    Lost_Friends,
    Mental_Health,
    Getting_Home,
    Friendly_Ear,
    First_Aid,
    Sexual,
    Hate_Crime,
    Domestic_Abu_Ass,
    Other,
    client_provisions,
    Contact_Family,
    Contact_Friend,
    Emotional_Support,
    First_Aid2,
    Phone_Charge3,
    Water_Tea,
    Advice,
    Safe_Route_Home,
    Shelter,
    Other4,
    provisions_other,
    venue_name,
    Calcd_TreatmentTime_Mins_,
    has_the_client_sustained_any_injuries,
    does_the_client_require_observations,
    found_alone,
    type_of_involvement,
    age_range,
    gender,
    nationality,
    residency,
    where_do_they_study,
    has_the_client_drank_alcohol,
    have_drugs_been_consumed,
    referred_by,
    job_outcome,
    was_ambulance_requested,
    how_requested_ambulance,
    who_requested_ambulance,
    ambulance_cancelled,
    who_cancelled_ambulance,
    was_police_involved,
    were_police_called,
    how_requested_police,
    who_requested_police,
    police_cancelled,
    who_cancelled_police
)
SELECT
    audit_id AS auditID,
    servicedelivery_date AS servicedelivery_date,
    NULL AS Weekday,                    -- No corresponding source column; adjust default as needed
    NULL AS volunteer_creating_form,    -- No corresponding source column; adjust default as needed
    form_id AS form_id,
    NULL AS job_category,               -- No corresponding source column
    assault AS Assault,
    alcohol AS Alcohol,
    drugs AS Drugs,
    phone_charge AS Phone_Charge,
    distressed AS Distressed,
    lost_friends AS Lost_Friends,
    mental_health AS Mental_Health,
    getting_home AS Getting_Home,
    friendly_ear AS Friendly_Ear,
    first_aid AS First_Aid,
    sexual AS Sexual,
    hate_crime AS Hate_Crime,
    domestic_abuse_assault AS Domestic_Abu_Ass,
    category_other AS Other,
    client_provisions AS client_provisions,
    contact_family AS Contact_Family,
    contact_friend AS Contact_Friend,
    emotional_support AS Emotional_Support,
    first_aid2 AS First_Aid2,
    phone_charge3 AS Phone_Charge3,
    water_tea AS Water_Tea,
    advice AS Advice,
    safe_route_home AS Safe_Route_Home,
    shelter AS Shelter,
    provisions_other AS Other4,
    provisions_other AS provisions_other,
    venue_name AS venue_name,
    total_job_minutes AS Calcd_TreatmentTime_Mins_,
    injuries AS has_the_client_sustained_any_injuries,
    observations AS does_the_client_require_observations,
    found_alone AS found_alone,
    police_involvement_type AS type_of_involvement,
    age_range AS age_range,
    gender AS gender,
    nationality AS nationality,
    residency AS residency,
    where_do_they_study AS where_do_they_study,
    alcohol_consumed AS has_the_client_drank_alcohol,
    drugs_consumed AS have_drugs_been_consumed,
    referred_by AS referred_by,
    job_outcome AS job_outcome,
    ambulance_requested AS was_ambulance_requested,
    ambulance_requested_how AS how_requested_ambulance,
    ambulance_requested_who AS who_requested_ambulance,
    ambulance_cancelled AS ambulance_cancelled,
    ambulance_cancelled_who AS who_cancelled_ambulance,
    police_involved AS was_police_involved,
    police_requested AS were_police_called,
    police_requested_how AS how_requested_police,
    police_requested_who AS who_requested_police,
    police_cancelled AS police_cancelled,
    police_cancelled_who AS who_cancelled_police
FROM dbo.historic_all_suf
WHERE servicedelivery_date < '2024-01-01';
GO

-- Copy in the view data
PRINT("Copy view data into AllDigitalSUF");
INSERT INTO dbo.AllDigitalSUF
(
    auditID,
    servicedelivery_date,
    Weekday,
    volunteer_creating_form,
    form_id,
    job_category,
    Assault,
    Alcohol,
    Drugs,
    Phone_Charge,
    Distressed,
    Lost_Friends,
    Mental_Health,
    Getting_Home,
    Friendly_Ear,
    First_Aid,
    Sexual,
    Hate_Crime,
    Domestic_Abu_Ass,
    Other,
    client_provisions,
    Contact_Family,
    Contact_Friend,
    Emotional_Support,
    First_Aid2,
    Phone_Charge3,
    Water_Tea,
    Advice,
    Safe_Route_Home,
    Shelter,
    Other4,
    provisions_other,
    venue_name,
    Calcd_TreatmentTime_Mins_,
    has_the_client_sustained_any_injuries,
    does_the_client_require_observations,
    found_alone,
    type_of_involvement,
    age_range,
    gender,
    nationality,
    residency,
    where_do_they_study,
    has_the_client_drank_alcohol,
    have_drugs_been_consumed,
    referred_by,
    job_outcome,
    was_ambulance_requested,
    how_requested_ambulance,
    who_requested_ambulance,
    ambulance_cancelled,
    who_cancelled_ambulance,
    was_police_involved,
    were_police_called,
    how_requested_police,
    who_requested_police,
    police_cancelled,
    who_cancelled_police
)
SELECT
    audit_id                     AS auditID,                        -- view provides audit_id
    servicedelivery_date         AS servicedelivery_date,           -- view provides service_date aliased as servicedelivery_date
    Weekday                      AS Weekday,                        -- view computes Weekday
    volunteer_creating_form      AS volunteer_creating_form,        -- view provides volunteer_creating_form
    form_id                      AS form_id,                        -- view provides form_id
    job_category                 AS job_category,                   -- view provides job_category
    Assault                      AS Assault,                        -- view calculates Assault from i.job_category
    Alcohol                      AS Alcohol,                        -- view calculates Alcohol
    Drugs                        AS Drugs,                          -- view calculates Drugs
    Phone_Charge                 AS Phone_Charge,                   -- view calculates Phone_Charge
    Distressed                   AS Distressed,                     -- view calculates Distressed
    Lost_Friends                 AS Lost_Friends,                   -- view calculates Lost_Friends
    Mental_Health                AS Mental_Health,                  -- view calculates Mental_Health
    Getting_Home                 AS Getting_Home,                   -- view calculates Getting Home
    Friendly_Ear                 AS Friendly_Ear,                   -- view calculates Friendly Ear
    First_Aid                    AS First_Aid,                      -- view calculates First Aid
    Sexual                       AS Sexual,                         -- view calculates Sexual
    Hate_Crime                   AS Hate_Crime,                     -- view calculates Hate Crime
    Domestic_Abu_Ass             AS Domestic_Abu_Ass,               -- view calculates Domestic Abu Ass
    Other                        AS Other,                          -- view calculates Other from job_category
    client_provisions            AS client_provisions,              -- view provides client_provisions
    Contact_Family               AS Contact_Family,                 -- view calculates Contact Family from client_provisions
    Contact_Friend               AS Contact_Friend,                 -- view calculates Contact Friend
    Emotional_Support            AS Emotional_Support,              -- view calculates Emotional Support from client_provisions
    First_Aid2                 AS First_Aid2,                    -- view calculates First Aid (client provision)
    Phone_Charge3              AS Phone_Charge3,                 -- view calculates Phone Charge (client provision)
    Water_Tea                  AS Water_Tea,                     -- view calculates Water (Tea)
    Advice                     AS Advice,                        -- view calculates Advice
    Safe_Route_Home            AS Safe_Route_Home,               -- view calculates Safe Route Home
    Shelter                    AS Shelter,                       -- view calculates Shelter
    Other4                     AS Other4,                        -- view calculates Other4 from client_provisions
    provisions_other           AS provisions_other,              -- view calculates provisions_other
    venue_name                 AS venue_name,                    -- view provides job_location as venue_name
    Calcd_TreatmentTime_Mins_  AS Calcd_TreatmentTime_Mins_,     -- view converts total_job_minutes to integer
    has_the_client_sustained_any_injuries AS has_the_client_sustained_any_injuries,    -- view provides injuries
    does_the_client_require_observations AS does_the_client_require_observations,        -- view provides observations
    found_alone                AS found_alone,                   -- view provides found_alone
    type_of_involvement        AS type_of_involvement,           -- view provides police_involvement_type
    age_range                  AS age_range,                     -- view provides age_range
    gender                     AS gender,                        -- view provides gender
    nationality                AS nationality,                   -- view provides nationality
    client_residency           AS residency,                     -- view provides residency (aliased as client_residency)
    where_do_they_study        AS where_do_they_study,           -- view provides where_do_they_study
    has_the_client_drank_alcohol AS has_the_client_drank_alcohol,  -- view provides alcohol_consumed as has_the_client_drank_alcohol
    have_drugs_been_consumed   AS have_drugs_been_consumed,      -- view provides drugs_consumed as have_drugs_been_consumed
    referred_by                AS referred_by,                   -- view provides referred_by
    job_outcome                AS job_outcome,                   -- view provides job_outcome
    was_ambulance_requested    AS was_ambulance_requested,       -- view provides ambulance_requested
    how_requested_ambulance    AS how_requested_ambulance,       -- view provides ambulance_requested_how
    who_requested_ambulance    AS who_requested_ambulance,       -- view provides ambulance_requested_who
    ambulance_cancelled        AS ambulance_cancelled,           -- view provides ambulance_cancelled
    who_cancelled_ambulance    AS who_cancelled_ambulance,       -- view provides ambulance_cancelled_who
    was_police_involved        AS was_police_involved,           -- view provides police_involved
    were_police_called         AS were_police_called,            -- view provides police_requested
    how_requested_police       AS how_requested_police,          -- view provides police_requested_how
    who_requested_police       AS who_requested_police,          -- view provides police_requested_who
    NULL                       AS police_cancelled,              -- no corresponding field in the view
    NULL                       AS who_cancelled_police           -- no corresponding field in the view
FROM dbo.all_suf_view
WHERE servicedelivery_date >= '2024-01-01';
GO
