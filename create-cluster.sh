#!/bin/bash


. ./common.sh

AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

cat eksctl.yaml | envsubst | eksctl create cluster -f -
