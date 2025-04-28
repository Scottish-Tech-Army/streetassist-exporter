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
    # Wait a moment to ensure all logs flush
    sleep 1
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
python load_data.py

# Write the timestamp when last run.
echo "Write out the time of this run"
SQLCMD=$(cat write_lasttime.sql | sed "s/THISRUN/${THISRUN}/g")
echo "    SQL command: \"${SQLCMD}\""
sqlcmd -b -S ${SERVER} -d ${DB} -U ${ADMINUSER} -P ${ADMINPWD} -Q "${SQLCMD}"

# Create the views.
echo "Create views"
echo "    Main views"
sqlcmd -b -S ${SERVER} -d ${DB} -U ${ADMINUSER} -P ${ADMINPWD} -i create_views.sql

echo "    Power BI source views"
sqlcmd -b -S ${SERVER} -d ${DB} -U ${ADMINUSER} -P ${ADMINPWD} -i create_powerbi_views.sql

echo "SUCCESS"
