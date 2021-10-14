#!/bin/bash

. ./common.sh

echo -n "oidc provider: "

aws eks describe-cluster --name ${CLUSTER_NAME} --query "cluster.identity.oidc.issuer" --output text

