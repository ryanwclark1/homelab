#!/bin/bash

# More information: https://github.com/prometheus-community/helm-charts/blob/main/charts/kube-prometheus-stack/README.md
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

kubectl create namespace kube-prometheus-stack
helm install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace kube-prometheus-stack
