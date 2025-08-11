# Lesson 7: Persistent Volumes and Claims

## Learning Objectives

By the end of this lesson, you will:

- Understand Kubernetes storage concepts
- Create and manage Persistent Volumes (PV)
- Use Persistent Volume Claims (PVC) to request storage
- Work with different storage classes
- Deploy stateful applications with persistent storage

## Why Persistent Storage?

Container filesystems are **ephemeral** - data is lost when containers restart. For stateful applications, we need **persistent storage** that survives:

- Pod restarts and rescheduling
- Node failures
- Application updates

## Kubernetes Storage Concepts

### Storage Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Application   │    │       Pod       │    │     Node        │
│                 │    │                 │    │                 │
│  ┌───────────┐  │    │  ┌───────────┐  │    │  ┌───────────┐  │
│  │    App    │  │────┤  │ Container │  │    │  │   Local   │  │
│  └───────────┘  │    │  └───────────┘  │    │  │  Storage  │  │
│                 │    │        │        │    │  └───────────┘  │
└─────────────────┘    │  ┌───────────┐  │    └─────────────────┘
                       │  │  Volume   │  │              │
                       │  │   Mount   │  │              │
                       │  └───────────┘  │              │
                       └─────────┬───────┘              │
                                 │                      │
                       ┌─────────┴───────┐              │
                       │      PVC        │              │
                       │   (Request)     │              │
                       └─────────┬───────┘              │
                                 │                      │
                       ┌─────────┴───────┐              │
                       │       PV        │              │
                       │   (Resource)    │──────────────┘
                       └─────────────────┘
```

### Key Components

- **Persistent Volume (PV)**: Storage resource in the cluster
- **Persistent Volume Claim (PVC)**: Request for storage by a user
- **Storage Class**: Defines types of storage available
- **Volume**: Mounted storage in a pod

## Hands-On: Basic Persistent Storage

### Step 1: Create a Persistent Volume

```yaml
# local-pv.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: local-pv
  labels:
    type: local
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  hostPath:
    path: /tmp/k8s-local-storage
```

Create the PV:

```bash
# Create directory on the node (for local testing)
# In minikube, create inside the VM
minikube ssh
sudo mkdir -p /tmp/k8s-local-storage
sudo chmod 777 /tmp/k8s-local-storage
exit

# Create the PV
kubectl apply -f local-pv.yaml

# Check PV status
kubectl get pv
kubectl describe pv local-pv
```

### Step 2: Create a Persistent Volume Claim

```yaml
# local-pvc.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: local-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 500Mi
  selector:
    matchLabels:
      type: local
```

Create the PVC:

```bash
# Create the PVC
kubectl apply -f local-pvc.yaml

# Check PVC status - should be Bound to local-pv
kubectl get pvc
kubectl describe pvc local-pvc

# Check PV status - should now show Bound
kubectl get pv
```

### Step 3: Use PVC in a Pod

```yaml
# pod-with-pvc.yaml
apiVersion: v1
kind: Pod
metadata:
  name: storage-pod
spec:
  containers:
  - name: app-container
    image: busybox
    command: ['sleep', '3600']
    volumeMounts:
    - name: storage-volume
      mountPath: /data
    resources:
      requests:
        memory: "16Mi"
        cpu: "50m"
      limits:
        memory: "32Mi"
        cpu: "100m"
  volumes:
  - name: storage-volume
    persistentVolumeClaim:
      claimName: local-pvc
```

Test persistent storage:

```bash
# Deploy pod
kubectl apply -f pod-with-pvc.yaml

# Write data to persistent volume
kubectl exec storage-pod -- sh -c 'echo "Hello Persistent Storage!" > /data/test.txt'
kubectl exec storage-pod -- sh -c 'date >> /data/test.txt'
kubectl exec storage-pod -- cat /data/test.txt

# Delete and recreate pod
kubectl delete pod storage-pod
kubectl apply -f pod-with-pvc.yaml

# Verify data persists
kubectl exec storage-pod -- cat /data/test.txt
kubectl exec storage-pod -- ls -la /data
```

## Access Modes

### Understanding Access Modes

- **ReadWriteOnce (RWO)**: Volume can be mounted read-write by a single node
- **ReadOnlyMany (ROX)**: Volume can be mounted read-only by many nodes
- **ReadWriteMany (RWX)**: Volume can be mounted read-write by many nodes

```yaml
# different-access-modes.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: rwo-pv
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteOnce  # Single node, read-write
  hostPath:
    path: /tmp/rwo-storage
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: rox-pv
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadOnlyMany   # Multiple nodes, read-only
  hostPath:
    path: /tmp/rox-storage
```

## Storage Classes

### Step 4: Dynamic Provisioning with Storage Classes

```yaml
# storage-class.yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast-ssd
provisioner: kubernetes.io/no-provisioner  # For local storage
allowVolumeExpansion: true
reclaimPolicy: Delete
volumeBindingMode: WaitForFirstConsumer
```

```yaml
# dynamic-pvc.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: dynamic-pvc
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: fast-ssd
  resources:
    requests:
      storage: 2Gi
```

Check default storage classes:

```bash
# View available storage classes
kubectl get storageclass
kubectl get sc  # Short form

# Check default storage class
kubectl get sc -o yaml | grep "is-default-class"

# Create storage class and PVC
kubectl apply -f storage-class.yaml
kubectl apply -f dynamic-pvc.yaml

# Check PVC status
kubectl get pvc dynamic-pvc
kubectl describe pvc dynamic-pvc
```

## StatefulSets with Persistent Storage

### Step 5: StatefulSet with Volume Claims

```yaml
# statefulset-with-storage.yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: web-stateful
spec:
  serviceName: web-service
  replicas: 3
  selector:
    matchLabels:
      app: web-stateful
  template:
    metadata:
      labels:
        app: web-stateful
    spec:
      containers:
      - name: web-container
        image: nginx:alpine
        ports:
        - containerPort: 80
        volumeMounts:
        - name: web-storage
          mountPath: /usr/share/nginx/html
        resources:
          requests:
            memory: "32Mi"
            cpu: "100m"
          limits:
            memory: "64Mi"
            cpu: "200m"
        # Create unique content for each pod
        lifecycle:
          postStart:
            exec:
              command:
              - sh
              - -c
              - |
                echo "<h1>Pod: $HOSTNAME</h1>" > /usr/share/nginx/html/index.html
                echo "<p>Persistent storage for $HOSTNAME</p>" >> /usr/share/nginx/html/index.html
  volumeClaimTemplates:
  - metadata:
      name: web-storage
    spec:
      accessModes:
        - ReadWriteOnce
      resources:
        requests:
          storage: 100Mi
---
apiVersion: v1
kind: Service
metadata:
  name: web-service
spec:
  clusterIP: None  # Headless service for StatefulSet
  selector:
    app: web-stateful
  ports:
  - port: 80
    targetPort: 80
```

Deploy and test StatefulSet:

```bash
# Deploy StatefulSet
kubectl apply -f statefulset-with-storage.yaml

# Watch pods being created in order
kubectl get pods -l app=web-stateful -w

# Check PVCs created for each pod
kubectl get pvc
kubectl get pvc -l app=web-stateful

# Test individual pod storage
kubectl port-forward web-stateful-0 8080:80 &
curl http://localhost:8080

kubectl port-forward web-stateful-1 8081:80 &
curl http://localhost:8081

# Stop port forwarding
pkill -f "kubectl port-forward"

# Scale StatefulSet
kubectl scale statefulset web-stateful --replicas=5
kubectl get pods -l app=web-stateful

# Check that new PVCs are created
kubectl get pvc -l app=web-stateful
```

## Database Example

### Step 6: PostgreSQL with Persistent Storage

```yaml
# postgres-storage.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres
spec:
  replicas: 1
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
      - name: postgres
        image: postgres:13
        env:
        - name: POSTGRES_DB
          value: myapp
        - name: POSTGRES_USER
          value: admin
        - name: POSTGRES_PASSWORD
          value: secretpassword
        - name: PGDATA
          value: /var/lib/postgresql/data/pgdata
        ports:
        - containerPort: 5432
        volumeMounts:
        - name: postgres-storage
          mountPath: /var/lib/postgresql/data
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
      volumes:
      - name: postgres-storage
        persistentVolumeClaim:
          claimName: postgres-pvc
---
apiVersion: v1
kind: Service
metadata:
  name: postgres-service
spec:
  selector:
    app: postgres
  ports:
  - port: 5432
    targetPort: 5432
  type: ClusterIP
```

Test database persistence:

```bash
# Deploy PostgreSQL
kubectl apply -f postgres-storage.yaml

# Wait for pod to be ready
kubectl wait --for=condition=ready pod -l app=postgres --timeout=300s

# Connect to database and create data
kubectl exec -it deployment/postgres -- psql -U admin -d myapp

# Inside PostgreSQL:
# CREATE TABLE users (id SERIAL, name VARCHAR(50));
# INSERT INTO users (name) VALUES ('Alice'), ('Bob'), ('Charlie');
# SELECT * FROM users;
# \q

# Delete and recreate deployment
kubectl delete deployment postgres
kubectl apply -f postgres-storage.yaml

# Wait for pod to be ready again
kubectl wait --for=condition=ready pod -l app=postgres --timeout=300s

# Verify data persists
kubectl exec -it deployment/postgres -- psql -U admin -d myapp -c "SELECT * FROM users;"
```

## Volume Types

### Step 7: Different Volume Types

```yaml
# volume-types-examples.yaml
apiVersion: v1
kind: Pod
metadata:
  name: volume-types-pod
spec:
  containers:
  - name: app-container
    image: busybox
    command: ['sleep', '3600']
    volumeMounts:
    - name: empty-dir-volume
      mountPath: /tmp/empty-dir
    - name: host-path-volume
      mountPath: /tmp/host-path
    - name: config-volume
      mountPath: /tmp/config
    resources:
      requests:
        memory: "16Mi"
        cpu: "50m"
      limits:
        memory: "32Mi"
        cpu: "100m"
  volumes:
  # EmptyDir - temporary storage
  - name: empty-dir-volume
    emptyDir: {}
  
  # HostPath - node filesystem
  - name: host-path-volume
    hostPath:
      path: /tmp
      type: Directory
  
  # ConfigMap - configuration files
  - name: config-volume
    configMap:
      name: local-pv  # Reusing existing configmap
```

## Storage Monitoring and Troubleshooting

### Step 8: Monitoring Storage

```bash
# Check PV and PVC status
kubectl get pv
kubectl get pvc
kubectl get pvc --all-namespaces

# Detailed information
kubectl describe pv <pv-name>
kubectl describe pvc <pvc-name>

# Check storage usage in pods
kubectl exec <pod-name> -- df -h

# View storage events
kubectl get events --field-selector involvedObject.kind=PersistentVolume
kubectl get events --field-selector involvedObject.kind=PersistentVolumeClaim
```

### Common Storage Issues

```bash
# PVC stuck in Pending
kubectl describe pvc <pvc-name>
# Check: No suitable PV available, storage class issues

# Pod stuck in Pending due to volume
kubectl describe pod <pod-name>
# Look for volume mounting errors

# Volume mount permission issues
kubectl exec <pod-name> -- ls -la /path/to/mount
# Check file permissions and ownership
```

## Best Practices

### Storage Best Practices

1. **Use appropriate access modes** for your use case
2. **Set resource requests** to avoid over-provisioning
3. **Choose the right storage class** for performance needs
4. **Backup important data** regularly
5. **Monitor storage usage** and set up alerts

### Security Considerations

```yaml
# secure-storage-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: secure-storage-pod
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    fsGroup: 2000
  containers:
  - name: app-container
    image: busybox
    command: ['sleep', '3600']
    securityContext:
      allowPrivilegeEscalation: false
      readOnlyRootFilesystem: true
    volumeMounts:
    - name: data-volume
      mountPath: /data
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
  - name: data-volume
    persistentVolumeClaim:
      claimName: local-pvc
  - name: tmp-volume
    emptyDir: {}
```

## Practice Exercises

### Exercise 1: Multi-Pod Shared Storage

1. Create a PV with ReadWriteMany access mode
2. Create multiple pods that write to the same volume
3. Verify data sharing between pods

### Exercise 2: Database Migration

1. Deploy a database with persistent storage
2. Create some data
3. Perform a "migration" by changing the deployment
4. Verify data persistence

### Exercise 3: Storage Classes

1. Create different storage classes
2. Deploy applications with different storage requirements
3. Compare performance characteristics

## Cleanup

```bash
# Delete StatefulSet (keeps PVCs)
kubectl delete statefulset web-stateful

# Delete PVCs (this deletes data!)
kubectl delete pvc local-pvc postgres-pvc dynamic-pvc
kubectl delete pvc -l app=web-stateful

# Delete PVs
kubectl delete pv local-pv

# Delete other resources
kubectl delete pod storage-pod volume-types-pod secure-storage-pod
kubectl delete deployment postgres
kubectl delete service postgres-service web-service
kubectl delete storageclass fast-ssd

# Clean up node storage (in minikube)
minikube ssh
sudo rm -rf /tmp/k8s-local-storage /tmp/rwo-storage /tmp/rox-storage
exit
```

## Key Takeaways

- ✅ Persistent Volumes provide storage resources in the cluster
- ✅ Persistent Volume Claims request storage from users
- ✅ Storage Classes enable dynamic provisioning
- ✅ StatefulSets provide stable storage for stateful applications
- ✅ Different access modes suit different use cases
- ✅ Proper security context is important for volume access

## What's Next?

You now understand persistent storage in Kubernetes! Next, we'll learn about Ingress:

- Exposing services to external traffic
- Load balancing and routing
- TLS termination
- Ingress controllers

**Ready?** Continue to [Lesson 8: Ingress and Load Balancing](../08-ingress-load-balancing/README.md)

## Quick Reference

```bash
# PV and PVC operations
kubectl get pv
kubectl get pvc
kubectl describe pv <name>
kubectl describe pvc <name>

# Storage classes
kubectl get storageclass
kubectl describe storageclass <name>

# Volume troubleshooting
kubectl describe pod <pod-name>  # Check volume events
kubectl exec <pod-name> -- df -h  # Check disk usage
kubectl exec <pod-name> -- ls -la /mount/path  # Check permissions
```
