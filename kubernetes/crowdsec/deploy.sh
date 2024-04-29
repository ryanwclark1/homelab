#!/bin/bash

helm repo add emberstack https://emberstack.github.io/helm-charts # required to share certs for CrowdSec
helm repo add crowdsec https://crowdsecurity.github.io/helm-charts
helm repo update