-- sqlcmd -b -S ${SERVER} -d ${DB} -U ${ADMINUSER} -P ${ADMINPWD} -i create_views.sql
-- Clear out the views that depend on this one; needed as they have schemabinding (i.e. are materialised)
DROP VIEW IF EXISTS dbo.AllDigitalSUF;
GO
DROP VIEW IF EXISTS dbo.SummaryView;
GO
DROP VIEW IF EXISTS dbo.signincount;
GO

-- General inspection view
CREATE OR ALTER VIEW dbo.inspectionview
WITH SCHEMABINDING
AS
SELECT
    i.audit_id2 AS audit_id,
    i.template_id2 AS template_id,
    i.template_name2 AS template_name,
    i.conducted_on2 AS conducted_on,
    i.service_date as service_date,
    i.date_started2 as date_started,
    i.date_completed2 as date_completed,
    MAX(CASE WHEN ii.item_id = '4022292f-ada2-4380-99d9-affd0da8c342' AND ii.type = 'question' THEN ii.response END) AS ambulance_requested,
    MAX(CASE WHEN ii.item_id = 'dbe1e0fd-29c7-4e19-b649-d22f914cffdc' AND ii.type = 'question' THEN ii.response END) AS ambulance_cancelled,
    MAX(CASE WHEN ii.item_id = 'b6d83695-890b-4b83-b044-3752f54a6ba6' AND ii.type = 'question' THEN ii.response END) AS alcohol_consumed,
    MAX(CASE WHEN
        ((ii.item_id = '27d0c021-90ac-41df-995c-5627cb6c30de' and ii.label LIKE '%requested%') OR
         (ii.item_id = '2d8cf6fd-4214-4eb3-af1b-4aba9fd2f338')) AND ii.type = 'question'
        THEN ii.response END) AS police_requested,
    -- Annoyingly, this item can be either "injuries or observations" followed up by 6b2dd713-e040-4322-886e-c421fbd38de7
    -- or else just "injuries". Need to figure out how to distinguish the two. xxx
    MAX(CASE WHEN ii.item_id = '0286c9b4-d8de-4c46-a624-e52a3a8fcc32' AND ii.type = 'question' THEN ii.response END) AS injuries,
    MAX(CASE WHEN ii.item_id = '0fe1fbb6-4eb1-4b8c-bdd3-8d9700f79ee2' AND ii.type = 'question' THEN ii.response END) AS observations,
    MAX(CASE WHEN ii.item_id = '1cc7a1f8-7d73-42c6-9978-e2fb28c0085c' AND ii.type = 'question' THEN ii.response END) AS residency,
    MAX(CASE WHEN ii.item_id = '2450001f-00ef-4cfe-bb35-8d7cf8df3574' AND ii.type = 'question' THEN ii.response END) AS drugs_consumed,
    MAX(CASE WHEN ii.item_id = 'e5bcd037-e4d7-44ce-8c6e-932de7becd97' AND ii.type = 'question' THEN ii.response END) AS found_alone,
    MAX(CASE WHEN ii.item_id = '27d0c021-90ac-41df-995c-5627cb6c30de' AND ii.type = 'question' THEN ii.response END) AS police_involved,
    MAX(CASE WHEN ii.item_id = '61dbd6c2-276c-44b5-8b15-3f1ddcff5bc2' AND (ii.type = 'question' OR ii.type = 'list') THEN ii.response END) AS ambulance_requested_how,
    MAX(CASE WHEN ii.item_id = '9891b13a-72a7-46bb-95f5-4fec9ecfca46' AND ii.type = 'list' THEN ii.response END) AS involvement_type,
    MAX(CASE WHEN (ii.item_id = '312f86c5-e628-45b7-aa8f-27aae6c2b6dd' OR ii.item_id = '8b3e1a03-b88e-4802-a852-d104f820851e') AND ii.type = 'list' THEN ii.response END) AS age_range,
    MAX(CASE WHEN (ii.item_id = '4d077523-4ee8-4f82-8031-ba2e8a7e0e8a' OR ii.item_id = '5bbf70ac-7433-49b7-9536-e67e7e859c15') AND ii.type = 'list' THEN ii.response END) AS volunteer_creating_form,
    MAX(CASE WHEN (ii.item_id = '467b7d9d-0419-44e0-9f34-7eb485728558' AND ii.type = 'question') OR (ii.item_id = '47a69179-4441-4708-b674-f8cc4c7be8d8' AND ii.type = 'list')  THEN ii.response END) AS gender,
    MAX(CASE WHEN ii.item_id = 'bce12607-00bc-4e26-a40b-d2d3aec84920' AND ii.type = 'list' THEN ii.response END) AS job_category,
    MAX(CASE WHEN ii.item_id = 'b9c94de8-b8ea-4a13-a618-0b9f97945c08' AND ii.type = 'list' THEN ii.response END) AS job_outcome,
    MAX(CASE WHEN (ii.item_id = '6ee84dfe-7b59-4989-a9fe-486b50e82bc2' OR ii.item_id = 'b11a1d3b-cf78-4ef7-b08e-cf54a2e4b41c') AND ii.type = 'list' THEN ii.response END) AS job_location,
    MAX(CASE WHEN (ii.item_id = '076c1f85-1c3e-4eba-8fa5-f46e850eb60e' OR ii.item_id = 'ca980823-c858-49de-90a2-b18933ef3383') AND ii.type = 'list' THEN ii.response END) AS nationality,
    MAX(CASE WHEN ii.item_id = '4d2dbd66-b3f4-4580-8a77-ebfbba9f05b8' AND ii.type = 'list' THEN ii.response END) AS ambulance_requested_who,
    MAX(CASE WHEN ii.item_id = '07b963a3-f99d-4e7d-a450-bd8ad6f2c7fe' AND ii.type = 'list' THEN ii.response END) AS ambulance_cancelled_who,
    MAX(CASE WHEN ii.item_id = 'e0b498fc-9366-4e3f-8a5f-7c25cc44672c' AND ii.type = 'list' THEN ii.response END) AS police_requested_how,
    MAX(CASE WHEN ii.item_id = 'a715f8b1-8f82-48ee-9761-528f5174c262' AND ii.type = 'list' THEN ii.response END) AS police_requested_who,
    MAX(CASE WHEN ii.item_id = 'e1e61792-909b-4633-a762-64e9f48b3640' AND ii.type = 'list' THEN ii.response END) AS where_do_they_study,
    MAX(CASE WHEN ii.item_id = 'dfd6f2e3-c9a6-419c-8692-6ee200e637ef' AND ii.type = 'list' THEN ii.response END) AS referred_by,
    MAX(CASE WHEN ii.item_id = '020249e7-f1b0-4283-b125-d18a7b2e3cdb' AND ii.type = 'list' THEN ii.response END) AS client_provisions,
    MAX(CASE WHEN ii.item_id = 'f3245d46-ea77-11e1-aff1-0800200c9a66' AND ii.type = 'textsingle' THEN ii.response END) AS form_id,
    MAX(CASE WHEN ii.item_id = '2ee02c31-bc20-45db-b421-1cbe707ed6a1'  AND ii.type = 'textsingle' THEN ISNULL(TRY_CAST(ii.response AS INT), 0) END) AS total_job_minutes
    -- MAX(CASE WHEN ii.label = 'Who Cancelled?' THEN ii.response END) AS police_cancelled_who, -- xxx
    -- MAX(CASE WHEN ii.label = 'Cancelled' THEN ii.response END) AS police_cancelled -- xxx
FROM dbo.inspections i
JOIN dbo.inspection_items ii
  ON i.audit_id2 = ii.audit_id
WHERE
    i.template_id2 IN ('template_f932e4e812f94947bddf5dffb1281a5b',
                       'template_ec8be5ac5155466a8a470e6f522f7a9b',
                       'template_9e66d01183b745df90aff675e0614c21',
                       'template_6c980e38b5c443118f26b204d347ed0a',
                       'template_8402a70b460948d187bd4d60f1a4ddf5',
                       'template_402fb4b8ff7745bea1e1cdfd54f8c898')
    AND
    ii.type in ('list', 'question', 'textsingle')
GROUP BY
    i.audit_id2,
    i.template_id2,
    i.template_name2,
    i.conducted_on2,
    i.service_date,
    i.date_started2,
    i.date_completed2;
GO

-- Welfare check specific view
CREATE OR ALTER VIEW dbo.welfarecheckview
WITH SCHEMABINDING
AS
SELECT
    i.audit_id2 as audit_id,
    i.template_id2 as template_id,
    i.template_name2 as template_name,
    i.conducted_on2 as conducted_on,
    i.service_date as service_date,
    MAX(CASE WHEN ii.item_id = '7bbfd9b0-9e8b-4571-84fe-b0abc84bf7b1' AND ii.type = 'question' THEN ii.response END) AS gender,
    MAX(CASE WHEN ii.item_id = 'b11a1d3b-cf78-4ef7-b08e-cf54a2e4b41c' AND ii.type = 'list' THEN ii.response END) AS location,
    MAX(CASE WHEN ii.item_id = '30b9229d-557b-468c-8a0c-141385a46946' AND ii.type = 'list' THEN ii.response END) AS check_type
FROM dbo.inspections i
JOIN dbo.inspection_items ii
  ON i.audit_id2 = ii.audit_id
WHERE
    i.template_id2 = 'template_b68037b3adca46d894a2e155032720f7' AND
    (ii.type = "list" OR ii.type = "question")
GROUP BY
    i.audit_id2,
    i.template_id2,
    i.template_name2,
    i.conducted_on2,
    i.service_date;
GO

-- Sign in form data
-- TODO: This only goes back to 2022-08, while the inspection data goes back further
CREATE OR ALTER VIEW dbo.signinview
WITH SCHEMABINDING
AS
SELECT
    i.conducted_on2 as conducted_on,
    i.service_date as service_date,
    MAX(ii.response) AS volunteer_name
FROM dbo.inspections i
JOIN dbo.inspection_items ii
  ON i.audit_id2 = ii.audit_id
WHERE
    ii.item_id  = '922d3c68-6f2e-4fa1-a851-362d25177205' AND ii.type = 'list' AND
    i.template_id2 = 'template_3c0c0ff6769c4d8c853cfae8f62b7caf'
GROUP BY
    i.conducted_on2,
    i.service_date;
GO

CREATE OR ALTER VIEW dbo.signincount
WITH SCHEMABINDING
AS
SELECT
    service_date,
    COUNT_BIG(*) AS volunteer_count,
    COUNT_BIG(*) * 7 AS volunteer_hours, -- assume 7 hours per night per volunteer
    CAST(COUNT_BIG(*) * 7 * 8.75 AS DECIMAL(10,2)) AS volunteer_real_living_wage, -- Cost of those hours at 8.75 real living wage
    CAST(COUNT_BIG(*) * 7 * 7.50 AS DECIMAL(10,2)) AS volunteer_national_living_wage -- Cost of those hours at 7.50 national living wage
FROM dbo.signinview
GROUP BY service_date;
GO
