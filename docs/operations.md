# Operations

*This tooling is intended just to run without needing human intervention; this is just to allow debugging, update and maintenance of an existing deployment.*

## Updating the code

Roughly this goes like this.

~~~bash
. config/your_config_file.sh
bash scripts/build.sh
~~~

## Running manually

Go to [the Azure portal](https://portal.azure.com).

- Select the resource group that has the tooling deployed.

- Select the Container Apps Job.

- In the `Overview` pane (selected from the left panel), click on `Run Now` at the top of the screen.

- To see how the run worked, select `Execution History` from within `Monitoring` on the left. That has links to the logs of the run.

## Viewing raw table data

The raw table data can be viewed with any SQL viewer, but the easiest way to just look at it is through the [Azure Portal](https://portal.azure.com).

- Select the resource group that has the tooling deployed.

- Select the SQL database (NOT the SQL server; it's easy to get them confused).

- Click on the `Query Editor` option on the left hand side.

- When prompted to login, login with your `Microsoft Entra Authentication` and your identity, NOT with the admin password.

- Type SQL and be happy.

## Restoring the database

Use this to recover the SQL database `sqldb` after damage or a bad change.

The template keeps two kinds of backup:

- point-in-time backups for the last 35 days, restorable to any moment in that period;
- long-term backups: one each week, kept for 4 weeks, and the first of each month, kept for 12 months. The first appears within about a week of the policy being applied.

Restores always go to a **new** database on the same server; Azure SQL cannot restore over the live one. Restoring to a new name does not affect the live database, so it is safe at any time. To make the copy live, swap it in by renaming (see [Make the restored copy live](#make-the-restored-copy-live)).

### Set up variables

Log in with the right subscription selected, and run everything from the repository root. Source the config file in every shell you use.

~~~bash
. config/your_config_file.sh
SQLSERVER=$(az sql server list -g ${RG} --query "[0].name" -o tsv)
SQLLOCATION=$(az sql server show -g ${RG} -n ${SQLSERVER:?no SQL server found in ${RG}} --query location -o tsv)
RESTORED=sqldb-restored
DAMAGED=sqldb-damaged
echo "Server ${SQLSERVER} in ${SQLLOCATION}; restoring to ${RESTORED}"
~~~

`RESTORED` and `DAMAGED` must be names not already in use. If an earlier attempt left either database behind, delete it or choose another name.

### Restore to a point in time

Set `--time` to a UTC time within the last 35 days, before the damage happened. Anything written to the database after that time is not in the copy. The job's last recorded run time is stored in the database, so it rolls back too, and the next run re-exports everything changed in Mitti since then.

~~~bash
az sql db restore -g ${RG} -s ${SQLSERVER} -n sqldb \
    --dest-name ${RESTORED} --time "2026-11-24T12:00:00Z"
~~~

The command finishes when the copy is ready. Check it by running a query against it in the portal Query Editor (see [Viewing raw table data](#viewing-raw-table-data)).

### Restore from a long-term backup

Use this when the damage is older than 35 days. List the long-term backups, choose one, and restore it using its `id`. If the list is empty, no long-term backup has been taken yet; use a point-in-time restore instead.

~~~bash
az sql db ltr-backup list --location ${SQLLOCATION} --server ${SQLSERVER} \
    --database sqldb --query "[].{id:id, time:backupTime}" -o table
BACKUP_ID=<id from the list>
az sql db ltr-backup restore --backup-id "${BACKUP_ID}" \
    --dest-database ${RESTORED} --dest-server ${SQLSERVER} \
    --dest-resource-group ${RG}
~~~

### Make the restored copy live

The job and Power BI use the database name `sqldb`, so the swap needs no other changes. Do it when the job is not running and away from the morning refresh: the job runs at 06:00 UTC and Power BI refreshes at 08:00 (see [Updating Power BI reports](deploy.md#updating-power-bi-reports)), so avoid roughly 05:30 to 09:00.

Rename the damaged database aside, then rename the copy to `sqldb`.

~~~bash
az sql db rename -g ${RG} -s ${SQLSERVER} -n sqldb --new-name ${DAMAGED}
az sql db rename -g ${RG} -s ${SQLSERVER} -n ${RESTORED} --new-name sqldb
~~~

Retention policies belong to a database, so the new `sqldb` has only the Azure defaults (7-day point-in-time retention, no long-term retention). Re-apply the template's settings and check them:

~~~bash
az sql db str-policy set -g ${RG} -s ${SQLSERVER} -n sqldb --retention-days 35
az sql db ltr-policy set -g ${RG} -s ${SQLSERVER} -n sqldb --weekly-retention P4W --monthly-retention P12M
az sql db str-policy show -g ${RG} -s ${SQLSERVER} -n sqldb
az sql db ltr-policy show -g ${RG} -s ${SQLSERVER} -n sqldb
~~~

Do not redeploy the template to do this, and never redeploy between the two renames: with no `sqldb` present, the template would create a new, empty one.

Long-term backups follow the database they were taken from. The new `sqldb` starts with none, so for about a week there is no long-term backup of it; the older long-term backups stay listed under the damaged database's name until they expire.

Run the job once (see [Running manually](#running-manually)) to confirm it succeeds against the restored data.

### Delete a database you no longer need

Keep the damaged database until you are sure the restored copy is good, then delete it. Its long-term backups remain until they expire, and a deleted database can still be restored from its point-in-time backups for 35 days.

~~~bash
az sql db delete -g ${RG} -s ${SQLSERVER} -n ${DAMAGED} --yes
~~~
