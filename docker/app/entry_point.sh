#!/bin/bash
# Set up initial deployment.
set -euo pipefail

echo "SERVER: ${SERVER}"
echo "DB: ${DB}"
echo "ADMINUSER: ${ADMINUSER}"
echo "SERVER: ${SERVER}"

# This function will be triggered whenever a command exits with a non-zero status.
error_handler() {
    local exit_code="$?"
    echo "Error occurred at line ${BASH_LINENO[0]}: command '${BASH_COMMAND}' exited with code ${exit_code}" >&2

    # Wait a couple of seconds to give logs time to flush
    sleep 2
    exit "${exit_code}"
}

# Trap any error
trap error_handler ERR

echo "Entry point running"

if [[ -z "${API_TOKEN:-}" ]]; then
    echo "Environment variable API_TOKEN not set - read from key vault ${KEYVAULTNAME} using ID ${UAMI_CLIENT_ID}"

    # For the mad workaround, there is this reference: https://github.com/Azure/azure-cli/issues/22677
    export APPSETTING_WEBSITE_SITE_NAME=DUMMY
    az login --identity --client-id ${UAMI_CLIENT_ID}

    # Fetch the secret value; replace <YourKeyVaultName> with the actual Key Vault name.
    echo "Get the access token"
    export API_TOKEN=$(az keyvault secret show --vault-name ${KEYVAULTNAME} --name accessToken --query value -o tsv)
    echo "Get the SQL server admin password"
    export ADMINPWD=$(az keyvault secret show --vault-name ${KEYVAULTNAME} --name sqlAdminPassword --query value -o tsv)
fi

export CONNECTION="sqlserver://${ADMINUSER}:${ADMINPWD}@${SERVER}:1433?database=${DB}"

# Read the timestamp when last run; the -h -1 suppresses headers, and the create is in case the table does not exist.
echo "Checking previous run times"
sqlcmd -b -S ${SERVER} -d ${DB} -U ${ADMINUSER} -P ${ADMINPWD} -i create_lasttime.sql
export LASTRUN=$(sqlcmd -S ${SERVER} -d ${DB} -U ${ADMINUSER} -P ${ADMINPWD} -h -1 -i read_lasttime.sql)
export THISRUN=$(date -u +"%Y-%m-%d %H:%M:%S")
echo "    Last run time: ${LASTRUN}"
echo "    This run time: ${THISRUN}"

# Do the export
echo "Run the export tool"
python export_data.py

# Write the timestamp when last run, as the export succeeded.
echo "Write out the time of this run"
SQLCMD="UPDATE dbo.JobTimestamp SET LastRunTime = '${THISRUN}';"
echo "    SQL command: \"${SQLCMD}\""
sqlcmd -b -S ${SERVER} -d ${DB} -U ${ADMINUSER} -P ${ADMINPWD} -Q "${SQLCMD}"

echo "Update tables including removal of PII and setting up of bulk import tables"
sqlcmd -b -S ${SERVER} -d ${DB} -U ${ADMINUSER} -P ${ADMINPWD} -i update_tables.sql

echo "Bulk import the manually uploaded data."
python load_csv.py

# Create duplicates of some columns. This is because we want to index them and use them in views.
# However, the exporter modifies the table definition, causing a failure of the exporter.
# We therefore create a duplicate of template_id called (imaginatively) template_id2,
# copy the data across each time the exporter completes, and use template_id2
# in our indices and views, and similarly with other fields.
#
# Quite why this is only needed for the inspections table is not all that clear, but it seems to
# be the case.
echo "Set up duplicate columns in inspections"
for i in "template_id" "template_name" "audit_id" "date_started" "date_completed" "conducted_on"
do
    echo "  Duplicate ${i}"
    SQLCMD="IF NOT EXISTS (
                SELECT 1
                FROM sys.columns
                WHERE object_id = OBJECT_ID(N'dbo.inspections')
                AND name = '${i}2'
            )
            BEGIN
                ALTER TABLE dbo.inspections
                    ADD ${i}2 NVARCHAR(255) NULL;
            END;
            GO

            UPDATE dbo.inspections
            SET ${i}2 = ${i}
            WHERE ${i}2 IS NULL;"
    echo $SQLCMD
    sqlcmd -b -S ${SERVER} -d ${DB} -U ${ADMINUSER} -P ${ADMINPWD} -Q "${SQLCMD}"
done

# Index everything; very slow when first run
# Would like to index "template_name", but it is arbitrary length, so SQL says no.
echo "Create indices for inspections"
for i in "date_started2" "audit_id2" "template_id2" "service_date" "conducted_on2"
do
    echo "  ${i} in inspections"
    SQLCMD="IF NOT EXISTS (
        SELECT 1
        FROM sys.indexes
        WHERE name = 'IX_Inspections_${i}' AND object_id = OBJECT_ID('dbo.inspections')
    )
    BEGIN
        CREATE INDEX IX_Inspections_${i}
        ON dbo.inspections (${i});
    END;"

    sqlcmd -b -S ${SERVER} -d ${DB} -U ${ADMINUSER} -P ${ADMINPWD} -Q "${SQLCMD}"
done

# Would like to index "template_id", but that causes issues with the exporter.
echo "Create indices for inspection_items"
for i in "item_id" "audit_id" "type"
do
    echo "  ${i} in inspection_items"
    SQLCMD="IF NOT EXISTS (
        SELECT 1
        FROM sys.indexes
        WHERE name = 'IX_InspectionItems_${i}' AND object_id = OBJECT_ID('dbo.inspection_items')
    )
    BEGIN
        CREATE INDEX IX_InspectionItems_${i}
        ON dbo.inspection_items (${i});
    END;"

    sqlcmd -b -S ${SERVER} -d ${DB} -U ${ADMINUSER} -P ${ADMINPWD} -Q "${SQLCMD}"
done

# An index intended to make the joins quick
echo "  composite join index"
SQLCMD="IF NOT EXISTS (
            SELECT 1
            FROM sys.indexes
            WHERE name = 'IX_inspection_items_AuditTypeItem'
        )
        BEGIN
            CREATE INDEX IX_inspection_items_AuditTypeItem
            ON inspection_items (audit_id, type, item_id)
            INCLUDE (response, label);
        END;"

sqlcmd -b -S ${SERVER} -d ${DB} -U ${ADMINUSER} -P ${ADMINPWD} -Q "${SQLCMD}"

# A join index for the summary
echo "  summary index"
SQLCMD="IF NOT EXISTS (
            SELECT 1
            FROM sys.indexes
            WHERE name = 'IX_inspections_service_date'
        )
        BEGIN
            CREATE UNIQUE CLUSTERED INDEX IX_inspections_service_date
            ON inspections (service_date);
        END;"

sqlcmd -b -S ${SERVER} -d ${DB} -U ${ADMINUSER} -P ${ADMINPWD} -Q "${SQLCMD}"

# Create the views.
echo "Create views"
echo "    Primary views"
sqlcmd -b -S ${SERVER} -d ${DB} -U ${ADMINUSER} -P ${ADMINPWD} -i create_primary_views.sql

echo "    Secondary views"
sqlcmd -b -S ${SERVER} -d ${DB} -U ${ADMINUSER} -P ${ADMINPWD} -i create_secondary_views.sql

# Turning views into tables is necessary to ensure that we can combine historic and live data.
echo "    Power BI source tables for inspections"
sqlcmd -b -S ${SERVER} -d ${DB} -U ${ADMINUSER} -P ${ADMINPWD} -i create_powerbi_tables.sql

# This could be combined with the above, but for debuggability of scripts it turns out better to split them.
echo "    Power BI source tables for nightly data"
sqlcmd -b -S ${SERVER} -d ${DB} -U ${ADMINUSER} -P ${ADMINPWD} -i create_powerbi_nightly.sql

echo "SUCCESS"
