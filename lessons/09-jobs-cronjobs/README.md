# Lesson 9: Jobs and CronJobs

## Learning Objectives

By the end of this lesson, you will:

- Understand batch processing in Kubernetes
- Create and manage Jobs for one-time tasks
- Schedule recurring tasks with CronJobs
- Implement different job patterns (single, parallel, work queue)
- Handle job failures and retries
- Monitor and troubleshoot batch workloads

## Why Jobs and CronJobs?

**Deployments are for long-running services**, but many tasks are:

- **One-time operations**: Database migrations, backups, data imports
- **Scheduled tasks**: Log cleanup, report generation, health checks
- **Batch processing**: Data analysis, image processing, ETL pipelines

**Jobs and CronJobs provide:**
- Guaranteed completion semantics
- Automatic retry on failure
- Parallel execution capabilities
- Scheduled execution
- Resource cleanup after completion

## Job Types

### 1. Job (One-time execution)
- Runs pods until successful completion
- Retries on failure
- Can run multiple pods in parallel

### 2. CronJob (Scheduled execution)
- Runs Jobs on a schedule
- Based on cron expressions
- Manages job history and cleanup

## Hands-On: Basic Jobs

### Step 1: Simple Job

```yaml
# simple-job.yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: simple-job
spec:
  template:
    spec:
      containers:
      - name: worker
        image: busybox
        command: ['sh', '-c']
        args:
        - |
          echo "Job started at $(date)"
          echo "Processing some data..."
          sleep 30
          echo "Job completed at $(date)"
          echo "Exit code: 0"
        resources:
          requests:
            memory: "16Mi"
            cpu: "50m"
          limits:
            memory: "32Mi"
            cpu: "100m"
      restartPolicy: Never  # Important: Never or OnFailure
```

Deploy and monitor the job:

```bash
# Create the job
kubectl apply -f simple-job.yaml

# Watch job progress
kubectl get jobs -w

# Check job status
kubectl describe job simple-job

# View job pods
kubectl get pods -l job-name=simple-job

# Check job logs
kubectl logs job/simple-job

# Get detailed job information
kubectl get job simple-job -o yaml
```

### Step 2: Job with Retries

```yaml
# retry-job.yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: retry-job
spec:
  backoffLimit: 3  # Retry up to 3 times
  template:
    spec:
      containers:
      - name: worker
        image: busybox
        command: ['sh', '-c']
        args:
        - |
          echo "Job attempt started at $(date)"
          
          # Simulate random failure (50% chance)
          if [ $((RANDOM % 2)) -eq 0 ]; then
            echo "Job failed - simulated error"
            exit 1
          else
            echo "Job succeeded"
            exit 0
          fi
        resources:
          requests:
            memory: "16Mi"
            cpu: "50m"
          limits:
            memory: "32Mi"
            cpu: "100m"
      restartPolicy: Never
```

```bash
# Deploy retry job
kubectl apply -f retry-job.yaml

# Watch the job retry on failures
kubectl get jobs -w
kubectl get pods -l job-name=retry-job

# Check logs from different attempts
kubectl logs job/retry-job  # Latest attempt
kubectl logs <pod-name>     # Specific attempt
```

### Step 3: Parallel Jobs

```yaml
# parallel-job.yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: parallel-job
spec:
  parallelism: 3      # Run 3 pods in parallel
  completions: 6      # Need 6 successful completions
  backoffLimit: 2
  template:
    spec:
      containers:
      - name: worker
        image: busybox
        command: ['sh', '-c']
        args:
        - |
          WORKER_ID=$RANDOM
          echo "Worker $WORKER_ID started at $(date)"
          
          # Simulate work (5-15 seconds)
          WORK_TIME=$((5 + RANDOM % 10))
          echo "Worker $WORKER_ID processing for $WORK_TIME seconds"
          sleep $WORK_TIME
          
          echo "Worker $WORKER_ID completed at $(date)"
        resources:
          requests:
            memory: "16Mi"
            cpu: "50m"
          limits:
            memory: "32Mi"
            cpu: "100m"
      restartPolicy: Never
```

```bash
# Deploy parallel job
kubectl apply -f parallel-job.yaml

# Watch parallel execution
kubectl get jobs -w
kubectl get pods -l job-name=parallel-job -w

# Check logs from all workers
kubectl logs -l job-name=parallel-job
```

## Job Patterns

### Step 4: Work Queue Pattern

First, create a simple work queue simulator:

```yaml
# work-queue-job.yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: work-queue-job
spec:
  parallelism: 3
  # No completions specified - workers decide when done
  template:
    spec:
      containers:
      - name: worker
        image: busybox
        command: ['sh', '-c']
        args:
        - |
          WORKER_ID="worker-$RANDOM"
          echo "$WORKER_ID: Starting work queue processing"
          
          # Simulate processing items from a queue
          for i in {1..5}; do
            ITEM_ID=$((RANDOM % 1000))
            echo "$WORKER_ID: Processing item $ITEM_ID"
            
            # Simulate work time (1-3 seconds per item)
            sleep $((1 + RANDOM % 3))
            
            echo "$WORKER_ID: Completed item $ITEM_ID"
          done
          
          echo "$WORKER_ID: Finished processing queue"
        resources:
          requests:
            memory: "16Mi"
            cpu: "50m"
          limits:
            memory: "32Mi"
            cpu: "100m"
      restartPolicy: Never
```

### Step 5: Database Backup Job

```yaml
# backup-job.yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: database-backup
  labels:
    app: backup
    type: database
spec:
  template:
    metadata:
      labels:
        app: backup
        type: database
    spec:
      containers:
      - name: backup-worker
        image: postgres:13
        command: ['sh', '-c']
        args:
        - |
          echo "Starting database backup at $(date)"
          
          # Simulate database backup
          echo "Connecting to database..."
          sleep 2
          
          echo "Creating backup..."
          BACKUP_FILE="backup_$(date +%Y%m%d_%H%M%S).sql"
          echo "-- Database backup created at $(date)" > /tmp/$BACKUP_FILE
          echo "-- Backup contains 1000 records" >> /tmp/$BACKUP_FILE
          
          # Simulate backup time
          sleep 10
          
          echo "Backup completed: $BACKUP_FILE"
          echo "Backup size: $(wc -c < /tmp/$BACKUP_FILE) bytes"
          
          # In real scenario, upload to cloud storage
          echo "Uploading backup to cloud storage..."
          sleep 3
          echo "Backup upload completed"
          
          echo "Database backup finished at $(date)"
        env:
        - name: PGHOST
          value: "postgres-service"
        - name: PGUSER
          value: "backup_user"
        - name: PGPASSWORD
          value: "backup_password"
        resources:
          requests:
            memory: "64Mi"
            cpu: "100m"
          limits:
            memory: "128Mi"
            cpu: "200m"
      restartPolicy: OnFailure
```

## CronJobs

### Step 6: Basic CronJob

```yaml
# simple-cronjob.yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: simple-cronjob
spec:
  schedule: "*/2 * * * *"  # Every 2 minutes
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: worker
            image: busybox
            command: ['sh', '-c']
            args:
            - |
              echo "CronJob execution at $(date)"
              echo "Hostname: $(hostname)"
              echo "Performing scheduled task..."
              sleep 5
              echo "Scheduled task completed"
            resources:
              requests:
                memory: "16Mi"
                cpu: "50m"
              limits:
                memory: "32Mi"
                cpu: "100m"
          restartPolicy: OnFailure
```

```bash
# Deploy CronJob
kubectl apply -f simple-cronjob.yaml

# Check CronJob status
kubectl get cronjobs
kubectl describe cronjob simple-cronjob

# Watch Jobs being created
kubectl get jobs -w

# Check CronJob history
kubectl get jobs --selector=job-name=simple-cronjob
```

### Step 7: Cleanup CronJob

```yaml
# cleanup-cronjob.yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: cleanup-job
spec:
  schedule: "0 2 * * *"  # Daily at 2 AM
  concurrencyPolicy: Forbid  # Don't run concurrent jobs
  successfulJobsHistoryLimit: 3
  failedJobsHistoryLimit: 1
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: cleanup-worker
            image: busybox
            command: ['sh', '-c']
            args:
            - |
              echo "Starting cleanup job at $(date)"
              
              # Simulate log cleanup
              echo "Cleaning up old log files..."
              find /tmp -name "*.log" -mtime +7 -type f | head -10
              
              # Simulate cache cleanup
              echo "Clearing application cache..."
              sleep 3
              
              # Simulate temp file cleanup
              echo "Removing temporary files..."
              sleep 2
              
              echo "Cleanup completed at $(date)"
            resources:
              requests:
                memory: "32Mi"
                cpu: "100m"
              limits:
                memory: "64Mi"
                cpu: "200m"
          restartPolicy: OnFailure
```

### Step 8: Advanced CronJob with Timezone

```yaml
# timezone-cronjob.yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: timezone-cronjob
spec:
  schedule: "0 9 * * MON-FRI"  # Weekdays at 9 AM
  timeZone: "America/New_York"  # Kubernetes 1.25+
  concurrencyPolicy: Replace   # Replace running job if overlaps
  startingDeadlineSeconds: 300 # Start within 5 minutes or skip
  jobTemplate:
    spec:
      activeDeadlineSeconds: 600  # Kill job after 10 minutes
      template:
        spec:
          containers:
          - name: report-worker
            image: busybox
            command: ['sh', '-c']
            args:
            - |
              echo "Generating daily report at $(date)"
              echo "Timezone: $TZ"
              
              # Simulate report generation
              echo "Collecting data from last 24 hours..."
              sleep 10
              
              echo "Processing data..."
              sleep 15
              
              echo "Generating report..."
              REPORT_FILE="daily_report_$(date +%Y%m%d).txt"
              echo "Daily Report - $(date)" > /tmp/$REPORT_FILE
              echo "===============================================" >> /tmp/$REPORT_FILE
              echo "Total processed items: $((RANDOM % 1000 + 100))" >> /tmp/$REPORT_FILE
              echo "Success rate: $((90 + RANDOM % 10))%" >> /tmp/$REPORT_FILE
              
              echo "Report generated: $REPORT_FILE"
              echo "Report size: $(wc -c < /tmp/$REPORT_FILE) bytes"
              
              # Simulate sending report
              echo "Sending report via email..."
              sleep 3
              echo "Report sent successfully"
            env:
            - name: TZ
              value: "America/New_York"
            resources:
              requests:
                memory: "64Mi"
                cpu: "200m"
              limits:
                memory: "128Mi"
                cpu: "400m"
          restartPolicy: OnFailure
```

## Real-World Examples

### Step 9: ETL Pipeline Job

```yaml
# etl-pipeline-job.yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: etl-pipeline
  labels:
    pipeline: data-processing
    version: v1.0
spec:
  parallelism: 2
  completions: 4
  backoffLimit: 1
  template:
    metadata:
      labels:
        pipeline: data-processing
    spec:
      containers:
      - name: etl-worker
        image: python:3.9-alpine
        command: ['sh', '-c']
        args:
        - |
          pip install requests > /dev/null 2>&1
          
          cat << 'EOF' > etl_script.py
          import json
          import time
          import random
          from datetime import datetime
          
          print(f"ETL Process started at {datetime.now()}")
          
          # Extract
          print("Phase 1: Extracting data...")
          time.sleep(5)
          data = [{"id": i, "value": random.randint(1, 100)} for i in range(100)]
          print(f"Extracted {len(data)} records")
          
          # Transform
          print("Phase 2: Transforming data...")
          time.sleep(3)
          transformed_data = [{"id": item["id"], "value": item["value"] * 2, "processed_at": str(datetime.now())} for item in data]
          print(f"Transformed {len(transformed_data)} records")
          
          # Load
          print("Phase 3: Loading data...")
          time.sleep(4)
          # Simulate loading to database
          print(f"Loaded {len(transformed_data)} records to database")
          
          print(f"ETL Process completed at {datetime.now()}")
          EOF
          
          python etl_script.py
        resources:
          requests:
            memory: "128Mi"
            cpu: "200m"
          limits:
            memory: "256Mi"
            cpu: "400m"
      restartPolicy: Never
```

### Step 10: Image Processing Job

```yaml
# image-processing-cronjob.yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: image-processing
spec:
  schedule: "*/15 * * * *"  # Every 15 minutes
  concurrencyPolicy: Forbid
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: image-processor
            image: busybox
            command: ['sh', '-c']
            args:
            - |
              echo "Image processing job started at $(date)"
              
              # Simulate finding new images
              NEW_IMAGES=$((RANDOM % 10 + 1))
              echo "Found $NEW_IMAGES new images to process"
              
              for i in $(seq 1 $NEW_IMAGES); do
                IMAGE_ID=$((RANDOM % 10000))
                echo "Processing image $IMAGE_ID..."
                
                # Simulate image processing tasks
                echo "  - Resizing image $IMAGE_ID"
                sleep 1
                
                echo "  - Generating thumbnails for image $IMAGE_ID"
                sleep 1
                
                echo "  - Optimizing image $IMAGE_ID"
                sleep 1
                
                echo "  - Image $IMAGE_ID processed successfully"
              done
              
              echo "Image processing completed at $(date)"
              echo "Processed $NEW_IMAGES images total"
            resources:
              requests:
                memory: "64Mi"
                cpu: "100m"
              limits:
                memory: "128Mi"
                cpu: "300m"
          restartPolicy: OnFailure
```

## Monitoring and Management

### Step 11: Job Monitoring

```bash
# Monitor active jobs
kubectl get jobs
kubectl get cronjobs

# Check job history
kubectl get jobs --sort-by=.metadata.creationTimestamp

# Get detailed job information
kubectl describe job <job-name>
kubectl describe cronjob <cronjob-name>

# View job logs
kubectl logs job/<job-name>
kubectl logs -l job-name=<job-name>

# Check job events
kubectl get events --field-selector involvedObject.kind=Job
kubectl get events --field-selector involvedObject.kind=CronJob

# Resource usage
kubectl top pods -l job-name=<job-name>
```

### Step 12: Job Cleanup and Management

```yaml
# job-cleanup.yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: job-cleanup
spec:
  schedule: "0 3 * * *"  # Daily at 3 AM
  jobTemplate:
    spec:
      template:
        spec:
          serviceAccountName: job-cleanup-sa
          containers:
          - name: cleanup
            image: bitnami/kubectl
            command: ['sh', '-c']
            args:
            - |
              echo "Starting job cleanup at $(date)"
              
              # Clean up completed jobs older than 24 hours
              kubectl delete jobs --field-selector=status.successful=1 \
                $(kubectl get jobs -o jsonpath='{.items[?(@.status.completionTime<"'$(date -d '24 hours ago' -u +%Y-%m-%dT%H:%M:%SZ)'")].metadata.name}') \
                --ignore-not-found=true
              
              # Clean up failed jobs older than 7 days
              kubectl delete jobs --field-selector=status.failed=1 \
                $(kubectl get jobs -o jsonpath='{.items[?(@.status.completionTime<"'$(date -d '7 days ago' -u +%Y-%m-%dT%H:%M:%SZ)'")].metadata.name}') \
                --ignore-not-found=true
              
              echo "Job cleanup completed at $(date)"
            resources:
              requests:
                memory: "32Mi"
                cpu: "100m"
              limits:
                memory: "64Mi"
                cpu: "200m"
          restartPolicy: OnFailure
---
# Service account with permissions to manage jobs
apiVersion: v1
kind: ServiceAccount
metadata:
  name: job-cleanup-sa
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: job-cleanup-role
rules:
- apiGroups: ["batch"]
  resources: ["jobs"]
  verbs: ["get", "list", "delete"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: job-cleanup-binding
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: job-cleanup-role
subjects:
- kind: ServiceAccount
  name: job-cleanup-sa
  namespace: default
```

## Troubleshooting Jobs

### Common Issues and Solutions

```bash
# 1. Job never completes
kubectl describe job <job-name>
# Check: pod failures, resource constraints, deadlocks

# 2. CronJob not triggering
kubectl describe cronjob <cronjob-name>
# Check: schedule format, timezone settings, suspension

# 3. Job pods failing immediately
kubectl logs job/<job-name>
kubectl describe pod <pod-name>
# Check: image issues, command/args, resource limits

# 4. Job history not cleaned up
kubectl get jobs
# Check: successfulJobsHistoryLimit, failedJobsHistoryLimit

# 5. Parallel jobs not working
kubectl get pods -l job-name=<job-name>
# Check: parallelism vs completions settings
```

### Debug Job Template

```yaml
# debug-job.yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: debug-job
spec:
  template:
    spec:
      containers:
      - name: debug
        image: busybox
        command: ['sh', '-c']
        args:
        - |
          echo "=== Debug Information ==="
          echo "Hostname: $(hostname)"
          echo "Date: $(date)"
          echo "Environment variables:"
          env | sort
          echo "=== System Information ==="
          uname -a
          df -h
          free -m
          echo "=== Network Information ==="
          cat /etc/resolv.conf
          echo "=== Keeping pod alive for debugging ==="
          sleep 3600
        resources:
          requests:
            memory: "16Mi"
            cpu: "50m"
          limits:
            memory: "32Mi"
            cpu: "100m"
      restartPolicy: Never
```

## Best Practices

### Job Design Principles

1. **Idempotent operations**: Jobs should be safe to retry
2. **Resource limits**: Set appropriate CPU and memory limits
3. **Timeout handling**: Use activeDeadlineSeconds for long-running jobs
4. **Error handling**: Implement proper error handling and logging
5. **State management**: Use external storage for job state if needed
6. **Monitoring**: Include health checks and monitoring

### CronJob Best Practices

1. **Concurrency control**: Use appropriate concurrencyPolicy
2. **History management**: Set reasonable history limits
3. **Timezone awareness**: Use timeZone field when available
4. **Starting deadline**: Set startingDeadlineSeconds for critical jobs
5. **Resource planning**: Consider cluster capacity during peak times

## Practice Exercises

### Exercise 1: Data Processing Pipeline

1. Create a Job that processes CSV data
2. Implement parallel processing with work queue pattern
3. Add retry logic for failed processing
4. Monitor job progress and resource usage

### Exercise 2: Backup and Maintenance

1. Create CronJobs for database backup
2. Implement log file cleanup
3. Add health check jobs
4. Set up job monitoring and alerting

### Exercise 3: Batch Analytics

1. Create a daily analytics job
2. Implement data aggregation and reporting
3. Add email notification on completion
4. Handle large dataset processing

## Cleanup

```bash
# Delete Jobs
kubectl delete job simple-job retry-job parallel-job work-queue-job database-backup etl-pipeline debug-job

# Delete CronJobs
kubectl delete cronjob simple-cronjob cleanup-job timezone-cronjob image-processing job-cleanup

# Check for remaining job pods
kubectl get pods --field-selector=status.phase=Succeeded
kubectl delete pods --field-selector=status.phase=Succeeded

# Clean up RBAC resources
kubectl delete clusterrolebinding job-cleanup-binding
kubectl delete clusterrole job-cleanup-role
kubectl delete serviceaccount job-cleanup-sa
```

## Key Takeaways

- ✅ Jobs ensure batch tasks run to completion
- ✅ CronJobs enable scheduled, recurring tasks
- ✅ Parallel processing can improve performance for suitable workloads
- ✅ Proper retry and timeout configuration is crucial
- ✅ Resource management prevents cluster overload
- ✅ Regular cleanup prevents resource accumulation

## What's Next?

You now understand batch processing in Kubernetes! Next, we'll learn about Helm:

- Package management for Kubernetes
- Application templating and configuration
- Release management and versioning
- Chart development and repositories

**Ready?** Continue to [Lesson 10: Helm Package Manager](../10-helm-package-manager/README.md)

## Quick Reference

```bash
# Job operations
kubectl create job <name> --image=<image> -- <command>
kubectl get jobs
kubectl describe job <name>
kubectl delete job <name>

# CronJob operations
kubectl create cronjob <name> --image=<image> --schedule="<cron>" -- <command>
kubectl get cronjobs
kubectl describe cronjob <name>

# Monitoring
kubectl logs job/<job-name>
kubectl get events --field-selector involvedObject.kind=Job
kubectl top pods -l job-name=<job-name>

# Cron schedule format
# ┌───────────── minute (0 - 59)
# │ ┌───────────── hour (0 - 23)
# │ │ ┌───────────── day of month (1 - 31)
# │ │ │ ┌───────────── month (1 - 12)
# │ │ │ │ ┌───────────── day of week (0 - 6)
# │ │ │ │ │
# * * * * *
```
