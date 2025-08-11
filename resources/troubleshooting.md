# Kubernetes Troubleshooting Guide

## Common Issues and Solutions

### Pod Issues

#### Pod Stuck in Pending State

**Symptoms:**
- Pod shows `Pending` status for extended time
- `kubectl get pods` shows pod not running

**Diagnosis:**
```bash
kubectl describe pod <pod-name>
kubectl get events --sort-by='.lastTimestamp'
```

**Common Causes & Solutions:**

1. **Insufficient Resources**
   - **Issue**: Not enough CPU/memory on any node
   - **Solution**: 
     ```bash
     kubectl top nodes
     kubectl describe nodes
     # Reduce resource requests or add more nodes
     ```

2. **Image Pull Issues**
   - **Issue**: Cannot pull container image
   - **Solution**:
     ```bash
     # Check image name and tag
     docker pull <image-name>
     # Use correct image name in pod spec
     ```

3. **Node Selector Issues**
   - **Issue**: No nodes match the selector
   - **Solution**: Check node labels and pod nodeSelector

#### Pod Stuck in ImagePullBackOff

**Symptoms:**
- Pod status shows `ImagePullBackOff` or `ErrImagePull`

**Diagnosis:**
```bash
kubectl describe pod <pod-name>
kubectl logs <pod-name>
```

**Solutions:**
1. **Check image name**: Ensure image name and tag are correct
2. **Registry access**: Verify access to the container registry
3. **Authentication**: Add image pull secrets if needed
   ```bash
   kubectl create secret docker-registry <secret-name> \
     --docker-server=<registry-url> \
     --docker-username=<username> \
     --docker-password=<password>
   ```

#### Pod Stuck in CrashLoopBackOff

**Symptoms:**
- Pod keeps restarting
- Status shows `CrashLoopBackOff`

**Diagnosis:**
```bash
kubectl logs <pod-name>
kubectl logs <pod-name> --previous  # Previous container logs
kubectl describe pod <pod-name>
```

**Common Solutions:**
1. **Application errors**: Fix application code
2. **Missing dependencies**: Ensure all required dependencies are available
3. **Configuration issues**: Check environment variables and config files
4. **Health check failures**: Adjust liveness/readiness probes

#### Container Won't Start

**Diagnosis:**
```bash
kubectl describe pod <pod-name>
kubectl logs <pod-name> -c <container-name>
```

**Common Issues:**
1. **Wrong command/args**: Check container command and arguments
2. **Missing files**: Ensure required files are in the image
3. **Permission issues**: Check file permissions and security context

### Service Issues

#### Service Not Reachable

**Symptoms:**
- Cannot connect to service
- Connection timeouts

**Diagnosis:**
```bash
kubectl get services
kubectl describe service <service-name>
kubectl get endpoints <service-name>
```

**Solutions:**
1. **Check selector**: Ensure service selector matches pod labels
   ```bash
   kubectl get pods --show-labels
   ```
2. **Check ports**: Verify targetPort matches container port
3. **Network policies**: Check if network policies are blocking traffic

#### No Endpoints for Service

**Symptoms:**
- Service exists but has no endpoints
- `kubectl get endpoints` shows empty endpoints

**Diagnosis:**
```bash
kubectl get pods -l <selector-labels>
kubectl describe service <service-name>
```

**Solutions:**
1. **Label mismatch**: Ensure pod labels match service selector
2. **Pod not ready**: Check if pods are in Ready state
3. **Port mismatch**: Verify container ports are correctly exposed

### Deployment Issues

#### Deployment Not Rolling Out

**Symptoms:**
- Deployment stuck in progress
- New pods not starting

**Diagnosis:**
```bash
kubectl describe deployment <deployment-name>
kubectl get replicasets
kubectl rollout status deployment/<deployment-name>
```

**Solutions:**
1. **Resource constraints**: Check if cluster has enough resources
2. **Image issues**: Verify new image is accessible
3. **Rolling update strategy**: Check deployment strategy settings

#### Deployment Rollback

```bash
# View rollout history
kubectl rollout history deployment/<deployment-name>

# Rollback to previous version
kubectl rollout undo deployment/<deployment-name>

# Rollback to specific revision
kubectl rollout undo deployment/<deployment-name> --to-revision=2
```

### Networking Issues

#### DNS Resolution Problems

**Symptoms:**
- Cannot resolve service names
- DNS lookup failures

**Diagnosis:**
```bash
# Test DNS from within a pod
kubectl exec -it <pod-name> -- nslookup kubernetes.default
kubectl exec -it <pod-name> -- nslookup <service-name>

# Check DNS pods
kubectl get pods -n kube-system -l k8s-app=kube-dns
```

**Solutions:**
1. **DNS pods down**: Restart DNS pods if they're not running
2. **Network plugin issues**: Check CNI plugin status
3. **Service naming**: Use fully qualified domain names

#### Pod-to-Pod Communication Issues

**Diagnosis:**
```bash
# Test connectivity between pods
kubectl exec -it <pod1> -- ping <pod2-ip>
kubectl exec -it <pod1> -- telnet <service-name> <port>
```

**Solutions:**
1. **Network policies**: Check for restrictive network policies
2. **Firewall rules**: Verify cluster networking configuration
3. **CNI plugin**: Ensure network plugin is working correctly

### Storage Issues

#### PVC Stuck in Pending

**Symptoms:**
- Persistent Volume Claim remains in Pending state

**Diagnosis:**
```bash
kubectl describe pvc <pvc-name>
kubectl get pv
kubectl get storageclass
```

**Solutions:**
1. **No matching PV**: Create a PV or use dynamic provisioning
2. **Storage class issues**: Check if storage class exists and works
3. **Access mode mismatch**: Ensure PV and PVC access modes match

#### Mount Issues

**Symptoms:**
- Pod fails to start with volume mount errors

**Diagnosis:**
```bash
kubectl describe pod <pod-name>
```

**Solutions:**
1. **Path issues**: Check mount paths and volume definitions
2. **Permissions**: Verify volume permissions
3. **Node storage**: Ensure nodes have required storage drivers

### Resource Issues

#### Out of Memory (OOMKilled)

**Symptoms:**
- Pod shows `OOMKilled` status
- Container restarts frequently

**Diagnosis:**
```bash
kubectl describe pod <pod-name>
kubectl top pod <pod-name>
```

**Solutions:**
1. **Increase memory limits**: Adjust container memory limits
2. **Optimize application**: Reduce application memory usage
3. **Add more nodes**: Scale cluster if consistently hitting limits

#### CPU Throttling

**Symptoms:**
- Application performance issues
- High CPU usage

**Diagnosis:**
```bash
kubectl top pods
kubectl top nodes
```

**Solutions:**
1. **Increase CPU limits**: Adjust container CPU limits
2. **Optimize code**: Improve application efficiency
3. **Scale horizontally**: Add more pod replicas

## Debugging Tools and Commands

### Essential Debugging Commands

```bash
# Get cluster information
kubectl cluster-info
kubectl get nodes -o wide
kubectl get pods --all-namespaces

# Describe resources for detailed info
kubectl describe pod <pod-name>
kubectl describe service <service-name>
kubectl describe node <node-name>

# View logs
kubectl logs <pod-name>
kubectl logs <pod-name> -c <container-name>  # Multi-container pods
kubectl logs <pod-name> --previous           # Previous container logs
kubectl logs -f <pod-name>                   # Follow logs

# Execute commands in pods
kubectl exec -it <pod-name> -- /bin/bash
kubectl exec -it <pod-name> -- sh

# Port forwarding for testing
kubectl port-forward <pod-name> 8080:80
kubectl port-forward service/<service-name> 8080:80

# Check events
kubectl get events --sort-by='.lastTimestamp'
kubectl get events --field-selector involvedObject.name=<pod-name>

# Resource usage
kubectl top nodes
kubectl top pods
kubectl top pods --all-namespaces
```

### Network Debugging

```bash
# Test DNS resolution
kubectl run test-pod --image=busybox --rm -it -- sh
# Inside the pod:
nslookup kubernetes.default
nslookup <service-name>
wget -qO- <service-name>:<port>

# Check service endpoints
kubectl get endpoints
kubectl describe endpoints <service-name>

# Network connectivity test
kubectl exec -it <pod1> -- ping <pod2-ip>
kubectl exec -it <pod1> -- telnet <service-name> <port>
```

### Storage Debugging

```bash
# Check storage resources
kubectl get pv
kubectl get pvc
kubectl get storageclass

# Volume information
kubectl describe pv <pv-name>
kubectl describe pvc <pvc-name>

# Check mount points in pods
kubectl exec -it <pod-name> -- df -h
kubectl exec -it <pod-name> -- mount | grep <volume-name>
```

## Performance Monitoring

### Resource Monitoring

```bash
# Node resource usage
kubectl top nodes

# Pod resource usage
kubectl top pods
kubectl top pods --all-namespaces
kubectl top pods --sort-by=cpu
kubectl top pods --sort-by=memory

# Detailed resource information
kubectl describe node <node-name>
```

### Application Monitoring

```bash
# Application logs
kubectl logs -f <pod-name>
kubectl logs <pod-name> --since=1h
kubectl logs <pod-name> --tail=100

# Health check status
kubectl get pods -o wide
kubectl describe pod <pod-name> | grep -A 5 Conditions
```

## Prevention Best Practices

### Resource Management
1. **Always set resource requests and limits**
2. **Monitor resource usage regularly**
3. **Use horizontal pod autoscaling when appropriate**

### Monitoring and Logging
1. **Implement proper logging in applications**
2. **Set up cluster monitoring (Prometheus/Grafana)**
3. **Monitor key metrics: CPU, memory, disk, network**

### Configuration Management
1. **Use ConfigMaps and Secrets for configuration**
2. **Validate YAML files before applying**
3. **Test in development environment first**

### Health Checks
1. **Implement liveness and readiness probes**
2. **Set appropriate timeouts and thresholds**
3. **Test health check endpoints**

## Quick Troubleshooting Checklist

When something goes wrong:

1. **Check pod status**: `kubectl get pods`
2. **Describe the resource**: `kubectl describe pod <name>`
3. **Check logs**: `kubectl logs <pod-name>`
4. **Check events**: `kubectl get events --sort-by='.lastTimestamp'`
5. **Verify configuration**: Check YAML files for errors
6. **Check resources**: `kubectl top nodes` and `kubectl top pods`
7. **Test connectivity**: Use port-forward or exec into pods
8. **Check dependencies**: Ensure all required services are running

Remember: Most Kubernetes issues are configuration-related. Double-check your YAML files and resource specifications!
