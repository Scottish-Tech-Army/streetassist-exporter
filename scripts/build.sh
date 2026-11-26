#!/bin/bash
# Script to build the container, and push it as exporter:${IMAGE_TAG}.
set -euo pipefail

# This script must run from the parent directory of the scripts directory
cd "$(dirname "$0")/.."

image=${REGISTRY}.azurecr.io/exporter:${IMAGE_TAG}

# Login to the ACR
az acr login -n ${REGISTRY}

# Refuse to overwrite a tag that already exists, so every release stays available for rollback.
# Lists are compared by exact line, and a failing az command stops the script (set -e), so only a
# successful listing can say the tag is absent. The repository is only listed once it exists.
repositories=$(az acr repository list -n ${REGISTRY} -o tsv)
if grep -qxF exporter <<< "${repositories}"; then
    tags=$(az acr repository show-tags -n ${REGISTRY} --repository exporter -o tsv)
    if grep -qxF "${IMAGE_TAG}" <<< "${tags}"; then
        echo "Image exporter:${IMAGE_TAG} already exists in ${REGISTRY}. Set a new IMAGE_TAG." >&2
        exit 1
    fi
fi

# Build the container locally, and push it
docker build docker/ -t ${image}
docker push ${image}
