#!/bin/bash

. ./common.sh

kubectl scale deployment inflate-tf --replicas "$1"
