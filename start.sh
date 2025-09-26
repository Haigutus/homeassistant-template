#!/bin/bash

# Exit on any error
set -e

# Input YAML file
YAML_FILE="ha-config/secrets.yaml"
# Output .env file
ENV_FILE=".env"
# Convert YAML to .env with uppercase keys
yq -r 'to_entries | .[] | (.key | ascii_upcase) + "=" + (.value | tostring)' "$YAML_FILE" > "$ENV_FILE"


echo "Converted YAML to .env file with uppercase keys at $ENV_FILE"

echo "Starting Home Assistant and other services..."

# Ensure we are in the home directory where docker-compose.yaml is located
docker-compose up -d

echo "Services started."
