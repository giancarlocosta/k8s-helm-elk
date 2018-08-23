{{/* vim: set filetype=mustache: */}}

{{/*
Generate common release/app labels. Use this using https://docs.helm.sh/chart_template_guide/#the-include-function
*/}}
{{- define "release_labels" }}
chart: "{{ .Chart.Name }}-{{ .Chart.Version }}"
release: "{{ .Release.Name }}"
heritage: "{{ .Release.Service }}"
app_version: "{{ .Chart.AppVersion }}"
{{- end }}
