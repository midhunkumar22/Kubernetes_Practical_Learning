#!/bin/bash

# Kubernetes Learning Environment Setup Script
# This script helps set up a local Kubernetes learning environment

set -e

echo "🚀 Kubernetes Learning Environment Setup"
echo "========================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check Prerequisites
echo ""
print_status "Checking prerequisites..."

# Check Docker
if command_exists docker; then
    DOCKER_VERSION=$(docker --version | cut -d' ' -f3 | cut -d',' -f1)
    print_success "Docker found: $DOCKER_VERSION"
else
    print_error "Docker not found. Please install Docker first."
    echo "Visit: https://docs.docker.com/get-docker/"
    exit 1
fi

# Check kubectl
if command_exists kubectl; then
    KUBECTL_VERSION=$(kubectl version --client --short 2>/dev/null | cut -d' ' -f3)
    print_success "kubectl found: $KUBECTL_VERSION"
else
    print_warning "kubectl not found. Installing via brew..."
    if command_exists brew; then
        brew install kubectl
        print_success "kubectl installed"
    else
        print_error "Homebrew not found. Please install kubectl manually."
        echo "Visit: https://kubernetes.io/docs/tasks/tools/install-kubectl-macos/"
        exit 1
    fi
fi

# Check for Kubernetes cluster options
echo ""
print_status "Checking for Kubernetes cluster options..."

HAS_CLUSTER=false

# Check Docker Desktop Kubernetes
if docker info >/dev/null 2>&1; then
    if kubectl cluster-info >/dev/null 2>&1; then
        CURRENT_CONTEXT=$(kubectl config current-context)
        print_success "Active Kubernetes cluster found: $CURRENT_CONTEXT"
        HAS_CLUSTER=true
    fi
fi

# Check for minikube
if command_exists minikube; then
    print_success "minikube found"
    if ! $HAS_CLUSTER; then
        print_status "Starting minikube cluster..."
        minikube start
        HAS_CLUSTER=true
    fi
elif command_exists brew; then
    print_warning "minikube not found. Installing..."
    brew install minikube
    print_status "Starting minikube cluster..."
    minikube start
    HAS_CLUSTER=true
fi

# Check for kind
if command_exists kind; then
    print_success "kind found"
    if ! $HAS_CLUSTER; then
        print_status "Creating kind cluster..."
        kind create cluster --name k8s-learning
        HAS_CLUSTER=true
    fi
elif command_exists brew && ! $HAS_CLUSTER; then
    print_warning "kind not found. Installing as backup option..."
    brew install kind
    print_status "Creating kind cluster..."
    kind create cluster --name k8s-learning
    HAS_CLUSTER=true
fi

if ! $HAS_CLUSTER; then
    print_error "No Kubernetes cluster available. Please set up one of:"
    echo "  1. Docker Desktop with Kubernetes enabled"
    echo "  2. minikube"
    echo "  3. kind"
    exit 1
fi

# Verify cluster connectivity
echo ""
print_status "Verifying cluster connectivity..."

if kubectl cluster-info >/dev/null 2>&1; then
    CLUSTER_INFO=$(kubectl cluster-info | head -1)
    print_success "Cluster is accessible"
    echo "   $CLUSTER_INFO"
    
    # Get node info
    NODE_COUNT=$(kubectl get nodes --no-headers | wc -l | tr -d ' ')
    print_success "Cluster has $NODE_COUNT node(s)"
    
    # Check if we can create resources
    if kubectl auth can-i create pods >/dev/null 2>&1; then
        print_success "You have permission to create pods"
    else
        print_warning "Limited permissions detected"
    fi
else
    print_error "Cannot connect to Kubernetes cluster"
    exit 1
fi

# Create learning namespace
echo ""
print_status "Setting up learning environment..."

if kubectl get namespace learning >/dev/null 2>&1; then
    print_success "Learning namespace already exists"
else
    kubectl create namespace learning
    print_success "Created 'learning' namespace"
fi

# Set learning namespace as default
kubectl config set-context --current --namespace=learning
print_success "Set 'learning' as default namespace"

# Verify setup
echo ""
print_status "Final verification..."

# Test creating a simple pod
kubectl run test-pod --image=nginx:alpine --dry-run=client -o yaml > /dev/null
if [ $? -eq 0 ]; then
    print_success "Can create pod configurations"
else
    print_error "Cannot create pod configurations"
fi

# Clean up any existing test resources
kubectl delete pod test-pod 2>/dev/null || true

echo ""
print_success "🎉 Kubernetes learning environment is ready!"
echo ""
echo "Next steps:"
echo "1. Navigate to the lessons/ directory"
echo "2. Start with lesson 1: 'cd lessons/01-containers-docker'"
echo "3. Follow the README.md file in each lesson"
echo ""
echo "Quick commands to get started:"
echo "  kubectl get nodes           # View cluster nodes"
echo "  kubectl get pods            # View pods in learning namespace"
echo "  kubectl cluster-info        # View cluster information"
echo ""
echo "Happy learning! 🚀"
