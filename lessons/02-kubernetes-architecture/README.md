# Lesson 2: Kubernetes Architecture and Core Concepts

## Learning Objectives

By the end of this lesson, you will understand:

- Kubernetes cluster architecture
- Master node components
- Worker node components
- Core Kubernetes objects
- How Kubernetes manages containers

## What is Kubernetes?

Kubernetes (k8s) is an open-source container orchestration platform that automates:

- **Deployment** of containerized applications
- **Scaling** applications up and down
- **Management** of application lifecycle
- **Service discovery** and load balancing
- **Storage orchestration**
- **Automated rollouts and rollbacks**

Think of Kubernetes as the "operating system" for your containerized applications.

## Kubernetes Cluster Architecture

A Kubernetes cluster consists of:

```
┌─────────────────────────────────────────────────────────────┐
│                    Kubernetes Cluster                      │
│                                                             │
│  ┌─────────────────┐    ┌─────────────────────────────────┐ │
│  │   Master Node   │    │         Worker Nodes            │ │
│  │                 │    │                                 │ │
│  │  ┌───────────┐  │    │  ┌─────────┐  ┌─────────────┐  │ │
│  │  │ API Server│  │◄───┤  │  kubelet │  │   Container │  │ │
│  │  └───────────┘  │    │  └─────────┘  │   Runtime   │  │ │
│  │  ┌───────────┐  │    │  ┌─────────┐  │  (Docker)   │  │ │
│  │  │   etcd    │  │    │  │kube-proxy│  └─────────────┘  │ │
│  │  └───────────┘  │    │  └─────────┘                    │ │
│  │  ┌───────────┐  │    │  ┌─────────────────────────────┐ │ │
│  │  │Scheduler  │  │    │  │         Pods                │ │ │
│  │  └───────────┘  │    │  │  ┌─────┐ ┌─────┐ ┌─────┐  │ │ │
│  │  ┌───────────┐  │    │  │  │App A│ │App B│ │App C│  │ │ │
│  │  │Controller │  │    │  │  └─────┘ └─────┘ └─────┘  │ │ │
│  │  │ Manager   │  │    │  └─────────────────────────────┘ │ │
│  │  └───────────┘  │    └─────────────────────────────────┘ │
│  └─────────────────┘                                        │
└─────────────────────────────────────────────────────────────┘
```

## Master Node Components

The master node (control plane) manages the cluster:

### 1. API Server
- **Purpose**: Front-end for the Kubernetes control plane
- **Function**: All communication goes through the API server
- **Access**: REST API that kubectl uses

### 2. etcd
- **Purpose**: Distributed key-value store
- **Function**: Stores all cluster data and state
- **Backup**: Critical to backup for disaster recovery

### 3. Scheduler
- **Purpose**: Decides which node runs which pods
- **Function**: Considers resource requirements, constraints, and policies
- **Factors**: CPU, memory, storage, affinity rules

### 4. Controller Manager
- **Purpose**: Runs controller processes
- **Function**: Ensures desired state matches actual state
- **Examples**: ReplicaSet Controller, Deployment Controller

## Worker Node Components

Worker nodes run your applications:

### 1. kubelet
- **Purpose**: Node agent that communicates with master
- **Function**: Manages pods and containers on the node
- **Responsibilities**: Starts, stops, and monitors containers

### 2. kube-proxy
- **Purpose**: Network proxy running on each node
- **Function**: Maintains network rules for pod communication
- **Implementation**: Usually uses iptables

### 3. Container Runtime
- **Purpose**: Runs containers
- **Options**: Docker, containerd, CRI-O
- **Interface**: Container Runtime Interface (CRI)

## Core Kubernetes Objects

### 1. Pod
- **Smallest deployable unit** in Kubernetes
- **Contains one or more containers**
- **Shared network and storage**
- **Ephemeral** - pods can be created and destroyed

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-pod
spec:
  containers:
  - name: web-server
    image: nginx:latest
    ports:
    - containerPort: 80
```

### 2. Service
- **Stable network endpoint** for pods
- **Load balancing** across multiple pods
- **Service discovery** via DNS
- **Types**: ClusterIP, NodePort, LoadBalancer

```yaml
apiVersion: v1
kind: Service
metadata:
  name: web-service
spec:
  selector:
    app: web-app
  ports:
  - port: 80
    targetPort: 80
  type: ClusterIP
```

### 3. Deployment
- **Declarative way** to manage pods
- **Rolling updates** and rollbacks
- **Replica management**
- **Self-healing** capabilities

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-deployment
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web-app
  template:
    metadata:
      labels:
        app: web-app
    spec:
      containers:
      - name: web-server
        image: nginx:latest
        ports:
        - containerPort: 80
```

## How Kubernetes Works

### The Desired State Model

1. **You declare** what you want (desired state)
2. **Kubernetes observes** the current state
3. **Controllers take action** to match desired state
4. **Continuous reconciliation** loop

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   Desired   │───▶│   Current   │───▶│   Actions   │
│    State    │    │    State    │    │   Taken     │
└─────────────┘    └─────────────┘    └─────────────┘
       ▲                                      │
       │                                      │
       └──────────────────────────────────────┘
              Continuous Reconciliation
```

### Example Workflow

1. **User** submits deployment YAML via kubectl
2. **API Server** validates and stores in etcd
3. **Scheduler** assigns pods to nodes
4. **kubelet** on worker nodes starts containers
5. **Controllers** monitor and maintain desired state

## Hands-On: Explore Your Cluster

Let's explore a Kubernetes cluster (make sure you have one running):

```bash
# Check cluster info
kubectl cluster-info

# Get cluster nodes
kubectl get nodes

# Get detailed node information
kubectl describe node <node-name>

# Check what's running in system namespaces
kubectl get pods -n kube-system

# Get API resources
kubectl api-resources

# Check cluster version
kubectl version
```

## Namespaces

Namespaces provide a way to divide cluster resources:

```bash
# List namespaces
kubectl get namespaces

# Get pods in specific namespace
kubectl get pods -n kube-system

# Create a namespace
kubectl create namespace my-namespace

# Set default namespace
kubectl config set-context --current --namespace=my-namespace
```

## Labels and Selectors

Labels are key-value pairs attached to objects:

```yaml
metadata:
  labels:
    app: web-server
    version: v1.0
    environment: production
```

Selectors query objects by labels:

```bash
# Get pods with specific label
kubectl get pods -l app=web-server

# Get pods with multiple labels
kubectl get pods -l app=web-server,environment=production
```

## Practice Exercise

1. **Explore your cluster**:
   ```bash
   kubectl get nodes -o wide
   kubectl get pods --all-namespaces
   kubectl get services --all-namespaces
   ```

2. **Create your first namespace**:
   ```bash
   kubectl create namespace learning
   kubectl get namespaces
   ```

3. **Set the namespace as default**:
   ```bash
   kubectl config set-context --current --namespace=learning
   ```

## Key Concepts Summary

| Concept | Purpose | Example |
|---------|---------|---------|
| **Pod** | Smallest unit, runs containers | A web server container |
| **Service** | Network access to pods | Load balancer for web servers |
| **Deployment** | Manages pod replicas | 3 replicas of web server |
| **Namespace** | Isolate resources | dev, staging, prod environments |
| **Labels** | Organize and select objects | app=frontend, tier=web |

## What We've Learned

- ✅ Kubernetes cluster architecture
- ✅ Master and worker node components  
- ✅ Core objects: Pods, Services, Deployments
- ✅ Desired state model
- ✅ Namespaces and labels
- ✅ Basic kubectl commands

## Next Steps

In the next lesson, we'll get hands-on with your first pod:

- Creating pods with YAML
- Connecting to pods
- Viewing logs and troubleshooting
- Pod lifecycle

**Ready?** Continue to [Lesson 3: Your First Pod](../03-your-first-pod/README.md)

## Quick Reference

```bash
# Cluster info
kubectl cluster-info
kubectl get nodes
kubectl version

# Namespaces
kubectl get namespaces
kubectl create namespace <name>
kubectl config set-context --current --namespace=<name>

# Basic object operations
kubectl get <resource>
kubectl describe <resource> <name>
kubectl delete <resource> <name>

# Labels and selectors
kubectl get pods -l key=value
kubectl label pod <name> key=value
```
