#!/bin/bash -e
# Helm/Tiller role bindings. Make sure automountServiceAccountToken: true (https://github.com/kubernetes/helm/issues/2464)

source "$(dirname ${BASH_SOURCE[0]})/common.bash"
require helm kubectl gettext envsubst
cd "${SCRIPT_DIR}"
setKubectlVersion

# Get/validate args
KUBE_CONTEXT=$1; NAMESPACE=$2; HELM_VERSION=$3;
[[ "$#" -lt 3 ]] && msgExit "USAGE: bin/helm-init-namespace.sh KUBE_CONTEXT NAMESPACE HELM_VERSION"

# Download Helm Binary
setHelmVersion ${HELM_VERSION}
HELM_COMMAND="helm${HELM_VERSION}"

# Set up context and namespace based on where this deployment is headed
KUBE_COMMAND="kubectl --context=${KUBE_CONTEXT}"
TILLER_SERVICE_ACCOUNT="tiller-${NAMESPACE}"

# Create the namespace if it doesn't already exist
out=$(${KUBE_COMMAND} get namespaces)
if ! echo $out | grep -q "${NAMESPACE}"; then
  ask "ERROR: Namespace \"$NAMESPACE\" does not exist in \"$KUBE_CONTEXT\" context" || abort
  ${KUBE_COMMAND} create namespace "${NAMESPACE}"
fi

# Apply the RBAC config to the namespace before deploying Helm
ask "WARNING:\nYou are deploying Helm version ${HELM_VERSION} to: \n   KUBE CONTEXT: \"$KUBE_CONTEXT\" \n   KUBE NAMESPACE: \"$NAMESPACE\"\nAre you sure you want to continue?" || exit 0;

${KUBE_COMMAND} --namespace=${NAMESPACE} apply -f <(NAMESPACE=$NAMESPACE envsubst '$NAMESPACE' < helm-init/template-rolebinding.yaml)
${KUBE_COMMAND} --namespace=${NAMESPACE} apply -f <(NAMESPACE=$NAMESPACE envsubst '$NAMESPACE' < helm-init/template-serviceaccount.yaml)
${KUBE_COMMAND} --namespace=${NAMESPACE} apply -f <(NAMESPACE=$NAMESPACE envsubst '$NAMESPACE' < helm-init/template-tiller-namespace-view.yaml)
${KUBE_COMMAND} --namespace=${NAMESPACE} apply -f <(NAMESPACE=$NAMESPACE envsubst '$NAMESPACE' < helm-init/template-tiller-storageclass-admin.yaml)

# Allow the 'monitor' namespace Tiller deployment cluster-admin ClusterRoleBinding
# since 'monitor' helm charts will often need to use create level resources like
# ClusterRoles, ClusterRoleBinding, etc.
if [[ "${NAMESPACE}" == "monitor" ]]; then
  ${KUBE_COMMAND} --namespace=${NAMESPACE} apply -f <(NAMESPACE=$NAMESPACE envsubst '$NAMESPACE' < helm-init/template-tiller-cluster-admin.yaml)
fi

# Deploy Helm (Tiller) to the namespace
${HELM_COMMAND} init --kube-context=${KUBE_CONTEXT} --tiller-namespace=${NAMESPACE} --service-account=${TILLER_SERVICE_ACCOUNT}
