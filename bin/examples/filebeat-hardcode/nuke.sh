#!/bin/sh

kubectl --context=prod-elk -n monitor delete configmap filebeat-inputs filebeat-configmap
kubectl --context=prod-elk -n monitor delete daemonset filebeat
