#!/bin/bash

# Helmチャート用のディレクトリを作成
mkdir -p helm/techtrends/templates

# Chart.yamlの作成
cat << 'EOF' > helm/techtrends/Chart.yaml
apiVersion: v1
name: techtrends
keywords: 
  - techtrends
version: 1.0.0
maintainers:
  - name: YourName
    email: YourEmail@example.com
EOF

# values.yamlの作成
cat << 'EOF' > helm/techtrends/values.yaml
namespace: sandbox
service:
  port: 4111
  targetPort: 3111
  protocol: TCP
  type: ClusterIP
image:
  repository: techtrends
  tag: latest
  pullPolicy: IfNotPresent
replicaCount: 1
resources:
  requests:
    memory: "64Mi"
    cpu: "250m"
  limits:
    memory: "128Mi"
    cpu: "500m"
containerPort: 3111
livenessProbe:
  path: /healthz
readinessProbe:
  path: /healthz
EOF

# namespace.yamlのテンプレート作成
cat << 'EOF' > helm/techtrends/templates/namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: {{ .Values.namespace }}
EOF

# deploy.yamlのテンプレート作成
cat << 'EOF' > helm/techtrends/templates/deploy.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: techtrends
  namespace: {{ .Values.namespace }}
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      app: techtrends
  template:
    metadata:
      labels:
        app: techtrends
    spec:
      containers:
      - name: techtrends
        image: {{ .Values.image.repository }}:{{ .Values.image.tag }}
        imagePullPolicy: {{ .Values.image.pullPolicy }}
        ports:
        - containerPort: {{ .Values.containerPort }}
        resources:
          requests:
            memory: {{ .Values.resources.requests.memory }}
            cpu: {{ .Values.resources.requests.cpu }}
          limits:
            memory: {{ .Values.resources.limits.memory }}
            cpu: {{ .Values.resources.limits.cpu }}
        livenessProbe:
          httpGet:
            path: {{ .Values.livenessProbe.path }}
            port: {{ .Values.containerPort }}
        readinessProbe:
          httpGet:
            path: {{ .Values.readinessProbe.path }}
            port: {{ .Values.containerPort }}
EOF

# service.yamlのテンプレート作成
cat << 'EOF' > helm/techtrends/templates/service.yaml
apiVersion: v1
kind: Service
metadata:
  name: techtrends
  namespace: {{ .Values.namespace }}
spec:
  selector:
    app: techtrends
  ports:
    - protocol: {{ .Values.service.protocol }}
      port: {{ .Values.service.port }}
      targetPort: {{ .Values.service.targetPort }}
  type: {{ .Values.service.type }}
EOF

# values-staging.yamlの作成
cat << 'EOF' > helm/techtrends/values-staging.yaml
namespace: staging
service:
  port: 5111
replicaCount: 3
resources:
  requests:
    memory: "90Mi"
    cpu: "300m"
  limits:
    memory: "128Mi"
    cpu: "500m"
EOF

# values-prod.yamlの作成
cat << 'EOF' > helm/techtrends/values-prod.yaml
namespace: prod
service:
  port: 7111
image:
  pullPolicy: Always
replicaCount: 5
resources:
  requests:
    memory: "128Mi"
    cpu: "350m"
  limits:
    memory: "256Mi"
    cpu: "500m"
EOF

echo "Helmチャートと環境別valuesファイルの作成が完了しました。" | tee helm/creation_log.txt
