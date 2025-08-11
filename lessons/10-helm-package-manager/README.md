# Lesson 10: Helm Package Manager

## Learning Objectives

By the end of this lesson, you will:

- Understand Helm and its role in Kubernetes
- Install and configure Helm
- Work with Helm charts and repositories
- Create custom Helm charts
- Manage application releases with Helm
- Implement templating and value management
- Handle Helm upgrades and rollbacks

## What is Helm?

**Helm is the package manager for Kubernetes**, often called "the npm of Kubernetes"

**Key Concepts:**

- **Chart**: A package containing Kubernetes manifests and metadata
- **Release**: An instance of a chart running in a cluster
- **Repository**: A collection of charts that can be shared
- **Values**: Configuration that customizes chart behavior

**Benefits:**

- **Package Management**: Install complex applications with a single command
- **Templating**: Create reusable, configurable Kubernetes manifests
- **Release Management**: Version control, upgrades, and rollbacks
- **Dependency Management**: Handle application dependencies automatically

## Installation and Setup

### Step 1: Install Helm

```bash
# Install Helm (macOS)
brew install helm

# Or download directly
curl https://get.helm.sh/helm-v3.13.1-darwin-amd64.tar.gz -o helm.tar.gz
tar -xzf helm.tar.gz
sudo mv darwin-amd64/helm /usr/local/bin/

# Verify installation
helm version
```

### Step 2: Add Chart Repositories

```bash
# Add official stable repo
helm repo add stable https://charts.helm.sh/stable

# Add Bitnami repo (popular charts)
helm repo add bitnami https://charts.bitnami.com/bitnami

# Add ingress-nginx repo
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx

# Update repository information
helm repo update

# List available repositories
helm repo list

# Search for charts
helm search repo nginx
helm search repo wordpress
```

## Working with Existing Charts

### Step 3: Install Your First Chart

```bash
# Search for nginx charts
helm search repo nginx

# Show chart information
helm show chart bitnami/nginx
helm show values bitnami/nginx

# Install nginx with default values
helm install my-nginx bitnami/nginx

# Check the release
helm list
kubectl get pods
kubectl get services
```

### Step 4: Installing with Custom Values

```bash
# Create custom values file
cat << 'EOF' > nginx-values.yaml
replicaCount: 2

service:
  type: LoadBalancer
  port: 80

ingress:
  enabled: true
  className: nginx
  hosts:
    - host: my-nginx.local
      paths:
        - path: /
          pathType: Prefix

resources:
  limits:
    cpu: 200m
    memory: 256Mi
  requests:
    cpu: 100m
    memory: 128Mi
EOF

# Install with custom values
helm install my-nginx-custom bitnami/nginx -f nginx-values.yaml

# Or override values directly
helm install my-nginx-inline bitnami/nginx \
  --set replicaCount=3 \
  --set service.type=NodePort \
  --set service.nodePort=30080
```

### Step 5: Managing Releases

```bash
# List all releases
helm list
helm list --all-namespaces

# Get release status
helm status my-nginx

# Get release values
helm get values my-nginx
helm get values my-nginx --all

# Get release manifest
helm get manifest my-nginx

# Get release notes
helm get notes my-nginx

# View release history
helm history my-nginx
```

## Creating Your First Chart

### Step 6: Generate Chart Scaffold

```bash
# Create a new chart
helm create my-web-app

# Explore the generated structure
cd my-web-app
tree .
```

**Chart Structure:**
```
my-web-app/
├── Chart.yaml          # Chart metadata
├── values.yaml         # Default configuration values
├── charts/             # Chart dependencies
├── templates/          # Kubernetes manifest templates
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── ingress.yaml
│   ├── serviceaccount.yaml
│   ├── hpa.yaml
│   ├── NOTES.txt       # Post-install notes
│   ├── _helpers.tpl    # Template helpers
│   └── tests/
│       └── test-connection.yaml
└── .helmignore         # Files to ignore when packaging
```

### Step 7: Customize Chart Metadata

```yaml
# Chart.yaml
apiVersion: v2
name: my-web-app
description: A sample web application Helm chart
type: application
version: 0.1.0
appVersion: "1.0.0"
keywords:
  - web
  - application
  - demo
home: https://github.com/yourusername/my-web-app
sources:
  - https://github.com/yourusername/my-web-app
maintainers:
  - name: Your Name
    email: your.email@example.com
dependencies: []
```

### Step 8: Configure Default Values

```yaml
# values.yaml
replicaCount: 1

image:
  repository: nginx
  pullPolicy: IfNotPresent
  tag: "1.21.6"

imagePullSecrets: []
nameOverride: ""
fullnameOverride: ""

serviceAccount:
  create: true
  annotations: {}
  name: ""

podAnnotations: {}

podSecurityContext:
  fsGroup: 2000

securityContext:
  capabilities:
    drop:
    - ALL
  readOnlyRootFilesystem: true
  runAsNonRoot: true
  runAsUser: 1000

service:
  type: ClusterIP
  port: 80
  targetPort: 8080

ingress:
  enabled: false
  className: ""
  annotations: {}
  hosts:
    - host: my-web-app.local
      paths:
        - path: /
          pathType: Prefix
  tls: []

resources:
  limits:
    cpu: 200m
    memory: 256Mi
  requests:
    cpu: 100m
    memory: 128Mi

autoscaling:
  enabled: false
  minReplicas: 1
  maxReplicas: 100
  targetCPUUtilizationPercentage: 80

nodeSelector: {}

tolerations: []

affinity: {}

# Application-specific configuration
app:
  name: my-web-app
  environment: production
  debug: false
  database:
    host: localhost
    port: 5432
    name: myapp
    user: myuser
  redis:
    enabled: true
    host: redis-service
    port: 6379
```

### Step 9: Create Custom Templates

```yaml
# templates/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "my-web-app.fullname" . }}
  labels:
    {{- include "my-web-app.labels" . | nindent 4 }}
spec:
  {{- if not .Values.autoscaling.enabled }}
  replicas: {{ .Values.replicaCount }}
  {{- end }}
  selector:
    matchLabels:
      {{- include "my-web-app.selectorLabels" . | nindent 6 }}
  template:
    metadata:
      annotations:
        checksum/config: {{ include (print $.Template.BasePath "/configmap.yaml") . | sha256sum }}
        {{- with .Values.podAnnotations }}
        {{- toYaml . | nindent 8 }}
        {{- end }}
      labels:
        {{- include "my-web-app.selectorLabels" . | nindent 8 }}
    spec:
      {{- with .Values.imagePullSecrets }}
      imagePullSecrets:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      serviceAccountName: {{ include "my-web-app.serviceAccountName" . }}
      securityContext:
        {{- toYaml .Values.podSecurityContext | nindent 8 }}
      containers:
        - name: {{ .Chart.Name }}
          securityContext:
            {{- toYaml .Values.securityContext | nindent 12 }}
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}"
          imagePullPolicy: {{ .Values.image.pullPolicy }}
          ports:
            - name: http
              containerPort: {{ .Values.service.targetPort }}
              protocol: TCP
          env:
            - name: APP_NAME
              value: {{ .Values.app.name }}
            - name: APP_ENV
              value: {{ .Values.app.environment }}
            - name: DEBUG
              value: {{ .Values.app.debug | quote }}
            - name: DB_HOST
              value: {{ .Values.app.database.host }}
            - name: DB_PORT
              value: {{ .Values.app.database.port | quote }}
            - name: DB_NAME
              value: {{ .Values.app.database.name }}
            - name: DB_USER
              value: {{ .Values.app.database.user }}
            {{- if .Values.app.redis.enabled }}
            - name: REDIS_HOST
              value: {{ .Values.app.redis.host }}
            - name: REDIS_PORT
              value: {{ .Values.app.redis.port | quote }}
            {{- end }}
          envFrom:
            - configMapRef:
                name: {{ include "my-web-app.fullname" . }}-config
            - secretRef:
                name: {{ include "my-web-app.fullname" . }}-secret
          livenessProbe:
            httpGet:
              path: /health
              port: http
            initialDelaySeconds: 30
            periodSeconds: 10
          readinessProbe:
            httpGet:
              path: /ready
              port: http
            initialDelaySeconds: 5
            periodSeconds: 5
          resources:
            {{- toYaml .Values.resources | nindent 12 }}
          volumeMounts:
            - name: config-volume
              mountPath: /app/config
              readOnly: true
      volumes:
        - name: config-volume
          configMap:
            name: {{ include "my-web-app.fullname" . }}-config
      {{- with .Values.nodeSelector }}
      nodeSelector:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .Values.affinity }}
      affinity:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .Values.tolerations }}
      tolerations:
        {{- toYaml . | nindent 8 }}
      {{- end }}
```

### Step 10: Add ConfigMap and Secret Templates

```yaml
# templates/configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ include "my-web-app.fullname" . }}-config
  labels:
    {{- include "my-web-app.labels" . | nindent 4 }}
data:
  app.properties: |
    app.name={{ .Values.app.name }}
    app.environment={{ .Values.app.environment }}
    app.debug={{ .Values.app.debug }}
    
    # Database configuration
    database.host={{ .Values.app.database.host }}
    database.port={{ .Values.app.database.port }}
    database.name={{ .Values.app.database.name }}
    
    {{- if .Values.app.redis.enabled }}
    # Redis configuration
    redis.host={{ .Values.app.redis.host }}
    redis.port={{ .Values.app.redis.port }}
    {{- end }}
  
  nginx.conf: |
    server {
        listen {{ .Values.service.targetPort }};
        server_name {{ include "my-web-app.fullname" . }};
        
        location / {
            root /usr/share/nginx/html;
            index index.html;
        }
        
        location /health {
            access_log off;
            return 200 "healthy\n";
            add_header Content-Type text/plain;
        }
        
        location /ready {
            access_log off;
            return 200 "ready\n";
            add_header Content-Type text/plain;
        }
    }

---
apiVersion: v1
kind: Secret
metadata:
  name: {{ include "my-web-app.fullname" . }}-secret
  labels:
    {{- include "my-web-app.labels" . | nindent 4 }}
type: Opaque
data:
  # These would normally come from external secret management
  database-password: {{ "supersecret" | b64enc }}
  api-key: {{ "my-api-key-12345" | b64enc }}
  jwt-secret: {{ "jwt-secret-key" | b64enc }}
```

### Step 11: Advanced Template Helpers

```yaml
# templates/_helpers.tpl
{{/*
Expand the name of the chart.
*/}}
{{- define "my-web-app.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "my-web-app.fullname" -}}
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
{{- define "my-web-app.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "my-web-app.labels" -}}
helm.sh/chart: {{ include "my-web-app.chart" . }}
{{ include "my-web-app.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: {{ include "my-web-app.name" . }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "my-web-app.selectorLabels" -}}
app.kubernetes.io/name: {{ include "my-web-app.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "my-web-app.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "my-web-app.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Generate database URL
*/}}
{{- define "my-web-app.databaseUrl" -}}
{{- printf "postgresql://%s:%s@%s:%v/%s" .Values.app.database.user "$(DATABASE_PASSWORD)" .Values.app.database.host .Values.app.database.port .Values.app.database.name }}
{{- end }}

{{/*
Check if redis is enabled and generate redis URL
*/}}
{{- define "my-web-app.redisUrl" -}}
{{- if .Values.app.redis.enabled }}
{{- printf "redis://%s:%v" .Values.app.redis.host .Values.app.redis.port }}
{{- else }}
{{- "" }}
{{- end }}
{{- end }}
```

## Chart Testing and Validation

### Step 12: Test Your Chart

```bash
# Validate chart syntax
helm lint my-web-app

# Test template rendering
helm template my-web-app ./my-web-app

# Test with different values
helm template my-web-app ./my-web-app -f test-values.yaml

# Dry run installation
helm install my-web-app ./my-web-app --dry-run

# Debug template rendering
helm template my-web-app ./my-web-app --debug
```

### Step 13: Create Test Values

```yaml
# test-values.yaml
replicaCount: 3

image:
  repository: nginx
  tag: "1.22.0"

service:
  type: LoadBalancer

ingress:
  enabled: true
  className: nginx
  hosts:
    - host: test.local
      paths:
        - path: /
          pathType: Prefix

resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 250m
    memory: 256Mi

autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 10
  targetCPUUtilizationPercentage: 70

app:
  environment: staging
  debug: true
  redis:
    enabled: true
```

## Advanced Helm Features

### Step 14: Chart Dependencies

```yaml
# Chart.yaml - Add dependencies
dependencies:
  - name: postgresql
    version: "12.x.x"
    repository: https://charts.bitnami.com/bitnami
    condition: postgresql.enabled
  - name: redis
    version: "17.x.x"
    repository: https://charts.bitnami.com/bitnami
    condition: redis.enabled
```

```yaml
# values.yaml - Configure dependencies
postgresql:
  enabled: true
  auth:
    postgresPassword: "postgres123"
    database: "myapp"
  primary:
    persistence:
      enabled: true
      size: 8Gi

redis:
  enabled: true
  auth:
    enabled: false
  master:
    persistence:
      enabled: true
      size: 2Gi
```

```bash
# Update dependencies
helm dependency update my-web-app

# Install with dependencies
helm install my-app ./my-web-app
```

### Step 15: Conditional Templates

```yaml
# templates/hpa.yaml
{{- if .Values.autoscaling.enabled }}
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: {{ include "my-web-app.fullname" . }}
  labels:
    {{- include "my-web-app.labels" . | nindent 4 }}
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: {{ include "my-web-app.fullname" . }}
  minReplicas: {{ .Values.autoscaling.minReplicas }}
  maxReplicas: {{ .Values.autoscaling.maxReplicas }}
  metrics:
    {{- if .Values.autoscaling.targetCPUUtilizationPercentage }}
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: {{ .Values.autoscaling.targetCPUUtilizationPercentage }}
    {{- end }}
    {{- if .Values.autoscaling.targetMemoryUtilizationPercentage }}
    - type: Resource
      resource:
        name: memory
        target:
          type: Utilization
          averageUtilization: {{ .Values.autoscaling.targetMemoryUtilizationPercentage }}
    {{- end }}
{{- end }}
```

### Step 16: Hooks and Tests

```yaml
# templates/tests/test-connection.yaml
apiVersion: v1
kind: Pod
metadata:
  name: "{{ include "my-web-app.fullname" . }}-test"
  labels:
    {{- include "my-web-app.labels" . | nindent 4 }}
  annotations:
    "helm.sh/hook": test
    "helm.sh/hook-weight": "1"
    "helm.sh/hook-delete-policy": before-hook-creation,hook-succeeded
spec:
  restartPolicy: Never
  containers:
    - name: wget
      image: busybox
      command: ['wget']
      args: ['{{ include "my-web-app.fullname" . }}:{{ .Values.service.port }}']
```

```yaml
# templates/job-migration.yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: "{{ include "my-web-app.fullname" . }}-migration"
  labels:
    {{- include "my-web-app.labels" . | nindent 4 }}
  annotations:
    "helm.sh/hook": pre-install,pre-upgrade
    "helm.sh/hook-weight": "-5"
    "helm.sh/hook-delete-policy": before-hook-creation,hook-succeeded
spec:
  template:
    metadata:
      name: "{{ include "my-web-app.fullname" . }}-migration"
    spec:
      restartPolicy: Never
      containers:
      - name: migration
        image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
        command: ['sh', '-c']
        args:
        - |
          echo "Running database migrations..."
          sleep 5
          echo "Migrations completed"
        env:
        - name: DATABASE_URL
          value: {{ include "my-web-app.databaseUrl" . | quote }}
```

## Release Management

### Step 17: Install and Manage Releases

```bash
# Install the chart
helm install my-app ./my-web-app

# Install in specific namespace
helm install my-app ./my-web-app --namespace myapp --create-namespace

# Install with custom values
helm install my-app ./my-web-app -f production-values.yaml

# Upgrade a release
helm upgrade my-app ./my-web-app

# Upgrade with new values
helm upgrade my-app ./my-web-app --set replicaCount=5

# Rollback to previous version
helm rollback my-app

# Rollback to specific version
helm rollback my-app 2

# Uninstall release
helm uninstall my-app

# Run tests
helm test my-app
```

### Step 18: Production Deployment

```yaml
# production-values.yaml
replicaCount: 3

image:
  repository: my-registry.com/my-web-app
  tag: "v1.2.3"
  pullPolicy: Always

imagePullSecrets:
  - name: registry-secret

service:
  type: ClusterIP
  port: 80

ingress:
  enabled: true
  className: nginx
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
  hosts:
    - host: myapp.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: myapp-tls
      hosts:
        - myapp.example.com

autoscaling:
  enabled: true
  minReplicas: 3
  maxReplicas: 20
  targetCPUUtilizationPercentage: 70
  targetMemoryUtilizationPercentage: 80

resources:
  limits:
    cpu: 1000m
    memory: 1Gi
  requests:
    cpu: 500m
    memory: 512Mi

app:
  environment: production
  debug: false
  database:
    host: postgres.example.com
    port: 5432
    name: myapp_prod
    user: myapp_user

nodeSelector:
  node-type: application

tolerations:
  - key: application
    operator: Equal
    value: "true"
    effect: NoSchedule

affinity:
  podAntiAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
    - labelSelector:
        matchExpressions:
        - key: app.kubernetes.io/name
          operator: In
          values:
          - my-web-app
      topologyKey: kubernetes.io/hostname

postgresql:
  enabled: false  # Use external database

redis:
  enabled: true
  auth:
    enabled: true
    password: "redis-prod-password"
  master:
    persistence:
      enabled: true
      size: 10Gi
      storageClass: fast-ssd
```

## Chart Repositories

### Step 19: Package and Publish Charts

```bash
# Package your chart
helm package my-web-app

# Create chart repository index
helm repo index . --url https://mycompany.github.io/helm-charts

# Add your repository
helm repo add mycompany https://mycompany.github.io/helm-charts

# Install from your repository
helm install my-app mycompany/my-web-app
```

### Step 20: Chart Museum (Self-hosted Repository)

```yaml
# chartmuseum-values.yaml
env:
  open:
    STORAGE: local
    STORAGE_LOCAL_ROOTDIR: /charts
    DEBUG: true
    ALLOW_OVERWRITE: true
    AUTH_ANONYMOUS_GET: true

persistence:
  enabled: true
  size: 10Gi

ingress:
  enabled: true
  hosts:
    - name: charts.example.com
      path: /
```

```bash
# Install ChartMuseum
helm repo add chartmuseum https://chartmuseum.github.io/charts
helm install chartmuseum chartmuseum/chartmuseum -f chartmuseum-values.yaml

# Upload charts to ChartMuseum
curl --data-binary "@my-web-app-0.1.0.tgz" http://charts.example.com/api/charts
```

## Troubleshooting and Best Practices

### Common Issues

```bash
# Debug template rendering
helm template my-app ./my-web-app --debug

# Check for template errors
helm lint my-web-app

# Validate against Kubernetes API
helm template my-app ./my-web-app | kubectl apply --dry-run=client -f -

# Check release status
helm status my-app

# Get release history
helm history my-app

# Check hooks
kubectl get jobs,pods -l app.kubernetes.io/managed-by=Helm

# Debug failed releases
helm get all my-app
```

### Best Practices

1. **Chart Structure**
   - Use semantic versioning
   - Include comprehensive README
   - Provide examples and documentation

2. **Values Design**
   - Use nested structure for organization
   - Provide sensible defaults
   - Document all options

3. **Templates**
   - Use helper templates for reusability
   - Include proper labels and annotations
   - Implement health checks

4. **Security**
   - Use specific image tags
   - Implement resource limits
   - Configure security contexts

5. **Production Readiness**
   - Include monitoring and logging
   - Implement proper networking
   - Handle secrets properly

## Practice Exercises

### Exercise 1: Multi-Tier Application Chart

1. Create a chart for a web application with database
2. Include frontend, backend, and database components
3. Implement proper service discovery
4. Add monitoring and health checks

### Exercise 2: Microservices Chart

1. Create umbrella chart for microservices
2. Use subcharts for individual services
3. Implement service mesh integration
4. Add inter-service communication

### Exercise 3: Chart Repository

1. Set up private chart repository
2. Implement CI/CD for chart updates
3. Add chart testing and validation
4. Create release automation

## Cleanup

```bash
# Remove releases
helm uninstall my-nginx my-nginx-custom my-nginx-inline my-app

# Remove repositories
helm repo remove stable bitnami ingress-nginx

# Clean up chart files
rm -rf my-web-app
rm -f *.tgz nginx-values.yaml test-values.yaml production-values.yaml
```

## Key Takeaways

- ✅ Helm simplifies Kubernetes application management
- ✅ Charts provide reusable, configurable application packages
- ✅ Templates enable dynamic manifest generation
- ✅ Release management provides versioning and rollbacks
- ✅ Repositories enable chart sharing and distribution
- ✅ Best practices ensure maintainable, secure charts

## What's Next?

You now understand Helm package management! Next, we'll learn about monitoring and logging:

- Prometheus and Grafana setup
- Application monitoring patterns
- Log aggregation and analysis
- Alerting and observability

**Ready?** Continue to [Lesson 11: Monitoring and Logging](../11-monitoring-logging/README.md)

## Quick Reference

```bash
# Chart operations
helm create <chart-name>
helm lint <chart-path>
helm package <chart-path>
helm template <release-name> <chart-path>

# Repository operations
helm repo add <name> <url>
helm repo update
helm search repo <keyword>

# Release operations
helm install <release-name> <chart>
helm upgrade <release-name> <chart>
helm rollback <release-name> <revision>
helm uninstall <release-name>

# Information
helm list
helm status <release-name>
helm history <release-name>
helm get values <release-name>
```
