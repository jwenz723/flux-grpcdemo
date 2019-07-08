#!/usr/bin/env bash

REPO_ROOT=$(git rev-parse --show-toplevel)

helm delete --purge grpcdemo-client
helm delete --purge grpcdemo-server
kubectl delete ns grpcdemo

helm delete --purge promop
kubectl delete ns promop

helm delete --purge flux
kubectl delete ns flux