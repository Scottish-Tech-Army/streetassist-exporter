#!/bin/bash
# Script to build the container, and push it.
set -euo pipefail

# This script must run from the parent directory of the scripts directory
cd "$(dirname "$0")/.."

# Login to the ACR
az acr login -n ${REGISTRY}

# Build the container locally
docker build docker/ -t exporter

# Retag that thing
docker tag exporter:latest ${REGISTRY}.azurecr.io/exporter:latest
docker push ${REGISTRY}.azurecr.io/exporter:latest

