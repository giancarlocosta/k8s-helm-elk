#!/bin/bash
set -ue
cd "$(dirname "$0")/.."
PATH="/home/${USER}/bin:/home/${USER}/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin"

CREDSTASH_REGION=${CREDSTASH_REGION:-"us-gov-west-1"}
CA_COMMON_NAME=${1} # logstash.yournetwork.net
DEPOT_PATH=${2:-"./tmp/filebeat-ssl"} # filebeat-daemon

# Parse args
if [[ -z "$CA_COMMON_NAME" || -z "$DEPOT_PATH" ]]; then
  echo "USAGE: bin/get-cert.sh DEPOT_PATH CA_COMMON_NAME"; exit 1;
fi

[ -d "${DEPOT_PATH}" ] && rm -rf "${DEPOT_PATH}"
mkdir -p "${DEPOT_PATH}"

# Retrieve CA certificate and key from AWS
credstash -r ${CREDSTASH_REGION} get elk-logstash-ca-key env=elk level=protected > "${DEPOT_PATH}/${CA_COMMON_NAME}.key"
credstash -r ${CREDSTASH_REGION} get elk-logstash-ca-cert env=elk > "${DEPOT_PATH}/${CA_COMMON_NAME}.crt"

echo "Retrieved cert files:"
ls ${DEPOT_PATH}
