#!/bin/bash
IP=$(hostname -I | cut -d' ' -f1)

kubectl create ns demo

cat << EOF | kubectl apply -n demo -f -
---
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: whoami
  name: whoami
spec:
  replicas: 1
  selector:
    matchLabels:
      app: whoami
  template:
    metadata:
      labels:
        app: whoami
    spec:
      containers:
        - image: traefik/whoami:latest
          name: whoami
          ports:
            - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: whoami-svc
spec:
  type: ClusterIP
  selector:
    app: whoami
  ports:
    - port: 80
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: whoami-http
  annotations:
    traefik.ingress.kubernetes.io/router.entrypoints: web
spec:
  rules:
    - host: whoami.$IP.sslip.io
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: whoami-svc
                port:
                  number: 80
EOF