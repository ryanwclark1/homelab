#!/bin/bash


export $(cat .env | xargs)
envsubst < cert-manager.yaml | kubectl apply -f -