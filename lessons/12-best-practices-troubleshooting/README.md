# Lesson 12: Best Practices and Troubleshooting

## Learning Objectives

By the end of this lesson, you will:

- Implement Kubernetes security best practices
- Optimize cluster performance and resource usage
- Develop effective troubleshooting strategies
- Create disaster recovery and backup plans
- Establish CI/CD pipelines for Kubernetes
- Apply production readiness principles
- Handle common Kubernetes issues

## Security Best Practices

### Step 1: Pod Security Standards

```yaml
# pod-security-policy.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: secure-app
  labels:
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/warn: restricted

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: secure-app
  namespace: secure-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: secure-app
  template:
    metadata:
      labels:
        app: secure-app
    spec:
      serviceAccountName: secure-app-sa
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
        runAsGroup: 3000
        fsGroup: 2000
        seccompProfile:
          type: RuntimeDefault
      containers:
      - name: app
        image: nginx:1.21
        ports:
        - containerPort: 8080
        securityContext:
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: true
          runAsNonRoot: true
          runAsUser: 1000
          capabilities:
            drop:
            - ALL
            add:
            - NET_BIND_SERVICE
        resources:
          requests:
            memory: "64Mi"
            cpu: "100m"
          limits:
            memory: "128Mi"
            cpu: "200m"
        volumeMounts:
        - name: tmp
          mountPath: /tmp
        - name: var-cache
          mountPath: /var/cache/nginx
        - name: var-run
          mountPath: /var/run
        livenessProbe:
          httpGet:
            path: /
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 5
      volumes:
      - name: tmp
        emptyDir: {}
      - name: var-cache
        emptyDir: {}
      - name: var-run
        emptyDir: {}

---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: secure-app-sa
  namespace: secure-app
automountServiceAccountToken: false
```

### Step 2: Network Policies

```yaml
# network-policies.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: secure-app
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress

---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-frontend-to-backend
  namespace: secure-app
spec:
  podSelector:
    matchLabels:
      tier: backend
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          tier: frontend
    ports:
    - protocol: TCP
      port: 8080

---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-backend-to-database
  namespace: secure-app
spec:
  podSelector:
    matchLabels:
      tier: backend
  policyTypes:
  - Egress
  egress:
  - to:
    - podSelector:
        matchLabels:
          tier: database
    ports:
    - protocol: TCP
      port: 5432

---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-dns-egress
  namespace: secure-app
spec:
  podSelector: {}
  policyTypes:
  - Egress
  egress:
  - to: []
    ports:
    - protocol: UDP
      port: 53
    - protocol: TCP
      port: 53
```

### Step 3: RBAC Configuration

```yaml
# rbac.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: app-reader
  namespace: secure-app

---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: app-reader-role
  namespace: secure-app
rules:
- apiGroups: [""]
  resources: ["pods", "services", "configmaps"]
  verbs: ["get", "list", "watch"]
- apiGroups: ["apps"]
  resources: ["deployments", "replicasets"]
  verbs: ["get", "list", "watch"]

---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: app-reader-binding
  namespace: secure-app
subjects:
- kind: ServiceAccount
  name: app-reader
  namespace: secure-app
roleRef:
  kind: Role
  name: app-reader-role
  apiGroup: rbac.authorization.k8s.io

---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: node-reader
rules:
- apiGroups: [""]
  resources: ["nodes", "nodes/status"]
  verbs: ["get", "list", "watch"]

---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: node-reader-binding
subjects:
- kind: ServiceAccount
  name: monitoring-sa
  namespace: monitoring
roleRef:
  kind: ClusterRole
  name: node-reader
  apiGroup: rbac.authorization.k8s.io
```

### Step 4: Secrets Management

```yaml
# secrets-management.yaml
apiVersion: v1
kind: Secret
metadata:
  name: app-secrets
  namespace: secure-app
type: Opaque
data:
  database-url: cG9zdGdyZXNxbDovL3VzZXI6cGFzc0BkYi5leGFtcGxlLmNvbTo1NDMyL215ZGI=
  api-key: bXktc2VjcmV0LWFwaS1rZXktMTIzNDU=
  jwt-secret: and0LXNlY3JldC1rZXktZm9yLWF1dGhlbnRpY2F0aW9u

---
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: vault-backend
  namespace: secure-app
spec:
  provider:
    vault:
      server: "https://vault.example.com"
      path: "secret"
      version: "v2"
      auth:
        kubernetes:
          mountPath: "kubernetes"
          role: "myapp"

---
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: vault-secret
  namespace: secure-app
spec:
  refreshInterval: 60s
  secretStoreRef:
    name: vault-backend
    kind: SecretStore
  target:
    name: vault-secret
    creationPolicy: Owner
  data:
  - secretKey: database-password
    remoteRef:
      key: myapp/database
      property: password
  - secretKey: api-key
    remoteRef:
      key: myapp/api
      property: key
```

### Step 5: Image Security

```yaml
# image-security.yaml
apiVersion: v1
kind: Pod
metadata:
  name: secure-pod
  namespace: secure-app
spec:
  imagePullSecrets:
  - name: registry-secret
  containers:
  - name: app
    image: myregistry.com/myapp:v1.2.3-sha256@sha256:abcd1234...  # Use digest
    imagePullPolicy: Always
    securityContext:
      allowPrivilegeEscalation: false
      readOnlyRootFilesystem: true
      runAsNonRoot: true
      runAsUser: 1000
      capabilities:
        drop:
        - ALL

---
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-image-signature
spec:
  validationFailureAction: enforce
  background: false
  rules:
  - name: check-signature
    match:
      any:
      - resources:
          kinds:
          - Pod
    verifyImages:
    - imageReferences:
      - "myregistry.com/*"
      attestors:
      - entries:
        - keys:
            publicKeys: |-
              -----BEGIN PUBLIC KEY-----
              MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAE...
              -----END PUBLIC KEY-----
```

## Performance Optimization

### Step 6: Resource Management

```yaml
# resource-optimization.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: production
  labels:
    name: production

---
apiVersion: v1
kind: ResourceQuota
metadata:
  name: production-quota
  namespace: production
spec:
  hard:
    requests.cpu: "10"
    requests.memory: "20Gi"
    limits.cpu: "20"
    limits.memory: "40Gi"
    requests.nvidia.com/gpu: "2"
    persistentvolumeclaims: "10"
    count/pods: "50"
    count/services: "10"

---
apiVersion: v1
kind: LimitRange
metadata:
  name: production-limits
  namespace: production
spec:
  limits:
  - default:
      cpu: "200m"
      memory: "256Mi"
    defaultRequest:
      cpu: "100m"
      memory: "128Mi"
    max:
      cpu: "2"
      memory: "4Gi"
    min:
      cpu: "50m"
      memory: "64Mi"
    type: Container
  - default:
      storage: "10Gi"
    max:
      storage: "100Gi"
    min:
      storage: "1Gi"
    type: PersistentVolumeClaim
```

### Step 7: Horizontal Pod Autoscaler (HPA)

```yaml
# hpa-optimization.yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: web-app-hpa
  namespace: production
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: web-app
  minReplicas: 3
  maxReplicas: 50
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
  - type: Pods
    pods:
      metric:
        name: custom_metric
      target:
        type: AverageValue
        averageValue: "100"
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
      - type: Percent
        value: 10
        periodSeconds: 60
    scaleUp:
      stabilizationWindowSeconds: 60
      policies:
      - type: Percent
        value: 100
        periodSeconds: 15
      - type: Pods
        value: 5
        periodSeconds: 60
      selectPolicy: Max

---
apiVersion: autoscaling/v1
kind: VerticalPodAutoscaler
metadata:
  name: web-app-vpa
  namespace: production
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: web-app
  updatePolicy:
    updateMode: "Auto"
  resourcePolicy:
    containerPolicies:
    - containerName: web-app
      minAllowed:
        cpu: "100m"
        memory: "128Mi"
      maxAllowed:
        cpu: "2"
        memory: "4Gi"
      controlledResources: ["cpu", "memory"]
```

### Step 8: Node Optimization

```yaml
# node-optimization.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cpu-intensive-app
  namespace: production
spec:
  replicas: 3
  selector:
    matchLabels:
      app: cpu-intensive-app
  template:
    metadata:
      labels:
        app: cpu-intensive-app
    spec:
      nodeSelector:
        node-type: compute-optimized
      tolerations:
      - key: compute-intensive
        operator: Equal
        value: "true"
        effect: NoSchedule
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: kubernetes.io/arch
                operator: In
                values: ["amd64"]
              - key: node.kubernetes.io/instance-type
                operator: In
                values: ["c5.xlarge", "c5.2xlarge"]
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            podAffinityTerm:
              labelSelector:
                matchExpressions:
                - key: app
                  operator: In
                  values: ["cpu-intensive-app"]
              topologyKey: kubernetes.io/hostname
      containers:
      - name: app
        image: cpu-intensive-app:latest
        resources:
          requests:
            cpu: "1"
            memory: "2Gi"
          limits:
            cpu: "2"
            memory: "4Gi"
        env:
        - name: GOMAXPROCS
          valueFrom:
            resourceFieldRef:
              resource: limits.cpu
```

## Troubleshooting Strategies

### Step 9: Debugging Pods

```bash
# Pod troubleshooting commands
kubectl get pods -o wide
kubectl describe pod <pod-name>
kubectl logs <pod-name> -c <container-name>
kubectl logs <pod-name> --previous
kubectl exec -it <pod-name> -- /bin/bash

# Debug with temporary pod
kubectl run debug-pod --image=busybox --rm -it --restart=Never -- sh

# Port forwarding for debugging
kubectl port-forward <pod-name> 8080:80

# Copy files to/from pod
kubectl cp <local-file> <pod-name>:/<path>
kubectl cp <pod-name>:/<path> <local-file>
```

### Step 10: Network Troubleshooting

```yaml
# network-debug-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: network-debug
  namespace: secure-app
spec:
  containers:
  - name: debug
    image: nicolaka/netshoot
    command: ["/bin/bash"]
    args: ["-c", "sleep 3600"]
    resources:
      requests:
        memory: "64Mi"
        cpu: "100m"
      limits:
        memory: "128Mi"
        cpu: "200m"
  restartPolicy: Never
```

```bash
# Network debugging commands
kubectl exec -it network-debug -- nslookup kubernetes.default
kubectl exec -it network-debug -- ping google.com
kubectl exec -it network-debug -- curl -I http://service-name:port
kubectl exec -it network-debug -- netstat -tulpn
kubectl exec -it network-debug -- ss -tulpn

# Test service connectivity
kubectl exec -it network-debug -- curl -v http://my-service:80/health

# DNS debugging
kubectl exec -it network-debug -- cat /etc/resolv.conf
kubectl exec -it network-debug -- nslookup my-service.my-namespace.svc.cluster.local
```

### Step 11: Performance Debugging

```yaml
# performance-debug.yaml
apiVersion: v1
kind: Pod
metadata:
  name: performance-debug
spec:
  containers:
  - name: debug
    image: alpine:latest
    command: ["/bin/sh"]
    args: ["-c", "apk add --no-cache htop iotop && sleep 3600"]
    resources:
      requests:
        memory: "128Mi"
        cpu: "200m"
      limits:
        memory: "256Mi"
        cpu: "500m"
    securityContext:
      privileged: true
  hostNetwork: true
  hostPID: true
  restartPolicy: Never
```

```bash
# Performance debugging
kubectl top nodes
kubectl top pods --all-namespaces
kubectl describe node <node-name>

# Resource usage
kubectl exec -it performance-debug -- htop
kubectl exec -it performance-debug -- iotop

# Application profiling
kubectl exec -it <app-pod> -- pprof
kubectl exec -it <app-pod> -- curl localhost:6060/debug/pprof/
```

## Disaster Recovery

### Step 12: Backup Strategy

```yaml
# velero-backup.yaml
apiVersion: velero.io/v1
kind: Schedule
metadata:
  name: daily-backup
  namespace: velero
spec:
  schedule: "0 2 * * *"  # Daily at 2 AM
  template:
    includedNamespaces:
    - production
    - secure-app
    excludedResources:
    - events
    - events.events.k8s.io
    storageLocation: default
    volumeSnapshotLocations:
    - default
    ttl: 720h0m0s  # 30 days

---
apiVersion: velero.io/v1
kind: Backup
metadata:
  name: pre-upgrade-backup
  namespace: velero
spec:
  includedNamespaces:
  - production
  includeClusterResources: true
  storageLocation: default
  volumeSnapshotLocations:
  - default
```

### Step 13: Database Backup

```yaml
# database-backup-cronjob.yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: postgres-backup
  namespace: production
spec:
  schedule: "0 3 * * *"  # Daily at 3 AM
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: postgres-backup
            image: postgres:13
            command: ["/bin/bash"]
            args:
            - -c
            - |
              BACKUP_FILE="backup_$(date +%Y%m%d_%H%M%S).sql"
              pg_dump $DATABASE_URL > /backup/$BACKUP_FILE
              
              # Upload to cloud storage
              aws s3 cp /backup/$BACKUP_FILE s3://my-backups/postgres/
              
              # Clean up old local backups
              find /backup -name "*.sql" -mtime +7 -delete
              
              echo "Backup completed: $BACKUP_FILE"
            env:
            - name: DATABASE_URL
              valueFrom:
                secretKeyRef:
                  name: postgres-secret
                  key: database-url
            - name: AWS_ACCESS_KEY_ID
              valueFrom:
                secretKeyRef:
                  name: aws-credentials
                  key: access-key-id
            - name: AWS_SECRET_ACCESS_KEY
              valueFrom:
                secretKeyRef:
                  name: aws-credentials
                  key: secret-access-key
            volumeMounts:
            - name: backup-storage
              mountPath: /backup
            resources:
              requests:
                memory: "256Mi"
                cpu: "200m"
              limits:
                memory: "512Mi"
                cpu: "500m"
          volumes:
          - name: backup-storage
            persistentVolumeClaim:
              claimName: backup-pvc
          restartPolicy: OnFailure
```

### Step 14: Cluster Recovery

```bash
# Cluster recovery procedures

# 1. Restore from Velero backup
velero restore create --from-backup daily-backup-20231201

# 2. Check restore status
velero restore describe <restore-name>

# 3. Verify cluster state
kubectl get pods --all-namespaces
kubectl get pv
kubectl get pvc --all-namespaces

# 4. Test application functionality
kubectl port-forward svc/my-app 8080:80
curl http://localhost:8080/health

# 5. Scale applications if needed
kubectl scale deployment my-app --replicas=3
```

## CI/CD Integration

### Step 15: GitOps with ArgoCD

```yaml
# argocd-application.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: web-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/mycompany/k8s-manifests
    targetRevision: HEAD
    path: apps/web-app
  destination:
    server: https://kubernetes.default.svc
    namespace: production
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
      allowEmpty: false
    syncOptions:
    - CreateNamespace=true
    - ApplyOutOfSyncOnly=true
    retry:
      limit: 5
      backoff:
        duration: 5s
        factor: 2
        maxDuration: 3m

---
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: production-project
  namespace: argocd
spec:
  description: Production applications
  sourceRepos:
  - https://github.com/mycompany/*
  destinations:
  - namespace: production
    server: https://kubernetes.default.svc
  - namespace: staging
    server: https://kubernetes.default.svc
  clusterResourceWhitelist:
  - group: ''
    kind: Namespace
  namespaceResourceWhitelist:
  - group: 'apps'
    kind: Deployment
  - group: ''
    kind: Service
  - group: ''
    kind: ConfigMap
  roles:
  - name: admin
    policies:
    - p, proj:production-project:admin, applications, *, production-project/*, allow
    groups:
    - mycompany:devops
```

### Step 16: Deployment Strategies

```yaml
# blue-green-deployment.yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: web-app-rollout
  namespace: production
spec:
  replicas: 5
  strategy:
    blueGreen:
      activeService: web-app-active
      previewService: web-app-preview
      autoPromotionEnabled: false
      scaleDownDelaySeconds: 30
      prePromotionAnalysis:
        templates:
        - templateName: success-rate
        args:
        - name: service-name
          value: web-app-preview
      postPromotionAnalysis:
        templates:
        - templateName: success-rate
        args:
        - name: service-name
          value: web-app-active
  selector:
    matchLabels:
      app: web-app
  template:
    metadata:
      labels:
        app: web-app
    spec:
      containers:
      - name: web-app
        image: web-app:latest
        ports:
        - containerPort: 8080
        resources:
          requests:
            memory: "128Mi"
            cpu: "200m"
          limits:
            memory: "256Mi"
            cpu: "400m"

---
apiVersion: argoproj.io/v1alpha1
kind: AnalysisTemplate
metadata:
  name: success-rate
spec:
  args:
  - name: service-name
  metrics:
  - name: success-rate
    interval: 30s
    count: 5
    successCondition: result[0] >= 0.95
    failureLimit: 3
    provider:
      prometheus:
        address: http://prometheus.monitoring.svc.cluster.local:9090
        query: |
          sum(irate(
            nginx_ingress_controller_requests{service="{{ args.service-name }}",status!~"5.*"}[2m]
          )) /
          sum(irate(
            nginx_ingress_controller_requests{service="{{ args.service-name }}"}[2m]
          ))
```

## Monitoring and Alerting

### Step 17: Production Monitoring

```yaml
# production-monitoring.yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: production-alerts
  namespace: monitoring
spec:
  groups:
  - name: production.rules
    rules:
    - alert: PodCrashLooping
      expr: |
        increase(kube_pod_container_status_restarts_total[1h]) > 5
      for: 5m
      labels:
        severity: critical
        team: platform
      annotations:
        summary: "Pod {{ $labels.pod }} is crash looping"
        description: "Pod {{ $labels.pod }} in namespace {{ $labels.namespace }} has restarted {{ $value }} times in the last hour"
        runbook_url: "https://runbooks.company.com/pod-crash-looping"

    - alert: DeploymentReplicasMismatch
      expr: |
        kube_deployment_spec_replicas != kube_deployment_status_available_replicas
      for: 10m
      labels:
        severity: warning
        team: platform
      annotations:
        summary: "Deployment replicas mismatch"
        description: "Deployment {{ $labels.deployment }} has {{ $labels.spec_replicas }} desired but {{ $labels.available_replicas }} available replicas"

    - alert: PersistentVolumeClaimPending
      expr: |
        kube_persistentvolumeclaim_status_phase{phase="Pending"} == 1
      for: 5m
      labels:
        severity: warning
        team: platform
      annotations:
        summary: "PVC is pending"
        description: "PVC {{ $labels.persistentvolumeclaim }} in namespace {{ $labels.namespace }} is in pending state"

    - alert: NodeNotReady
      expr: |
        kube_node_status_condition{condition="Ready",status="true"} == 0
      for: 5m
      labels:
        severity: critical
        team: infrastructure
      annotations:
        summary: "Node is not ready"
        description: "Node {{ $labels.node }} is not ready for {{ $humanizeDuration $value }}"

    - alert: HighMemoryUsage
      expr: |
        (
          container_memory_working_set_bytes{container!=""}
          /
          container_spec_memory_limit_bytes{container!=""} > 0.9
        )
      for: 10m
      labels:
        severity: warning
        team: application
      annotations:
        summary: "High memory usage"
        description: "Container {{ $labels.container }} in pod {{ $labels.pod }} is using {{ $value | humanizePercentage }} of memory limit"
```

### Step 18: Health Checks

```yaml
# health-checks.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: robust-app
  namespace: production
spec:
  replicas: 3
  selector:
    matchLabels:
      app: robust-app
  template:
    metadata:
      labels:
        app: robust-app
    spec:
      containers:
      - name: app
        image: robust-app:latest
        ports:
        - containerPort: 8080
        env:
        - name: HEALTH_CHECK_INTERVAL
          value: "30s"
        livenessProbe:
          httpGet:
            path: /health/live
            port: 8080
            httpHeaders:
            - name: Custom-Header
              value: liveness
          initialDelaySeconds: 30
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 3
          successThreshold: 1
        readinessProbe:
          httpGet:
            path: /health/ready
            port: 8080
            httpHeaders:
            - name: Custom-Header
              value: readiness
          initialDelaySeconds: 10
          periodSeconds: 5
          timeoutSeconds: 3
          failureThreshold: 3
          successThreshold: 1
        startupProbe:
          httpGet:
            path: /health/startup
            port: 8080
          initialDelaySeconds: 10
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 30
          successThreshold: 1
        resources:
          requests:
            memory: "256Mi"
            cpu: "200m"
          limits:
            memory: "512Mi"
            cpu: "500m"
```

## Common Issues and Solutions

### Step 19: Troubleshooting Checklist

```bash
#!/bin/bash
# troubleshooting-script.sh

echo "=== Kubernetes Troubleshooting Script ==="

echo "1. Checking cluster status..."
kubectl cluster-info
kubectl get nodes

echo "2. Checking system pods..."
kubectl get pods -n kube-system

echo "3. Checking resource usage..."
kubectl top nodes
kubectl top pods --all-namespaces --sort-by=cpu

echo "4. Checking events..."
kubectl get events --sort-by=.metadata.creationTimestamp

echo "5. Checking persistent volumes..."
kubectl get pv
kubectl get pvc --all-namespaces

echo "6. Checking services..."
kubectl get svc --all-namespaces

echo "7. Checking ingress..."
kubectl get ingress --all-namespaces

echo "8. Checking certificates..."
kubectl get certificates --all-namespaces

echo "9. Checking RBAC..."
kubectl auth can-i --list

echo "10. Checking network policies..."
kubectl get networkpolicies --all-namespaces

echo "=== Troubleshooting complete ==="
```

### Step 20: Performance Tuning

```yaml
# performance-tuning.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: performance-config
  namespace: production
data:
  # Application tuning
  GOMAXPROCS: "4"
  GOMEMLIMIT: "1GiB"
  
  # JVM tuning
  JAVA_OPTS: |
    -Xms512m -Xmx2g
    -XX:+UseG1GC
    -XX:G1HeapRegionSize=16m
    -XX:+UseStringDeduplication
    -XX:+OptimizeStringConcat
    -XX:+UseCompressedOops
    -Djava.security.egd=file:/dev/./urandom
  
  # Node.js tuning
  NODE_OPTIONS: |
    --max-old-space-size=2048
    --max-semi-space-size=128
    --optimize-for-size
  
  # Nginx tuning
  nginx.conf: |
    worker_processes auto;
    worker_connections 1024;
    keepalive_timeout 65;
    keepalive_requests 100;
    
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css application/json application/javascript;
    
    # Caching
    location ~* \.(jpg|jpeg|png|gif|ico|css|js)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

---
apiVersion: v1
kind: Pod
metadata:
  name: performance-test
  namespace: production
spec:
  containers:
  - name: app
    image: performance-app:latest
    envFrom:
    - configMapRef:
        name: performance-config
    resources:
      requests:
        memory: "1Gi"
        cpu: "500m"
      limits:
        memory: "2Gi"
        cpu: "1"
    # Topology spread constraints
  topologySpreadConstraints:
  - maxSkew: 1
    topologyKey: topology.kubernetes.io/zone
    whenUnsatisfiable: DoNotSchedule
    labelSelector:
      matchLabels:
        app: performance-app
  # Priority class for important workloads
  priorityClassName: high-priority
```

## Practice Exercises

### Exercise 1: Security Hardening

1. Implement comprehensive security policies
2. Set up network segmentation
3. Configure RBAC for different user roles
4. Implement image scanning and signing
5. Set up secret management with external providers

### Exercise 2: Production Readiness

1. Create a multi-environment setup
2. Implement proper monitoring and alerting
3. Set up automated backup and recovery
4. Configure CI/CD pipelines
5. Perform chaos engineering tests

### Exercise 3: Performance Optimization

1. Analyze application performance
2. Implement resource optimization
3. Set up autoscaling policies
4. Optimize network policies
5. Tune JVM/runtime settings

### Exercise 4: Disaster Recovery

1. Create backup and restore procedures
2. Test failover scenarios
3. Implement cross-region replication
4. Create runbooks for common issues
5. Perform disaster recovery drills

## Cleanup

```bash
# Remove practice resources
kubectl delete namespace secure-app production
kubectl delete -f network-policies.yaml
kubectl delete -f rbac.yaml
kubectl delete -f performance-tuning.yaml
kubectl delete -f production-monitoring.yaml

# Clean up debugging pods
kubectl delete pod network-debug performance-debug --ignore-not-found

# Remove configurations
kubectl delete configmap performance-config --ignore-not-found
kubectl delete secret app-secrets aws-credentials postgres-secret --ignore-not-found
```

## Key Takeaways

- ✅ Security is a multi-layered approach requiring constant attention
- ✅ Performance optimization requires monitoring and iterative improvement
- ✅ Troubleshooting skills are essential for production operations
- ✅ Disaster recovery planning prevents catastrophic failures
- ✅ CI/CD integration ensures reliable deployments
- ✅ Best practices evolve with experience and technology

## Production Readiness Checklist

### Security
- [ ] Pod Security Standards implemented
- [ ] Network policies configured
- [ ] RBAC properly set up
- [ ] Secrets managed securely
- [ ] Images scanned and signed
- [ ] Security monitoring in place

### Performance
- [ ] Resource limits and requests set
- [ ] Autoscaling configured
- [ ] Performance monitoring enabled
- [ ] Load testing completed
- [ ] Optimization tuning applied

### Reliability
- [ ] Health checks implemented
- [ ] Monitoring and alerting configured
- [ ] Backup strategy in place
- [ ] Disaster recovery tested
- [ ] SLI/SLO defined and monitored

### Operations
- [ ] CI/CD pipelines implemented
- [ ] Documentation up to date
- [ ] Runbooks created
- [ ] Team training completed
- [ ] Incident response procedures defined

## Congratulations!

🎉 **You've completed the comprehensive Kubernetes learning journey!**

You now have the knowledge and skills to:

- Design and deploy cloud-native applications
- Implement security best practices
- Optimize performance and resource usage
- Troubleshoot complex issues
- Manage production Kubernetes clusters

**Continue your learning:**

- Explore service mesh technologies (Istio, Linkerd)
- Learn about GitOps and advanced CI/CD
- Study cloud-native security tools
- Practice chaos engineering
- Contribute to open-source Kubernetes projects

## Quick Reference

```bash
# Emergency commands
kubectl get pods --all-namespaces --field-selector=status.phase!=Running
kubectl describe node <node-name>
kubectl logs -f deployment/<deployment-name>
kubectl rollout undo deployment/<deployment-name>

# Debugging
kubectl exec -it <pod> -- /bin/bash
kubectl port-forward <pod> 8080:80
kubectl cp <pod>:/path/file ./local-file

# Resource management
kubectl top nodes
kubectl top pods --all-namespaces
kubectl describe limitrange -n <namespace>
kubectl describe resourcequota -n <namespace>

# Security
kubectl auth can-i <verb> <resource>
kubectl get rolebindings,clusterrolebindings --all-namespaces
kubectl get networkpolicies --all-namespaces
```
