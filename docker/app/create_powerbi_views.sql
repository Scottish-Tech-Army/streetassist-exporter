-- sqlcmd -b -S ${SERVER} -d ${DB} -U ${ADMINUSER} -P ${ADMINPWD} -i create_powerbi_views.sql
--
CREATE OR ALTER VIEW dbo.AllDigitalSUF
WITH SCHEMABINDING
AS
SELECT
    i.audit_id,
    i.service_date as servicedelivery_date,
    FORMAT(TRY_CONVERT(DATE, i.conducted_on), 'ddd', 'en-US') AS Weekday,
    i.volunteer_creating_form as volunteer_creating_form,
    i.form_id as form_id,
    -- Why we have all these three is beyond me, but it seems that we do
    CONVERT(DATE, i.date_started) as job_creation_date,
    i.date_started as job_creation_datetime,
    i.date_started as job_creation_time,
    CASE
        WHEN i.job_category COLLATE Latin1_General_CS_AS LIKE '%Assault%' THEN 1
        ELSE 0
    END AS Assault,
    CASE
        WHEN i.job_category COLLATE Latin1_General_CS_AS LIKE '%Alcohol%' THEN 1
        ELSE 0
    END AS Alcohol,
    CASE
        WHEN i.job_category COLLATE Latin1_General_CS_AS LIKE '%Drugs%' THEN 1
        ELSE 0
    END AS Drugs,
    CASE
        WHEN i.job_category COLLATE Latin1_General_CS_AS LIKE '%Phone Charge%' THEN 1
        ELSE 0
    END AS Phone_Charge,
    CASE
        WHEN i.job_category COLLATE Latin1_General_CS_AS LIKE '%Distressed%' THEN 1
        ELSE 0
    END AS Distressed,
    CASE
        WHEN i.job_category COLLATE Latin1_General_CS_AS LIKE '%Lost Friends%' THEN 1
        ELSE 0
    END AS Lost_Friends,
    CASE
        WHEN i.job_category COLLATE Latin1_General_CS_AS LIKE '%Mental Health%' THEN 1
        ELSE 0
    END AS Mental_Health,
    CASE
        WHEN i.job_category COLLATE Latin1_General_CS_AS LIKE '%Getting Home%' THEN 1
        ELSE 0
    END AS Getting_Home,
    CASE
        WHEN i.job_category COLLATE Latin1_General_CS_AS LIKE '%Friendly Ear%' THEN 1
        ELSE 0
    END AS Friendly_Ear,
    CASE
        WHEN i.job_category COLLATE Latin1_General_CS_AS LIKE '%First Aid%' THEN 1
        ELSE 0
    END AS First_Aid,
    CASE
        WHEN i.job_category COLLATE Latin1_General_CS_AS LIKE '%Sexual%' THEN 1
        ELSE 0
    END AS Sexual,
    CASE
        WHEN i.job_category COLLATE Latin1_General_CS_AS LIKE '%Hate Crime%' THEN 1
        ELSE 0
    END AS Hate_Crime,
    CASE
        WHEN i.job_category COLLATE Latin1_General_CS_AS LIKE '%Domestic Abu Ass%' THEN 1
        ELSE 0
    END AS Domestic_Abu_Ass,
    CASE
        WHEN i.job_category COLLATE Latin1_General_CS_AS LIKE '%Other%' THEN 1
        ELSE 0
    END AS Other,
    i.job_location as venue_name,
    -- TODO: should figure out if we need this
    'xxx placeholder' as venue_name_other,
    i.injuries as has_the_client_sustained_any_injuries,
    i.observations as does_the_client_require_observations,
    i.found_alone as found_alone,
    i.involvement_type as type_of_involvement,
    i.client_provisions as client_provisions,
    CASE
        WHEN i.job_category COLLATE Latin1_General_CS_AS LIKE '%Contact Family%' THEN 1
        ELSE 0
    END AS Contact_Family,
    CASE
        WHEN i.job_category COLLATE Latin1_General_CS_AS LIKE '%Contact Friend%' THEN 1
        ELSE 0
    END AS Contact_Friend,
    CASE
        WHEN i.job_category COLLATE Latin1_General_CS_AS LIKE '%Emotional Support%' THEN 1
        ELSE 0
    END AS Emotional_Support,
    CASE
        WHEN i.job_category COLLATE Latin1_General_CS_AS LIKE '%First Aid%' THEN 1
        ELSE 0
    END AS First_Aid2,
    CASE
        WHEN i.job_category COLLATE Latin1_General_CS_AS LIKE '%Phone Charge%' THEN 1
        ELSE 0
    END AS Phone_Charge3,
    CASE
        WHEN i.job_category COLLATE Latin1_General_CS_AS LIKE '%Water%' THEN 1
        ELSE 0
    END AS Water_Tea,
    CASE
        WHEN i.job_category COLLATE Latin1_General_CS_AS LIKE '%Advice%' THEN 1
        ELSE 0
    END AS Advice,
    CASE
        WHEN i.job_category COLLATE Latin1_General_CS_AS LIKE '%Safe Route Home%' THEN 1
        ELSE 0
    END AS Safe_Route_Home,
    CASE
        WHEN i.job_category COLLATE Latin1_General_CS_AS LIKE '%Shelter%' THEN 1
        ELSE 0
    END AS Shelter,
    CASE
        WHEN i.job_category COLLATE Latin1_General_CS_AS LIKE '%Other%' THEN 1
        ELSE 0
    END AS Other4,
    CASE
        WHEN i.job_category COLLATE Latin1_General_CS_AS LIKE '%Other%' THEN 1
        ELSE 0
    END AS OtherOutcome,
    TRY_CONVERT(INT, i.total_job_minutes) as Calcd_TreatmentTime_Mins_,
    i.age_range as age_range,
    i.gender as gender,
    i.nationality as nationality,
    i.residency as client_residency,
    i.where_do_they_study as where_do_they_study,
    i.alcohol_consumed as has_the_client_drank_alcohol,
    i.drugs_consumed as have_drugs_been_consumed,
    i.referred_by as referred_by,
    i.job_outcome as job_outcome,
    i.ambulance_requested as was_ambulance_requested,
    i.ambulance_requested_how as how_requested_ambulance,
    i.ambulance_requested_who as who_requested_ambulance,
    i.ambulance_cancelled as ambulance_cancelled,
    i.ambulance_cancelled_who as who_cancelled_ambulance,
    i.police_involved as was_police_involved,
    i.police_requested as were_police_called,
    i.police_requested_how as how_requested_police,
    -- TODO: what is this?
    -- i.police_requested_how as how_requested_police_other,
    i.police_requested_who as who_requested_police
    -- TODO: what is this?
    -- i.police_requested_who as who_requested_police_other
    -- TODO: Does not appear to exist in current data, but might be in old data
    -- MAX(i.police_cancelled) as police_cancelled,
    -- MAX(i.police_cancelled_who) as who_cancelled_police
FROM dbo.inspectionview i
GO

CREATE OR ALTER VIEW dbo.WelfareChecks
WITH SCHEMABINDING
AS
SELECT
    i.audit_id as auditID,
    i.service_date as Conducted,
    i.gender as Gender,
    i.location as Location,
    i.check_type as Type
FROM dbo.welfarecheckview i
GO

-- TODO: This view is unusably slow
-- We avoid using COUNT or AVG as they interfere with materialised views.
CREATE OR ALTER VIEW dbo.SummaryView
WITH SCHEMABINDING
AS
SELECT
    i.service_date as service_date,
    i.service_date as Date_Report_Format_,
    1 AS Delivery_Nights, -- Each night is one night; quite why this is needed is unclear
    7 AS Delivery_Hours, -- Assumed 7 hours per night; some legacy data uses different values
    MAX(s.volunteer_count) AS Volunteers_Total, -- How many volunteers were on that night
    MAX(s.volunteer_hours) AS Volunteers_Hours, -- Hours that night, based on 7 delivery hours
    MAX(s.volunteer_real_living_wage) AS Real_Living_Wage_, -- Cost of those hours at 8.75 real living wage
    MAX(s.volunteer_national_living_wage) AS National_LivingWage_, -- Cost of those hours at 7.50 national living wage
    COUNT_BIG(*) AS Patients_Treated, -- Number of inspections identified
    CAST(COUNT_BIG(*) * 850 AS DECIMAL(10,2)) AS DATA_SROI_, -- Value, assuming £850 per person engaged with
    SUM(i.total_job_minutes) AS Treatment_Time_Mins_, -- Total time spent on inspections
    SUM(i.total_job_minutes) / COUNT_BIG(i.total_job_minutes) AS Time_Mins_per_Patient, -- Inspection time per inspection
    CAST(COUNT_BIG(*) * 850 - MAX(s.volunteer_real_living_wage) AS DECIMAL(10,2)) AS CB_Overall, -- Cost Benefit - SROI minus real living wage cost
    CAST((COUNT_BIG(*) * 850 - MAX(s.volunteer_real_living_wage)) / MAX(s.volunteer_count) AS DECIMAL(10,2)) AS CB_per_volunteer, -- Cost Benefit per volunteer
    -- TODO: unmapped fields
    -- Observations performed
    SUM(CASE WHEN i.observations = 'Yes' THEN 1 ELSE 0 END) AS Obs,
    -- gender
    SUM(CASE WHEN i.gender LIKE 'Male%' THEN 1 ELSE 0 END) AS Male,
    SUM(CASE WHEN i.gender LIKE 'Female%' THEN 1 ELSE 0 END) AS Female,
    -- Since this is no longer a valid answer to the question (which explicitly allows "Male (including transgender men)"), not going to include
    SUM(CASE WHEN i.gender LIKE 'Trans%' THEN 1 ELSE 0 END) AS TG,
    SUM(CASE WHEN i.gender IS NOT NULL AND gender NOT IN ('Male', 'Female', 'Trans') THEN 1 ELSE 0 END) AS GenderOther, -- My addition
    SUM(CASE WHEN i.gender IS NULL THEN 1 ELSE 0 END) AS GenderNull, -- My addition
    -- Counts if found alone
    -- TODO: horrible names, as uninformative
    SUM(CASE WHEN i.found_alone = 'Yes' THEN 1 ELSE 0 END) AS [Yes],
    SUM(CASE WHEN i.found_alone = 'No' THEN 1 ELSE 0 END) AS [No],
    -- ignoring LIVE_REPORT_DATA_TG_1 as never set
    SUM(CASE WHEN i.found_alone = 'Yes' AND i.gender LIKE 'Male%' THEN 1 ELSE 0 END) AS Male_Alone,
    SUM(CASE WHEN i.found_alone = 'Yes' AND i.gender LIKE 'Female%' THEN 1 ELSE 0 END) AS Female_Alone,
    SUM(CASE WHEN i.found_alone = 'Yes' AND i.gender LIKE 'Trans%' THEN 1 ELSE 0 END) AS TG_Alone,
    -- age_range
    -- TODO: horrible names for SQL, so should clean up, but needs PowerBI changes too
    SUM(CASE WHEN i.age_range = 'U16' THEN 1 ELSE 0 END) as Under_16,
    SUM(CASE WHEN i.age_range = '17-18' THEN 1 ELSE 0 END) as [17-18],
    SUM(CASE WHEN i.age_range = '19-24' THEN 1 ELSE 0 END) as [19-24],
    SUM(CASE WHEN i.age_range = '25-34' THEN 1 ELSE 0 END) as [25-34],
    SUM(CASE WHEN i.age_range = '35-45' THEN 1 ELSE 0 END) as [35-45],
    SUM(CASE WHEN i.age_range = '46+' THEN 1 ELSE 0 END) as [46],
    SUM(CASE WHEN i.age_range = '' OR i.age_range is NULL THEN 1 ELSE 0 END) as Age_Unknown,
    -- residency
    SUM(CASE WHEN i.residency = 'Local to Edinburgh' THEN 1 ELSE 0 END) as Local,
    SUM(CASE WHEN i.residency = 'Student' THEN 1 ELSE 0 END) as Student,
    SUM(CASE WHEN i.residency = 'Tourist' THEN 1 ELSE 0 END) as Tourist_Holiday,
    SUM(CASE WHEN i.residency = 'Visiting' THEN 1 ELSE 0 END) as Visiting,
    SUM(CASE WHEN i.residency = 'Homeless' THEN 1 ELSE 0 END) as Homeless,
    -- where_do_they_study
    SUM(CASE WHEN i.where_do_they_study = 'Edinburgh Uni' THEN 1 ELSE 0 END) as EDI_Uni,
    SUM(CASE WHEN i.where_do_they_study = 'Heriot Watt Uni' THEN 1 ELSE 0 END) as HW_Uni,
    SUM(CASE WHEN i.where_do_they_study = 'Queen Margaret Uni' THEN 1 ELSE 0 END) as QMU,
    SUM(CASE WHEN i.where_do_they_study = 'Napier Uni' THEN 1 ELSE 0 END) as Napier,
    -- Data expects this, even though no examples
    0 as EDI_Coll,
    SUM(CASE WHEN i.where_do_they_study IS NOT NULL AND
                  i.where_do_they_study NOT IN ('Edinburgh Uni', 'Heriot Watt Uni', 'Queen Margaret Uni', 'Napier Uni')
        THEN 1 ELSE 0 END) as Academic_Other,
    -- referred_by
    SUM(CASE WHEN i.referred_by LIKE '%General Public%' THEN 1 ELSE 0 END) as General_Public,
    SUM(CASE WHEN i.referred_by LIKE '%Street Pastor%' THEN 1 ELSE 0 END) as Street_Pastor,
    SUM(CASE WHEN i.referred_by LIKE '%Street Assist%' THEN 1 ELSE 0 END) as Street_Assist,
    SUM(CASE WHEN i.referred_by LIKE '%Partner / Friend%' THEN 1 ELSE 0 END) as Partner_Friend,
    -- This can match either "Police" or "Transport Police", but we bundle together anyway
    SUM(CASE WHEN i.referred_by LIKE '%Police%' THEN 1 ELSE 0 END) as Police_BTP,
    SUM(CASE WHEN i.referred_by LIKE '%Pub / Club%' THEN 1 ELSE 0 END) as Pub_Club,
    SUM(CASE WHEN i.referred_by LIKE '%Self-Refer%' THEN 1 ELSE 0 END) as Self_Refer,
    SUM(CASE WHEN i.referred_by LIKE '%Taxi Marshall%' THEN 1 ELSE 0 END) as Taxi_Marshall,
    SUM(CASE WHEN i.referred_by LIKE '%SAS%' THEN 1 ELSE 0 END) as Ambulance,
    SUM(CASE WHEN i.referred_by LIKE '%Lothian Buses%' OR i.referred_by LIKE '%Edin Trams%' THEN 1 ELSE 0 END) as Lothian_Buses,
    SUM(CASE WHEN i.referred_by LIKE '%Community Safety%' THEN 1 ELSE 0 END) as Com_Safety,
    SUM(CASE WHEN i.referred_by LIKE '%CCTV%' THEN 1 ELSE 0 END) as CCTV_Control,
    -- TODO: fix spelling, but need to work it through the Power BI dashboards too.
    SUM(CASE WHEN i.referred_by LIKE '%Other%' OR i.referred_by LIKE '%Not On List%' THEN 1 ELSE 0 END) as Refferal_Other,
    -- job_category
    SUM(CASE WHEN i.job_category LIKE '%Alcohol%' THEN 1 ELSE 0 END) as Alcohol,
    SUM(CASE WHEN i.job_category LIKE '%Drugs%' THEN 1 ELSE 0 END) as Drugs,
    SUM(CASE WHEN i.job_category LIKE '%Phone Charge%' THEN 1 ELSE 0 END) as Phone_Charge,
    SUM(CASE WHEN i.job_category LIKE '%Distressed%' THEN 1 ELSE 0 END) as Distressed,
    -- TODO: Seems odd that we have both "Lost" and "Lost Friends"
    SUM(CASE WHEN i.job_category LIKE '%Lost Friends%' THEN 1 ELSE 0 END) as Lost,
    SUM(CASE WHEN i.job_category LIKE '%Lost Friends%' THEN 1 ELSE 0 END) as Lost_Friends,
    SUM(CASE WHEN i.job_category LIKE '%Mental Health%' THEN 1 ELSE 0 END) as Mental_Health,
    SUM(CASE WHEN i.job_category LIKE '%Issues Getting Home%' THEN 1 ELSE 0 END) as Getting_Home,
    SUM(CASE WHEN i.job_category LIKE '%Friendly Ear%' THEN 1 ELSE 0 END) Friendly_Ear,
    SUM(CASE WHEN i.job_category LIKE '%First Aid%' THEN 1 ELSE 0 END) First_Aid,
    SUM(CASE WHEN i.job_category LIKE '%Assault%' THEN 1 ELSE 0 END) as Assault,
    SUM(CASE WHEN i.job_category LIKE '%Sexual Assault%' THEN 1 ELSE 0 END) Sexual_Assault,
    SUM(CASE WHEN i.job_category LIKE '%Hate Crime%' THEN 1 ELSE 0 END) Hate_Crime,
    SUM(CASE WHEN i.job_category LIKE '%Domestic%' THEN 1 ELSE 0 END) as Domestic_Abu_Ass,
    -- TODO: misleading name
    SUM(CASE WHEN i.job_category LIKE '%Other%' THEN 1 ELSE 0 END) as Condition_Other,
    -- job_outcome
    -- Slightly odd name for "Left_on_Own_Taxi", as getting a taxi is another column
    SUM(CASE WHEN i.job_outcome LIKE '%Left on Own Accord%' THEN 1 ELSE 0 END) as Left_on_Own_Taxi,
    SUM(CASE WHEN i.job_outcome LIKE '%Home by SA%' THEN 1 ELSE 0 END) as Home_by_SA,
    SUM(CASE WHEN i.job_outcome LIKE '%Home by Family%' THEN 1 ELSE 0 END) as Home_by_Family,
    SUM(CASE WHEN i.job_outcome LIKE '%Home by Friend%' THEN 1 ELSE 0 END) as Home_by_Friend,
    SUM(CASE WHEN i.job_outcome LIKE '%Phone Charged%' THEN 1 ELSE 0 END) as Phone_Charged,
    SUM(CASE WHEN i.job_outcome LIKE '%Refused Treatment%' THEN 1 ELSE 0 END) as Refused_Treat,
    SUM(CASE WHEN i.job_outcome LIKE '%SAS to ERI%' OR i.job_outcome LIKE '%SAS to Edinburgh Royal Inf%' THEN 1 ELSE 0 END) as SAS_to_ERI,
    SUM(CASE WHEN i.job_outcome LIKE '%SA to ERI%' OR i.job_outcome LIKE '%SA to Edinburgh Royal Inf%' THEN 1 ELSE 0 END) as SA_to_ERI,
    SUM(CASE WHEN i.job_outcome LIKE '%Royal ED Hospital%' THEN 1 ELSE 0 END) as REH,
    SUM(CASE WHEN i.job_outcome LIKE '%Police Care%' THEN 1 ELSE 0 END) as Police_Care,
    SUM(CASE WHEN i.job_outcome LIKE '%Taxi home%' THEN 1 ELSE 0 END) as Taxi_Home,
    SUM(CASE WHEN i.job_outcome LIKE '%Taxi_to_ERI%' OR i.job_outcome LIKE '%Taxi to Edinburgh Royal Inf%' THEN 1 ELSE 0 END) as Taxi_to_ERI,
    SUM(CASE WHEN i.job_outcome LIKE '%Stood Down%' THEN 1 ELSE 0 END) as Stood_Down,
    SUM(CASE WHEN i.job_outcome LIKE '%Arrested%' THEN 1 ELSE 0 END) as Arrested,
    -- client_provisions
    -- TODO: Poor naming, but need to fix PowerBI too
    SUM(CASE WHEN i.client_provisions LIKE '%First Aid%' THEN 1 ELSE 0 END) as First_Aid_2,
    SUM(CASE WHEN i.client_provisions LIKE '%Phone Charge%' THEN 1 ELSE 0 END) as Phone_Charge_3,
    SUM(CASE WHEN i.client_provisions LIKE '%Safe Route Home%' THEN 1 ELSE 0 END) as Safe_Route_Home,
    SUM(CASE WHEN i.client_provisions LIKE '%Contact Family%' THEN 1 ELSE 0 END) as Contact_Family,
    SUM(CASE WHEN i.client_provisions LIKE '%Contact Friend%' THEN 1 ELSE 0 END) as Contact_Friend,
    SUM(CASE WHEN i.client_provisions LIKE '%Emotional Support%' THEN 1 ELSE 0 END) as Emotional_Support,
    SUM(CASE WHEN i.client_provisions LIKE '%Advice%' THEN 1 ELSE 0 END) as Advice,
    SUM(CASE WHEN i.client_provisions LIKE '%Shelter%' THEN 1 ELSE 0 END) as Shelter,
    SUM(CASE WHEN i.client_provisions LIKE '%Water%' THEN 1 ELSE 0 END) as Water_Tea,
    SUM(CASE WHEN i.client_provisions LIKE '%Other%' THEN 1 ELSE 0 END) as Provision_Other
    -- LIVE_REPORT_DATA_Outcome_Unknown ignored - never set
    -- LIVE_REPORT_DATA_Cuts ignored - never set
    -- LIVE_REPORT_DATA_Bruising ignored - never set
    -- LIVE_REPORT_DATA_Blood_Sugar ignored - never set
    -- LIVE_REPORT_DATA_First_Aid_ADV_ ignored - never set
    -- LIVE_REPORT_DATA_First_Aid_Other ignored - never set
    -- LIVE_REPORT_DATA_Geographic_Unknown ignored - never set
FROM dbo.inspectionview i
JOIN dbo.signincount s
  ON i.service_date = s.service_date
GROUP BY i.service_date;