# Lesson 3: Your First Pod

## Learning Objectives

By the end of this lesson, you will:

- Create and deploy your first pod using YAML
- Understand pod specifications and structure
- Interact with running pods
- Use labels and annotations effectively
- Troubleshoot common pod issues

## What is a Pod?

A Pod is the smallest deployable unit in Kubernetes. Key characteristics:

- **Contains one or more containers** that share resources
- **Shared network** - all containers share the same IP
- **Shared storage** - volumes can be mounted in multiple containers
- **Atomic unit** - pods are created and destroyed as a whole
- **Ephemeral** - pods are replaceable, not permanent

### Pod Use Cases

**Single Container Pod (Most Common):**
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: web-server
spec:
  containers:
  - name: nginx
    image: nginx:alpine
```

**Multi-Container Pod (Sidecar Pattern):**
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-with-sidecar
spec:
  containers:
  - name: main-app
    image: my-app:latest
  - name: log-collector
    image: fluent-bit:latest
```

## Hands-On: Your First Pod

### Step 1: Create a Simple Pod

Create a file called `my-first-pod.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-first-pod
  labels:
    app: hello-world
    tier: frontend
    version: v1
  annotations:
    description: "My first Kubernetes pod"
    created-by: "learning-exercise"
spec:
  containers:
  - name: hello-container
    image: nginx:alpine
    ports:
    - containerPort: 80
      name: http
    env:
    - name: ENVIRONMENT
      value: "learning"
    - name: POD_NAME
      valueFrom:
        fieldRef:
          fieldPath: metadata.name
    resources:
      requests:
        memory: "32Mi"
        cpu: "100m"
      limits:
        memory: "64Mi"
        cpu: "200m"
```

### Step 2: Deploy the Pod

```bash
# Apply the configuration
kubectl apply -f my-first-pod.yaml

# Check pod status
kubectl get pods

# Get more detailed information
kubectl get pods -o wide

# Watch pod status in real-time
kubectl get pods -w
```

### Step 3: Inspect the Pod

```bash
# Get detailed pod information
kubectl describe pod my-first-pod

# Check pod logs
kubectl logs my-first-pod

# Get pod definition in YAML format
kubectl get pod my-first-pod -o yaml

# Get pod definition in JSON format
kubectl get pod my-first-pod -o json
```

## Understanding Pod Specifications

### Metadata Section

```yaml
metadata:
  name: my-pod                    # Pod name (required)
  namespace: default              # Namespace (optional)
  labels:                         # Key-value pairs for organization
    app: web-server
    environment: production
  annotations:                    # Metadata for tools and libraries
    description: "Production web server"
    version: "1.0.0"
```

### Container Specification

```yaml
spec:
  containers:
  - name: web-server              # Container name (required)
    image: nginx:1.21             # Container image (required)
    imagePullPolicy: IfNotPresent # Always, Never, IfNotPresent
    ports:
    - containerPort: 80           # Port exposed by container
      name: http                  # Optional port name
      protocol: TCP               # TCP or UDP
    env:                          # Environment variables
    - name: ENV_VAR
      value: "some-value"
    - name: SECRET_VALUE
      valueFrom:
        secretKeyRef:
          name: my-secret
          key: password
    resources:                    # Resource requirements
      requests:
        memory: "64Mi"
        cpu: "250m"
      limits:
        memory: "128Mi"
        cpu: "500m"
    volumeMounts:                 # Volume mounts
    - name: config-volume
      mountPath: /etc/config
```

## Working with Pods

### Step 4: Execute Commands in Pods

```bash
# Get a shell inside the pod
kubectl exec -it my-first-pod -- /bin/sh

# Inside the pod, try these commands:
hostname                        # Shows pod name
cat /etc/hostname              # Same as hostname
ps aux                         # Running processes
env | grep POD                 # Environment variables
curl localhost                # Test nginx
exit

# Execute single commands
kubectl exec my-first-pod -- hostname
kubectl exec my-first-pod -- env
kubectl exec my-first-pod -- ls -la /usr/share/nginx/html
```

### Step 5: Port Forwarding

```bash
# Forward local port 8080 to pod port 80
kubectl port-forward my-first-pod 8080:80

# In another terminal, test the connection
curl http://localhost:8080

# Or open in browser: http://localhost:8080

# Stop port forwarding with Ctrl+C
```

### Step 6: View Pod Logs

```bash
# View current logs
kubectl logs my-first-pod

# Follow logs in real-time
kubectl logs -f my-first-pod

# Get last 10 lines
kubectl logs my-first-pod --tail=10

# Logs since a specific time
kubectl logs my-first-pod --since=1h
```

## Multi-Container Pods

### Step 7: Create a Multi-Container Pod

Create `multi-container-pod.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: multi-container-pod
  labels:
    app: multi-app
spec:
  containers:
  # Main web server
  - name: web-server
    image: nginx:alpine
    ports:
    - containerPort: 80
    volumeMounts:
    - name: shared-content
      mountPath: /usr/share/nginx/html
    resources:
      requests:
        memory: "32Mi"
        cpu: "100m"
      limits:
        memory: "64Mi"
        cpu: "200m"
  
  # Sidecar container that generates content
  - name: content-generator
    image: busybox
    command: ['sh', '-c']
    args:
    - |
      while true; do
        echo "<h1>Multi-Container Pod</h1>" > /shared/index.html
        echo "<p>Current time: $(date)</p>" >> /shared/index.html
        echo "<p>Generated by: content-generator container</p>" >> /shared/index.html
        echo "<hr>" >> /shared/index.html
        echo "<p>Pod Name: $HOSTNAME</p>" >> /shared/index.html
        sleep 30
      done
    volumeMounts:
    - name: shared-content
      mountPath: /shared
    resources:
      requests:
        memory: "16Mi"
        cpu: "50m"
      limits:
        memory: "32Mi"
        cpu: "100m"
  
  volumes:
  - name: shared-content
    emptyDir: {}
```

### Step 8: Deploy and Test Multi-Container Pod

```bash
# Deploy the multi-container pod
kubectl apply -f multi-container-pod.yaml

# Check both containers are running
kubectl get pod multi-container-pod

# View logs from specific containers
kubectl logs multi-container-pod -c web-server
kubectl logs multi-container-pod -c content-generator

# Port forward and test
kubectl port-forward multi-container-pod 8081:80

# Test the dynamic content
curl http://localhost:8081
```

## Labels and Selectors

### Step 9: Working with Labels

```bash
# View labels on pods
kubectl get pods --show-labels

# Filter pods by labels
kubectl get pods -l app=hello-world
kubectl get pods -l tier=frontend
kubectl get pods -l app=hello-world,tier=frontend

# Add labels to existing pods
kubectl label pod my-first-pod environment=development

# Update existing labels
kubectl label pod my-first-pod version=v2 --overwrite

# Remove labels
kubectl label pod my-first-pod environment-

# Use label selectors with different operators
kubectl get pods -l 'environment in (development,staging)'
kubectl get pods -l 'version!=v1'
```

## Pod Lifecycle and States

### Understanding Pod Phases

```bash
# Create a pod that will fail to demonstrate phases
kubectl run failing-pod --image=nginx:nonexistent-tag

# Watch the pod go through phases
kubectl get pods -w

# Check detailed status
kubectl describe pod failing-pod
```

**Pod Phases:**
- **Pending**: Pod accepted but not yet scheduled/running
- **Running**: Pod bound to node, at least one container running
- **Succeeded**: All containers terminated successfully
- **Failed**: At least one container failed
- **Unknown**: Pod state cannot be determined

### Container States

```yaml
# Check container status
kubectl get pod my-first-pod -o jsonpath='{.status.containerStatuses[0].state}'
```

**Container States:**
- **Waiting**: Container not running (pulling image, waiting for secrets)
- **Running**: Container executing without issues
- **Terminated**: Container finished execution

## Troubleshooting Pods

### Step 10: Common Issues and Solutions

```bash
# Pod stuck in Pending
kubectl describe pod <pod-name>
kubectl get events --sort-by='.lastTimestamp'

# Pod in CrashLoopBackOff
kubectl logs <pod-name> --previous
kubectl describe pod <pod-name>

# ImagePullBackOff
kubectl describe pod <pod-name>
# Check Events section for image pull errors

# Resource issues
kubectl top nodes
kubectl top pods
```

### Debug Pod Template

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: debug-pod
spec:
  containers:
  - name: debug-container
    image: busybox
    command: ['sleep', '3600']  # Keep container running
    resources:
      requests:
        memory: "16Mi"
        cpu: "50m"
      limits:
        memory: "32Mi"
        cpu: "100m"
```

## Health Checks

### Step 11: Adding Health Checks

Create `pod-with-health-checks.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-with-health-checks
spec:
  containers:
  - name: web-server
    image: nginx:alpine
    ports:
    - containerPort: 80
    # Liveness probe - restarts container if fails
    livenessProbe:
      httpGet:
        path: /
        port: 80
      initialDelaySeconds: 30
      periodSeconds: 10
      timeoutSeconds: 5
      failureThreshold: 3
    
    # Readiness probe - removes from service if fails
    readinessProbe:
      httpGet:
        path: /
        port: 80
      initialDelaySeconds: 5
      periodSeconds: 5
      timeoutSeconds: 3
      failureThreshold: 3
    
    resources:
      requests:
        memory: "32Mi"
        cpu: "100m"
      limits:
        memory: "64Mi"
        cpu: "200m"
```

## Practice Exercises

### Exercise 1: Pod with Environment Variables

Create a pod that:
1. Uses the `alpine` image
2. Runs `sleep 3600` command
3. Has environment variables for:
   - `APP_NAME=my-app`
   - `VERSION=1.0`
   - Pod name from metadata
   - Pod IP from status

### Exercise 2: Debug Container

Create a debug pod that:
1. Uses `busybox` image
2. Includes network tools (`nicolaka/netshoot` image)
3. Can be used to test network connectivity
4. Stays running indefinitely

### Exercise 3: Resource Constrained Pod

Create a pod that:
1. Has very low resource limits (16Mi memory, 50m CPU)
2. Tries to run nginx
3. Observe what happens and troubleshoot

## Cleanup

```bash
# Delete individual pods
kubectl delete pod my-first-pod
kubectl delete pod multi-container-pod
kubectl delete pod pod-with-health-checks

# Or delete all pods with a label
kubectl delete pods -l app=hello-world

# Delete using files
kubectl delete -f my-first-pod.yaml
kubectl delete -f multi-container-pod.yaml

# Verify cleanup
kubectl get pods
```

## Key Takeaways

- ✅ Pods are the basic unit of deployment in Kubernetes
- ✅ Containers in a pod share network and storage
- ✅ Labels are essential for organizing and selecting pods
- ✅ Resource requests and limits are important for cluster stability
- ✅ Health checks help maintain application reliability
- ✅ Multi-container pods enable sidecar patterns

## What's Next?

You now understand pods! In the next lesson, we'll learn about Services:

- How to expose pods to network traffic
- Different service types
- Load balancing across multiple pods
- Service discovery

**Ready?** Continue to [Lesson 4: Services and Networking](../04-services-networking/README.md)

## Quick Reference

```bash
# Pod management
kubectl apply -f pod.yaml
kubectl get pods
kubectl describe pod <name>
kubectl delete pod <name>

# Pod interaction
kubectl exec -it <pod> -- <command>
kubectl logs <pod>
kubectl port-forward <pod> <local-port>:<pod-port>

# Labels and selection
kubectl get pods --show-labels
kubectl get pods -l key=value
kubectl label pod <name> key=value
```
