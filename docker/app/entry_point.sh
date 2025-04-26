#!/bin/bash
# Set up initial deployment.
set -euo pipefail

if [[ -z "${API_TOKEN:-}" ]]; then
    echo "Error: Environment variable API_TOKEN is not set." >&2
    exit 1
fi

if [[ -z "${CONNECTION:-}" ]]; then
    echo "Error: Environment variable CONNECTION is not set." >&2
    exit 1
fi

# Read the timestamp when last run; the -h -1 suppresses headers, and the create is in case the table does not exist.
echo "Checking previous run times"
sqlcmd -S ${SERVER} -d ${DB} -U ${ADMINUSER} -P ${ADMINPWD} -i create_lasttime.sql
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
sqlcmd -S ${SERVER} -d ${DB} -U ${ADMINUSER} -P ${ADMINPWD} -Q "${SQLCMD}"

# Create the views.
echo "Create views"
#sqlcmd -S ${SERVER} -d ${DB} -U ${ADMINUSER} -P ${ADMINPWD} -i create_views.sql

echo "SUCCESS"
