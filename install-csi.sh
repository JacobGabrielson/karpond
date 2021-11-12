#!/bin/bash

. ./common.sh

cf_std_out=$(mktemp --tmpdir XXXXXXXX.std.out)
cf_err_out=$(mktemp --tmpdir XXXXXXXX.err.out)

describeStax() {
    aws cloudformation describe-stacks \
	--stack-name eksctl-$CLUSTER_NAME-addon-iamserviceaccount-kube-system-ebs-csi-controller-sa \
	--query='Stacks[].Outputs[?OutputKey==`Role1`].OutputValue' \
	--output text 1>$cf_std_out 2>$cf_err_out

    if [[ -s $cf_err_out ]]; then
	if ! grep -q "does not exist" $cf_err_out; then
	    eksctl create iamserviceaccount \
		   --name ebs-csi-controller-sa \
		   --namespace kube-system \
		   --cluster $CLUSTER_NAME \
		   --attach-policy-arn arn:aws:iam::${AWS_ACCOUNT_ID}:policy/AmazonEKS_EBS_CSI_Driver_Policy \
		   --approve \
		   --override-existing-serviceaccounts
	    describeStax
	else
	    cat $cf_err_out 1>&2
	    exit 1
	fi
    else
	cat $cf_std_out
	exit 0
    fi
}

describeStax

# from https://docs.aws.amazon.com/eks/latest/userguide/ebs-csi.html

example_policy=$(mktemp --tmpdir XXXXXXXXX.json)

curl -o "$example_policy" https://raw.githubusercontent.com/kubernetes-sigs/aws-ebs-csi-driver/release-1.3/docs/example-iam-policy.json

err_out=$(mktemp --tmpdir XXXXXXXX.err.out)

aws iam create-policy \
    --policy-name AmazonEKS_EBS_CSI_Driver_Policy \
    --policy-document "file://$example_policy" 2>"$err_out"

if ! grep -q "EntityAlreadyExists" "$err_out"; then
    cat "$err_out" 2>&1
    exit 1
fi

describeStax

