#!/bin/bash

# Get the current working directory of the script
WORKING_DIR=$(dirname "$BASH_SOURCE")
WORKING_DIR=$(cd "$WORKING_DIR" && pwd)

# Define the path to the .env file
ENV_FILE="$WORKING_DIR/.env"

# Check if the .env file already exists
if [ -f "$ENV_FILE" ]; then
    echo "The .env file already exists in the directory: $WORKING_DIR"
    exit 1
else
    echo "No .env file found in $WORKING_DIR. Creating one now..."

    # Ask for user input
    read -p "Enter Grafana admin username: " GF_ADMIN_USER
    read -sp "Enter Grafana admin password: " GF_ADMIN_PASSWORD
    echo

    # Create the .env file and write the environment variables
    echo "GF_ADMIN_USER=$GF_ADMIN_USER" > "$ENV_FILE"
    echo "GF_ADMIN_PASSWORD=$GF_ADMIN_PASSWORD" >> "$ENV_FILE"

    echo ".env file has been created successfully."
fi