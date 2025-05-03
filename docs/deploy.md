# Deployment

## Initial deployment creation

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

- Add the field `accessToken` to the Azure key vault using the portal.

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

## Set up AAD permissions for SQL Server

Find the SQL Server database in the portal.

- Configure AAD access, with yourself as the admin as follows

    - On the left, click on `Microsoft Entra ID` under `Settings` to see the screen of Microsoft Entra options.

    - Ensure that the `Support only Microsoft Entra ID` option is *not* checked.

    - Click on `Set admin` at the top of the screen.

    - Select your own account, and click `Select`

    - Click `Save` at the top of the screen, so the change is not immediately forgotten.

- Set up users in the database as follows.

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
