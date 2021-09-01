#!/bin/sh

. ./common.sh

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
# FYI: `helm search repo prometheus-community` to see the charts
helm repo add stable https://charts.helm.sh/stable
helm repo update
#helm install --generate-name prometheus-community/kube-prometheus-stack
helm install prometheus prometheus-community/prometheus \
    --namespace monitoring \
    --set alertmanager.persistentVolume.storageClass="gp2",server.persistentVolume.storageClass="gp2"

# export POD_NAME=$(kubectl get pods --namespace monitoring -l "app=prometheus,component=pushgateway" -o jsonpath="{.items[0].metadata.name}")
