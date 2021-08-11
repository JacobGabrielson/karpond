#!/bin/bash

. ./common.sh

kubectl apply -f inflate.yaml
kubectl scale deployment inflate --replicas 5
kubectl logs -f -n karpenter $(kubectl get pods -n karpenter -l karpenter=controller -o name)
