CREATE OR ALTER VIEW dbo.AllDigitalSUF AS
SELECT
    i.audit_id,
    i.date as All_Digital_SUF_servicedelivery_date,
    MAX(i.age_range) as All_Digital_SUF_age_range,
    MAX(i.gender) as All_Digital_SUF_gender,
    MAX(i.nationality) as All_Digital_SUF_nationality,
    MAX(i.residency) as All_Digital_SUF_client_residency,
    MAX(i.where_do_they_study) as All_Digital_SUF_where_do_they_study,
    MAX(i.ambulance_requested) as All_Digital_SUF_was_ambulance_requested,
    MAX(i.ambulance_requested_how) as All_Digital_SUF_how_requested_ambulance,
    MAX(i.ambulance_requested_who) as All_Digital_SUF_who_requested_ambulance,
    MAX(i.ambulance_cancelled) as All_Digital_SUF_ambulance_cancelled,
    MAX(i.ambulance_cancelled_who) as All_Digital_SUF_who_cancelled_ambulance,
    MAX(i.police_involved) as All_Digital_SUF_was_police_involved,
    MAX(i.police_requested) as All_Digital_SUF_were_police_called,
    MAX(i.police_requested_how) as All_Digital_SUF_how_requested_police,
    MAX(i.police_requested_how) as All_Digital_SUF_how_requested_police_other,
    MAX(i.police_requested_who) as All_Digital_SUF_who_requested_police,
    MAX(i.police_requested_who) as All_Digital_SUF_who_requested_police_other,
    MAX(i.police_cancelled) as All_Digital_SUF_police_cancelled,
    MAX(i.police_cancelled_who) as All_Digital_SUF_who_cancelled_police
FROM inspectionview i
GROUP BY
    i.audit_id,
    i.date;
GO
