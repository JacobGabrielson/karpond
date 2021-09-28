#!/bin/sh

. ./common.sh

# create test vpc for messing around with instances, with ssm enabled

cfn -n karpond -s testStack -t test-stack.yaml create
