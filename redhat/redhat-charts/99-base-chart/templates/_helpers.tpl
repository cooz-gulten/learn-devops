{{- define "99-bootstrap-cdn.name" -}}
{{ default .Release.Name .Values.global.nameOverride }}
{{- end -}}

{{- define "99-bootstrap-cdn.labels" -}}
helm.sh/chart: {{ .Chart.Name }}
{{ include "99-bootstrap-cdn.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "99-bootstrap-cdn.selectorLabels" -}}
app.kubernetes.io/name: {{ include "99-bootstrap-cdn.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "99-bootstrap-cdn.imageName" -}}
{{ default (include "99-bootstrap-cdn.name" .) .Values.image.name }}:{{ .Values.image.tag }}
{{- end -}}
