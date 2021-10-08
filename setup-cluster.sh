#!/bin/bash

# Adds additional helm charts to the cluster

# 1. https://github.com/NVIDIA/gpu-feature-discovery#deployment-via-helm

set -eu pipefail

helm repo add nvgfd https://nvidia.github.io/gpu-feature-discovery
helm repo update

helm install \
    --version=0.4.1 \
    --generate-name \
    nvgfd/gpu-feature-discovery

# 2. AMD node labeller?
