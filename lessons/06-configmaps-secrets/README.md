# Lesson 6: ConfigMaps and Secrets

## Learning Objectives

By the end of this lesson, you will:

- Understand configuration management in Kubernetes
- Create and use ConfigMaps for application configuration
- Manage sensitive data with Secrets
- Inject configuration into pods via environment variables and volumes
- Follow security best practices for secrets

## Why Configuration Management?

Applications need configuration that varies by environment:

- **Database connections** (dev, staging, prod)
- **API keys and credentials**
- **Feature flags and settings**
- **Environment-specific values**

**Hardcoding these in images is problematic:**
- Requires rebuilding images for each environment
- Secrets in images are security risks
- No separation of code and configuration

## ConfigMaps

ConfigMaps store **non-sensitive** configuration data as key-value pairs.

### Step 1: Create ConfigMaps

#### Method 1: From Literal Values

```bash
# Create ConfigMap from command line
kubectl create configmap app-config \
  --from-literal=database_host=postgres.example.com \
  --from-literal=database_port=5432 \
  --from-literal=log_level=INFO \
  --from-literal=feature_flag=enabled

# View the ConfigMap
kubectl get configmaps
kubectl describe configmap app-config
kubectl get configmap app-config -o yaml
```

#### Method 2: From Files

Create configuration files:

```bash
# Create config files
cat > database.properties << EOF
host=postgres.example.com
port=5432
name=myapp
connection_pool_size=10
EOF

cat > logging.conf << EOF
[loggers]
keys=root

[handlers]
keys=consoleHandler

[formatters]
keys=simpleFormatter

[logger_root]
level=INFO
handlers=consoleHandler

[handler_consoleHandler]
class=StreamHandler
level=INFO
formatter=simpleFormatter
args=(sys.stdout,)

[formatter_simpleFormatter]
format=%(asctime)s - %(name)s - %(levelname)s - %(message)s
EOF

# Create ConfigMap from files
kubectl create configmap app-files-config \
  --from-file=database.properties \
  --from-file=logging.conf

# View the file-based ConfigMap
kubectl get configmap app-files-config -o yaml
```

#### Method 3: From Directory

```bash
# Create config directory
mkdir config-dir
echo "debug=true" > config-dir/app.properties
echo "version=1.0" > config-dir/version.txt

# Create ConfigMap from directory
kubectl create configmap app-dir-config --from-file=config-dir/

kubectl describe configmap app-dir-config
```

#### Method 4: Using YAML

```yaml
# app-configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-yaml-config
  labels:
    app: my-app
data:
  # Simple key-value pairs
  database_host: "postgres.example.com"
  database_port: "5432"
  log_level: "INFO"
  
  # Multi-line configuration
  app.properties: |
    debug=true
    version=1.0
    feature.new_ui=enabled
    feature.analytics=disabled
  
  nginx.conf: |
    events {
        worker_connections 1024;
    }
    http {
        server {
            listen 80;
            location / {
                proxy_pass http://backend;
            }
        }
    }
```

Apply the YAML ConfigMap:

```bash
kubectl apply -f app-configmap.yaml
kubectl get configmap app-yaml-config -o yaml
```

### Step 2: Using ConfigMaps in Pods

#### Environment Variables from ConfigMap

```yaml
# pod-with-configmap-env.yaml
apiVersion: v1
kind: Pod
metadata:
  name: configmap-env-pod
spec:
  containers:
  - name: app-container
    image: busybox
    command: ['sleep', '3600']
    env:
    # Individual keys
    - name: DATABASE_HOST
      valueFrom:
        configMapKeyRef:
          name: app-config
          key: database_host
    - name: DATABASE_PORT
      valueFrom:
        configMapKeyRef:
          name: app-config
          key: database_port
    envFrom:
    # All keys from ConfigMap
    - configMapRef:
        name: app-config
    resources:
      requests:
        memory: "16Mi"
        cpu: "50m"
      limits:
        memory: "32Mi"
        cpu: "100m"
```

Test environment variables:

```bash
# Deploy pod
kubectl apply -f pod-with-configmap-env.yaml

# Check environment variables
kubectl exec configmap-env-pod -- env | grep -E "(DATABASE|log_level|feature_flag)"

# Interactive shell to explore
kubectl exec -it configmap-env-pod -- sh
# Inside pod: echo $DATABASE_HOST
```

#### Volume Mounts from ConfigMap

```yaml
# pod-with-configmap-volume.yaml
apiVersion: v1
kind: Pod
metadata:
  name: configmap-volume-pod
spec:
  containers:
  - name: app-container
    image: nginx:alpine
    volumeMounts:
    - name: config-volume
      mountPath: /etc/config
    - name: nginx-config
      mountPath: /etc/nginx/nginx.conf
      subPath: nginx.conf
    resources:
      requests:
        memory: "32Mi"
        cpu: "100m"
      limits:
        memory: "64Mi"
        cpu: "200m"
  volumes:
  - name: config-volume
    configMap:
      name: app-yaml-config
  - name: nginx-config
    configMap:
      name: app-yaml-config
      items:
      - key: nginx.conf
        path: nginx.conf
```

Test volume mounts:

```bash
# Deploy pod
kubectl apply -f pod-with-configmap-volume.yaml

# Check mounted files
kubectl exec configmap-volume-pod -- ls -la /etc/config
kubectl exec configmap-volume-pod -- cat /etc/config/app.properties
kubectl exec configmap-volume-pod -- cat /etc/nginx/nginx.conf
```

## Secrets

Secrets store **sensitive** data like passwords, tokens, and keys.

### Step 3: Create Secrets

#### Method 1: From Literal Values

```bash
# Create secret from command line
kubectl create secret generic app-secrets \
  --from-literal=database_username=admin \
  --from-literal=database_password=secretpassword \
  --from-literal=api_key=abc123xyz789

# View the secret (values are base64 encoded)
kubectl get secrets
kubectl describe secret app-secrets
kubectl get secret app-secrets -o yaml
```

#### Method 2: From Files

```bash
# Create secret files
echo -n 'admin' > username.txt
echo -n 'supersecretpassword' > password.txt

# Create secret from files
kubectl create secret generic file-secrets \
  --from-file=username=username.txt \
  --from-file=password=password.txt

# Clean up files
rm username.txt password.txt

kubectl get secret file-secrets -o yaml
```

#### Method 3: Using YAML

```yaml
# app-secrets.yaml
apiVersion: v1
kind: Secret
metadata:
  name: app-yaml-secrets
type: Opaque
data:
  # Values must be base64 encoded
  username: YWRtaW4=           # base64 of "admin"
  password: c2VjcmV0cGFzcw==   # base64 of "secretpass"
  api_key: YWJjMTIzNHh5ejc4OQ== # base64 of "abc1234xyz789"
```

**Note:** To encode values:
```bash
echo -n 'admin' | base64
echo -n 'secretpass' | base64
echo -n 'abc1234xyz789' | base64
```

#### Method 4: String Data (Auto-encoded)

```yaml
# app-secrets-stringdata.yaml
apiVersion: v1
kind: Secret
metadata:
  name: app-stringdata-secrets
type: Opaque
stringData:  # Automatically base64 encoded
  username: admin
  password: secretpass
  api_key: abc1234xyz789
  database_url: postgresql://admin:secretpass@postgres:5432/mydb
```

Apply secrets:

```bash
kubectl apply -f app-secrets.yaml
kubectl apply -f app-secrets-stringdata.yaml
```

### Step 4: Using Secrets in Pods

#### Environment Variables from Secrets

```yaml
# pod-with-secrets-env.yaml
apiVersion: v1
kind: Pod
metadata:
  name: secrets-env-pod
spec:
  containers:
  - name: app-container
    image: busybox
    command: ['sleep', '3600']
    env:
    # Individual secret keys
    - name: DB_USERNAME
      valueFrom:
        secretKeyRef:
          name: app-secrets
          key: database_username
    - name: DB_PASSWORD
      valueFrom:
        secretKeyRef:
          name: app-secrets
          key: database_password
    - name: API_KEY
      valueFrom:
        secretKeyRef:
          name: app-secrets
          key: api_key
    resources:
      requests:
        memory: "16Mi"
        cpu: "50m"
      limits:
        memory: "32Mi"
        cpu: "100m"
```

Test secret environment variables:

```bash
# Deploy pod
kubectl apply -f pod-with-secrets-env.yaml

# Check secret values (be careful in production!)
kubectl exec secrets-env-pod -- env | grep -E "(DB_|API_KEY)"
```

#### Volume Mounts from Secrets

```yaml
# pod-with-secrets-volume.yaml
apiVersion: v1
kind: Pod
metadata:
  name: secrets-volume-pod
spec:
  containers:
  - name: app-container
    image: nginx:alpine
    volumeMounts:
    - name: secret-volume
      mountPath: /etc/secrets
      readOnly: true
    resources:
      requests:
        memory: "32Mi"
        cpu: "100m"
      limits:
        memory: "64Mi"
        cpu: "200m"
  volumes:
  - name: secret-volume
    secret:
      secretName: app-secrets
      defaultMode: 0400  # Read-only for owner
```

Test secret volume mounts:

```bash
# Deploy pod
kubectl apply -f pod-with-secrets-volume.yaml

# Check mounted secret files
kubectl exec secrets-volume-pod -- ls -la /etc/secrets
kubectl exec secrets-volume-pod -- cat /etc/secrets/database_username
kubectl exec secrets-volume-pod -- cat /etc/secrets/api_key
```

## Real-World Application Example

### Step 5: Complete Application with ConfigMaps and Secrets

Create a web application with configuration:

```yaml
# web-app-config.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: web-app-config
data:
  app_name: "My Web Application"
  environment: "development"
  log_level: "DEBUG"
  feature_flags: "new_ui=true,analytics=false"
  app.properties: |
    server.port=8080
    server.servlet.context-path=/
    logging.level.root=DEBUG
    management.endpoints.web.exposure.include=health,info
---
apiVersion: v1
kind: Secret
metadata:
  name: web-app-secrets
type: Opaque
stringData:
  database_url: "postgresql://user:password@postgres:5432/webapp"
  jwt_secret: "super-secret-jwt-key-12345"
  api_key: "external-api-key-xyz789"
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
spec:
  replicas: 2
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
        image: nginx:alpine
        ports:
        - containerPort: 80
        env:
        # ConfigMap values
        - name: APP_NAME
          valueFrom:
            configMapKeyRef:
              name: web-app-config
              key: app_name
        - name: ENVIRONMENT
          valueFrom:
            configMapKeyRef:
              name: web-app-config
              key: environment
        - name: LOG_LEVEL
          valueFrom:
            configMapKeyRef:
              name: web-app-config
              key: log_level
        # Secret values
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: web-app-secrets
              key: database_url
        - name: JWT_SECRET
          valueFrom:
            secretKeyRef:
              name: web-app-secrets
              key: jwt_secret
        volumeMounts:
        - name: config-volume
          mountPath: /etc/config
        - name: secrets-volume
          mountPath: /etc/secrets
          readOnly: true
        resources:
          requests:
            memory: "64Mi"
            cpu: "100m"
          limits:
            memory: "128Mi"
            cpu: "200m"
      volumes:
      - name: config-volume
        configMap:
          name: web-app-config
      - name: secrets-volume
        secret:
          secretName: web-app-secrets
---
apiVersion: v1
kind: Service
metadata:
  name: web-app-service
spec:
  selector:
    app: web-app
  ports:
  - port: 80
    targetPort: 80
  type: ClusterIP
```

Deploy and test:

```bash
# Deploy the complete application
kubectl apply -f web-app-config.yaml

# Check deployment
kubectl get all -l app=web-app

# Test configuration
kubectl exec -it deployment/web-app -- env | grep -E "(APP_NAME|DATABASE_URL|LOG_LEVEL)"
kubectl exec -it deployment/web-app -- ls -la /etc/config
kubectl exec -it deployment/web-app -- ls -la /etc/secrets
```

### Step 6: Updating Configuration

```bash
# Update ConfigMap
kubectl patch configmap web-app-config -p '{"data":{"log_level":"INFO"}}'

# Check updated value
kubectl get configmap web-app-config -o yaml

# Note: Pod restart needed for env vars to update
kubectl rollout restart deployment/web-app

# For volume mounts, changes are reflected automatically (with slight delay)
```

## Docker Registry Secrets

### Step 7: Image Pull Secrets

```bash
# Create Docker registry secret
kubectl create secret docker-registry my-registry-secret \
  --docker-server=registry.example.com \
  --docker-username=myuser \
  --docker-password=mypassword \
  --docker-email=user@example.com

# Use in pod spec
```

```yaml
# pod-with-image-pull-secret.yaml
apiVersion: v1
kind: Pod
metadata:
  name: private-image-pod
spec:
  imagePullSecrets:
  - name: my-registry-secret
  containers:
  - name: app
    image: registry.example.com/private/myapp:latest
    resources:
      requests:
        memory: "32Mi"
        cpu: "100m"
      limits:
        memory: "64Mi"
        cpu: "200m"
```

## Security Best Practices

### Step 8: Secret Security

```yaml
# secure-secret-usage.yaml
apiVersion: v1
kind: Pod
metadata:
  name: secure-pod
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    fsGroup: 2000
  containers:
  - name: app
    image: busybox
    command: ['sleep', '3600']
    securityContext:
      allowPrivilegeEscalation: false
      readOnlyRootFilesystem: true
      capabilities:
        drop:
        - ALL
    env:
    - name: SECRET_VALUE
      valueFrom:
        secretKeyRef:
          name: app-secrets
          key: api_key
    volumeMounts:
    - name: secret-volume
      mountPath: /etc/secrets
      readOnly: true
    - name: tmp-volume
      mountPath: /tmp
    resources:
      requests:
        memory: "16Mi"
        cpu: "50m"
      limits:
        memory: "32Mi"
        cpu: "100m"
  volumes:
  - name: secret-volume
    secret:
      secretName: app-secrets
      defaultMode: 0400
  - name: tmp-volume
    emptyDir: {}
```

## Practice Exercises

### Exercise 1: Multi-Environment Configuration

Create ConfigMaps and Secrets for three environments:
1. Development
2. Staging  
3. Production

Deploy the same application with different configurations.

### Exercise 2: Configuration Updates

1. Create an application with ConfigMap
2. Update the ConfigMap
3. Demonstrate different update strategies (restart vs volume mount)

### Exercise 3: Secret Rotation

1. Create a deployment using secrets
2. Update the secret
3. Rolling restart to pick up new secret values

## Troubleshooting

```bash
# Check ConfigMap/Secret existence
kubectl get configmaps
kubectl get secrets

# Verify references in pods
kubectl describe pod <pod-name>

# Check mounted volumes
kubectl exec <pod-name> -- ls -la /etc/config
kubectl exec <pod-name> -- ls -la /etc/secrets

# View actual values (be careful with secrets!)
kubectl get configmap <name> -o yaml
kubectl get secret <name> -o yaml
```

## Cleanup

```bash
# Delete ConfigMaps
kubectl delete configmap app-config app-files-config app-dir-config app-yaml-config web-app-config

# Delete Secrets
kubectl delete secret app-secrets file-secrets app-yaml-secrets app-stringdata-secrets web-app-secrets my-registry-secret

# Delete Pods and Deployments
kubectl delete pod configmap-env-pod configmap-volume-pod secrets-env-pod secrets-volume-pod secure-pod
kubectl delete deployment web-app
kubectl delete service web-app-service

# Clean up files
rm -f database.properties logging.conf
rm -rf config-dir
```

## Key Takeaways

- ✅ ConfigMaps store non-sensitive configuration data
- ✅ Secrets store sensitive information with base64 encoding
- ✅ Configuration can be injected via environment variables or volumes
- ✅ Volume mounts update automatically, environment variables need pod restart
- ✅ Follow security best practices for secret handling
- ✅ Separate configuration from application code

## What's Next?

You now understand configuration management in Kubernetes! Next, we'll learn about persistent storage:

- Persistent Volumes and Claims
- Storage Classes
- StatefulSets for stateful applications
- Data persistence patterns

**Ready?** Continue to [Lesson 7: Persistent Volumes and Claims](../07-persistent-volumes/README.md)

## Quick Reference

```bash
# ConfigMaps
kubectl create configmap <name> --from-literal=key=value
kubectl create configmap <name> --from-file=<file>
kubectl get configmaps
kubectl describe configmap <name>

# Secrets
kubectl create secret generic <name> --from-literal=key=value
kubectl create secret docker-registry <name> --docker-server=<server>
kubectl get secrets
kubectl describe secret <name>

# Usage in pods
env:
- name: VAR_NAME
  valueFrom:
    configMapKeyRef: / secretKeyRef:
      name: <config/secret-name>
      key: <key>
```
