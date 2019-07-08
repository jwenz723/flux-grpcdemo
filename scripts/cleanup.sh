#!/usr/bin/env bash

REPO_ROOT=$(git rev-parse --show-toplevel)

helm delete --purge istio
helm delete --purge promop
helm delete --purge grpcdemo-client
helm delete --purge grpcdemo-server
helm delete --purge flux

kubectl delete ns istio-system
kubectl delete ns grpcdemo
kubectl delete ns promop
kubectl delete ns flux