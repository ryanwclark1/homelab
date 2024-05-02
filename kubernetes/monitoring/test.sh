#!/usr/bin/env bash

kubectl --namespace monitoring port-forward svc/prometheus-k8s 9090
ssh -L 9090:10.10.101.220:9090 administrator@10.10.101.220