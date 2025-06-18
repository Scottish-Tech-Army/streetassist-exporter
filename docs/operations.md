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



