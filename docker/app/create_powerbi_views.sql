--
CREATE OR ALTER VIEW dbo.AllDigitalSUF AS
SELECT
    i.audit_id,
    i.date as All_Digital_SUF_servicedelivery_date,
    i.age_range as All_Digital_SUF_age_range,
    i.gender as All_Digital_SUF_gender,
    i.nationality as All_Digital_SUF_nationality,
    i.residency as All_Digital_SUF_client_residency,
    i.where_do_they_study as All_Digital_SUF_where_do_they_study,
    i.ambulance_requested as All_Digital_SUF_was_ambulance_requested,
    i.ambulance_requested_how as All_Digital_SUF_how_requested_ambulance,
    i.ambulance_requested_who as All_Digital_SUF_who_requested_ambulance,
    i.ambulance_cancelled as All_Digital_SUF_ambulance_cancelled,
    i.ambulance_cancelled_who as All_Digital_SUF_who_cancelled_ambulance,
    i.police_involved as All_Digital_SUF_was_police_involved,
    i.police_requested as All_Digital_SUF_were_police_called,
    i.police_requested_how as All_Digital_SUF_how_requested_police,
    -- i.police_requested_how as All_Digital_SUF_how_requested_police_other,
    i.police_requested_who as All_Digital_SUF_who_requested_police
    -- i.police_requested_who as All_Digital_SUF_who_requested_police_other
    -- MAX(i.police_cancelled) as All_Digital_SUF_police_cancelled,
    -- MAX(i.police_cancelled_who) as All_Digital_SUF_who_cancelled_police
FROM inspectionview i
GO

CREATE OR ALTER VIEW dbo.WelfareChecks AS
SELECT
    i.audit_id as WelfareChecks_auditID,
    i.date as WelfareChecks_Conducted,
    i.gender as WelfareChecks_Gender,
    i.location as WelfareChecks_Location,
    i.check_type as WelfareChecks_Type
FROM welfarecheckview i
GO