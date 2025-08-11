# Lesson 8: Ingress and Load Balancing

## Learning Objectives

By the end of this lesson, you will:

- Understand Ingress concepts and architecture
- Set up an Ingress controller
- Configure HTTP and HTTPS routing
- Implement path-based and host-based routing
- Set up TLS/SSL termination
- Troubleshoot Ingress issues

## Why Ingress?

**Services expose applications within the cluster**, but for external access you have limited options:

- **NodePort**: Exposes service on each node's IP at a static port
- **LoadBalancer**: Requires cloud provider, one per service (expensive)

**Ingress solves these problems** by providing:
- Single entry point for multiple services
- HTTP/HTTPS routing rules
- TLS termination
- Load balancing
- Name-based virtual hosting

## Ingress Architecture

```
Internet
    │
    ▼
┌─────────────────┐
│   Load Balancer │  (Cloud Provider)
└─────────┬───────┘
          │
          ▼
┌─────────────────┐
│ Ingress Controller│  (nginx, traefik, etc.)
└─────────┬───────┘
          │
          ▼
┌─────────────────┐
│    Ingress      │  (Routing Rules)
│                 │
│  /api    → API Service
│  /web    → Web Service
│  /admin  → Admin Service
└─────────┬───────┘
          │
    ┌─────┼─────┐
    ▼     ▼     ▼
┌─────┐ ┌───┐ ┌─────┐
│ API │ │Web│ │Admin│
│ Svc │ │Svc│ │ Svc │
└─────┘ └───┘ └─────┘
```

## Hands-On: Setting Up Ingress

### Step 1: Enable Ingress Controller in Minikube

```bash
# Enable nginx ingress controller in minikube
minikube addons enable ingress

# Check ingress controller is running
kubectl get pods -n ingress-nginx

# Wait for ingress controller to be ready
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=300s
```

### Step 2: Create Sample Applications

First, let's create multiple applications to route to:

```yaml
# sample-apps.yaml
# Web Application
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
  labels:
    app: web-app
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
        resources:
          requests:
            memory: "32Mi"
            cpu: "100m"
          limits:
            memory: "64Mi"
            cpu: "200m"
        volumeMounts:
        - name: web-content
          mountPath: /usr/share/nginx/html
      initContainers:
      - name: content-creator
        image: busybox
        command: ['sh', '-c']
        args:
        - |
          echo "<h1>Web Application</h1>" > /web/index.html
          echo "<p>This is the main web application</p>" >> /web/index.html
          echo "<p>Path: /</p>" >> /web/index.html
        volumeMounts:
        - name: web-content
          mountPath: /web
      volumes:
      - name: web-content
        emptyDir: {}
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
---
# API Application
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-app
  labels:
    app: api-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: api-app
  template:
    metadata:
      labels:
        app: api-app
    spec:
      containers:
      - name: api-app
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
        volumeMounts:
        - name: api-content
          mountPath: /usr/share/nginx/html
      initContainers:
      - name: content-creator
        image: busybox
        command: ['sh', '-c']
        args:
        - |
          echo "<h1>API Application</h1>" > /api/index.html
          echo "<p>This is the API backend</p>" >> /api/index.html
          echo "<p>Path: /api</p>" >> /api/index.html
          echo "<pre>{'status': 'OK', 'version': '1.0'}</pre>" >> /api/index.html
        volumeMounts:
        - name: api-content
          mountPath: /api
      volumes:
      - name: api-content
        emptyDir: {}
---
apiVersion: v1
kind: Service
metadata:
  name: api-app-service
spec:
  selector:
    app: api-app
  ports:
  - port: 80
    targetPort: 80
---
# Admin Application
apiVersion: apps/v1
kind: Deployment
metadata:
  name: admin-app
  labels:
    app: admin-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: admin-app
  template:
    metadata:
      labels:
        app: admin-app
    spec:
      containers:
      - name: admin-app
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
        volumeMounts:
        - name: admin-content
          mountPath: /usr/share/nginx/html
      initContainers:
      - name: content-creator
        image: busybox
        command: ['sh', '-c']
        args:
        - |
          echo "<h1>Admin Dashboard</h1>" > /admin/index.html
          echo "<p>Administrative interface</p>" >> /admin/index.html
          echo "<p>Path: /admin</p>" >> /admin/index.html
          echo "<p>🔒 Secured area</p>" >> /admin/index.html
        volumeMounts:
        - name: admin-content
          mountPath: /admin
      volumes:
      - name: admin-content
        emptyDir: {}
---
apiVersion: v1
kind: Service
metadata:
  name: admin-app-service
spec:
  selector:
    app: admin-app
  ports:
  - port: 80
    targetPort: 80
```

Deploy the applications:

```bash
# Deploy sample applications
kubectl apply -f sample-apps.yaml

# Verify deployments
kubectl get deployments
kubectl get services
kubectl get pods
```

### Step 3: Create Basic Ingress

```yaml
# basic-ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: basic-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
  - host: myapp.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: web-app-service
            port:
              number: 80
      - path: /api
        pathType: Prefix
        backend:
          service:
            name: api-app-service
            port:
              number: 80
      - path: /admin
        pathType: Prefix
        backend:
          service:
            name: admin-app-service
            port:
              number: 80
```

Deploy and test the Ingress:

```bash
# Deploy Ingress
kubectl apply -f basic-ingress.yaml

# Check Ingress status
kubectl get ingress
kubectl describe ingress basic-ingress

# Get Ingress IP address
kubectl get ingress basic-ingress -o jsonpath='{.status.loadBalancer.ingress[0].ip}'

# For minikube, get the minikube IP
minikube ip

# Add entry to /etc/hosts (replace <MINIKUBE_IP> with actual IP)
echo "$(minikube ip) myapp.local" | sudo tee -a /etc/hosts

# Test the routing
curl http://myapp.local/
curl http://myapp.local/api
curl http://myapp.local/admin
```

## Path-Based Routing

### Step 4: Advanced Path Routing

```yaml
# path-based-ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: path-based-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /$2
spec:
  ingressClassName: nginx
  rules:
  - host: pathrouting.local
    http:
      paths:
      # Exact match
      - path: /health
        pathType: Exact
        backend:
          service:
            name: web-app-service
            port:
              number: 80
      
      # Prefix match with rewrite
      - path: /v1/api(/|$)(.*)
        pathType: ImplementationSpecific
        backend:
          service:
            name: api-app-service
            port:
              number: 80
      
      # Default fallback
      - path: /
        pathType: Prefix
        backend:
          service:
            name: web-app-service
            port:
              number: 80
```

```bash
# Deploy path-based routing
kubectl apply -f path-based-ingress.yaml

# Add to /etc/hosts
echo "$(minikube ip) pathrouting.local" | sudo tee -a /etc/hosts

# Test different paths
curl http://pathrouting.local/
curl http://pathrouting.local/health
curl http://pathrouting.local/v1/api/users
```

## Host-Based Routing

### Step 5: Virtual Hosts

```yaml
# host-based-ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: host-based-ingress
spec:
  ingressClassName: nginx
  rules:
  # Main website
  - host: www.example.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: web-app-service
            port:
              number: 80
  
  # API subdomain
  - host: api.example.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: api-app-service
            port:
              number: 80
  
  # Admin subdomain
  - host: admin.example.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: admin-app-service
            port:
              number: 80
```

```bash
# Deploy host-based routing
kubectl apply -f host-based-ingress.yaml

# Add hosts to /etc/hosts
echo "$(minikube ip) www.example.local" | sudo tee -a /etc/hosts
echo "$(minikube ip) api.example.local" | sudo tee -a /etc/hosts
echo "$(minikube ip) admin.example.local" | sudo tee -a /etc/hosts

# Test different hosts
curl http://www.example.local/
curl http://api.example.local/
curl http://admin.example.local/
```

## TLS/SSL Configuration

### Step 6: HTTPS with Self-Signed Certificates

```bash
# Generate self-signed certificate
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout tls.key -out tls.crt \
  -subj "/CN=secure.example.local/O=secure.example.local"

# Create TLS secret
kubectl create secret tls example-tls \
  --key tls.key \
  --cert tls.crt

# Clean up certificate files
rm tls.key tls.crt
```

```yaml
# tls-ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: tls-ingress
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - secure.example.local
    secretName: example-tls
  rules:
  - host: secure.example.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: web-app-service
            port:
              number: 80
```

```bash
# Deploy TLS Ingress
kubectl apply -f tls-ingress.yaml

# Add to /etc/hosts
echo "$(minikube ip) secure.example.local" | sudo tee -a /etc/hosts

# Test HTTPS (ignore certificate warnings for self-signed)
curl -k https://secure.example.local/
curl -k -v https://secure.example.local/

# Test HTTP redirect to HTTPS
curl -v http://secure.example.local/
```

## Advanced Ingress Features

### Step 7: Load Balancing and Session Affinity

```yaml
# advanced-ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: advanced-ingress
  annotations:
    # Load balancing algorithm
    nginx.ingress.kubernetes.io/upstream-hash-by: "$remote_addr"
    
    # Session affinity
    nginx.ingress.kubernetes.io/affinity: "cookie"
    nginx.ingress.kubernetes.io/affinity-mode: "persistent"
    nginx.ingress.kubernetes.io/session-cookie-name: "INGRESSCOOKIE"
    nginx.ingress.kubernetes.io/session-cookie-expires: "86400"
    nginx.ingress.kubernetes.io/session-cookie-max-age: "86400"
    
    # Rate limiting
    nginx.ingress.kubernetes.io/rate-limit: "100"
    nginx.ingress.kubernetes.io/rate-limit-window: "1m"
    
    # Request size limits
    nginx.ingress.kubernetes.io/proxy-body-size: "8m"
    
    # Custom headers
    nginx.ingress.kubernetes.io/configuration-snippet: |
      add_header X-Served-By $hostname;
      add_header X-Load-Balancer "nginx-ingress";
spec:
  ingressClassName: nginx
  rules:
  - host: advanced.example.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: web-app-service
            port:
              number: 80
```

### Step 8: Authentication and Authorization

```yaml
# auth-ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: auth-ingress
  annotations:
    # Basic authentication
    nginx.ingress.kubernetes.io/auth-type: basic
    nginx.ingress.kubernetes.io/auth-secret: basic-auth
    nginx.ingress.kubernetes.io/auth-realm: 'Authentication Required'
    
    # Whitelist IPs
    nginx.ingress.kubernetes.io/whitelist-source-range: "10.0.0.0/8,172.16.0.0/16"
spec:
  ingressClassName: nginx
  rules:
  - host: auth.example.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: admin-app-service
            port:
              number: 80
```

Create basic auth secret:

```bash
# Create basic auth credentials
htpasswd -c auth admin
# Enter password when prompted

# Create secret from auth file
kubectl create secret generic basic-auth --from-file=auth

# Clean up auth file
rm auth

# Deploy auth ingress
kubectl apply -f auth-ingress.yaml

# Add to /etc/hosts
echo "$(minikube ip) auth.example.local" | sudo tee -a /etc/hosts

# Test authentication
curl -u admin:<password> http://auth.example.local/
```

## Monitoring and Troubleshooting

### Step 9: Ingress Monitoring

```bash
# Check Ingress controller logs
kubectl logs -n ingress-nginx deployment/ingress-nginx-controller

# Check Ingress status
kubectl get ingress --all-namespaces
kubectl describe ingress <ingress-name>

# Check endpoints
kubectl get endpoints

# Check Ingress controller configuration
kubectl exec -n ingress-nginx deployment/ingress-nginx-controller -- cat /etc/nginx/nginx.conf
```

### Step 10: Debugging Common Issues

```bash
# 1. Check if Ingress controller is running
kubectl get pods -n ingress-nginx

# 2. Verify Ingress resources
kubectl get ingress
kubectl describe ingress <name>

# 3. Check service endpoints
kubectl get endpoints <service-name>

# 4. Test service directly
kubectl port-forward service/<service-name> 8080:80

# 5. Check DNS resolution
nslookup <hostname>

# 6. Verify firewall/security groups (cloud environments)
```

## Real-World Example: Complete Web Application

### Step 11: Multi-Tier Application with Ingress

```yaml
# complete-web-app.yaml
# Frontend Application
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
spec:
  replicas: 3
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      containers:
      - name: frontend
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
---
apiVersion: v1
kind: Service
metadata:
  name: frontend-service
spec:
  selector:
    app: frontend
  ports:
  - port: 80
    targetPort: 80
---
# Backend API
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
spec:
  replicas: 2
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
    spec:
      containers:
      - name: backend
        image: nginx:alpine  # In real scenario, use your API image
        ports:
        - containerPort: 80
        resources:
          requests:
            memory: "64Mi"
            cpu: "200m"
          limits:
            memory: "128Mi"
            cpu: "400m"
---
apiVersion: v1
kind: Service
metadata:
  name: backend-service
spec:
  selector:
    app: backend
  ports:
  - port: 80
    targetPort: 80
---
# Production Ingress with multiple features
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: production-ingress
  annotations:
    # Enable CORS
    nginx.ingress.kubernetes.io/enable-cors: "true"
    nginx.ingress.kubernetes.io/cors-allow-origin: "*"
    nginx.ingress.kubernetes.io/cors-allow-methods: "GET, POST, PUT, DELETE, OPTIONS"
    nginx.ingress.kubernetes.io/cors-allow-headers: "Content-Type, Authorization"
    
    # Rate limiting
    nginx.ingress.kubernetes.io/rate-limit: "500"
    nginx.ingress.kubernetes.io/rate-limit-window: "1m"
    
    # Compression
    nginx.ingress.kubernetes.io/enable-brotli: "true"
    
    # Security headers
    nginx.ingress.kubernetes.io/configuration-snippet: |
      add_header X-Frame-Options "SAMEORIGIN";
      add_header X-Content-Type-Options "nosniff";
      add_header X-XSS-Protection "1; mode=block";
      add_header Strict-Transport-Security "max-age=31536000; includeSubDomains";
spec:
  ingressClassName: nginx
  rules:
  - host: mycompany.local
    http:
      paths:
      # API routes
      - path: /api/v1
        pathType: Prefix
        backend:
          service:
            name: backend-service
            port:
              number: 80
      
      # Health check endpoint
      - path: /health
        pathType: Exact
        backend:
          service:
            name: backend-service
            port:
              number: 80
      
      # Frontend (catch-all)
      - path: /
        pathType: Prefix
        backend:
          service:
            name: frontend-service
            port:
              number: 80
```

## Practice Exercises

### Exercise 1: Blue-Green Deployment with Ingress

1. Deploy two versions of an application (blue and green)
2. Use Ingress to route traffic to the blue version
3. Switch traffic to green version by updating Ingress
4. Implement a canary deployment with weighted routing

### Exercise 2: Multi-Environment Setup

1. Create separate Ingress rules for dev, staging, and prod
2. Use different hostnames and paths
3. Implement environment-specific authentication
4. Set up monitoring for each environment

### Exercise 3: SSL/TLS Management

1. Set up cert-manager for automatic certificate provisioning
2. Configure Let's Encrypt certificates
3. Implement certificate renewal
4. Test SSL/TLS configuration

## Best Practices

### Production Considerations

1. **Use proper DNS** instead of /etc/hosts entries
2. **Implement proper SSL/TLS** with valid certificates
3. **Set up monitoring** for Ingress controller and applications
4. **Configure rate limiting** to prevent abuse
5. **Use appropriate resource limits** for Ingress controller
6. **Implement proper authentication** and authorization
7. **Regular security updates** for Ingress controller

### Performance Optimization

```yaml
# performance-ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: performance-ingress
  annotations:
    # Connection settings
    nginx.ingress.kubernetes.io/proxy-connect-timeout: "60"
    nginx.ingress.kubernetes.io/proxy-send-timeout: "60"
    nginx.ingress.kubernetes.io/proxy-read-timeout: "60"
    
    # Buffer settings
    nginx.ingress.kubernetes.io/proxy-buffer-size: "16k"
    nginx.ingress.kubernetes.io/proxy-buffers-number: "8"
    
    # Compression
    nginx.ingress.kubernetes.io/enable-brotli: "true"
    
    # Keep-alive
    nginx.ingress.kubernetes.io/upstream-keepalive-connections: "50"
    nginx.ingress.kubernetes.io/upstream-keepalive-requests: "100"
    nginx.ingress.kubernetes.io/upstream-keepalive-timeout: "60"
spec:
  ingressClassName: nginx
  rules:
  - host: performance.example.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: web-app-service
            port:
              number: 80
```

## Cleanup

```bash
# Remove /etc/hosts entries
sudo sed -i '' '/\.local/d' /etc/hosts

# Delete Ingress resources
kubectl delete ingress basic-ingress path-based-ingress host-based-ingress tls-ingress advanced-ingress auth-ingress production-ingress

# Delete applications
kubectl delete -f sample-apps.yaml
kubectl delete -f complete-web-app.yaml

# Delete secrets
kubectl delete secret example-tls basic-auth

# Disable ingress addon (optional)
# minikube addons disable ingress
```

## Key Takeaways

- ✅ Ingress provides intelligent HTTP/HTTPS routing
- ✅ Ingress controllers implement the actual routing logic
- ✅ Path-based and host-based routing enable flexible traffic management
- ✅ TLS termination secures communications
- ✅ Advanced features include rate limiting, authentication, and load balancing
- ✅ Proper monitoring and troubleshooting are essential for production

## What's Next?

You now understand Ingress and external traffic management! Next, we'll learn about Jobs and CronJobs:

- Batch processing workloads
- Scheduled tasks and maintenance
- Job patterns and parallelism
- Backup and data processing jobs

**Ready?** Continue to [Lesson 9: Jobs and CronJobs](../09-jobs-cronjobs/README.md)

## Quick Reference

```bash
# Ingress management
kubectl get ingress
kubectl describe ingress <name>
kubectl logs -n ingress-nginx deployment/ingress-nginx-controller

# Testing
curl -H "Host: example.com" http://<ingress-ip>/
curl -k https://secure.example.com/

# TLS secrets
kubectl create secret tls <name> --key=tls.key --cert=tls.crt
kubectl get secrets

# Troubleshooting
kubectl get endpoints
kubectl port-forward service/<name> 8080:80
kubectl exec -n ingress-nginx deployment/ingress-nginx-controller -- cat /etc/nginx/nginx.conf
```
