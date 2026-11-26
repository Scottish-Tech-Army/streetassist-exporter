# Parameters in use
export RG=exporter
export REGION=northeurope
export KEYVAULT=streetassistvault
export REGISTRY=streetassistregistry
export STORAGEACCOUNTNAME=streetassiststorage

# Alert configuration
# Name of the action group that is manually created.
export ALERT_ACTION_GROUP=exporter-alerts

# This tenant stuff is purely to make sure we are using the right Azure subscription.
export SUBSCRIPTION=ee920741-64d0-4ffa-8eb1-e709c57f1f19
az account set --subscription ${SUBSCRIPTION}
