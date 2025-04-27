#!/bin/bash
# Script to build the container, and do a manual export.
set -euo pipefail

# This script must run from the parent directory of the scripts directory
cd "$(dirname "$0")/.."

# Build the container locally
docker build docker/ -t exporter

# Run the container.
docker run -e API_TOKEN -e SERVER -e DB -e ADMINUSER -e ADMINPWD -a stdin -a stdout -it exporter

