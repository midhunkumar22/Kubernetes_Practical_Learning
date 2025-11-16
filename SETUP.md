# Kubernetes Local Setup Guide

Complete guide to install and configure Kubernetes locally for learning and development.

## Table of Contents

- [macOS Setup](#macos-setup)
- [Linux Setup](#linux-setup)
- [Windows Setup](#windows-setup)
- [Verification](#verification)
- [Post-Installation](#post-installation)
- [Troubleshooting](#troubleshooting)

---

## macOS Setup

### Prerequisites

Install Homebrew (if not already installed):

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### Option 1: Minikube (Recommended for Learning)

```bash
# Install Docker (required for Minikube)
brew install --cask docker

# Start Docker Desktop from Applications

# Install kubectl
brew install kubectl

# Install Minikube
brew install minikube

# Start Minikube with Docker driver
minikube start --driver=docker

# Enable useful addons
minikube addons enable dashboard
minikube addons enable metrics-server
minikube addons enable ingress

# Install Helm
brew install helm
```

### Option 2: Docker Desktop Kubernetes

```bash
# Install Docker Desktop
brew install --cask docker

# Start Docker Desktop
open /Applications/Docker.app

# Enable Kubernetes in Docker Desktop:
# Docker Desktop → Preferences → Kubernetes → Enable Kubernetes

# Install kubectl
brew install kubectl

# Install Helm
brew install helm
```

### Option 3: Kind (Kubernetes in Docker)

```bash
# Install Docker
brew install --cask docker

# Install kubectl
brew install kubectl

# Install Kind
brew install kind

# Create a cluster
kind create cluster --name k8s-learning

# Install Helm
brew install helm
```

---

## Linux Setup

### Ubuntu/Debian

```bash
# Update package index
sudo apt-get update

# Install Docker
sudo apt-get install -y docker.io
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker $USER

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Install Minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# Start Minikube
minikube start --driver=docker

# Install Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

### Fedora/RHEL/CentOS

```bash
# Install Docker
sudo dnf install -y docker
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker $USER

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Install Minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# Start Minikube
minikube start --driver=docker

# Install Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

---

## Windows Setup

### Option 1: Docker Desktop with Kubernetes

1. **Install Docker Desktop**:
   - Download from [Docker Desktop for Windows](https://www.docker.com/products/docker-desktop)
   - Run installer and restart if required

2. **Enable Kubernetes**:
   - Open Docker Desktop
   - Settings → Kubernetes → Enable Kubernetes
   - Click "Apply & Restart"

3. **Install kubectl**:

```powershell
# Using Chocolatey
choco install kubernetes-cli

# Or using Scoop
scoop install kubectl
```

4. **Install Helm**:

```powershell
# Using Chocolatey
choco install kubernetes-helm

# Or using Scoop
scoop install helm
```

### Option 2: Minikube on Windows

```powershell
# Install Chocolatey (if not installed)
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Install Docker Desktop
choco install docker-desktop

# Install kubectl
choco install kubernetes-cli

# Install Minikube
choco install minikube

# Start Minikube
minikube start --driver=docker

# Install Helm
choco install kubernetes-helm
```

---

## Verification

After installation, verify everything is working:

```bash
# Check Docker
docker --version
docker ps

# Check kubectl
kubectl version --client

# Check cluster connection
kubectl cluster-info

# Check nodes
kubectl get nodes

# Check Helm
helm version

# Create a test pod
kubectl run test-nginx --image=nginx --port=80

# Check pod status
kubectl get pods

# Cleanup test pod
kubectl delete pod test-nginx
```

### Expected Output

```bash
# kubectl get nodes should show:
NAME       STATUS   ROLES           AGE   VERSION
minikube   Ready    control-plane   1m    v1.28.0

# kubectl cluster-info should show:
Kubernetes control plane is running at https://127.0.0.1:xxxxx
CoreDNS is running at https://127.0.0.1:xxxxx/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy
```

---

## Post-Installation

### Configure kubectl Autocomplete

**Bash:**

```bash
echo 'source <(kubectl completion bash)' >>~/.bashrc
echo 'alias k=kubectl' >>~/.bashrc
echo 'complete -o default -F __start_kubectl k' >>~/.bashrc
source ~/.bashrc
```

**Zsh:**

```bash
echo 'source <(kubectl completion zsh)' >>~/.zshrc
echo 'alias k=kubectl' >>~/.zshrc
echo 'complete -o default -F __start_kubectl k' >>~/.zshrc
source ~/.zshrc
```

### Useful Aliases

Add to your `~/.bashrc` or `~/.zshrc`:

```bash
alias k='kubectl'
alias kgp='kubectl get pods'
alias kgs='kubectl get services'
alias kgd='kubectl get deployments'
alias kga='kubectl get all'
alias kdp='kubectl describe pod'
alias kds='kubectl describe service'
alias kl='kubectl logs'
alias kex='kubectl exec -it'
alias kaf='kubectl apply -f'
alias kdf='kubectl delete -f'
```

### Install Useful Tools

```bash
# kubectx and kubens (switch contexts and namespaces easily)
# macOS:
brew install kubectx

# Linux:
git clone https://github.com/ahmetb/kubectx /opt/kubectx
sudo ln -s /opt/kubectx/kubectx /usr/local/bin/kubectx
sudo ln -s /opt/kubectx/kubens /usr/local/bin/kubens

# k9s (Terminal UI for Kubernetes)
# macOS:
brew install derailed/k9s/k9s

# Linux:
curl -sS https://webinstall.dev/k9s | bash

# Lens (Desktop Kubernetes IDE)
# Download from: https://k8slens.dev/
```

### Minikube Useful Commands

```bash
# Start cluster
minikube start

# Stop cluster
minikube stop

# Delete cluster
minikube delete

# Open Kubernetes dashboard
minikube dashboard

# SSH into minikube VM
minikube ssh

# Get minikube IP
minikube ip

# Enable addon
minikube addons enable <addon-name>

# List addons
minikube addons list

# Tunnel to LoadBalancer services
minikube tunnel
```

### Enable Minikube Addons

```bash
# Dashboard
minikube addons enable dashboard

# Metrics Server (for kubectl top)
minikube addons enable metrics-server

# Ingress Controller
minikube addons enable ingress

# Registry
minikube addons enable registry

# Storage Provisioner (usually enabled by default)
minikube addons enable storage-provisioner
```

---

## Troubleshooting

### Docker Issues

**Problem**: Cannot connect to Docker daemon

```bash
# macOS/Linux
sudo systemctl start docker
# Or start Docker Desktop application

# Check if Docker is running
docker ps
```

**Problem**: Permission denied while connecting to Docker

```bash
# Linux
sudo usermod -aG docker $USER
newgrp docker

# Logout and login again
```

### Minikube Issues

**Problem**: Minikube fails to start

```bash
# Delete and recreate cluster
minikube delete
minikube start --driver=docker --force

# Check available drivers
minikube start --help | grep driver

# Use different driver if needed
minikube start --driver=virtualbox
```

**Problem**: Insufficient resources

```bash
# Start with more resources
minikube start --memory=4096 --cpus=2

# Check current config
minikube config view
```

**Problem**: Network issues

```bash
# Check minikube status
minikube status

# Check logs
minikube logs

# Reset network
minikube delete
minikube start
```

### kubectl Issues

**Problem**: kubectl cannot connect to cluster

```bash
# Check current context
kubectl config current-context

# List all contexts
kubectl config get-contexts

# Switch context
kubectl config use-context <context-name>

# For Minikube specifically
minikube update-context
```

**Problem**: kubectl command not found

```bash
# Check if kubectl is in PATH
which kubectl

# macOS: reinstall
brew reinstall kubectl

# Linux: verify installation path
echo $PATH
```

### General Issues

**Problem**: Pods stuck in Pending state

```bash
# Check node resources
kubectl describe nodes

# Check pod events
kubectl describe pod <pod-name>

# Check if metrics-server is running
kubectl top nodes
```

**Problem**: ImagePullBackOff errors

```bash
# Check pod events
kubectl describe pod <pod-name>

# Common causes:
# - Wrong image name
# - Private registry without credentials
# - Network connectivity issues

# Pull image manually to test
docker pull <image-name>
```

**Problem**: CrashLoopBackOff

```bash
# Check logs
kubectl logs <pod-name>

# Check previous logs if container restarted
kubectl logs <pod-name> --previous

# Describe pod for events
kubectl describe pod <pod-name>
```

### Check System Resources

```bash
# Check Docker resources (macOS)
# Docker Desktop → Preferences → Resources

# Check available disk space
df -h

# Check memory
free -h  # Linux
vm_stat  # macOS

# Check Minikube resource usage
docker stats minikube
```

---

## Quick Reference

### Cluster Management

```bash
# Start cluster
minikube start

# Stop cluster
minikube stop

# Check cluster status
kubectl cluster-info
minikube status

# Access dashboard
minikube dashboard
```

### Context Management

```bash
# List contexts
kubectl config get-contexts

# Switch context
kubectl config use-context <context-name>

# View current context
kubectl config current-context
```

### Resource Cleanup

```bash
# Delete all resources in current namespace
kubectl delete all --all

# Delete cluster
minikube delete

# Clean up Docker resources
docker system prune -a --volumes
```

---

## Next Steps

Once setup is complete:

1. ✅ Verify all tools are working
2. ✅ Enable necessary Minikube addons
3. ✅ Configure kubectl aliases
4. ✅ Start with [Lesson 1: Containers and Docker](lessons/01-containers-docker/README.md)

**Happy Learning!** 🚀
