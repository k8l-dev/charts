{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "k8l.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "k8l.fullname" -}}
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
{{- define "k8l.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "k8l.labels" -}}
helm.sh/chart: {{ include "k8l.chart" . }}
{{ include "k8l.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "k8l.selectorLabels" -}}
app.kubernetes.io/name: {{ include "k8l.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "k8l.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "k8l.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}


{{/*
Renders a value that contains template.
Usage:
{{ include "k8l.tplValue" (dict "value" .Values.path.to.the.Value "context" $) }}
*/}}
{{- define "k8l.tplValue" -}}
    {{- if typeIs "string" .value }}
        {{- tpl .value .context }}
    {{- else }}
        {{- tpl (.value | toYaml) .context }}
    {{- end }}
{{- end -}}


{{/*
Generate certificates for dqlite connection 
*/}}
{{- define "k8l.gen-certs" -}}
{{- $altNames := list  ( printf "%s.%s" (include "k8l.name" .) .Release.Namespace ) ( printf "%s.%s.svc" (include "k8l.name" .) .Release.Namespace ) ( printf "*.%s.%s.svc" (include "k8l.name" .) .Release.Namespace ) -}}

{{- $ca := genCA "k8l-ca" 3650 -}}
{{- $cert := genSignedCert ( include "k8l.name" . ) nil $altNames 3650 $ca -}}
tls.crt: {{ $cert.Cert | b64enc }}
tls.key: {{ $cert.Key | b64enc }}
ca.crt:  {{ $ca.Cert | b64enc }}
ca.key:  {{ $ca.Key | b64enc }}
{{- end -}}