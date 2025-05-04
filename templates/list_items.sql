-- sqlcmd -b -S ${SERVER} -d ${DB} -U ${ADMINUSER} -P ${ADMINPWD} -i ../exporter/templates/list_items.sql -s "," -W -o items.csv
SELECT
    i.template_id,
    t.name,
    i.item_id,
    i.label,
    i.response
FROM inspection_items i
JOIN templates t
  ON i.template_id = t.template_id
WHERE
    i.type = 'textsingle'
