# Kubernetes Quick Reference and Cheat Sheet

## Essential kubectl Commands

### Cluster Information
```bash
kubectl cluster-info                    # Display cluster info
kubectl get nodes                      # List all nodes
kubectl get nodes -o wide              # List nodes with more details
kubectl describe node <node-name>      # Detailed node information
kubectl version                        # Client and server versions
```

### Namespace Operations
```bash
kubectl get namespaces                 # List all namespaces
kubectl create namespace <name>        # Create namespace
kubectl delete namespace <name>        # Delete namespace
kubectl config view                    # View current config
kubectl config get-contexts           # List all contexts
kubectl config set-context --current --namespace=<name>  # Set default namespace
```

### Pod Operations
```bash
kubectl get pods                       # List pods in current namespace
kubectl get pods -A                    # List pods in all namespaces
kubectl get pods -o wide               # List pods with more details
kubectl describe pod <name>            # Detailed pod information
kubectl logs <pod-name>                # View pod logs
kubectl logs -f <pod-name>             # Stream pod logs
kubectl exec -it <pod-name> -- /bin/bash  # Execute command in pod
kubectl delete pod <name>              # Delete pod
```

### Apply and Create Resources
```bash
kubectl apply -f <file.yaml>           # Apply configuration from file
kubectl create -f <file.yaml>          # Create resource from file
kubectl delete -f <file.yaml>          # Delete resources from file
kubectl get -f <file.yaml>             # Get resources from file
```

### Labels and Selectors
```bash
kubectl get pods -l app=nginx          # Get pods with label
kubectl get pods -l 'environment in (production,staging)'  # Multiple values
kubectl label pod <name> key=value     # Add label to pod
kubectl label pod <name> key-          # Remove label from pod
```

### Resource Management
```bash
kubectl get all                        # Get all resources
kubectl get all -A                     # Get all resources in all namespaces
kubectl api-resources                  # List all resource types
kubectl explain <resource>             # Get resource documentation
kubectl explain pod.spec               # Get specific field documentation
```

## YAML Structure Basics

### Basic Pod Template
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-pod
  labels:
    app: my-app
spec:
  containers:
  - name: my-container
    image: nginx:latest
    ports:
    - containerPort: 80
```

### Basic Service Template
```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-service
spec:
  selector:
    app: my-app
  ports:
  - port: 80
    targetPort: 80
  type: ClusterIP
```

### Basic Deployment Template
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-deployment
spec:
  replicas: 3
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
    spec:
      containers:
      - name: my-container
        image: nginx:latest
        ports:
        - containerPort: 80
```

## Common Resource Fields

### Metadata
```yaml
metadata:
  name: resource-name          # Required: unique name
  namespace: my-namespace      # Optional: defaults to 'default'
  labels:                      # Optional: key-value pairs
    app: my-app
    version: v1.0
  annotations:                 # Optional: metadata for tools
    description: "My application"
```

### Container Spec
```yaml
containers:
- name: my-container
  image: nginx:1.21
  ports:
  - containerPort: 80
  env:
  - name: ENV_VAR
    value: "some-value"
  resources:
    requests:
      memory: "64Mi"
      cpu: "250m"
    limits:
      memory: "128Mi"
      cpu: "500m"
  volumeMounts:
  - name: my-volume
    mountPath: /app/data
```

## Troubleshooting Commands

### Pod Issues
```bash
kubectl describe pod <name>            # Check events and status
kubectl logs <pod-name>                # Check application logs
kubectl logs <pod-name> -c <container> # Multi-container pod logs
kubectl get events                     # Cluster events
kubectl get events --sort-by='.lastTimestamp'  # Recent events first
```

### Resource Status
```bash
kubectl get pods -o yaml              # Full YAML output
kubectl get pods -o json              # JSON output
kubectl get pods --watch              # Watch for changes
kubectl top nodes                     # Node resource usage
kubectl top pods                      # Pod resource usage
```

### Debug Running Pods
```bash
kubectl exec -it <pod> -- /bin/bash    # Interactive shell
kubectl exec <pod> -- ls -la /app      # Execute single command
kubectl port-forward <pod> 8080:80     # Forward local port to pod
kubectl cp <pod>:/path/file ./file     # Copy file from pod
```

## Common Kubernetes Patterns

### Health Checks
```yaml
livenessProbe:
  httpGet:
    path: /health
    port: 80
  initialDelaySeconds: 30
  periodSeconds: 10

readinessProbe:
  httpGet:
    path: /ready
    port: 80
  initialDelaySeconds: 5
  periodSeconds: 5
```

### Environment Variables
```yaml
env:
- name: DATABASE_URL
  value: "postgres://localhost:5432/mydb"
- name: SECRET_KEY
  valueFrom:
    secretKeyRef:
      name: my-secret
      key: password
```

### Volume Mounts
```yaml
volumeMounts:
- name: config-volume
  mountPath: /app/config
- name: data-volume
  mountPath: /app/data

volumes:
- name: config-volume
  configMap:
    name: app-config
- name: data-volume
  persistentVolumeClaim:
    claimName: data-pvc
```

## Resource Units

### CPU
- `100m` = 0.1 CPU core
- `1` = 1 CPU core
- `2` = 2 CPU cores

### Memory
- `128Mi` = 128 Mebibytes
- `1Gi` = 1 Gibibyte
- `1G` = 1 Gigabyte

### Storage
- `1Gi` = 1 Gibibyte
- `10Gi` = 10 Gibibytes

## Quick Debug Checklist

1. **Pod not starting?**
   ```bash
   kubectl describe pod <name>
   kubectl logs <name>
   ```

2. **Service not accessible?**
   ```bash
   kubectl get svc
   kubectl describe svc <name>
   kubectl get endpoints
   ```

3. **Check resource usage:**
   ```bash
   kubectl top nodes
   kubectl top pods
   ```

4. **View recent events:**
   ```bash
   kubectl get events --sort-by='.lastTimestamp'
   ```

## Useful Aliases

Add these to your shell configuration (~/.bashrc or ~/.zshrc):

```bash
alias k='kubectl'
alias kg='kubectl get'
alias kd='kubectl describe'
alias ka='kubectl apply'
alias kdel='kubectl delete'
alias kl='kubectl logs'
alias kex='kubectl exec -it'
```
