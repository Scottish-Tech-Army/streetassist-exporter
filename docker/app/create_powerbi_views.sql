--
CREATE OR ALTER VIEW dbo.AllDigitalSUF
WITH SCHEMABINDING
AS
SELECT
    i.audit_id,
    TRY_CONVERT(DATE, i.conducted_at) as servicedelivery_date,
    FORMAT(TRY_CONVERT(DATE, i.conducted_at), 'ddd', 'en-US') AS Weekday,
    i.volunteer_creating_form as volunteer_creating_form,
    i.form_id as SUF_form_id,
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
    -- i.police_requested_how as how_requested_police_other,
    i.police_requested_who as who_requested_police
    -- i.police_requested_who as who_requested_police_other
    -- MAX(i.police_cancelled) as police_cancelled,
    -- MAX(i.police_cancelled_who) as who_cancelled_police
FROM dbo.inspectionview i
GO

CREATE OR ALTER VIEW dbo.WelfareChecks
WITH SCHEMABINDING
AS
SELECT
    i.audit_id as auditID,
    CONVERT(DATE, i.date_started) as Conducted,
    i.gender as Gender,
    i.location as Location,
    i.check_type as Type
FROM dbo.welfarecheckview i
GO