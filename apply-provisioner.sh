#!/bin/bash

. ./common.sh

cat <<EOF | kubectl apply -f -
apiVersion: karpenter.sh/v1alpha3
kind: Provisioner
metadata:
  name: default
spec:
  labels:
    node.k8s.aws/launch-template-name: "Karpenter-jacob-karpenter-demo-11759955701874416904"
  ttlSecondsAfterEmpty: 30
EOF
