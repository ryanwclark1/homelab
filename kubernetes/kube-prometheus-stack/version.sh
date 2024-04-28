
WORKING_DIR=$(dirname "$BASH_SOURCE")
WORKING_DIR=$(cd "$WORKING_DIR"; pwd)


#!/bin/bash

# URL of the RSS feed
API_URL="https://artifacthub.io/api/v1/packages/helm/prometheus-community/kube-prometheus-stack/feed/rss"

# Fetch the latest version number using curl and parse it using xmllint
latest_version=$(curl -s $API_URL | xmllint --xpath 'string(//rss/channel/item[1]/title)' -)
