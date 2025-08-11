# Kubernetes Glossary

## Core Concepts

### **API Server**
The front-end for the Kubernetes control plane. All communication with the cluster goes through the API server, which exposes the Kubernetes API.

### **Cluster**
A set of nodes that run containerized applications managed by Kubernetes. A cluster consists of at least one master node and multiple worker nodes.

### **ConfigMap**
A Kubernetes object used to store non-confidential configuration data in key-value pairs. Pods can consume ConfigMaps as environment variables, command-line arguments, or configuration files.

### **Container**
A lightweight, portable package that includes an application and all its dependencies. Containers share the host OS kernel but are isolated from each other.

### **Control Plane**
The set of components that make global decisions about the cluster (e.g., scheduling) and detect and respond to cluster events. Includes API server, etcd, scheduler, and controller manager.

### **CronJob**
A Kubernetes object that creates Jobs on a scheduled basis, similar to a cron job in Unix/Linux systems.

### **DaemonSet**
Ensures that all (or some) nodes run a copy of a specific pod. Typically used for system daemons like log collectors or monitoring agents.

### **Deployment**
A Kubernetes object that provides declarative updates for pods and ReplicaSets. It manages the deployment and scaling of applications.

### **etcd**
A distributed key-value store that stores all cluster data, including configuration data, state, and metadata.

### **Ingress**
An API object that manages external access to services in a cluster, typically HTTP/HTTPS. Can provide load balancing, SSL termination, and name-based virtual hosting.

### **Job**
A Kubernetes object that runs pods to completion. Unlike Deployments, Jobs are designed for finite tasks that run until successful completion.

### **kubelet**
The node agent that runs on each worker node. It ensures containers are running in pods according to the specifications provided by the control plane.

### **kubectl**
The command-line tool for interacting with Kubernetes clusters. Used to deploy applications, inspect cluster resources, and view logs.

### **kube-proxy**
A network proxy that runs on each node, maintaining network rules that allow communication to pods from inside or outside the cluster.

### **Label**
Key-value pairs attached to objects (like pods) used for organizing and selecting subsets of objects.

### **Namespace**
A way to divide cluster resources between multiple users or environments. Provides a scope for names and can be used to apply resource quotas.

### **Node**
A worker machine in Kubernetes. Can be a virtual or physical machine. Each node contains the services necessary to run pods.

### **Persistent Volume (PV)**
A piece of storage in the cluster that has been provisioned by an administrator or dynamically provisioned using Storage Classes.

### **Persistent Volume Claim (PVC)**
A request for storage by a user. Claims can specify size, access modes, and storage class requirements.

### **Pod**
The smallest deployable unit in Kubernetes. A pod represents a single instance of a running process and contains one or more containers.

### **ReplicaSet**
Ensures that a specified number of pod replicas are running at any given time. Usually managed by Deployments.

### **Secret**
A Kubernetes object used to store sensitive information such as passwords, OAuth tokens, and SSH keys.

### **Selector**
A label query that identifies a set of objects. Used by services and other controllers to identify which pods to manage.

### **Service**
An abstract way to expose an application running on a set of pods as a network service. Provides stable networking for dynamic pod sets.

### **StatefulSet**
Manages the deployment and scaling of pods with persistent storage and stable network identities. Used for stateful applications.

### **Volume**
A directory accessible to containers in a pod. Volumes have explicit lifetimes and can persist data beyond the life of individual containers.

## Service Types

### **ClusterIP**
Exposes the service on an internal IP in the cluster. This is the default service type and makes the service only reachable from within the cluster.

### **NodePort**
Exposes the service on each node's IP at a static port. You can contact the NodePort service from outside the cluster.

### **LoadBalancer**
Exposes the service externally using a cloud provider's load balancer. Creates a NodePort and ClusterIP automatically.

### **ExternalName**
Maps the service to a DNS name by returning a CNAME record with its value.

## Container States

### **Pending**
The pod has been accepted by the cluster but one or more containers are not yet running.

### **Running**
All containers in the pod have been created and at least one container is running, starting, or restarting.

### **Succeeded**
All containers in the pod have terminated successfully and will not be restarted.

### **Failed**
All containers in the pod have terminated, and at least one container has terminated in failure.

### **Unknown**
The state of the pod could not be obtained, typically due to communication issues with the host.

## Resource Management

### **Requests**
The minimum amount of CPU or memory that a container needs. Used by the scheduler to decide which node to place the pod on.

### **Limits**
The maximum amount of CPU or memory that a container can use. Prevents containers from consuming too many resources.

### **Quality of Service (QoS) Classes**

#### **Guaranteed**
Pods where every container has memory and CPU requests and limits set, and they are equal.

#### **Burstable**
Pods that don't meet Guaranteed criteria but have at least one container with memory or CPU requests.

#### **BestEffort**
Pods where no container has any memory or CPU requests or limits set.

## Networking Terms

### **CNI (Container Network Interface)**
A specification and libraries for writing plugins to configure network interfaces in Linux containers.

### **Service Mesh**
A dedicated infrastructure layer for handling service-to-service communication, often implemented using sidecar proxies.

### **Ingress Controller**
A specialized load balancer for Kubernetes environments that accepts traffic from outside and routes it to services inside the cluster.

### **Network Policy**
A specification of how groups of pods are allowed to communicate with each other and other network endpoints.

## Storage Terms

### **Storage Class**
Describes the "classes" of storage offered by the cluster administrator. Different classes might map to different quality-of-service levels or backup policies.

### **Volume Mount**
The process of making a volume available inside a container at a specified path.

### **EmptyDir**
A temporary volume that's created when a pod is assigned to a node and deleted when the pod is removed.

### **HostPath**
Mounts a file or directory from the host node's filesystem into a pod.

## Security Terms

### **RBAC (Role-Based Access Control)**
A method of regulating access to resources based on the roles of individual users within an organization.

### **Service Account**
Provides an identity for processes that run in a pod, used for authentication to the API server.

### **Security Context**
Defines privilege and access control settings for a pod or container, including user ID, group ID, and capabilities.

### **Pod Security Policy**
A cluster-level resource that controls security-sensitive aspects of pod specification.

## Helm Terms

### **Chart**
A Helm package containing all resource definitions necessary to run an application in Kubernetes.

### **Release**
An instance of a chart running in a Kubernetes cluster. One chart can be installed multiple times with different releases.

### **Repository**
A collection of charts that can be shared with others.

### **Values**
Configuration data for a chart. Can be overridden during installation or upgrade.

## Common Abbreviations

- **k8s**: Kubernetes (8 letters between 'k' and 's')
- **API**: Application Programming Interface
- **CLI**: Command Line Interface
- **CRUD**: Create, Read, Update, Delete
- **DNS**: Domain Name System
- **HTTP/HTTPS**: HyperText Transfer Protocol (Secure)
- **IP**: Internet Protocol
- **JSON**: JavaScript Object Notation
- **REST**: Representational State Transfer
- **SSH**: Secure Shell
- **TLS/SSL**: Transport Layer Security / Secure Sockets Layer
- **URL**: Uniform Resource Locator
- **YAML**: YAML Ain't Markup Language (recursive acronym)

## Useful Commands Reference

```bash
# Get help for any command
kubectl --help
kubectl <command> --help

# Get detailed information about resources
kubectl explain <resource>
kubectl explain pod.spec.containers

# Common resource shortcuts
kubectl get po        # pods
kubectl get svc       # services
kubectl get deploy    # deployments
kubectl get ns        # namespaces
kubectl get no        # nodes
```

## Learning Tips

1. **Start Simple**: Begin with basic concepts like pods and services before moving to complex topics
2. **Practice Regularly**: Use a local cluster for hands-on experimentation
3. **Read Error Messages**: Kubernetes error messages are usually informative
4. **Use kubectl explain**: Get documentation for any resource field
5. **Join Communities**: Engage with Kubernetes communities for support and learning

---

*This glossary covers the essential Kubernetes terminology you'll encounter during your learning journey. Refer back to it whenever you encounter unfamiliar terms.*
