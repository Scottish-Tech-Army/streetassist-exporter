# Deployment

Roughly as follows.

- Set up a config file.

- Run the deploy script.

    ~~~bash
    bash scripts/deploy.sh
    ~~~

- Build and push the container image

    ~~~bash
    bash scripts/build.sh
    ~~~

- Add the field `accessToken` to the Azure key vault.

- Run the container image to get all the data for an initial run, including setting up views

    ~~~bash
    az containerapp job run
    ~~~

## Configuring SQL Server DB

- Enable AAD in the portal, and set up groups appropriately

