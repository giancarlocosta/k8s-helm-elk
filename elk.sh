#!/bin/sh -e -x

HELM_VERSION=${HELM_VERSION:-"2.9.0"}

kube_context=${1:-"ephemeral"}
kube_namespace=${2:-"ephemeral"}
chart=${3:-"ephemeral"}
action=${4}

release_name="${NAME:-$chart}"
values="${VALUES:-"${kube_context}-${chart}-values.yaml"}"

helm_command="helm${HELM_VERSION}"

if [[ "${action}" == "template" ]]; then
  ${helm_command} template "./${chart}" --name="${release_name}" --kube-context="${kube_context}" --namespace="${kube_namespace}" --tiller-namespace="${kube_namespace}" --values="${values}"
elif [[ "${action}" == "install" ]]; then
  ${helm_command} install "./${chart}" --name="${release_name}" --kube-context="${kube_context}" --namespace="${kube_namespace}" --tiller-namespace="${kube_namespace}" --values="${values}"
elif [[ "${action}" == "upgrade" ]]; then
  ${helm_command} upgrade "${release_name}" "./${chart}" --kube-context="${kube_context}" --tiller-namespace="${kube_namespace}" --values="${values}"
elif [[ "${action}" == "delete" ]]; then
  ${helm_command} delete --purge "${release_name}" --kube-context="${kube_context}" --tiller-namespace="${kube_namespace}"
else
  set +x; echo; echo "ERROR: Missing/invalid Helm action specified as fourth arg. Valid values are: [template, install, upgrade, delete]"; echo;
fi
