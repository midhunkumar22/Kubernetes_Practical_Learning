# Lesson 11: Monitoring and Logging

## Learning Objectives

By the end of this lesson, you will:

- Set up monitoring infrastructure with Prometheus and Grafana
- Implement application metrics and observability
- Configure log aggregation with Fluentd/Fluent Bit
- Create alerts and notification systems
- Monitor cluster health and resource usage
- Implement distributed tracing
- Build comprehensive dashboards

## Why Monitoring and Logging?

**In production Kubernetes, you need visibility into:**

- **Application Performance**: Response times, error rates, throughput
- **Infrastructure Health**: CPU, memory, disk, network usage
- **Cluster State**: Pod status, node health, resource allocation
- **Business Metrics**: User activity, feature usage, revenue impact

**The Three Pillars of Observability:**

- **Metrics**: Time-series data (CPU usage, request count)
- **Logs**: Event records with context
- **Traces**: Request flow through distributed systems

## Setting Up Prometheus and Grafana

### Step 1: Install Prometheus Stack

```bash
# Add Prometheus community repository
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Create monitoring namespace
kubectl create namespace monitoring

# Install Prometheus stack (includes Grafana, AlertManager)
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false \
  --set prometheus.prometheusSpec.podMonitorSelectorNilUsesHelmValues=false

# Check installation
kubectl get pods -n monitoring
kubectl get services -n monitoring
```

### Step 2: Access Grafana Dashboard

```bash
# Get Grafana admin password
kubectl get secret -n monitoring prometheus-grafana \
  -o jsonpath="{.data.admin-password}" | base64 --decode && echo

# Port forward to access Grafana
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80

# Access: http://localhost:3000
# Username: admin
# Password: (from command above)
```

### Step 3: Access Prometheus UI

```bash
# Port forward to access Prometheus
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090

# Access: http://localhost:9090
```

## Application Metrics

### Step 4: Create Monitored Application

```yaml
# monitored-app.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: monitored-app
  labels:
    app: monitored-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: monitored-app
  template:
    metadata:
      labels:
        app: monitored-app
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "8080"
        prometheus.io/path: "/metrics"
    spec:
      containers:
      - name: app
        image: nginx:1.21
        ports:
        - containerPort: 80
          name: http
        - containerPort: 8080
          name: metrics
        resources:
          requests:
            memory: "64Mi"
            cpu: "100m"
          limits:
            memory: "128Mi"
            cpu: "200m"
        # Add metrics endpoint simulation
        command: ["/bin/sh"]
        args:
        - -c
        - |
          # Create simple metrics endpoint
          cat > /etc/nginx/conf.d/metrics.conf << 'EOF'
          server {
              listen 8080;
              location /metrics {
                  access_log off;
                  return 200 '# HELP nginx_requests_total Total nginx requests
          # TYPE nginx_requests_total counter
          nginx_requests_total{method="GET",status="200"} 1027
          nginx_requests_total{method="POST",status="200"} 234
          nginx_requests_total{method="GET",status="404"} 12
          
          # HELP nginx_request_duration_seconds Request duration
          # TYPE nginx_request_duration_seconds histogram
          nginx_request_duration_seconds_bucket{le="0.1"} 500
          nginx_request_duration_seconds_bucket{le="0.5"} 800
          nginx_request_duration_seconds_bucket{le="1.0"} 900
          nginx_request_duration_seconds_bucket{le="+Inf"} 1000
          nginx_request_duration_seconds_sum 450.5
          nginx_request_duration_seconds_count 1000
          
          # HELP nginx_active_connections Active connections
          # TYPE nginx_active_connections gauge
          nginx_active_connections 42
          ';
                  add_header Content-Type text/plain;
              }
              
              location /health {
                  access_log off;
                  return 200 'healthy';
                  add_header Content-Type text/plain;
              }
          }
          EOF
          
          # Start nginx
          nginx -g 'daemon off;'
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 10
          periodSeconds: 5
        readinessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 3

---
apiVersion: v1
kind: Service
metadata:
  name: monitored-app-service
  labels:
    app: monitored-app
spec:
  selector:
    app: monitored-app
  ports:
  - name: http
    port: 80
    targetPort: 80
  - name: metrics
    port: 8080
    targetPort: 8080
```

```bash
# Deploy the monitored application
kubectl apply -f monitored-app.yaml

# Check metrics endpoint
kubectl port-forward svc/monitored-app-service 8080:8080
curl http://localhost:8080/metrics
```

### Step 5: Create ServiceMonitor

```yaml
# service-monitor.yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: monitored-app-metrics
  labels:
    app: monitored-app
spec:
  selector:
    matchLabels:
      app: monitored-app
  endpoints:
  - port: metrics
    interval: 30s
    path: /metrics
    honorLabels: true
```

```bash
# Apply ServiceMonitor
kubectl apply -f service-monitor.yaml

# Check if Prometheus discovers the target
# In Prometheus UI: Status > Targets
```

## Custom Metrics with Node Exporter

### Step 6: Deploy Node Exporter

```yaml
# node-exporter.yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: node-exporter
  namespace: monitoring
  labels:
    app: node-exporter
spec:
  selector:
    matchLabels:
      app: node-exporter
  template:
    metadata:
      labels:
        app: node-exporter
    spec:
      hostNetwork: true
      hostPID: true
      containers:
      - name: node-exporter
        image: prom/node-exporter:v1.6.1
        args:
        - --web.listen-address=:9100
        - --path.procfs=/host/proc
        - --path.sysfs=/host/sys
        - --path.rootfs=/host/root
        - --collector.filesystem.ignored-mount-points
        - ^/(dev|proc|sys|var/lib/docker/.+|var/lib/kubelet/.+)($|/)
        - --collector.filesystem.ignored-fs-types
        - ^(autofs|binfmt_misc|bpf|cgroup2?|configfs|debugfs|devpts|devtmpfs|fusectl|hugetlbfs|iso9660|mqueue|nsfs|overlay|proc|procfs|pstore|rpc_pipefs|securityfs|selinuxfs|squashfs|sysfs|tracefs)$
        ports:
        - containerPort: 9100
          name: metrics
        resources:
          requests:
            memory: "64Mi"
            cpu: "100m"
          limits:
            memory: "128Mi"
            cpu: "200m"
        volumeMounts:
        - name: proc
          mountPath: /host/proc
          readOnly: true
        - name: sys
          mountPath: /host/sys
          readOnly: true
        - name: root
          mountPath: /host/root
          readOnly: true
      volumes:
      - name: proc
        hostPath:
          path: /proc
      - name: sys
        hostPath:
          path: /sys
      - name: root
        hostPath:
          path: /
      tolerations:
      - effect: NoSchedule
        operator: Exists

---
apiVersion: v1
kind: Service
metadata:
  name: node-exporter
  namespace: monitoring
  labels:
    app: node-exporter
spec:
  selector:
    app: node-exporter
  ports:
  - name: metrics
    port: 9100
    targetPort: 9100

---
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: node-exporter
  namespace: monitoring
  labels:
    app: node-exporter
spec:
  selector:
    matchLabels:
      app: node-exporter
  endpoints:
  - port: metrics
    interval: 30s
```

```bash
# Deploy Node Exporter
kubectl apply -f node-exporter.yaml

# Check node metrics
kubectl port-forward -n monitoring svc/node-exporter 9100:9100
curl http://localhost:9100/metrics | grep node_cpu
```

## Log Aggregation

### Step 7: Deploy Fluent Bit

```yaml
# fluent-bit-config.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: fluent-bit-config
  namespace: kube-system
data:
  fluent-bit.conf: |
    [SERVICE]
        Daemon Off
        Flush 1
        Log_Level info
        Parsers_File parsers.conf
        Plugins_File plugins.conf
        HTTP_Server On
        HTTP_Listen 0.0.0.0
        HTTP_Port 2020
        Health_Check On

    [INPUT]
        Name tail
        Path /var/log/containers/*.log
        multiline.parser docker, cri
        Tag kube.*
        Mem_Buf_Limit 50MB
        Skip_Long_Lines On

    [INPUT]
        Name systemd
        Tag host.*
        Systemd_Filter _SYSTEMD_UNIT=kubelet.service
        Read_From_Tail On

    [FILTER]
        Name kubernetes
        Match kube.*
        Kube_URL https://kubernetes.default.svc:443
        Kube_CA_File /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
        Kube_Token_File /var/run/secrets/kubernetes.io/serviceaccount/token
        Kube_Tag_Prefix kube.var.log.containers.
        Merge_Log On
        Keep_Log Off
        K8S-Logging.Parser On
        K8S-Logging.Exclude Off

    [FILTER]
        Name modify
        Match kube.*
        Add cluster_name my-cluster
        Add node_name ${NODE_NAME}

    [OUTPUT]
        Name stdout
        Match *
        Format json_lines

    [OUTPUT]
        Name forward
        Match kube.*
        Host fluentd.logging.svc.cluster.local
        Port 24224
        tls off

  parsers.conf: |
    [PARSER]
        Name docker
        Format json
        Time_Key time
        Time_Format %Y-%m-%dT%H:%M:%S.%L
        Time_Keep On

    [PARSER]
        Name cri
        Format regex
        Regex ^(?<time>[^ ]+) (?<stream>stdout|stderr) (?<logtag>[^ ]*) (?<message>.*)$
        Time_Key time
        Time_Format %Y-%m-%dT%H:%M:%S.%L%z

  plugins.conf: |
    [PLUGINS]
        Path /fluent-bit/bin/out_td.so
        Path /fluent-bit/bin/out_retry.so

---
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: fluent-bit
  namespace: kube-system
  labels:
    app: fluent-bit
spec:
  selector:
    matchLabels:
      app: fluent-bit
  template:
    metadata:
      labels:
        app: fluent-bit
    spec:
      serviceAccountName: fluent-bit
      containers:
      - name: fluent-bit
        image: cr.fluentbit.io/fluent/fluent-bit:2.1
        ports:
        - containerPort: 2020
          name: http
        env:
        - name: NODE_NAME
          valueFrom:
            fieldRef:
              fieldPath: spec.nodeName
        resources:
          requests:
            memory: "64Mi"
            cpu: "100m"
          limits:
            memory: "128Mi"
            cpu: "200m"
        volumeMounts:
        - name: config
          mountPath: /fluent-bit/etc/
        - name: varlog
          mountPath: /var/log
          readOnly: true
        - name: varlibdockercontainers
          mountPath: /var/lib/docker/containers
          readOnly: true
        - name: systemd
          mountPath: /var/log/journal
          readOnly: true
      volumes:
      - name: config
        configMap:
          name: fluent-bit-config
      - name: varlog
        hostPath:
          path: /var/log
      - name: varlibdockercontainers
        hostPath:
          path: /var/lib/docker/containers
      - name: systemd
        hostPath:
          path: /var/log/journal
      tolerations:
      - effect: NoSchedule
        operator: Exists

---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: fluent-bit
  namespace: kube-system

---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: fluent-bit
rules:
- apiGroups: [""]
  resources: ["pods", "namespaces"]
  verbs: ["get", "list", "watch"]

---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: fluent-bit
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: fluent-bit
subjects:
- kind: ServiceAccount
  name: fluent-bit
  namespace: kube-system
```

### Step 8: Deploy Elasticsearch and Kibana

```bash
# Add Elastic repository
helm repo add elastic https://helm.elastic.co
helm repo update

# Create logging namespace
kubectl create namespace logging

# Install Elasticsearch
helm install elasticsearch elastic/elasticsearch \
  --namespace logging \
  --set replicas=1 \
  --set minimumMasterNodes=1 \
  --set resources.requests.memory="1Gi" \
  --set resources.limits.memory="2Gi"

# Install Kibana
helm install kibana elastic/kibana \
  --namespace logging \
  --set elasticsearchHosts="http://elasticsearch-master:9200"

# Check deployment
kubectl get pods -n logging
```

### Step 9: Configure Fluentd for Log Forwarding

```yaml
# fluentd-config.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: fluentd-config
  namespace: logging
data:
  fluent.conf: |
    <source>
      @type forward
      port 24224
      bind 0.0.0.0
    </source>

    <filter kube.**>
      @type kubernetes_metadata
    </filter>

    <filter kube.**>
      @type record_transformer
      <record>
        cluster_name my-cluster
        log_type kubernetes
      </record>
    </filter>

    <match kube.**>
      @type elasticsearch
      host elasticsearch-master.logging.svc.cluster.local
      port 9200
      index_name kubernetes-%Y.%m.%d
      type_name _doc
      include_tag_key true
      tag_key @log_name
      <buffer>
        @type file
        path /var/log/fluentd-buffers/kubernetes.system.buffer
        flush_mode interval
        retry_type exponential_backoff
        flush_thread_count 2
        flush_interval 5s
        retry_forever
        retry_max_interval 30
        chunk_limit_size 2M
        queue_limit_length 8
        overflow_action block
      </buffer>
    </match>

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: fluentd
  namespace: logging
spec:
  replicas: 1
  selector:
    matchLabels:
      app: fluentd
  template:
    metadata:
      labels:
        app: fluentd
    spec:
      containers:
      - name: fluentd
        image: fluent/fluentd-kubernetes-daemonset:v1.16-debian-elasticsearch7-1
        ports:
        - containerPort: 24224
          name: forward
        env:
        - name: FLUENTD_CONF
          value: fluent.conf
        resources:
          requests:
            memory: "256Mi"
            cpu: "200m"
          limits:
            memory: "512Mi"
            cpu: "400m"
        volumeMounts:
        - name: config
          mountPath: /fluentd/etc/fluent.conf
          subPath: fluent.conf
        - name: buffer
          mountPath: /var/log/fluentd-buffers
      volumes:
      - name: config
        configMap:
          name: fluentd-config
      - name: buffer
        emptyDir: {}

---
apiVersion: v1
kind: Service
metadata:
  name: fluentd
  namespace: logging
spec:
  selector:
    app: fluentd
  ports:
  - name: forward
    port: 24224
    targetPort: 24224
```

```bash
# Deploy Fluentd
kubectl apply -f fluent-bit-config.yaml
kubectl apply -f fluentd-config.yaml

# Access Kibana
kubectl port-forward -n logging svc/kibana-kibana 5601:5601
# Visit: http://localhost:5601
```

## Alerting

### Step 10: Configure AlertManager

```yaml
# alertmanager-config.yaml
apiVersion: v1
kind: Secret
metadata:
  name: alertmanager-prometheus-kube-prometheus-alertmanager
  namespace: monitoring
stringData:
  alertmanager.yml: |
    global:
      smtp_smarthost: 'smtp.gmail.com:587'
      smtp_from: 'alerts@example.com'
      smtp_auth_username: 'alerts@example.com'
      smtp_auth_password: 'app-password'

    route:
      group_by: ['alertname', 'cluster', 'service']
      group_wait: 30s
      group_interval: 5m
      repeat_interval: 12h
      receiver: 'web.hook'
      routes:
      - match:
          severity: critical
        receiver: 'critical-alerts'
      - match:
          severity: warning
        receiver: 'warning-alerts'

    receivers:
    - name: 'web.hook'
      webhook_configs:
      - url: 'http://localhost:5001/webhook'
        send_resolved: true

    - name: 'critical-alerts'
      email_configs:
      - to: 'oncall@example.com'
        subject: 'CRITICAL: {{ .GroupLabels.alertname }}'
        body: |
          {{ range .Alerts }}
          Alert: {{ .Annotations.summary }}
          Description: {{ .Annotations.description }}
          Runbook: {{ .Annotations.runbook_url }}
          {{ end }}
      slack_configs:
      - api_url: 'https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK'
        channel: '#critical-alerts'
        title: 'Critical Alert'
        text: '{{ range .Alerts }}{{ .Annotations.summary }}{{ end }}'

    - name: 'warning-alerts'
      email_configs:
      - to: 'team@example.com'
        subject: 'WARNING: {{ .GroupLabels.alertname }}'
        body: |
          {{ range .Alerts }}
          Alert: {{ .Annotations.summary }}
          Description: {{ .Annotations.description }}
          {{ end }}
```

### Step 11: Create Custom Alerts

```yaml
# custom-alerts.yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: custom-application-alerts
  namespace: monitoring
  labels:
    prometheus: kube-prometheus
    role: alert-rules
spec:
  groups:
  - name: application.rules
    rules:
    - alert: HighErrorRate
      expr: |
        (
          rate(nginx_requests_total{status=~"5.."}[5m])
          /
          rate(nginx_requests_total[5m])
        ) > 0.1
      for: 5m
      labels:
        severity: critical
      annotations:
        summary: "High error rate detected"
        description: "Error rate is {{ $value | humanizePercentage }} for {{ $labels.instance }}"
        runbook_url: "https://runbooks.example.com/high-error-rate"

    - alert: HighLatency
      expr: |
        histogram_quantile(0.95, rate(nginx_request_duration_seconds_bucket[5m])) > 0.5
      for: 10m
      labels:
        severity: warning
      annotations:
        summary: "High latency detected"
        description: "95th percentile latency is {{ $value }}s for {{ $labels.instance }}"

    - alert: PodCrashLooping
      expr: |
        rate(kube_pod_container_status_restarts_total[15m]) > 0
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "Pod is crash looping"
        description: "Pod {{ $labels.pod }} in namespace {{ $labels.namespace }} is restarting frequently"

    - alert: NodeHighCPU
      expr: |
        100 - (avg by (instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
      for: 10m
      labels:
        severity: warning
      annotations:
        summary: "Node CPU usage is high"
        description: "Node {{ $labels.instance }} CPU usage is {{ $value }}%"

    - alert: NodeHighMemory
      expr: |
        (
          (node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes)
          /
          node_memory_MemTotal_bytes
        ) > 0.85
      for: 5m
      labels:
        severity: critical
      annotations:
        summary: "Node memory usage is high"
        description: "Node {{ $labels.instance }} memory usage is {{ $value | humanizePercentage }}"

    - alert: PodMemoryUsage
      expr: |
        (
          container_memory_working_set_bytes{container!=""}
          /
          container_spec_memory_limit_bytes{container!=""} > 0.9
        )
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "Pod memory usage is high"
        description: "Pod {{ $labels.pod }} memory usage is {{ $value | humanizePercentage }}"

    - alert: PersistentVolumeUsage
      expr: |
        (
          kubelet_volume_stats_used_bytes
          /
          kubelet_volume_stats_capacity_bytes
        ) > 0.85
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "Persistent volume usage is high"
        description: "PV {{ $labels.persistentvolumeclaim }} usage is {{ $value | humanizePercentage }}"
```

```bash
# Apply custom alerts
kubectl apply -f alertmanager-config.yaml
kubectl apply -f custom-alerts.yaml

# Check alert rules
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
# Visit: http://localhost:9090/alerts
```

## Grafana Dashboards

### Step 12: Create Custom Dashboard

```json
{
  "dashboard": {
    "id": null,
    "title": "Kubernetes Application Dashboard",
    "tags": ["kubernetes", "application"],
    "timezone": "browser",
    "panels": [
      {
        "id": 1,
        "title": "Request Rate",
        "type": "stat",
        "targets": [
          {
            "expr": "sum(rate(nginx_requests_total[5m]))",
            "legendFormat": "Requests/sec"
          }
        ],
        "gridPos": {"h": 8, "w": 12, "x": 0, "y": 0}
      },
      {
        "id": 2,
        "title": "Error Rate",
        "type": "stat",
        "targets": [
          {
            "expr": "sum(rate(nginx_requests_total{status=~\"5..\"}[5m])) / sum(rate(nginx_requests_total[5m]))",
            "legendFormat": "Error Rate"
          }
        ],
        "gridPos": {"h": 8, "w": 12, "x": 12, "y": 0}
      },
      {
        "id": 3,
        "title": "Response Time",
        "type": "graph",
        "targets": [
          {
            "expr": "histogram_quantile(0.50, rate(nginx_request_duration_seconds_bucket[5m]))",
            "legendFormat": "50th percentile"
          },
          {
            "expr": "histogram_quantile(0.95, rate(nginx_request_duration_seconds_bucket[5m]))",
            "legendFormat": "95th percentile"
          },
          {
            "expr": "histogram_quantile(0.99, rate(nginx_request_duration_seconds_bucket[5m]))",
            "legendFormat": "99th percentile"
          }
        ],
        "gridPos": {"h": 8, "w": 24, "x": 0, "y": 8}
      }
    ],
    "time": {"from": "now-1h", "to": "now"},
    "refresh": "30s"
  }
}
```

### Step 13: Resource Monitoring Dashboard

```bash
# Import community dashboards
# 1. Node Exporter Full: Dashboard ID 1860
# 2. Kubernetes cluster monitoring: Dashboard ID 315
# 3. Kubernetes Pod Monitoring: Dashboard ID 6417

# In Grafana UI:
# + > Import > Enter dashboard ID > Load
```

## Distributed Tracing

### Step 14: Deploy Jaeger

```bash
# Add Jaeger repository
helm repo add jaegertracing https://jaegertracing.github.io/helm-charts
helm repo update

# Install Jaeger
helm install jaeger jaegertracing/jaeger \
  --namespace monitoring \
  --set provisionDataStore.cassandra=false \
  --set allInOne.enabled=true \
  --set storage.type=memory \
  --set agent.enabled=false \
  --set collector.enabled=false \
  --set query.enabled=false

# Access Jaeger UI
kubectl port-forward -n monitoring svc/jaeger-query 16686:16686
# Visit: http://localhost:16686
```

### Step 15: Application with Tracing

```yaml
# traced-app.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: traced-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: traced-app
  template:
    metadata:
      labels:
        app: traced-app
    spec:
      containers:
      - name: app
        image: jaegertracing/example-hotrod:latest
        ports:
        - containerPort: 8080
        env:
        - name: JAEGER_AGENT_HOST
          value: "jaeger-agent.monitoring.svc.cluster.local"
        - name: JAEGER_AGENT_PORT
          value: "6831"
        resources:
          requests:
            memory: "64Mi"
            cpu: "100m"
          limits:
            memory: "128Mi"
            cpu: "200m"

---
apiVersion: v1
kind: Service
metadata:
  name: traced-app-service
spec:
  selector:
    app: traced-app
  ports:
  - port: 8080
    targetPort: 8080
```

```bash
# Deploy traced application
kubectl apply -f traced-app.yaml

# Generate traces
kubectl port-forward svc/traced-app-service 8080:8080
# Visit: http://localhost:8080 and click around to generate traces
```

## Health Checks and SLIs/SLOs

### Step 16: Service Level Indicators

```yaml
# sli-recording-rules.yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: sli-recording-rules
  namespace: monitoring
spec:
  groups:
  - name: sli.rules
    interval: 30s
    rules:
    # Request rate
    - record: sli:request_rate
      expr: sum(rate(nginx_requests_total[5m]))
    
    # Error rate
    - record: sli:error_rate
      expr: |
        sum(rate(nginx_requests_total{status=~"5.."}[5m]))
        /
        sum(rate(nginx_requests_total[5m]))
    
    # Latency percentiles
    - record: sli:latency_p50
      expr: histogram_quantile(0.50, rate(nginx_request_duration_seconds_bucket[5m]))
    
    - record: sli:latency_p95
      expr: histogram_quantile(0.95, rate(nginx_request_duration_seconds_bucket[5m]))
    
    - record: sli:latency_p99
      expr: histogram_quantile(0.99, rate(nginx_request_duration_seconds_bucket[5m]))
    
    # Availability
    - record: sli:availability
      expr: |
        1 - (
          sum(rate(nginx_requests_total{status=~"5.."}[5m]))
          /
          sum(rate(nginx_requests_total[5m]))
        )
    
    # Saturation - CPU
    - record: sli:cpu_utilization
      expr: |
        100 - (avg(irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)
    
    # Saturation - Memory
    - record: sli:memory_utilization
      expr: |
        (
          (node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes)
          /
          node_memory_MemTotal_bytes
        ) * 100
```

### Step 17: SLO Alerts

```yaml
# slo-alerts.yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: slo-alerts
  namespace: monitoring
spec:
  groups:
  - name: slo.rules
    rules:
    # Error budget burn rate alerts
    - alert: HighErrorBudgetBurn
      expr: |
        (
          sli:error_rate > (14.4 * 0.001)  # 14.4x burn rate for 1h window
          and
          sli:error_rate > (14.4 * 0.001)
        )
        or
        (
          sli:error_rate > (6 * 0.001)     # 6x burn rate for 6h window
          and
          sli:error_rate > (6 * 0.001)
        )
      for: 2m
      labels:
        severity: critical
      annotations:
        summary: "High error budget burn rate"
        description: "Error budget is burning too fast. Current error rate: {{ $value | humanizePercentage }}"

    # Latency SLO violation
    - alert: LatencySLOViolation
      expr: sli:latency_p95 > 0.5  # 95th percentile > 500ms
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "Latency SLO violation"
        description: "95th percentile latency is {{ $value }}s, exceeding SLO of 500ms"

    # Availability SLO violation
    - alert: AvailabilitySLOViolation
      expr: sli:availability < 0.999  # 99.9% availability SLO
      for: 2m
      labels:
        severity: critical
      annotations:
        summary: "Availability SLO violation"
        description: "Service availability is {{ $value | humanizePercentage }}, below SLO of 99.9%"
```

## Performance Testing Integration

### Step 18: Load Testing with k6

```yaml
# k6-load-test.yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: k6-load-test
spec:
  template:
    spec:
      containers:
      - name: k6
        image: grafana/k6:latest
        command: ["k6"]
        args: ["run", "--out", "influxdb=http://influxdb:8086/k6", "/scripts/load-test.js"]
        env:
        - name: TARGET_URL
          value: "http://monitored-app-service"
        volumeMounts:
        - name: test-script
          mountPath: /scripts
        resources:
          requests:
            memory: "128Mi"
            cpu: "200m"
          limits:
            memory: "256Mi"
            cpu: "400m"
      volumes:
      - name: test-script
        configMap:
          name: k6-test-script
      restartPolicy: Never

---
apiVersion: v1
kind: ConfigMap
metadata:
  name: k6-test-script
data:
  load-test.js: |
    import http from 'k6/http';
    import { check, sleep } from 'k6';
    
    export let options = {
      stages: [
        { duration: '5m', target: 50 },   // Ramp up
        { duration: '10m', target: 50 },  // Stay at 50 users
        { duration: '5m', target: 100 },  // Ramp up to 100
        { duration: '10m', target: 100 }, // Stay at 100 users
        { duration: '5m', target: 0 },    // Ramp down
      ],
      thresholds: {
        http_req_duration: ['p(95)<500'], // 95% of requests under 500ms
        http_req_failed: ['rate<0.01'],   // Error rate under 1%
      },
    };
    
    export default function() {
      let response = http.get(`${__ENV.TARGET_URL}/`);
      
      check(response, {
        'status is 200': (r) => r.status === 200,
        'response time < 500ms': (r) => r.timings.duration < 500,
      });
      
      sleep(1);
    }
```

```bash
# Run load test
kubectl apply -f k6-load-test.yaml

# Monitor during load test
kubectl logs job/k6-load-test -f
```

## Monitoring Best Practices

### Step 19: Resource Monitoring

```yaml
# resource-quotas.yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: monitoring-quota
  namespace: monitoring
spec:
  hard:
    requests.cpu: "4"
    requests.memory: "8Gi"
    limits.cpu: "8"
    limits.memory: "16Gi"
    persistentvolumeclaims: "10"

---
apiVersion: v1
kind: LimitRange
metadata:
  name: monitoring-limits
  namespace: monitoring
spec:
  limits:
  - default:
      cpu: "200m"
      memory: "256Mi"
    defaultRequest:
      cpu: "100m"
      memory: "128Mi"
    type: Container
```

### Step 20: Cleanup and Maintenance

```bash
# Set up monitoring cleanup job
kubectl create job prometheus-cleanup \
  --image=prom/prometheus:latest \
  --dry-run=client -o yaml -- \
  prometheus-tool query \
  --query.timeout=60s \
  '{__name__=~"prometheus_tsdb_.*"}' > cleanup-job.yaml

# Add retention policies in prometheus configuration
# retention.time: "30d"
# retention.size: "100GB"
```

## Practice Exercises

### Exercise 1: Complete Monitoring Setup

1. Deploy a multi-tier application
2. Set up comprehensive monitoring
3. Create custom dashboards
4. Configure alerting rules
5. Implement SLI/SLO monitoring

### Exercise 2: Log Analysis Pipeline

1. Set up centralized logging
2. Create log parsing rules
3. Build log analysis dashboards
4. Implement log-based alerting
5. Set up log retention policies

### Exercise 3: Performance Monitoring

1. Implement distributed tracing
2. Set up performance testing
3. Create performance dashboards
4. Monitor resource utilization
5. Optimize based on metrics

## Cleanup

```bash
# Remove monitoring stack
helm uninstall prometheus -n monitoring
helm uninstall jaeger -n monitoring

# Remove logging stack
helm uninstall elasticsearch kibana -n logging
kubectl delete -f fluent-bit-config.yaml
kubectl delete -f fluentd-config.yaml

# Remove test applications
kubectl delete -f monitored-app.yaml
kubectl delete -f traced-app.yaml
kubectl delete job k6-load-test

# Remove namespaces
kubectl delete namespace monitoring logging

# Remove configurations
kubectl delete -f service-monitor.yaml
kubectl delete -f custom-alerts.yaml
kubectl delete -f sli-recording-rules.yaml
kubectl delete -f slo-alerts.yaml
```

## Key Takeaways

- ✅ Prometheus provides powerful metrics collection and alerting
- ✅ Grafana enables rich visualization and dashboards
- ✅ Centralized logging improves troubleshooting capabilities
- ✅ Distributed tracing helps debug complex systems
- ✅ SLI/SLO monitoring ensures service reliability
- ✅ Proactive alerting prevents issues from escalating

## What's Next?

You now have comprehensive monitoring and logging! Next, we'll cover best practices and troubleshooting:

- Production readiness checklist
- Security best practices
- Performance optimization
- Disaster recovery planning

**Ready?** Continue to [Lesson 12: Best Practices and Troubleshooting](../12-best-practices-troubleshooting/README.md)

## Quick Reference

```bash
# Prometheus queries
rate(http_requests_total[5m])                    # Request rate
histogram_quantile(0.95, rate(http_duration[5m])) # 95th percentile latency
up == 0                                          # Service down
increase(error_count[1h])                        # Error increase

# Grafana shortcuts
Ctrl+K: Dashboard search
Ctrl+H: Hide/show controls
Ctrl+S: Save dashboard
Ctrl+Z: Zoom out

# kubectl monitoring
kubectl top nodes
kubectl top pods
kubectl describe pod <name>
kubectl logs -f <pod> -c <container>
```
