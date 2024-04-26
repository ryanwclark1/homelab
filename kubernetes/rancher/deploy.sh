#!/bin/bash


helm install rancher rancher-latest/rancher \
  --namespace cattle-system \
  --set hostname=rancher.${DOMAIN} \
  --set bootstrapPassword=password123
kubectl -n cattle-system rollout status deploy/rancher
kubectl -n cattle-system get deploy rancher

kubectl get svc -n cattle-system
kubectl expose deployment rancher --name=rancher-lb --port=443 --type=LoadBalancer -n cattle-system
kubectl get svc -n cattle-system