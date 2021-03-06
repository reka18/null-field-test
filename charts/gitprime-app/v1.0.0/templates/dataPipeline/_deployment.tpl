{{- /* This represents a deployment that runs the main Data Pipeline jar and moves into different modes based on */}}
{{- /* environment variables and the like. */}}
{{- define "dataPipeline.deploymentTemplate" }}
{{- $globalEnvironment := .Values.dataPipeline.environment }}
{{- $environment := .templateData.environment }}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: gitprime-dp-{{- template "helpers.environment.fullName" .}}-{{ .templateData.operationMode }}
  labels:
    app: gitprime-dp-{{- template "helpers.environment.fullName" .}}-{{ .templateData.operationMode }}
spec:
  replicas: {{ .templateData.replicaCount }}
  selector:
    matchLabels:
      app: gitprime-dp-{{- template "helpers.environment.fullName" .}}-{{ .templateData.operationMode }}
  strategy:
    rollingUpdate:
      maxSurge: 25%
      maxUnavailable: 25%
    type: RollingUpdate
  template:
    metadata:
      labels:
        app: gitprime-dp-{{- template "helpers.environment.fullName" .}}-{{ .templateData.operationMode }}
    spec:
      containers:
        - name: gitprime-dp-{{- template "helpers.environment.fullName" .}}-{{ .templateData.operationMode }}
          image: gp-docker.gitprime-ops.com/integrations/gitprime-data-pipeline:{{ .Values.dataPipeline.build.commitSHA }}
          imagePullPolicy: IfNotPresent
          env:
            - name: SYSTEM_ENV_PARENT
              value: {{ quote .Values.environment.parentName }}
            - name: SYSTEM_ENV_MODIFIER
              value: {{ quote .Values.environment.modifierValue }}
            - name: SYSTEM_ENV
              value: {{ include "helpers.environment.fullName" . | quote }}
            - name: SYSTEM_POD_NAME
              valueFrom:
                fieldRef:
                  fieldPath: metadata.name
            - name: SYSTEM_OPERATION_MODE
              value: {{ quote .templateData.operationMode }}
            - name: SYSTEM_CONFIG_SERVER_URL
              value: {{ include "helpers.configServerURL" . }}
            - name: GP_REQUEUE_AOD
              value: {{ quote .templateData.requeueAOD | default true }}
            - name: GP_LOG_LEVEL
              value: {{ quote .templateData.logLevel | default "INFO" | lower }}
          {{- if .templateData.javaOptions }}
            - name: JAVA_OPTS
              value: {{ quote .templateData.javaOptions }}
          {{- end }}
          {{- if .templateData.maxConcurrentJobs }}
            - name: GP_MAX_CONCURRENT_JOBS
              value: {{ quote .templateData.maxConcurrentJobs }}
          {{- end }}
          {{- if .templateData.maxCommitCount }}
            - name: GP_MAX_COMMIT_COUNT
              value: {{ quote .templateData.maxCommitCount }}
          {{- end }}
          {{- if .templateData.processorThreadCount }}
            - name: GP_COMMIT_PROCESSOR_THREADS
              value: {{ quote .templateData.processorThreadCount }}
          {{- end }}
          {{- range $globalEnvironment }}
            - name: {{ .name }}
              value: {{ .value | quote }}
          {{- end }}
          {{- range $environment }}
            - name: {{ .name }}
              value: {{ .value | quote }}
          {{- end }}
          resources:
          {{- if .templateData.resources }}
          {{- if or (.templateData.resources.requests.cpu) (.templateData.resources.requests.memory) }}
            requests:
            {{- if .templateData.resources.requests.cpu }}
              cpu: {{ quote .templateData.resources.requests.cpu }}
            {{- end }}
            {{- if .templateData.resources.requests.memory }}
              memory: {{ .templateData.resources.requests.memory }}
            {{- end }}
          {{- end }}
          {{- if or (.templateData.resources.limits.cpu) (.templateData.resources.limits.memory) }}
            limits:
            {{- if .templateData.resources.limits.cpu }}
              cpu: {{ quote .templateData.resources.limits.cpu }}
            {{- end }}
            {{- if .templateData.resources.limits.memory }}
              memory: {{ .templateData.resources.limits.memory }}
            {{- end }}
          {{- end }}
          {{- end }}
          {{- if .Values.dataPipeline.volumes.enableLocalMount }}
          volumeMounts:
            - mountPath: {{ quote .Values.dataPipeline.volumes.podMountDirectory }}
              name: repository-storage-volume
          {{- end }}
          terminationMessagePath: /dev/termination-log
          terminationMessagePolicy: File
      dnsPolicy: ClusterFirst
      restartPolicy: Always
      schedulerName: default-scheduler
      securityContext: {}
      terminationGracePeriodSeconds: 30
      {{- if .Values.dataPipeline.volumes.enableLocalMount }}
      volumes:
      - hostPath:
          path: {{ quote .Values.dataPipeline.volumes.nodeMountDirectory }}
          type: DirectoryOrCreate
        name: repository-storage-volume
      {{- end }}
{{- end }}