#!/bin/bash

set -eu

. ./common.sh

oidc_issuer=$(aws eks describe-cluster --name ${CLUSTER_NAME} --query "cluster.identity.oidc.issuer" --output text)

oidc_id=${oidc_issuer##*/}

echo "oidc issuer: $oidc_issuer ($oidc_id)"

echo -n "active oidc provider: "
aws iam list-open-id-connect-providers | grep "$oidc_id"

