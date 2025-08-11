# Lesson 5: Deployments and ReplicaSets

## Learning Objectives

By the end of this lesson, you will:

- Understand the relationship between Deployments, ReplicaSets, and Pods
- Create and manage Deployments
- Perform rolling updates and rollbacks
- Scale applications horizontally
- Use different deployment strategies

## Why Deployments?

Managing individual pods has limitations:

- **No automatic restart** if a pod fails
- **No scaling** - manually create/delete pods
- **No rolling updates** - downtime during updates
- **No rollback** capability

**Deployments solve these problems** by providing declarative application management.

## Deployment Architecture

```
Deployment
    │
    ├── ReplicaSet (v1)
    │   ├── Pod 1
    │   ├── Pod 2
    │   └── Pod 3
    │
    └── ReplicaSet (v2) - During updates
        ├── Pod 4
        ├── Pod 5
        └── Pod 6
```

### Key Components

- **Deployment**: High-level controller for managing application lifecycle
- **ReplicaSet**: Ensures desired number of pod replicas are running
- **Pods**: The actual application instances

## Hands-On: Your First Deployment

### Step 1: Create a Simple Deployment

Create `nginx-deployment.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  labels:
    app: nginx
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.21
        ports:
        - containerPort: 80
        resources:
          requests:
            memory: "32Mi"
            cpu: "100m"
          limits:
            memory: "64Mi"
            cpu: "200m"
```

Deploy and explore:

```bash
# Create the deployment
kubectl apply -f nginx-deployment.yaml

# Check deployment status
kubectl get deployments
kubectl get deployments -o wide

# Check ReplicaSets
kubectl get replicasets
kubectl get rs  # Short form

# Check pods
kubectl get pods
kubectl get pods -l app=nginx

# Get detailed deployment info
kubectl describe deployment nginx-deployment
```

### Step 2: Understanding the Hierarchy

```bash
# Show the relationship between Deployment, ReplicaSet, and Pods
kubectl get all -l app=nginx

# Check deployment events
kubectl describe deployment nginx-deployment

# Check ReplicaSet details
kubectl describe rs <replicaset-name>

# See how pods are managed
kubectl get pods -l app=nginx --show-labels
```

## Scaling Deployments

### Step 3: Manual Scaling

```bash
# Scale up to 5 replicas
kubectl scale deployment nginx-deployment --replicas=5

# Watch the scaling happen
kubectl get pods -l app=nginx -w

# Scale down to 2 replicas
kubectl scale deployment nginx-deployment --replicas=2

# Check final state
kubectl get deployment nginx-deployment
kubectl get pods -l app=nginx
```

### Step 4: Declarative Scaling

Edit the deployment file:

```yaml
# nginx-deployment.yaml (updated)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  labels:
    app: nginx
spec:
  replicas: 4  # Changed from 3 to 4
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.21
        ports:
        - containerPort: 80
        resources:
          requests:
            memory: "32Mi"
            cpu: "100m"
          limits:
            memory: "64Mi"
            cpu: "200m"
```

Apply the changes:

```bash
# Apply updated configuration
kubectl apply -f nginx-deployment.yaml

# Verify scaling
kubectl get deployment nginx-deployment
kubectl get pods -l app=nginx
```

## Rolling Updates

### Step 5: Perform a Rolling Update

Update the image version:

```yaml
# nginx-deployment.yaml (updated image)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  labels:
    app: nginx
spec:
  replicas: 4
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.22  # Updated from 1.21 to 1.22
        ports:
        - containerPort: 80
        resources:
          requests:
            memory: "32Mi"
            cpu: "100m"
          limits:
            memory: "64Mi"
            cpu: "200m"
```

Perform the rolling update:

```bash
# Apply the update
kubectl apply -f nginx-deployment.yaml

# Watch the rollout
kubectl rollout status deployment/nginx-deployment

# See the rolling update in action
kubectl get pods -l app=nginx -w

# Check rollout history
kubectl rollout history deployment/nginx-deployment
```

### Step 6: Alternative Update Methods

```bash
# Update image using kubectl
kubectl set image deployment/nginx-deployment nginx=nginx:1.23

# Edit deployment directly
kubectl edit deployment nginx-deployment

# Patch deployment
kubectl patch deployment nginx-deployment -p '{"spec":{"template":{"spec":{"containers":[{"name":"nginx","image":"nginx:alpine"}]}}}}'
```

## Rollback

### Step 7: Rollback to Previous Version

```bash
# Check rollout history with details
kubectl rollout history deployment/nginx-deployment
kubectl rollout history deployment/nginx-deployment --revision=2

# Rollback to previous version
kubectl rollout undo deployment/nginx-deployment

# Rollback to specific revision
kubectl rollout undo deployment/nginx-deployment --to-revision=1

# Check rollback status
kubectl rollout status deployment/nginx-deployment
```

## Deployment Strategies

### Step 8: Rolling Update Strategy (Default)

```yaml
# rolling-update-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: rolling-update-app
spec:
  replicas: 6
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 25%      # 25% of pods can be unavailable
      maxSurge: 25%            # 25% extra pods during update
  selector:
    matchLabels:
      app: rolling-app
  template:
    metadata:
      labels:
        app: rolling-app
    spec:
      containers:
      - name: app
        image: nginx:1.21
        ports:
        - containerPort: 80
        resources:
          requests:
            memory: "32Mi"
            cpu: "100m"
          limits:
            memory: "64Mi"
            cpu: "200m"
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 10
```

### Step 9: Recreate Strategy

```yaml
# recreate-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: recreate-app
spec:
  replicas: 3
  strategy:
    type: Recreate  # All pods are killed before creating new ones
  selector:
    matchLabels:
      app: recreate-app
  template:
    metadata:
      labels:
        app: recreate-app
    spec:
      containers:
      - name: app
        image: nginx:1.21
        ports:
        - containerPort: 80
        resources:
          requests:
            memory: "32Mi"
            cpu: "100m"
          limits:
            memory: "64Mi"
            cpu: "200m"
```

Test both strategies:

```bash
# Deploy both strategies
kubectl apply -f rolling-update-deployment.yaml
kubectl apply -f recreate-deployment.yaml

# Update rolling update app and watch
kubectl set image deployment/rolling-update-app app=nginx:1.22
kubectl get pods -l app=rolling-app -w

# Update recreate app and watch
kubectl set image deployment/recreate-app app=nginx:1.22
kubectl get pods -l app=recreate-app -w
```

## Advanced Deployment Features

### Step 10: Blue-Green Deployment Simulation

```yaml
# blue-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: blue-deployment
  labels:
    app: web-app
    version: blue
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web-app
      version: blue
  template:
    metadata:
      labels:
        app: web-app
        version: blue
    spec:
      containers:
      - name: web-app
        image: nginx:1.21
        ports:
        - containerPort: 80
        resources:
          requests:
            memory: "32Mi"
            cpu: "100m"
          limits:
            memory: "64Mi"
            cpu: "200m"
        env:
        - name: VERSION
          value: "blue"
---
apiVersion: v1
kind: Service
metadata:
  name: web-app-service
spec:
  selector:
    app: web-app
    version: blue  # Points to blue deployment initially
  ports:
  - port: 80
    targetPort: 80
```

Create green deployment:

```yaml
# green-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: green-deployment
  labels:
    app: web-app
    version: green
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web-app
      version: green
  template:
    metadata:
      labels:
        app: web-app
        version: green
    spec:
      containers:
      - name: web-app
        image: nginx:1.22
        ports:
        - containerPort: 80
        resources:
          requests:
            memory: "32Mi"
            cpu: "100m"
          limits:
            memory: "64Mi"
            cpu: "200m"
        env:
        - name: VERSION
          value: "green"
```

Simulate blue-green deployment:

```bash
# Deploy blue version
kubectl apply -f blue-deployment.yaml

# Test blue version
kubectl port-forward service/web-app-service 8080:80 &
curl http://localhost:8080

# Deploy green version (parallel)
kubectl apply -f green-deployment.yaml

# Switch traffic to green
kubectl patch service web-app-service -p '{"spec":{"selector":{"version":"green"}}}'

# Test green version
curl http://localhost:8080

# If satisfied, remove blue deployment
kubectl delete deployment blue-deployment
```

## Health Checks and Deployment

### Step 11: Deployment with Health Checks

```yaml
# healthy-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: healthy-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: healthy-app
  template:
    metadata:
      labels:
        app: healthy-app
    spec:
      containers:
      - name: app
        image: nginx:alpine
        ports:
        - containerPort: 80
        resources:
          requests:
            memory: "32Mi"
            cpu: "100m"
          limits:
            memory: "64Mi"
            cpu: "200m"
        # Liveness probe - restart if fails
        livenessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 30
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 3
        # Readiness probe - remove from service if fails
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 5
          timeoutSeconds: 3
          failureThreshold: 3
        # Startup probe - for slow starting containers
        startupProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 10
          periodSeconds: 10
          timeoutSeconds: 3
          failureThreshold: 30
```

## Troubleshooting Deployments

### Step 12: Common Issues and Solutions

```bash
# Check deployment status
kubectl get deployments
kubectl describe deployment <deployment-name>

# Check ReplicaSet status
kubectl get rs
kubectl describe rs <replicaset-name>

# Check pod status
kubectl get pods -l app=<app-label>
kubectl describe pod <pod-name>

# Check rollout status
kubectl rollout status deployment/<deployment-name>

# Check rollout history
kubectl rollout history deployment/<deployment-name>

# View events
kubectl get events --sort-by='.lastTimestamp'
```

### Common Problems

**1. Deployment stuck in progress:**
```bash
# Check if new ReplicaSet can't create pods
kubectl describe rs <new-replicaset>
# Usually resource constraints or image pull issues
```

**2. Pods not becoming ready:**
```bash
# Check readiness probe failures
kubectl describe pod <pod-name>
kubectl logs <pod-name>
```

**3. Image pull errors:**
```bash
# Check image name and registry access
kubectl describe pod <pod-name>
# Look for ImagePullBackOff or ErrImagePull
```

## Practice Exercises

### Exercise 1: Multi-Stage Deployment

1. Create a deployment with 5 replicas
2. Perform a rolling update with different maxUnavailable/maxSurge settings
3. Rollback if needed
4. Scale up to 10 replicas

### Exercise 2: Deployment Strategies

1. Compare rolling update vs recreate strategies
2. Implement a blue-green deployment manually
3. Test both approaches with a service

### Exercise 3: Troubleshooting

1. Create a deployment with a non-existent image
2. Diagnose the problem
3. Fix it and verify the deployment succeeds

## Cleanup

```bash
# Delete deployments
kubectl delete deployment nginx-deployment
kubectl delete deployment rolling-update-app
kubectl delete deployment recreate-app
kubectl delete deployment blue-deployment
kubectl delete deployment green-deployment
kubectl delete deployment healthy-app

# Delete services
kubectl delete service web-app-service

# Or delete all with label
kubectl delete all -l app=nginx
```

## Key Takeaways

- ✅ Deployments provide declarative application management
- ✅ ReplicaSets ensure desired number of pod replicas
- ✅ Rolling updates enable zero-downtime deployments
- ✅ Rollbacks provide safety when updates fail
- ✅ Health checks ensure only healthy pods receive traffic
- ✅ Different strategies suit different application needs

## What's Next?

You now understand application deployment and scaling! Next, we'll learn about configuration management:

- ConfigMaps for application configuration
- Secrets for sensitive data
- Environment-specific deployments
- Configuration best practices

**Ready?** Continue to [Lesson 6: ConfigMaps and Secrets](../06-configmaps-secrets/README.md)

## Quick Reference

```bash
# Deployment management
kubectl create deployment <name> --image=<image>
kubectl get deployments
kubectl scale deployment <name> --replicas=<count>
kubectl set image deployment/<name> <container>=<image>

# Rolling updates
kubectl rollout status deployment/<name>
kubectl rollout history deployment/<name>
kubectl rollout undo deployment/<name>

# Debugging
kubectl describe deployment <name>
kubectl get rs
kubectl get pods -l app=<label>
```
