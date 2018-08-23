{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "es.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 53 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 53 chars (63 - len("-discovery")) because some Kubernetes name fields are limited to 63 (by the DNS naming spec).
*/}}
{{- define "es.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- printf .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Return the appropriate apiVersion for Curactor cron job.
*/}}
{{- define "curator.cronJob.apiVersion" -}}
{{- if ge .Capabilities.KubeVersion.Minor "8" -}}
"batch/v1beta1"
{{- else -}}
"batch/v2alpha1"
{{- end -}}
{{- end -}}
