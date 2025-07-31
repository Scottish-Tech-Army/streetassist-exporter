# Parameters in use
export RG=exporter
export REGION=northeurope
export KEYVAULT=streetassistvault
export REGISTRY=streetassistregistry
export STORAGEACCOUNTNAME=streetassiststorage

# This tenant stuff is purely to make sure we are using the right Azure subscription.
export TENANT=61f4ee80-4b44-47dd-a4ba-4dda6a92197e

actual_tenant=$(az account show | jq ".tenantId" -r)
if [ "$TENANT" != "${actual_tenant}" ]; then
  echo "Error: TENANT ('$TENANT') does not match current Azure subscription name ('${actual_tenant}')."
  exit 1
fi
