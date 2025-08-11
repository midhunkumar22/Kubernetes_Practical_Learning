# Exercise 1: Your First Pod

## Objective
Create, deploy, and interact with your first Kubernetes pod using YAML configuration.

## Prerequisites
- Kubernetes cluster running (minikube, kind, or Docker Desktop)
- kubectl configured and connected to cluster

## Part 1: Create a Simple Pod

### Step 1: Create the Pod YAML
Create a file called `my-first-pod.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-first-pod
  labels:
    app: hello-world
    tier: frontend
spec:
  containers:
  - name: hello-container
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
```

### Step 2: Deploy the Pod
```bash
# Apply the configuration
kubectl apply -f my-first-pod.yaml

# Check if pod is running
kubectl get pods

# Get more details
kubectl get pods -o wide
```

### Step 3: Inspect the Pod
```bash
# Get detailed information
kubectl describe pod my-first-pod

# Check the logs
kubectl logs my-first-pod

# Get the pod's IP address
kubectl get pod my-first-pod -o jsonpath='{.status.podIP}'
```

## Part 2: Interact with the Pod

### Step 4: Access the Pod
```bash
# Execute commands inside the pod
kubectl exec -it my-first-pod -- /bin/sh

# Inside the pod, try these commands:
whoami
hostname
ps aux
cat /etc/os-release
exit
```

### Step 5: Port Forwarding
```bash
# Forward local port to pod
kubectl port-forward my-first-pod 8080:80

# In another terminal, test it:
curl http://localhost:8080

# Stop port forwarding with Ctrl+C
```

## Part 3: Modify and Update

### Step 6: Add Environment Variables
Modify your YAML file to include environment variables:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-first-pod-v2
  labels:
    app: hello-world
    tier: frontend
    version: v2
spec:
  containers:
  - name: hello-container
    image: nginx:alpine
    ports:
    - containerPort: 80
    env:
    - name: ENVIRONMENT
      value: "learning"
    - name: POD_NAME
      valueFrom:
        fieldRef:
          fieldPath: metadata.name
    - name: POD_IP
      valueFrom:
        fieldRef:
          fieldPath: status.podIP
    resources:
      requests:
        memory: "32Mi"
        cpu: "100m"
      limits:
        memory: "64Mi"
        cpu: "200m"
```

### Step 7: Deploy and Test the Updated Pod
```bash
# Deploy the new pod
kubectl apply -f my-first-pod-v2.yaml

# Check environment variables
kubectl exec my-first-pod-v2 -- env | grep -E "(ENVIRONMENT|POD_NAME|POD_IP)"
```

## Part 4: Multi-Container Pod

### Step 8: Create a Multi-Container Pod
Create `multi-container-exercise.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: multi-container-exercise
  labels:
    app: multi-app
spec:
  containers:
  # Web server container
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
  
  # Content generator container
  - name: content-generator
    image: busybox
    command: ['sh', '-c']
    args:
    - |
      while true; do
        echo "<h1>Multi-Container Pod Demo</h1>" > /shared/index.html
        echo "<p>Current time: $(date)</p>" >> /shared/index.html
        echo "<p>Container: content-generator</p>" >> /shared/index.html
        echo "<p>Refresh to see updated time!</p>" >> /shared/index.html
        sleep 10
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

### Step 9: Deploy and Test Multi-Container Pod
```bash
# Deploy the multi-container pod
kubectl apply -f multi-container-exercise.yaml

# Check both containers are running
kubectl get pod multi-container-exercise

# Check logs from specific container
kubectl logs multi-container-exercise -c web-server
kubectl logs multi-container-exercise -c content-generator

# Port forward and test
kubectl port-forward multi-container-exercise 8081:80

# Test in browser or with curl
curl http://localhost:8081
```

## Part 5: Labels and Selectors

### Step 10: Practice with Labels
```bash
# Get pods with specific labels
kubectl get pods -l app=hello-world

# Get pods with multiple label conditions
kubectl get pods -l app=hello-world,tier=frontend

# Add a new label to existing pod
kubectl label pod my-first-pod environment=development

# Remove a label
kubectl label pod my-first-pod environment-

# Show labels on pods
kubectl get pods --show-labels
```

## Part 6: Cleanup and Troubleshooting

### Step 11: Troubleshooting Practice
```bash
# Create a pod with wrong image name to see failure
kubectl run broken-pod --image=nginx:nonexistent-tag

# Check what went wrong
kubectl describe pod broken-pod
kubectl get events --sort-by='.lastTimestamp'

# Delete the broken pod
kubectl delete pod broken-pod
```

### Step 12: Cleanup
```bash
# Delete individual pods
kubectl delete pod my-first-pod
kubectl delete pod my-first-pod-v2
kubectl delete pod multi-container-exercise

# Or delete using the files
kubectl delete -f my-first-pod.yaml
kubectl delete -f my-first-pod-v2.yaml
kubectl delete -f multi-container-exercise.yaml

# Verify cleanup
kubectl get pods
```

## Challenge Questions

1. **What happens if you don't specify resource limits?**
2. **Why do containers in the same pod share the same IP address?**
3. **How would you check which node your pod is running on?**
4. **What's the difference between `kubectl create` and `kubectl apply`?**
5. **How can you see all containers in a multi-container pod?**

## Expected Outcomes

After completing this exercise, you should be able to:

- ✅ Create pod YAML configurations
- ✅ Deploy pods to Kubernetes
- ✅ Inspect pod status and logs
- ✅ Execute commands inside pods
- ✅ Use port forwarding to access pods
- ✅ Work with multi-container pods
- ✅ Use labels and selectors
- ✅ Troubleshoot common pod issues
- ✅ Clean up resources

## Next Steps

Once you've completed this exercise:
1. Try creating pods with different images (redis, postgres, etc.)
2. Experiment with different resource limits
3. Practice troubleshooting by intentionally breaking configurations
4. Move on to [Exercise 2: Services and Networking](exercise-02-services.md)

## Solutions

The solution files are available in the `solutions/exercise-01/` directory.
