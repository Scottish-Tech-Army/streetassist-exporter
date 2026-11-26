# Operations

*This tooling is intended just to run without needing human intervention; this is just to allow debugging, update and maintenance of an existing deployment.*

This document covers

- [updating the code](#updating-the-code);
- [running the job manually](#running-manually);
- [failure alerts](#failure-alerts);
- [viewing raw table data](#viewing-raw-table-data); and
- [restoring the database](#restoring-the-database).

## Updating the code

The job runs the image tag `IMAGE_TAG` set in your config file. Every release has its own tag, so earlier images stay in the registry for [rolling back](#rolling-back).

### Releasing

Set a new `IMAGE_TAG` in your config file (for example today's date, `20261126`, or `20261126-2` for a second release that day), then build, push and deploy.

~~~bash
. config/your_config_file.sh
bash scripts/build.sh
bash scripts/deploy.sh
~~~

Every `deploy.sh` run generates a new SQL admin password in Key Vault. The job reads it from there, but anything else using the old password (for example a saved connection) stops working.

`build.sh` refuses to build if the tag already exists in the registry, and stops with an error saying so. Choose a new tag; only if you really mean to reuse one, [delete it](#listing-and-deleting-image-tags) first.

### Rolling back

1. Set `IMAGE_TAG` in your config file to the earlier tag.

2. Deploy. Runs that start afterwards use it; a run already in progress is not affected.

   ~~~bash
   . config/your_config_file.sh
   bash scripts/deploy.sh
   ~~~

3. Run the job once (see [Running manually](#running-manually)) and confirm it succeeds. A mistyped tag only shows up when the job runs.

The next release needs a fresh tag, as in [Releasing](#releasing).

**If the release changed the database:** rolling back the image does not undo those changes. If the data is wrong, also restore the database (see [Restoring the database](#restoring-the-database)), and do not redeploy while a restore is in progress.

### Listing and deleting image tags

To list the tags and delete unused ones, you may either use the portal (find the registry, then select `Services/Repositories` to find them) or use the CLI as documented below.

- List the tags, newest first:

    ~~~bash
    . config/your_config_file.sh
    az acr repository show-tags -n ${REGISTRY} --repository exporter --orderby time_desc -o table
    ~~~

- Delete any unwanted tags, replacing `<tag>` with the tag name:

    ~~~bash
    az acr repository delete -n ${REGISTRY} --image exporter:<tag>
    ~~~

Deleting by tag removes the image itself, and so every tag on it. Do not delete the tag the job is running, or the one you would roll back to.

### Upgrading the exporter

Use this to apply a new Mitti exporter version that changes its table layout, or to recover when some of the exporter's tables are missing.

Before you start, you need access to the portal Query Editor (see [Viewing raw table data](#viewing-raw-table-data)), and no job may be running. Until the job succeeds the Power BI tables keep their old contents, so avoid doing this shortly before the morning refresh.

1. Drop the views that depend on the tables, then the four exporter tables. `IF EXISTS` makes each statement safe whether or not the object is still there.

   ~~~sql
   DROP VIEW IF EXISTS dbo.all_suf_view;
   DROP VIEW IF EXISTS dbo.nightly_view;
   DROP VIEW IF EXISTS dbo.signincount;
   DROP VIEW IF EXISTS dbo.signinview;
   DROP VIEW IF EXISTS dbo.welfarecheckview;
   DROP VIEW IF EXISTS dbo.observationview;
   DROP VIEW IF EXISTS dbo.inspectionview;
   DROP TABLE IF EXISTS dbo.inspections;
   DROP TABLE IF EXISTS dbo.inspection_items;
   DROP TABLE IF EXISTS dbo.templates;
   DROP TABLE IF EXISTS dbo.actions;
   ~~~

2. Reset the last run time, so that the next run exports everything (or drop `dbo.JobTimestamp`, which the job recreates).

   ~~~sql
   UPDATE dbo.JobTimestamp SET LastRunTime = '1900-01-01 00:00:00';
   ~~~

3. Run the job (see [Running manually](#running-manually)). It creates the tables and exports everything, which takes hours. The job then adds its indexes and extra columns and rebuilds the views, as in [data](data.md).

The upgrade worked when the job execution shows `SUCCESS` and the four tables have rows.

#### Why this is needed

The exporter creates or alters its tables (its "migration") only when `dbo.inspection_items` does not exist, because the migration fails on that table once `entry_point.sh` has indexed it. So the job never changes the layout of existing exporter tables, and a run fails if they no longer fit the new version. If only some of the tables are missing:

- `inspection_items` exists but another table is missing: nothing recreates it and the run fails.
- only `inspection_items` is missing: the migration runs against the other three and may fail on them.

## Running manually

Go to [the Azure portal](https://portal.azure.com).

- Select the resource group that has the tooling deployed.

- Select the Container Apps Job.

- In the `Overview` pane (selected from the left panel), click on `Run Now` at the top of the screen.

- To see how the run worked, select `Execution History` from within `Monitoring` on the left. That has links to the logs of the run.

## Failure alerts

The alert rule `exporter-run-failed` emails the recipients in the [alert action group](deploy.md#creating-the-alert-action-group) when a run fails. The alert fires in one of two cases:

- The job logged `FAILED: exit code N`. This is checked every 15 minutes, so the email arrives within about 30 minutes of the failure.
- The job has not logged `SUCCESS` for 26 hours, for example because it never started or timed out. This is a backstop, so the email can arrive about 26 hours after the last success.

One mail is sent when the alert fires, with subject "Alert 'Exporter run failed' was fired". Multiple consecutive failures only trigger a single mail unless the alert cleared in the meantime. When a later run succeeds the alert clears, usually within about 45 minutes of the success and at most about an hour, and a second email "Alert 'Exporter run failed' was resolved" is sent.

To investigate further, check the alert's state under `Monitor`, then `Alerts`, in the portal. Any failed run can be investigated by opening `Execution History` as in [Running manually](#running-manually) and reading the logs of the failed run.

To add or remove a recipient, open the action group under `Monitor`, then `Alerts`, then `Action groups`, and edit its email notifications.

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
- long-term backups: one each week, kept for 4 weeks, and the first weekly backup of each month, kept for 12 months. The first appears within about a week of the policy being applied.

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

Set `--time` to a UTC time within the last 35 days, before the damage happened (the time in the example must be edited). Anything written to the database after that time is not in the copy. The job's last recorded run time is stored in the database, so it rolls back too, and the next run re-exports everything changed in Mitti since then.

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

Do not redeploy the template to do this, and never redeploy between the two renames: with no `sqldb` present, the template would create a new, empty one.

Rename the damaged database aside, then rename the copy to `sqldb`, and check that `sqldb` exists.

~~~bash
az sql db rename -g ${RG} -s ${SQLSERVER} -n sqldb --new-name ${DAMAGED}
az sql db rename -g ${RG} -s ${SQLSERVER} -n ${RESTORED} --new-name sqldb
az sql db show -g ${RG} -s ${SQLSERVER} -n sqldb --query name -o tsv
~~~

Retention policies belong to a database, so the new `sqldb` has only the Azure defaults (7-day point-in-time retention, no long-term retention). Re-apply the settings from the retention resources in [`templates/deploy.bicep`](../templates/deploy.bicep), then check them:

~~~bash
az sql db str-policy set -g ${RG} -s ${SQLSERVER} -n sqldb --retention-days 35
az sql db ltr-policy set -g ${RG} -s ${SQLSERVER} -n sqldb --weekly-retention P4W --monthly-retention P12M
az sql db str-policy show -g ${RG} -s ${SQLSERVER} -n sqldb
az sql db ltr-policy show -g ${RG} -s ${SQLSERVER} -n sqldb
~~~

Run the job once (see [Running manually](#running-manually)) to confirm it succeeds against the restored data.

Long-term backups follow the database they were taken from. The new `sqldb` starts with none, so for about a week there is no long-term backup of it; the older long-term backups stay listed under the damaged database's name until they expire.

### Delete a database you no longer need

Keep the damaged database until you are sure the restored copy is good, then delete it. Its long-term backups remain until they expire, and a deleted database can still be restored from its point-in-time backups for 35 days.

~~~bash
az sql db delete -g ${RG} -s ${SQLSERVER} -n ${DAMAGED} --yes
~~~
