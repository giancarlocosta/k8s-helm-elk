#!/bin/sh -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

es_host=${1}

templates="es-index-template-test es-index-template-kubernetes-event"

for t in ${templates}; do

curl --header "Content-Type: application/json" \
-XPUT ${es_host}/_template/${t}?pretty \
-d @${SCRIPT_DIR}/${t}.json
echo "Created \"${t}\" index mapping in ${es_host}"

done

#curl --header "Content-Type: application/json" -XDELETE https://elasticsearch.prod-elk.yournetwork.net/_template/es-index-template-kubernetes-event
