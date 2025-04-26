#!/bin/bash
# Set up initial deployment.
set -euo pipefail
echo "RG: ${RG}"

# This script must run from the parent directory of the scripts directory
cd "$(dirname "$0")/.."

# Before running this, you must be logged in.
# az login --use-device-code

# Create the group
az group create --location northeurope --resource-group ${RG}

# Create the resources in the group
az deployment group create \
    --resource-group ${RG} --template-file templates/deploy.bicep \
    --parameters keyVaultName=${KEYVAULT} \
                 containerRegistryName=${REGISTRY}

echo "SUCCESS"