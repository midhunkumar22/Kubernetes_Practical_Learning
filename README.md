# Kubernetes Learning Journey 🚀

Welcome to your comprehensive Kubernetes learning workspace! This repository is designed to take you from zero to confident with Kubernetes through hands-on examples and progressive lessons.

## 📚 Learning Path

### Phase 1: Foundation (Lessons 1-3)
- **Lesson 1**: Containers and Docker Basics
- **Lesson 2**: Kubernetes Architecture and Concepts
- **Lesson 3**: Your First Pod

### Phase 2: Core Workloads (Lessons 4-6)
- **Lesson 4**: Services and Networking
- **Lesson 5**: Deployments and ReplicaSets
- **Lesson 6**: ConfigMaps and Secrets

### Phase 3: Storage and Advanced Topics (Lessons 7-9)
- **Lesson 7**: Persistent Volumes and Claims
- **Lesson 8**: Ingress and Load Balancing
- **Lesson 9**: Jobs and CronJobs

### Phase 4: Production Ready (Lessons 10-12)
- **Lesson 10**: Helm Package Manager
- **Lesson 11**: Monitoring and Logging
- **Lesson 12**: Best Practices and Troubleshooting

## 🛠️ Prerequisites

### Required Tools
```bash
# 1. Install Docker
# Visit: https://docs.docker.com/get-docker/

# 2. Install kubectl
# macOS:
brew install kubectl

# 3. Install a local Kubernetes cluster (choose one):
# Option A: Docker Desktop (enable Kubernetes in preferences)
# Option B: minikube
brew install minikube

# Option C: kind
brew install kind
```

### Verify Installation
```bash
# Check Docker
docker --version

# Check kubectl
kubectl version --client

# Check local cluster (after setup)
kubectl cluster-info
```

## 🚀 Quick Start

1. **Clone and navigate to this workspace**
2. **Start your local Kubernetes cluster**:
   ```bash
   # For Docker Desktop: Enable in preferences
   # For minikube:
   minikube start
   
   # For kind:
   kind create cluster --name k8s-learning
   ```
3. **Verify connection**:
   ```bash
   kubectl get nodes
   ```
4. **Start with Lesson 1** in the `lessons/` directory

## 📁 Repository Structure

```
k8_testing/
├── lessons/           # Step-by-step tutorials
├── examples/          # Practical YAML files
├── exercises/         # Hands-on challenges
├── resources/         # Cheat sheets and references
├── scripts/           # Helper scripts
└── solutions/         # Exercise solutions
```

## 🎯 Learning Objectives

By the end of this course, you will be able to:

- ✅ Understand Kubernetes architecture and core concepts
- ✅ Deploy applications using Pods, Deployments, and Services
- ✅ Manage configuration with ConfigMaps and Secrets
- ✅ Handle persistent data with Volumes and Claims
- ✅ Set up ingress and load balancing
- ✅ Use Helm for package management
- ✅ Monitor and troubleshoot Kubernetes clusters
- ✅ Apply production-ready best practices

## 🤝 How to Use This Workspace

1. **Follow lessons sequentially** - Each builds on the previous
2. **Practice with examples** - Try modifying the provided YAML files
3. **Complete exercises** - Hands-on practice reinforces learning
4. **Reference resources** - Use cheat sheets as needed
5. **Experiment safely** - Your local cluster is perfect for testing

## 🆘 Getting Help

- Check the `resources/troubleshooting.md` file
- Review the `resources/glossary.md` for terminology
- Experiment in your local cluster - it's safe to break things!

## 📋 Progress Tracker

- [ ] Lesson 1: Containers and Docker Basics
- [ ] Lesson 2: Kubernetes Architecture
- [ ] Lesson 3: Your First Pod
- [ ] Lesson 4: Services and Networking
- [ ] Lesson 5: Deployments and ReplicaSets
- [ ] Lesson 6: ConfigMaps and Secrets
- [ ] Lesson 7: Persistent Volumes
- [ ] Lesson 8: Ingress and Load Balancing
- [ ] Lesson 9: Jobs and CronJobs
- [ ] Lesson 10: Helm Package Manager
- [ ] Lesson 11: Monitoring and Logging
- [ ] Lesson 12: Best Practices

---

**Ready to start your Kubernetes journey? Begin with [Lesson 1](lessons/01-containers-docker/README.md)!** 🎉
