#!/bin/bash

set -eu pipefail

helm repo add nvgfd https://nvidia.github.io/gpu-feature-discovery
helm repo update

helm install \
    --version=0.4.1 \
    --generate-name \
    nvgfd/gpu-feature-discovery
