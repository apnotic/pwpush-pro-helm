{{/*
Expand the name of the chart.
*/}}
{{- define "pwpush-pro.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "pwpush-pro.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "pwpush-pro.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "pwpush-pro.labels" -}}
helm.sh/chart: {{ include "pwpush-pro.chart" . }}
{{ include "pwpush-pro.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: pwpush-pro
pwpush-pro/edition: {{ .Values.edition | default "starter" }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "pwpush-pro.selectorLabels" -}}
app.kubernetes.io/name: {{ include "pwpush-pro.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Secret name - returns existing secret name or generated name
*/}}
{{- define "pwpush-pro.secretName" -}}
{{- if .Values.secrets.existingSecretName }}
{{- .Values.secrets.existingSecretName }}
{{- else }}
{{- include "pwpush-pro.fullname" . }}
{{- end }}
{{- end }}

{{/*
PostgreSQL host - returns subchart service name or external host
*/}}
{{- define "pwpush-pro.postgresql.host" -}}
{{- if .Values.postgresql.enabled }}
{{- printf "%s-postgresql" .Release.Name }}
{{- else }}
{{- .Values.database.host }}
{{- end }}
{{- end }}

{{/*
PostgreSQL password secret name
*/}}
{{- define "pwpush-pro.postgresql.secretName" -}}
{{- if and .Values.postgresql.enabled .Values.postgresql.auth.existingSecret }}
{{- .Values.postgresql.auth.existingSecret }}
{{- else if .Values.postgresql.enabled }}
{{- printf "%s-postgresql" .Release.Name }}
{{- else if .Values.database.existingSecretName }}
{{- .Values.database.existingSecretName }}
{{- else }}
{{- include "pwpush-pro.fullname" . }}
{{- end }}
{{- end }}
