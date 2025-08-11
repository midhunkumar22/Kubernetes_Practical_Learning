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

# Containers
docker run <image>              # Create and start container
docker ps                      # List running containers
docker ps -a                   # List all containers
docker stop <container>        # Stop container
docker start <container>       # Start stopped container
docker rm <container>          # Remove container
docker exec -it <container> <cmd>  # Execute command in container

# Cleanup
docker system prune            # Remove unused containers, images, networks
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
