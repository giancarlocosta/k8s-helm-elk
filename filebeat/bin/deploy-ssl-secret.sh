#!/bin/bash
set -ue
cd "$(dirname "$0")/.."
PATH="/home/${USER}/bin:/home/${USER}/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin"

KUBE_CONTEXT=${1} # docker-for-desktop
KUBE_NAMESPACE=${2} # ops
CERT_DIR=${3} # dir containing CA cert and key
DOMAIN_NAME=${4} # filebeat-daemon
CA_COMMON_NAME=${5} # logstash.yournetwork.net
DEPOT_PATH="./tmp/filebeat-ssl-copy"

# Parse args
if [[ -z "$KUBE_CONTEXT" || -z "$KUBE_NAMESPACE" || -z "$DOMAIN_NAME" || -z "$CA_COMMON_NAME" ]]; then
  echo "USAGE: bin/deploy-ssl-secret.sh KUBE_CONTEXT KUBE_NAMESPACE CERT_DIR DOMAIN_NAME CA_COMMON_NAME"; exit -1;
fi
if ! [[ -d ${CERT_DIR} ]]; then
  echo "ERROR: CERT_DIR must be a dir containing the CA certificate and key."; exit -1;
fi

# Copy cert files into a temp working dir
[ -d "${DEPOT_PATH}" ] && rm -rf "${DEPOT_PATH}"
mkdir -p "${DEPOT_PATH}"
cp -r ${CERT_DIR}/* "${DEPOT_PATH}"

# Generate SSL Client certificate for Filebeat
certstrap --depot-path "${DEPOT_PATH}" request-cert --domain "${DOMAIN_NAME}" --passphrase ""
certstrap --depot-path "${DEPOT_PATH}" sign "${DOMAIN_NAME}" --CA "${CA_COMMON_NAME}" --passphrase ""

# Convert into PKCS8 format.
openssl pkcs8 -topk8 -inform PEM -outform PEM -nocrypt -in "${DEPOT_PATH}/${DOMAIN_NAME}.key" -out "${DEPOT_PATH}/${DOMAIN_NAME}.pkcs8.key"

rm -f "${DEPOT_PATH}/${CA_COMMON_NAME}.key"
rm -f "${DEPOT_PATH}/${DOMAIN_NAME}.key"
rm -f "${DEPOT_PATH}/${DOMAIN_NAME}.csr"
echo "Creating secrets from files:"
ls ${DEPOT_PATH}
KUBE_COMMAND="kubectl --context ${KUBE_CONTEXT} -n ${KUBE_NAMESPACE}"
${KUBE_COMMAND} delete secret filebeat-ssl || true
${KUBE_COMMAND} create secret generic filebeat-ssl --from-file "${DEPOT_PATH}"

rm -rf "${DEPOT_PATH}"
