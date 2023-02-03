{{- define "99-base-chart.name" -}}
{{ default .Release.Name .Values.global.nameOverride }}
{{- end -}}

{{- define "99-base-chart.labels" -}}
helm.sh/chart: {{ .Chart.Name }}
{{ include "99-base-chart.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "99-base-chart.selectorLabels" -}}
app.kubernetes.io/name: {{ include "99-base-chart.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "99-base-chart.imageName" -}}
{{ default (include "99-base-chart.name" .) .Values.image.name }}:{{ .Values.image.tag }}
{{- end -}}
