#!/bin/bash
WORKING_DIR=$(dirname "$BASH_SOURCE")
WORKING_DIR=$(cd "$WORKING_DIR"; pwd)

REPO_OWNER="prometheus-community"
REPO_NAME="kube-prometheus-stack"

# GitHub API URL for the latest release
API_URL="https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/releases/latest"


# URL of the RSS feed
API_URL="https://artifacthub.io/api/v1/packages/helm/$REPO_OWNER/$REPO_NAME/feed/rss"

# Fetch the latest version number using curl and parse it using xmllint
latest_version=$(curl -s $API_URL | xmllint --xpath 'string(//rss/channel/item[1]/title)' -)

