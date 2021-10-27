#!/bin/bash

. ./common.sh

cat <<EOF | kubectl apply -f -
apiVersion: karpenter.sh/v1alpha5
kind: Provisioner
metadata:
  name: default
spec:
  requirements:
    - key: "kubernetes.io/os" # If not included, all operating systems are considered
      operator: In
      values: ["linux"]
    - key: "kubernetes.io/arch" # If not included, all architectures are considered
      operator: In
      values: ["amd64"]
  labels:
  #  node.k8s.aws/launch-template-name: "Karpenter-jacob-karpenter-demo-11759955701874416904"
     larry: sounders
     phil: swif
     pikov: andropov
  ttlSecondsAfterEmpty: 30
  #architectures: ['amd64']
  provider:
    #capacityTypes: ["spot", "on-demand"]
    #capacityTypes: ["on-demand"]
    #capacityTypes: ["spot"]
    instanceProfile: KarpenterNodeInstanceProfile-${CLUSTER_NAME}
    cluster:
      name: ${CLUSTER_NAME}
      endpoint: $(aws eks describe-cluster --name ${CLUSTER_NAME} --query "cluster.endpoint" --output json)
EOF
