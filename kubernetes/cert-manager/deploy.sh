export $(cat .env | xargs)
envsubst < cert-manager-clusterissuer.yaml | kubectl apply -f -