# Lesson 4: Services and Networking

## Learning Objectives

By the end of this lesson, you will:

- Understand how Kubernetes networking works
- Create and use different types of Services
- Implement service discovery
- Load balance traffic across multiple pods
- Debug networking issues

## Why Do We Need Services?

Pods are ephemeral - they come and go. Each pod gets its own IP address, but:

- **Pod IPs change** when pods restart
- **Multiple pods** may provide the same service
- **External access** to pods is needed
- **Load balancing** across pods is required

**Services solve these problems** by providing stable networking.

## Service Types

### 1. ClusterIP (Default)
- **Internal cluster access only**
- Provides stable IP for pod access within cluster
- Most common service type

### 2. NodePort
- **External access via node IP and port**
- Accessible from outside the cluster
- Port range: 30000-32767

### 3. LoadBalancer
- **Cloud provider load balancer**
- Automatically provisions external load balancer
- Works with AWS, GCP, Azure

### 4. ExternalName
- **DNS CNAME mapping**
- Maps service to external DNS name
- No proxying involved

## Hands-On: Creating Services

### Step 1: Create Multiple Pods for Load Balancing

First, let's create multiple pods to demonstrate load balancing:

```yaml
# web-pods.yaml
apiVersion: v1
kind: Pod
metadata:
  name: web-pod-1
  labels:
    app: web-server
    version: v1
spec:
  containers:
  - name: nginx
    image: nginx:alpine
    ports:
    - containerPort: 80
    env:
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
    volumeMounts:
    - name: html-content
      mountPath: /usr/share/nginx/html
  initContainers:
  - name: content-creator
    image: busybox
    command: ['sh', '-c']
    args:
    - |
      echo "<h1>Hello from $(hostname)</h1>" > /html/index.html
      echo "<p>Pod IP: $(hostname -i)</p>" >> /html/index.html
      echo "<p>Timestamp: $(date)</p>" >> /html/index.html
    volumeMounts:
    - name: html-content
      mountPath: /html
  volumes:
  - name: html-content
    emptyDir: {}
---
apiVersion: v1
kind: Pod
metadata:
  name: web-pod-2
  labels:
    app: web-server
    version: v1
spec:
  containers:
  - name: nginx
    image: nginx:alpine
    ports:
    - containerPort: 80
    env:
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
    volumeMounts:
    - name: html-content
      mountPath: /usr/share/nginx/html
  initContainers:
  - name: content-creator
    image: busybox
    command: ['sh', '-c']
    args:
    - |
      echo "<h1>Hello from $(hostname)</h1>" > /html/index.html
      echo "<p>Pod IP: $(hostname -i)</p>" >> /html/index.html
      echo "<p>Timestamp: $(date)</p>" >> /html/index.html
    volumeMounts:
    - name: html-content
      mountPath: /html
  volumes:
  - name: html-content
    emptyDir: {}
---
apiVersion: v1
kind: Pod
metadata:
  name: web-pod-3
  labels:
    app: web-server
    version: v1
spec:
  containers:
  - name: nginx
    image: nginx:alpine
    ports:
    - containerPort: 80
    env:
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
    volumeMounts:
    - name: html-content
      mountPath: /usr/share/nginx/html
  initContainers:
  - name: content-creator
    image: busybox
    command: ['sh', '-c']
    args:
    - |
      echo "<h1>Hello from $(hostname)</h1>" > /html/index.html
      echo "<p>Pod IP: $(hostname -i)</p>" >> /html/index.html
      echo "<p>Timestamp: $(date)</p>" >> /html/index.html
    volumeMounts:
    - name: html-content
      mountPath: /html
  volumes:
  - name: html-content
    emptyDir: {}
```

Deploy the pods:

```bash
kubectl apply -f web-pods.yaml

# Check pods are running
kubectl get pods -l app=web-server -o wide

# Test individual pod connectivity
kubectl port-forward web-pod-1 8081:80 &
kubectl port-forward web-pod-2 8082:80 &
kubectl port-forward web-pod-3 8083:80 &

# Test each pod
curl http://localhost:8081
curl http://localhost:8082
curl http://localhost:8083

# Stop port forwarding
pkill -f "kubectl port-forward"
```

### Step 2: Create a ClusterIP Service

```yaml
# web-service-clusterip.yaml
apiVersion: v1
kind: Service
metadata:
  name: web-service
  labels:
    app: web-server
spec:
  type: ClusterIP  # Default type
  selector:
    app: web-server
  ports:
  - name: http
    port: 80        # Service port
    targetPort: 80  # Pod port
    protocol: TCP
```

Deploy and test the service:

```bash
# Apply the service
kubectl apply -f web-service-clusterip.yaml

# Check service details
kubectl get services
kubectl describe service web-service

# Check service endpoints (should show all 3 pods)
kubectl get endpoints web-service

# Test load balancing with a debug pod
kubectl run debug-pod --image=busybox --rm -it -- sh

# Inside the debug pod:
# Test service discovery by name
wget -qO- web-service
wget -qO- web-service.default.svc.cluster.local

# Test multiple times to see load balancing
for i in {1..10}; do wget -qO- web-service | grep "Hello from"; done
exit
```

### Step 3: Create a NodePort Service

```yaml
# web-service-nodeport.yaml
apiVersion: v1
kind: Service
metadata:
  name: web-service-nodeport
spec:
  type: NodePort
  selector:
    app: web-server
  ports:
  - name: http
    port: 80
    targetPort: 80
    nodePort: 30080  # Optional: specify port, otherwise auto-assigned
```

Deploy and test:

```bash
# Apply NodePort service
kubectl apply -f web-service-nodeport.yaml

# Get service info
kubectl get service web-service-nodeport

# For minikube, get the URL
minikube service web-service-nodeport --url

# Test the service
curl $(minikube service web-service-nodeport --url)

# Test multiple times to see load balancing
for i in {1..5}; do curl $(minikube service web-service-nodeport --url) | grep "Hello from"; done
```

### Step 4: LoadBalancer Service (Cloud Provider)

```yaml
# web-service-loadbalancer.yaml
apiVersion: v1
kind: Service
metadata:
  name: web-service-loadbalancer
spec:
  type: LoadBalancer
  selector:
    app: web-server
  ports:
  - name: http
    port: 80
    targetPort: 80
```

**Note:** LoadBalancer type requires a cloud provider. In minikube, it will show `<pending>` for EXTERNAL-IP.

```bash
# Apply LoadBalancer service
kubectl apply -f web-service-loadbalancer.yaml

# Check status (will be pending in minikube)
kubectl get service web-service-loadbalancer

# In minikube, you can still access it via minikube tunnel
# minikube tunnel  # Run this in a separate terminal
```

## Service Discovery

### DNS-Based Service Discovery

Kubernetes automatically creates DNS records for services:

```yaml
# service-discovery-test.yaml
apiVersion: v1
kind: Pod
metadata:
  name: service-discovery-test
spec:
  containers:
  - name: test-container
    image: busybox
    command: ['sleep', '3600']
    resources:
      requests:
        memory: "16Mi"
        cpu: "50m"
      limits:
        memory: "32Mi"
        cpu: "100m"
```

Test service discovery:

```bash
# Deploy test pod
kubectl apply -f service-discovery-test.yaml

# Test different DNS resolution patterns
kubectl exec service-discovery-test -- nslookup web-service
kubectl exec service-discovery-test -- nslookup web-service.default
kubectl exec service-discovery-test -- nslookup web-service.default.svc.cluster.local

# Test actual connectivity
kubectl exec service-discovery-test -- wget -qO- web-service
kubectl exec service-discovery-test -- wget -qO- web-service.default.svc.cluster.local
```

### Environment Variable Service Discovery

```bash
# Check environment variables in a pod
kubectl exec service-discovery-test -- env | grep WEB_SERVICE

# Kubernetes automatically creates environment variables for services:
# WEB_SERVICE_SERVICE_HOST=10.96.x.x
# WEB_SERVICE_SERVICE_PORT=80
```

## Advanced Service Features

### Step 5: Service with Multiple Ports

```yaml
# multi-port-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: multi-port-service
spec:
  selector:
    app: web-server
  ports:
  - name: http
    port: 80
    targetPort: 80
  - name: https
    port: 443
    targetPort: 443
  - name: metrics
    port: 9090
    targetPort: 9090
```

### Step 6: Service with Session Affinity

```yaml
# sticky-session-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: sticky-session-service
spec:
  selector:
    app: web-server
  sessionAffinity: ClientIP  # Routes same client to same pod
  sessionAffinityConfig:
    clientIP:
      timeoutSeconds: 3600
  ports:
  - port: 80
    targetPort: 80
```

### Step 7: Headless Service

```yaml
# headless-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: headless-service
spec:
  clusterIP: None  # Makes it headless
  selector:
    app: web-server
  ports:
  - port: 80
    targetPort: 80
```

Test headless service:

```bash
# Apply headless service
kubectl apply -f headless-service.yaml

# DNS lookup returns individual pod IPs instead of service IP
kubectl exec service-discovery-test -- nslookup headless-service
```

## Network Debugging

### Step 8: Troubleshooting Network Issues

```bash
# Check service details
kubectl get services
kubectl describe service web-service

# Check endpoints
kubectl get endpoints
kubectl describe endpoints web-service

# Check if pods are labeled correctly
kubectl get pods --show-labels

# Test connectivity from within cluster
kubectl run test-pod --image=busybox --rm -it -- sh
# Inside pod:
wget -qO- web-service
nslookup web-service
exit

# Check kube-proxy logs (if needed)
kubectl logs -n kube-system -l k8s-app=kube-proxy

# Check service iptables rules (advanced)
kubectl get nodes
# SSH to node and run: iptables -t nat -L | grep web-service
```

### Common Network Issues

**1. Service has no endpoints:**
```bash
kubectl get endpoints web-service
# If empty, check pod labels match service selector
```

**2. DNS resolution fails:**
```bash
kubectl exec test-pod -- nslookup kubernetes.default
# If this fails, DNS pods may be down
kubectl get pods -n kube-system -l k8s-app=kube-dns
```

**3. Port connectivity issues:**
```bash
kubectl exec test-pod -- telnet web-service 80
# Check if the port is correct and container is listening
```

## Service Examples by Use Case

### Web Application Service

```yaml
apiVersion: v1
kind: Service
metadata:
  name: web-app-service
  labels:
    app: web-app
    tier: frontend
spec:
  type: LoadBalancer
  selector:
    app: web-app
    tier: frontend
  ports:
  - name: http
    port: 80
    targetPort: 8080
  - name: https
    port: 443
    targetPort: 8443
```

### Database Service

```yaml
apiVersion: v1
kind: Service
metadata:
  name: database-service
spec:
  type: ClusterIP  # Internal only
  selector:
    app: database
  ports:
  - name: postgres
    port: 5432
    targetPort: 5432
```

### Microservice Communication

```yaml
apiVersion: v1
kind: Service
metadata:
  name: user-service
spec:
  selector:
    app: user-service
  ports:
  - name: grpc
    port: 9090
    targetPort: 9090
  - name: http
    port: 8080
    targetPort: 8080
```

## Practice Exercises

### Exercise 1: Multi-Tier Application

Create services for a 3-tier application:
1. **Frontend service** (NodePort) - nginx pods
2. **API service** (ClusterIP) - application pods  
3. **Database service** (ClusterIP) - database pods

### Exercise 2: Service Discovery

1. Create a service with multiple pods
2. Deploy a client pod that discovers and calls the service
3. Scale the service pods up and down
4. Verify load balancing works

### Exercise 3: Network Troubleshooting

1. Create a service with incorrect selector
2. Diagnose why it has no endpoints
3. Fix the issue
4. Test connectivity

## Cleanup

```bash
# Delete services
kubectl delete service web-service
kubectl delete service web-service-nodeport
kubectl delete service web-service-loadbalancer

# Delete pods
kubectl delete pods -l app=web-server
kubectl delete pod service-discovery-test

# Or delete using files
kubectl delete -f web-pods.yaml
kubectl delete -f web-service-clusterip.yaml
kubectl delete -f web-service-nodeport.yaml
```

## Key Takeaways

- ✅ Services provide stable networking for ephemeral pods
- ✅ ClusterIP for internal access, NodePort for external access
- ✅ LoadBalancer requires cloud provider integration
- ✅ Service discovery works via DNS and environment variables
- ✅ Selectors link services to pods via labels
- ✅ Endpoints show which pods are backing a service

## What's Next?

You now understand Kubernetes networking and services! Next, we'll learn about Deployments:

- Managing multiple pod replicas
- Rolling updates and rollbacks
- Scaling applications
- Deployment strategies

**Ready?** Continue to [Lesson 5: Deployments and ReplicaSets](../05-deployments-replicasets/README.md)

## Quick Reference

```bash
# Service operations
kubectl get services
kubectl describe service <name>
kubectl get endpoints <name>

# Test connectivity
kubectl port-forward service/<name> <local-port>:<service-port>
kubectl run test-pod --image=busybox --rm -it -- sh

# Service types
type: ClusterIP      # Internal only
type: NodePort       # External via node IP:port
type: LoadBalancer   # Cloud provider LB
type: ExternalName   # DNS mapping
```
