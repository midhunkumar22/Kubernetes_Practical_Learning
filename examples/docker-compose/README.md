# Docker Compose Examples

This directory contains practical Docker Compose examples for various scenarios.

## Available Examples

1. **web-app-basic** - Simple web application with database
2. **fullstack-app** - Complete full-stack application with frontend, backend, and database
3. **microservices** - Microservices architecture example
4. **monitoring-stack** - Monitoring setup with Prometheus and Grafana
5. **development-env** - Development environment with hot reload

## How to Use

Navigate to any example directory and run:

```bash
# Start all services
docker-compose up -d

# View logs
docker-compose logs -f

# Stop all services
docker-compose down

# Stop and remove volumes
docker-compose down -v
```

## Prerequisites

- Docker installed
- Docker Compose installed
- Basic understanding of Docker concepts

## Tips

- Always check the README.md in each example directory for specific instructions
- Use `docker-compose ps` to see running services
- Use `docker-compose exec <service> sh` to access a service shell
- Environment variables can be overridden using `.env` files
