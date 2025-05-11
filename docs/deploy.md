# Deployment and management

## Initial deployment creation

### Prerequisites

*TODO: Azure subscription, access key to Safety Culture*

### Setting up resources in Azure

Follow the following steps.

- Set up a config file. *TODO: document with an example.*


    Before running any of the bash commands, you should source this config file.

    ~~~bash
    . config/my_config_file.sh
    ~~~

- Ensure that you have created an Azure subscription to use, and that you are logged into Azure, defaulting to that subscription.

    ~~~bash
    az login --use-device-code
    az account show
    ~~~

    If necessary, you can log in using a different account, or use `az account set` to reset which subscription is in use.

- Run the deploy script.

    ~~~bash
    bash scripts/deploy.sh
    ~~~

    This will fail because the container apps job (rather tediously) refuses to create until the image is uploaded. Ignore this initial error.

    *TODO: we should do better here, but this is not blocking anything for now.*

- Build and push the container image, then redeploy. This should succeed

    ~~~bash
    bash scripts/build.sh
    bash scripts/deploy.sh
    ~~~

### Setting the access token

This process needs to be performed whenever your access token expires, and involves adding the field `accessToken` to the Azure key vault using the portal.

- Go to the [Azure portal](portal.azure.com).

- Find the key vault and click on it.

- Select `Access policies` from the left hand pane to create an access policy allowing you access to secrets in the key vault.

    - Select `Create`

    - In the `Permissions` screen, `Select all` under `Secret permissions`, and click the `Next` button

    - In the `Principal` screen, search for your own account, and click it, then click the `Next` button

    - Ignore the `Application` screen, select nothing and click the `Next` button

    - Finally, click the `Create` button

- Select `Objects` from the left hand pane to create the secret.

    - Select `Secrets`

    - Click `Generate/Import`

    - Enter `accessToken` as the name

    - Enter your API token for Safety Culture as the `Secret value`

    - Click the `Create` button

### Uploading data files

*TODO: To be provided - just document the portal steps, for the files.*

- `places.csv`

## Set up AAD permissions for SQL Server

This must be done before users can actually use the provisioned data.

### Enable admin access

This process sets yourself up as the Entra managed admin for the SQL Server Database. It only needs to be done once, unless the admin leaves and needs to be replaced.

To do this, find the SQL Server database in the portal.

- Configure AAD access, with yourself as the admin as follows

    - On the left, click on `Microsoft Entra ID` under `Settings` to see the screen of Microsoft Entra options.

    - Ensure that the `Support only Microsoft Entra ID` option is *not* checked.

    - Click on `Set admin` at the top of the screen.

    - Select your own account, and click `Select`

    - Click `Save` at the top of the screen, so the change is not immediately forgotten.

### Set up users and groups to have read rights to the data

This must be done to allow individual users to run Power BI reports, and involves entering either their IDs or the ID of a security group they are a member of into the portal.

- Click on `SQL databases` under `Settings` of the SQL Server instance.

- Click on the `sqldb` database.

- Click on `Query Editor`

- Do not enter a password; you should click the `Continue as yourmail@yourdomain` button.

- Enter the following for each user you wish to grant rights, assuming that their email is `user@domain`.

    ```sql
    CREATE USER [user@domain] FROM EXTERNAL PROVIDER;
    ALTER ROLE db_datareader ADD MEMBER [user@domain];
    ```

- If you want to grant permissions to a security group, then create a security group in the Entra admin centre, and then do

    ```sql
    CREATE USER [SecurityGroupName] FROM EXTERNAL PROVIDER;
    ALTER ROLE db_datareader ADD MEMBER [SecurityGroupName];
    ```
