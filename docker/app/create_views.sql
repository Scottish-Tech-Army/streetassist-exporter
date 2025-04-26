CREATE OR ALTER VIEW dbo.inspectionview AS
SELECT
    i.audit_id,
    i.template_name,
    MAX(CASE WHEN ii.question = 'question1' THEN ii.response END) AS response1,
    MAX(CASE WHEN ii.question = 'question2' THEN ii.response END) AS response2,
    MAX(CASE WHEN ii.question = 'question3' THEN ii.response END) AS response3
FROM inspections i
JOIN inspection_items ii
  ON i.audit_id = ii.audit_id
GROUP BY
    i.audit_id,
    i.template_name;
GO
