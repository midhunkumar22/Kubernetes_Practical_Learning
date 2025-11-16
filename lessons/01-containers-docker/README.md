# Lesson 1: Containers and Docker Basics

## Learning Objectives
By the end of this lesson, you will understand:
- What containers are and why they're important
- How Docker works
- Basic Docker commands
- The relationship between containers and Kubernetes

## What Are Containers?

Containers are lightweight, portable units that package an application and all its dependencies together. Think of them as:

- **Standardized shipping containers** for software
- **Isolated environments** that run on a shared OS kernel
- **Consistent runtime environments** across different machines

### Traditional VMs vs Containers

```
Traditional VMs:
┌─────────────────────────────────────┐
│ App A │ App B │ App C │ App D      │
├───────┼───────┼───────┼───────      │
│ OS    │ OS    │ OS    │ OS         │
├───────┴───────┴───────┴───────      │
│ Hypervisor                         │
├─────────────────────────────────────│
│ Host Operating System              │
└─────────────────────────────────────┘

Containers:
┌─────────────────────────────────────┐
│ App A │ App B │ App C │ App D      │
├───────┼───────┼───────┼───────      │
│ Container Runtime (Docker)         │
├─────────────────────────────────────│
│ Host Operating System              │
└─────────────────────────────────────┘
```

## Docker Fundamentals

Docker is a platform that uses OS-level virtualization to deliver software in containers.

### Key Docker Concepts

1. **Image**: A read-only template used to create containers
2. **Container**: A running instance of an image
3. **Dockerfile**: Instructions to build an image
4. **Registry**: A storage location for images (like Docker Hub)

## Hands-On: Your First Container

Let's start with a simple example:

### 1. Pull and Run a Container

```bash
# Pull the official nginx image
docker pull nginx:latest

# Run nginx in a container
docker run -d -p 8080:80 --name my-nginx nginx:latest

# Check if it's running
docker ps

# Test it
curl http://localhost:8080
# Or open http://localhost:8080 in your browser
```

### 2. Explore the Container

```bash
# Execute commands inside the container
docker exec -it my-nginx bash

# Inside the container, try:
ls /usr/share/nginx/html
cat /usr/share/nginx/html/index.html
exit

# View container logs
docker logs my-nginx

# Stop and remove the container
docker stop my-nginx
docker rm my-nginx
```

### 3. Create Your Own Image

Create a simple web application:

```bash
# Create a directory for our app
mkdir my-app && cd my-app

# Create a simple HTML file
cat > index.html << EOF
<!DOCTYPE html>
<html>
<head>
    <title>My First Container App</title>
</head>
<body>
    <h1>Hello from Docker!</h1>
    <p>This is running in a container.</p>
</body>
</html>
EOF

# Create a Dockerfile
cat > Dockerfile << EOF
FROM nginx:alpine
COPY index.html /usr/share/nginx/html/index.html
EXPOSE 80
EOF

# Build the image
docker build -t my-web-app .

# Run your custom container
docker run -d -p 8081:80 --name my-app my-web-app

# Test it
curl http://localhost:8081
```

## Essential Docker Commands

```bash
# Images
docker images                    # List images
docker pull <image>             # Download image
docker build -t <name> .        # Build image from Dockerfile
docker rmi <image>              # Remove image
docker image prune              # Remove unused images
docker tag <source> <target>    # Tag an image

# Containers
docker run <image>              # Create and start container
docker ps                      # List running containers
docker ps -a                   # List all containers
docker stop <container>        # Stop container
docker start <container>       # Start stopped container
docker restart <container>     # Restart container
docker rm <container>          # Remove container
docker rm -f <container>       # Force remove running container
docker exec -it <container> <cmd>  # Execute command in container
docker logs -f <container>     # Follow container logs
docker inspect <container>     # Detailed container info
docker stats                   # Show resource usage statistics

# Networking
docker network ls              # List networks
docker network create <name>   # Create network
docker network inspect <name>  # Inspect network

# Volumes
docker volume ls               # List volumes
docker volume create <name>    # Create volume
docker volume inspect <name>   # Inspect volume
docker volume rm <name>        # Remove volume

# Cleanup
docker system prune            # Remove unused containers, images, networks
docker system prune -a         # Remove all unused images
docker container prune         # Remove stopped containers
```

## Advanced Docker Concepts

### 1. Dockerfile Best Practices

Let's create a more sophisticated application with a multi-stage build:

```dockerfile
# Multi-stage build example
# Stage 1: Build
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .

# Stage 2: Runtime
FROM node:18-alpine
WORKDIR /app

# Create non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

# Copy from builder
COPY --from=builder --chown=nodejs:nodejs /app /app

# Use non-root user
USER nodejs

EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=3s \
  CMD node -e "require('http').get('http://localhost:3000/health', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})"

CMD ["node", "app.js"]
```

**Key Best Practices:**
- Use multi-stage builds to reduce image size
- Run as non-root user for security
- Use specific image tags (not `latest`)
- Leverage layer caching by ordering commands properly
- Use `.dockerignore` to exclude unnecessary files
- Add health checks

### 2. Docker Networking

Understanding Docker networks is crucial:

```bash
# Create a custom bridge network
docker network create my-network

# Run containers in the same network
docker run -d --name db --network my-network postgres:14-alpine
docker run -d --name app --network my-network -p 8080:8080 my-app

# Containers can communicate using container names as hostnames
# Inside app container, connect to: postgresql://db:5432
```

**Network Types:**
- **bridge**: Default network for standalone containers
- **host**: Remove network isolation, use host's network
- **none**: Disable networking
- **overlay**: Multi-host networking (Swarm/Kubernetes)

### 3. Docker Volumes and Data Persistence

```bash
# Named volume
docker volume create my-data
docker run -d -v my-data:/app/data my-app

# Bind mount (development)
docker run -d -v $(pwd)/app:/app my-app

# Read-only mount
docker run -d -v my-data:/app/data:ro my-app

# Volume with specific driver
docker volume create --driver local \
  --opt type=none \
  --opt device=/path/on/host \
  --opt o=bind \
  my-volume
```

### 4. Environment Variables and Secrets

```bash
# Pass environment variables
docker run -e DATABASE_URL=postgres://localhost/mydb my-app
docker run --env-file .env my-app

# Use secrets (Docker Swarm)
echo "mysecretpassword" | docker secret create db_password -
docker service create --secret db_password my-app
```

### 5. Resource Constraints

```bash
# Limit CPU and memory
docker run -d \
  --memory="512m" \
  --memory-swap="1g" \
  --cpus="1.5" \
  --cpu-shares="1024" \
  my-app

# Monitor resource usage
docker stats my-app
```

## Docker Compose

Docker Compose simplifies multi-container application management. Instead of running multiple `docker run` commands, define everything in a YAML file.

### Basic Docker Compose Example

Create a `docker-compose.yml` file:

```yaml
version: '3.8'

services:
  web:
    build: .
    ports:
      - "8080:8080"
    environment:
      - NODE_ENV=production
      - DATABASE_URL=postgres://db:5432/myapp
    depends_on:
      - db
      - redis
    networks:
      - app-network
    volumes:
      - ./app:/app
      - node_modules:/app/node_modules

  db:
    image: postgres:14-alpine
    environment:
      POSTGRES_DB: myapp
      POSTGRES_USER: user
      POSTGRES_PASSWORD: password
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - app-network

  redis:
    image: redis:7-alpine
    networks:
      - app-network
    volumes:
      - redis_data:/data

volumes:
  postgres_data:
  redis_data:
  node_modules:

networks:
  app-network:
    driver: bridge
```

### Docker Compose Commands

```bash
# Start all services
docker-compose up

# Start in detached mode
docker-compose up -d

# Build images before starting
docker-compose up --build

# Stop all services
docker-compose down

# Stop and remove volumes
docker-compose down -v

# View logs
docker-compose logs
docker-compose logs -f web

# Execute command in service
docker-compose exec web bash

# Scale a service
docker-compose up -d --scale web=3

# View running services
docker-compose ps

# Restart a service
docker-compose restart web
```

### Real-World Multi-Service Application

Let's create a complete full-stack application with Docker Compose:

**Project Structure:**
```
my-fullstack-app/
├── docker-compose.yml
├── frontend/
│   ├── Dockerfile
│   └── ...
├── backend/
│   ├── Dockerfile
│   └── ...
└── nginx/
    └── nginx.conf
```

**docker-compose.yml:**
```yaml
version: '3.8'

services:
  # Frontend (React/Vue/Angular)
  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile
    volumes:
      - ./frontend:/app
      - /app/node_modules
    environment:
      - REACT_APP_API_URL=http://localhost:8080/api
    networks:
      - app-network

  # Backend API (Node.js/Python/Go)
  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile
    environment:
      - DATABASE_URL=postgresql://postgres:password@db:5432/myapp
      - REDIS_URL=redis://redis:6379
      - JWT_SECRET=your-secret-key
    depends_on:
      - db
      - redis
    volumes:
      - ./backend:/app
      - /app/node_modules
    networks:
      - app-network

  # PostgreSQL Database
  db:
    image: postgres:14-alpine
    environment:
      POSTGRES_DB: myapp
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: password
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./init.sql:/docker-entrypoint-initdb.d/init.sql
    ports:
      - "5432:5432"
    networks:
      - app-network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 10s
      timeout: 5s
      retries: 5

  # Redis Cache
  redis:
    image: redis:7-alpine
    command: redis-server --appendonly yes
    volumes:
      - redis_data:/data
    networks:
      - app-network

  # Nginx Reverse Proxy
  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf
    depends_on:
      - frontend
      - backend
    networks:
      - app-network

volumes:
  postgres_data:
  redis_data:

networks:
  app-network:
    driver: bridge
```

### Docker Compose Override Files

For different environments:

**docker-compose.override.yml** (development - automatically loaded):
```yaml
version: '3.8'

services:
  backend:
    command: npm run dev
    environment:
      - DEBUG=true
      - LOG_LEVEL=debug
    ports:
      - "9229:9229"  # Debugging port

  frontend:
    command: npm start
    ports:
      - "3000:3000"
```

**docker-compose.prod.yml** (production):
```yaml
version: '3.8'

services:
  backend:
    command: npm start
    restart: always
    deploy:
      replicas: 3
      resources:
        limits:
          cpus: '0.50'
          memory: 512M

  frontend:
    restart: always
    build:
      context: ./frontend
      target: production

  nginx:
    restart: always
```

Run production compose:
```bash
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

### Advanced Docker Compose Features

**Health Checks:**
```yaml
services:
  api:
    image: my-api
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
```

**Restart Policies:**
```yaml
services:
  app:
    image: my-app
    restart: unless-stopped  # no, always, on-failure, unless-stopped
```

**Dependency Control:**
```yaml
services:
  app:
    depends_on:
      db:
        condition: service_healthy
      redis:
        condition: service_started
```

### Docker Compose Networking Example

```yaml
version: '3.8'

services:
  web:
    image: nginx
    networks:
      - frontend
      - backend

  app:
    image: my-app
    networks:
      - backend
      - database

  db:
    image: postgres
    networks:
      - database

networks:
  frontend:
  backend:
  database:
    internal: true  # Isolated, no external access
```

## Docker Tips and Tricks

### 1. .dockerignore File

Create a `.dockerignore` to exclude files from build context:

```
node_modules
npm-debug.log
.git
.gitignore
.env
.env.local
*.md
.DS_Store
coverage
.vscode
.idea
dist
build
```

### 2. Build Arguments

```dockerfile
FROM node:18-alpine
ARG NODE_ENV=production
ARG BUILD_VERSION=1.0.0

ENV NODE_ENV=$NODE_ENV
LABEL version=$BUILD_VERSION

RUN echo "Building for ${NODE_ENV}"
```

```bash
docker build --build-arg NODE_ENV=development --build-arg BUILD_VERSION=1.2.3 -t my-app .
```

### 3. Layer Caching Optimization

```dockerfile
# ❌ Bad - rebuilds every time code changes
COPY . .
RUN npm install

# ✅ Good - caches dependencies layer
COPY package*.json ./
RUN npm install
COPY . .
```

### 4. Debugging Containers

```bash
# Access shell in running container
docker exec -it <container> /bin/sh

# Copy files from container
docker cp <container>:/app/logs/error.log ./error.log

# Inspect container details
docker inspect <container> | jq '.[0].State'

# View port mappings
docker port <container>

# View processes in container
docker top <container>

# View real-time events
docker events
```

### 5. Docker Registry Operations

```bash
# Login to registry
docker login

# Tag image for registry
docker tag my-app:latest username/my-app:1.0.0

# Push to registry
docker push username/my-app:1.0.0

# Pull from registry
docker pull username/my-app:1.0.0

# Search Docker Hub
docker search nginx
```

## Why Kubernetes Needs Containers

Containers solve several problems that Kubernetes addresses at scale:

1. **Consistency**: Same environment everywhere
2. **Isolation**: Applications don't interfere with each other
3. **Portability**: Run anywhere containers are supported
4. **Resource Efficiency**: Lightweight compared to VMs

But containers alone have limitations:
- How do you manage hundreds of containers?
- How do you handle failures and restarts?
- How do you scale applications up and down?
- How do you manage networking between containers?

**This is where Kubernetes comes in!** Kubernetes orchestrates containers at scale.

## Practice Exercise

Try this on your own:

1. Create a simple Node.js application in a container
2. Create a `package.json` with express dependency
3. Create an `app.js` that serves "Hello Kubernetes!" on port 3000
4. Write a Dockerfile to containerize it
5. Build and run the container

### Solution Template

```javascript
// app.js
const express = require('express');
const app = express();
const port = 3000;

app.get('/', (req, res) => {
    res.send('Hello Kubernetes! Ready for orchestration.');
});

app.listen(port, '0.0.0.0', () => {
    console.log(`App running on port ${port}`);
});
```

```dockerfile
# Dockerfile
FROM node:16-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
EXPOSE 3000
CMD ["node", "app.js"]
```

## Practice Exercises

### Exercise 1: Multi-Stage Build

Create a Go application with a multi-stage Docker build that produces a minimal final image:

**Task:**

1. Create a simple Go HTTP server
2. Build it in a golang image
3. Copy only the binary to an alpine final image
4. Final image should be under 10MB

**Solution:**

```go
// main.go
package main

import (
    "fmt"
    "net/http"
)

func main() {
    http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
        fmt.Fprintf(w, "Hello from minimal Go container!")
    })
    http.ListenAndServe(":8080", nil)
}
```

```dockerfile
# Dockerfile
FROM golang:1.21-alpine AS builder
WORKDIR /app
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o main .

FROM alpine:latest
RUN apk --no-cache add ca-certificates
WORKDIR /root/
COPY --from=builder /app/main .
EXPOSE 8080
CMD ["./main"]
```

### Exercise 2: Docker Compose Microservices

Create a microservices architecture with Docker Compose:

**Services:**

- Frontend (React/HTML)
- API Gateway (Node.js)
- User Service (Python)
- Product Service (Node.js)
- PostgreSQL
- Redis
- Nginx Load Balancer

**docker-compose.yml:**

```yaml
version: '3.8'

services:
  frontend:
    build: ./frontend
    networks:
      - frontend-network

  api-gateway:
    build: ./api-gateway
    ports:
      - "3000:3000"
    environment:
      - USER_SERVICE_URL=http://user-service:8001
      - PRODUCT_SERVICE_URL=http://product-service:8002
    networks:
      - frontend-network
      - backend-network
    depends_on:
      - user-service
      - product-service

  user-service:
    build: ./user-service
    environment:
      - DATABASE_URL=postgresql://postgres:password@postgres:5432/users
      - REDIS_URL=redis://redis:6379
    networks:
      - backend-network
      - db-network
    depends_on:
      - postgres
      - redis

  product-service:
    build: ./product-service
    environment:
      - DATABASE_URL=postgresql://postgres:password@postgres:5432/products
    networks:
      - backend-network
      - db-network
    depends_on:
      - postgres

  postgres:
    image: postgres:14-alpine
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: password
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./init-db:/docker-entrypoint-initdb.d
    networks:
      - db-network

  redis:
    image: redis:7-alpine
    networks:
      - backend-network

  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf
    depends_on:
      - frontend
      - api-gateway
    networks:
      - frontend-network

volumes:
  postgres_data:

networks:
  frontend-network:
  backend-network:
  db-network:
```

### Exercise 3: Development Environment with Hot Reload

Create a development setup with hot reloading for rapid development:

```yaml
version: '3.8'

services:
  # React Frontend with Hot Reload
  frontend:
    image: node:18-alpine
    working_dir: /app
    command: npm start
    ports:
      - "3000:3000"
    volumes:
      - ./frontend:/app
      - /app/node_modules
    environment:
      - CHOKIDAR_USEPOLLING=true
      - REACT_APP_API_URL=http://localhost:8080

  # Node.js Backend with Nodemon
  backend:
    image: node:18-alpine
    working_dir: /app
    command: npm run dev
    ports:
      - "8080:8080"
    volumes:
      - ./backend:/app
      - /app/node_modules
    environment:
      - DATABASE_URL=mongodb://mongo:27017/myapp
      - NODE_ENV=development

  # MongoDB
  mongo:
    image: mongo:6
    ports:
      - "27017:27017"
    volumes:
      - mongo_data:/data/db

  # MongoDB Express Admin UI
  mongo-express:
    image: mongo-express
    ports:
      - "8081:8081"
    environment:
      ME_CONFIG_MONGODB_URL: mongodb://mongo:27017/
    depends_on:
      - mongo

volumes:
  mongo_data:
```

### Exercise 4: CI/CD Pipeline Simulation

Create a docker-compose setup that simulates a CI/CD pipeline:

```yaml
version: '3.8'

services:
  # Build Stage
  builder:
    build:
      context: .
      target: builder
    volumes:
      - build-artifacts:/build

  # Test Stage
  tester:
    build:
      context: .
      target: tester
    depends_on:
      - builder
    volumes:
      - build-artifacts:/build
      - test-results:/test-results

  # Production Image
  app:
    build:
      context: .
      target: production
    ports:
      - "8080:8080"
    depends_on:
      - tester
    environment:
      - NODE_ENV=production

volumes:
  build-artifacts:
  test-results:
```

## Common Docker Patterns

### 1. Health Check Pattern

```dockerfile
FROM node:18-alpine

WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .

# Add curl for health checks
RUN apk add --no-cache curl

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:3000/health || exit 1

CMD ["node", "server.js"]
```

### 2. Init Container Pattern

```yaml
version: '3.8'

services:
  init:
    image: busybox
    command: sh -c "echo 'Initializing...' && sleep 2"
    volumes:
      - shared-data:/data

  app:
    image: my-app
    depends_on:
      - init
    volumes:
      - shared-data:/data

volumes:
  shared-data:
```

### 3. Sidecar Container Pattern

```yaml
version: '3.8'

services:
  app:
    image: my-app
    volumes:
      - logs:/var/log/app

  log-collector:
    image: fluentd
    volumes:
      - logs:/var/log/app
      - ./fluentd.conf:/fluentd/etc/fluent.conf

volumes:
  logs:
```

### 4. Database Migration Pattern

```yaml
version: '3.8'

services:
  db:
    image: postgres:14-alpine
    environment:
      POSTGRES_DB: myapp
      POSTGRES_USER: user
      POSTGRES_PASSWORD: password
    volumes:
      - postgres_data:/var/lib/postgresql/data

  migration:
    image: my-app:latest
    command: npm run migrate
    environment:
      DATABASE_URL: postgresql://user:password@db:5432/myapp
    depends_on:
      - db

  app:
    image: my-app:latest
    ports:
      - "8080:8080"
    depends_on:
      - migration

volumes:
  postgres_data:
```

## Troubleshooting Guide

### Common Issues and Solutions

**1. Container exits immediately:**

```bash
# Check logs
docker logs <container>

# Run with interactive terminal
docker run -it <image> /bin/sh

# Override entrypoint
docker run -it --entrypoint /bin/sh <image>
```

**2. Port already in use:**

```bash
# Find process using port
lsof -i :8080
# Or on Linux
ss -tuln | grep 8080

# Use different host port
docker run -p 8081:8080 my-app
```

**3. Volume permission issues:**

```dockerfile
# In Dockerfile, ensure correct ownership
RUN chown -R node:node /app
USER node
```

```yaml
# In docker-compose.yml
services:
  app:
    user: "1000:1000"  # Use host user UID:GID
```

**4. Network connectivity issues:**

```bash
# Inspect network
docker network inspect bridge

# Test connectivity between containers
docker exec <container1> ping <container2>

# Ensure containers are on same network
docker-compose ps
```

**5. Image build cache issues:**

```bash
# Build without cache
docker build --no-cache -t my-app .

# Docker Compose build without cache
docker-compose build --no-cache
```

**6. Container resource limits:**

```bash
# Check if container is being OOM killed
docker inspect <container> | jq '.[0].State.OOMKilled'

# Increase memory limit
docker run -m 1g my-app
```

## Docker Security Best Practices

### 1. User Security

```dockerfile
# Don't run as root
FROM node:18-alpine

# Create user
RUN addgroup -g 1001 appgroup && \
    adduser -D -u 1001 -G appgroup appuser

WORKDIR /app
COPY --chown=appuser:appgroup . .

USER appuser
CMD ["node", "app.js"]
```

### 2. Minimal Base Images

```dockerfile
# Use distroless or alpine images
FROM gcr.io/distroless/nodejs18-debian11
# Or
FROM node:18-alpine
```

### 3. Secrets Management

```yaml
# Use Docker secrets (Swarm mode)
version: '3.8'

services:
  app:
    image: my-app
    secrets:
      - db_password
      - api_key

secrets:
  db_password:
    external: true
  api_key:
    external: true
```

```bash
# Create secrets
echo "mypassword" | docker secret create db_password -
```

### 4. Scan Images for Vulnerabilities

```bash
# Using Docker Scout
docker scout cves my-app:latest

# Using Trivy
trivy image my-app:latest

# Using Snyk
snyk container test my-app:latest
```

### 5. Read-only Filesystem

```yaml
services:
  app:
    image: my-app
    read_only: true
    tmpfs:
      - /tmp
      - /var/run
```

## Performance Optimization

### 1. Optimize Layer Caching

```dockerfile
# Bad - Rebuilds everything on code change
COPY . .
RUN npm install && npm run build

# Good - Caches dependencies separately
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build
```

### 2. Use .dockerignore

```gitignore
# .dockerignore
node_modules
.git
.env
*.md
.vscode
.idea
dist
build
coverage
.DS_Store
*.log
```

### 3. Minimize Image Size

```dockerfile
# Use multi-stage builds
FROM node:18 AS builder
WORKDIR /app
COPY . .
RUN npm install && npm run build

FROM node:18-alpine
WORKDIR /app
COPY --from=builder /app/dist ./dist
COPY package*.json ./
RUN npm ci --only=production
CMD ["node", "dist/server.js"]
```

### 4. Parallel Builds in Docker Compose

```yaml
# docker-compose.yml uses BuildKit for parallel builds
services:
  service1:
    build: ./service1
  service2:
    build: ./service2
  service3:
    build: ./service3
```

```bash
# Enable BuildKit
export DOCKER_BUILDKIT=1
docker-compose build --parallel
```

## Next Steps

You now understand containers and Docker basics! In the next lesson, we'll explore:

- Kubernetes architecture
- How Kubernetes manages containers
- Key Kubernetes concepts

**Ready?** Continue to [Lesson 2: Kubernetes Architecture](../02-kubernetes-architecture/README.md)

## Quick Reference

### Docker Cheat Sheet

```bash
# Build and run workflow
docker build -t myapp .
docker run -d -p 8080:80 myapp
docker ps
docker logs <container_id>
docker stop <container_id>

# Debugging
docker exec -it <container> /bin/bash
docker inspect <container>
```
