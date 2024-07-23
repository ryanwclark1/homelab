#!/usr/bin/env bash

export NORD_TOKEN=$(grep NORD_TOKEN .env | cut -d'=' -f 2-)
curl -s -u token:$NORD_TOKEN https://api.nordvpn.com/v1/users/services/credentials | jq -r .nordlynx_private_key