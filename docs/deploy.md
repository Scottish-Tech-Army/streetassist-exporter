# Deployment

Roughly as follows.

- Set up a config file.

- Run the deploy script.

    ~~~bash
    bash scripts/deploy.sh
    ~~~

- Do something with the password, and store it in the AKV

    *Details TBD - actually better to create AKV, generate a random value there, and then pass links to the deployment*

    ~~~bicep
    @secure()
    param adminPassword string = newGuid() // Generate a random string for the password

    resource keyVault 'Microsoft.KeyVault/vaults@2022-11-01' = {
    name: 'myKeyVault'
    location: 'West Europe'
    properties: {
        sku: {
        name: 'standard'
        }
        tenantId: subscription().tenantId
        accessPolicies: [
        {
            objectId: tenant().objectId // Replace with appropriate object ID
            permissions: {
            secrets: ['get', 'list', 'set']
            }
        }
        ]
    }
    }

    resource keyVaultSecret 'Microsoft.KeyVault/vaults/secrets@2022-11-01' = {
    parent: keyVault
    name: 'sqlAdminPassword'
    properties: {
        value: adminPassword
    }
    }

    resource sqlServer 'Microsoft.Sql/servers@2022-11-01' = {
    name: 'mySqlServer'
    location: 'West Europe'
    properties: {
        administratorLogin: 'adminUser'
        administratorLoginPassword: adminPassword
        version: '12.0'
    }
    }

    output sqlServerAdminPasswordSecretUri string = keyVaultSecret.properties.id // Output URI for reference
    ~~~

- Build and push the container image

- Run the container image to get all the data, including setting up views

    *Details TBD*

- Set up the container image to run nightly (or similar)

    *Details TBD*

## Configuring SQL Server DB

- Enable AAD in the portal, and set up groups appropriately

