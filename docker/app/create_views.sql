CREATE OR ALTER VIEW dbo.inspectionview AS
SELECT
    i.audit_id,
    i.template_name,
    i.date_started as date,
    MAX(CASE WHEN ii.label = 'Age Range' THEN ii.response END) AS age_range,
    MAX(CASE WHEN LOWER(ii.label) LIKE '%gender%' THEN ii.response END) AS gender,
    MAX(CASE WHEN ii.label = 'Nationality' THEN ii.response END) AS nationality,
    MAX(CASE WHEN LOWER(ii.label) LIKE '%residency%' THEN ii.response END) AS residency,
    MAX(CASE WHEN LOWER(ii.label) LIKE '%where do they study%' THEN ii.response END) AS where_do_they_study,
    MAX(CASE WHEN LOWER(ii.label) LIKE '%was ambulance requested%' THEN ii.response END) AS ambulance_requested,
    MAX(CASE WHEN LOWER(ii.label) LIKE '%how ambulance requested%' THEN ii.response END) AS ambulance_requested_how,
    MAX(CASE WHEN LOWER(ii.label) LIKE '%who requested ambulance%' THEN ii.response END) AS ambulance_requested_who,
    MAX(CASE WHEN ii.label = 'Ambulance Cancelled' THEN ii.response END) AS ambulance_cancelled,
    MAX(CASE WHEN ii.label = 'Who Cancelled?' THEN ii.response END) AS ambulance_cancelled_who,
    MAX(CASE WHEN LOWER(ii.label) LIKE '%was police involved%' THEN ii.response END) AS police_involved,
    MAX(CASE WHEN LOWER(ii.label) LIKE '%was police requested%' THEN ii.response END) AS police_requested,
    MAX(CASE WHEN ii.label = 'xxx Who Requested?' THEN ii.response END) AS police_requested_who, -- xxx unclear if correct
    MAX(CASE WHEN ii.label = 'xxx Who Requested?' THEN ii.response END) AS police_requested_how,
    MAX(CASE WHEN ii.label = 'Who Cancelled?' THEN ii.response END) AS police_cancelled_who, -- xxx same as for ambulance?
    MAX(CASE WHEN ii.label = 'Cancelled' THEN ii.response END) AS police_cancelled
FROM inspections i
JOIN inspection_items ii
  ON i.audit_id = ii.audit_id
WHERE
    i.template_name LIKE '%Service User Form%' OR i.template_name LIKE '%Welfare Check%'
GROUP BY
    i.audit_id,
    i.template_name,
    i.date_started;
GO
