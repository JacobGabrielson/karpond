#!/bin/bash

. ./common.sh

kubectl patch configmap config-logging -n karpenter --patch '{"data":{"loglevel.controller":"debug"}}'
kubectl patch configmap config-logging -n karpenter --patch '{"data":{"loglevel.webhook":"debug"}}'
