#!/usr/bin/env bash

DELETE_CRD=${1:-false}

REPO_ROOT=$(git rev-parse --show-toplevel)


kubectl delete hr -n grpcdemo --all
kubectl delete hr -n promop --all

helm del --purge grpcdemo-client
helm del --purge grpcdemo-server
helm del --purge promop
helm del --purge flux

kubectl delete ns flux grpcdemo promop


crdList="alertmanagers.monitoring.coreos.com helmreleases.flux.weave.works podmonitors.monitoring.coreos.com prometheuses.monitoring.coreos.com prometheusrules.monitoring.coreos.com servicemonitors.monitoring.coreos.com"
if [[ "$DELETE_CRD" == "true" ]]; then
	kubectl delete crd $crdList
fi

echo ""
echo -e "\033[36mManual Cleanup Steps:\033[0m"
echo -e "\033[36m\t- Delete the github deploy key that was added to your repo by browsing to https://github.com/<YOUR-USERNAME>/flux-grpcdemo/settings/keys\033[0m"
if [[ "$DELETE_CRD" != "true" ]]; then
	echo -e "\033[36m\t- Delete the CRDs that were created by executing kubectl delete crd <name> or each CRD or execute this script with \$1 set to 'true' ($0 true) to delete the following: \033[31m$crdList\033[0m"
fi