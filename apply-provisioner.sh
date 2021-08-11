#!/bin/bash

. ./common.sh

cat <<EOF | kubectl apply -f -
apiVersion: karpenter.sh/v1alpha3
kind: Provisioner
metadata:
  name: default
spec:
  cluster:
    name: ${CLUSTER_NAME}
    endpoint: $(aws eks describe-cluster --name ${CLUSTER_NAME} --query "cluster.endpoint" --output json)
  ttlSecondsAfterEmpty: 30
EOF
