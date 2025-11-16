# Microservices Architecture

A complete microservices application demonstrating service-to-service communication, message queues, and multiple databases.

## Architecture

```
                     ┌──────────┐
                     │  Nginx   │
                     │   :80    │
                     └────┬─────┘
                          │
                  ┌───────▼────────┐
                  │  API Gateway   │
                  │     :8080      │
                  └───────┬────────┘
                          │
        ┌─────────────────┼─────────────────┐
        │                 │                 │
   ┌────▼────┐      ┌────▼────┐      ┌────▼────┐
   │  User   │      │  Order  │      │ Product │
   │ Service │      │ Service │      │ Service │
   │  :8001  │      │  :8002  │      │  :8003  │
   └────┬────┘      └────┬────┘      └────┬────┘
        │                │                 │
        │           ┌────▼────┐            │
        │           │RabbitMQ │            │
        │           │ :15672  │            │
        │           └─────────┘            │
        │                                  │
   ┌────▼────┐                       ┌────▼────┐
   │Postgres │                       │ MongoDB │
   │  :5432  │                       │ :27017  │
   └─────────┘                       └─────────┘
```

## Services

### API Gateway (Port 8080)

- Routes requests to appropriate microservices
- Handles authentication
- Request/response transformation
- Rate limiting and caching

### User Service (Port 8001)

- User authentication and authorization
- User profile management
- PostgreSQL database

### Order Service (Port 8002)

- Order creation and management
- Order status tracking
- Communicates with RabbitMQ for async processing
- PostgreSQL database

### Product Service (Port 8003)

- Product catalog management
- Product search and filtering
- MongoDB database

## Message Queue

**RabbitMQ** handles asynchronous communication between services:

- Order events
- Email notifications
- Data synchronization

## Getting Started

1. Create service directories and basic files:

```bash
# Create directory structure
mkdir -p api-gateway user-service order-service product-service nginx

# API Gateway Dockerfile
cat > api-gateway/Dockerfile << 'EOF'
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
EXPOSE 8080
CMD ["node", "server.js"]
EOF

# User Service Dockerfile
cat > user-service/Dockerfile << 'EOF'
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
EXPOSE 8001
CMD ["node", "server.js"]
EOF

# Order Service Dockerfile
cat > order-service/Dockerfile << 'EOF'
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
EXPOSE 8002
CMD ["node", "server.js"]
EOF

# Product Service Dockerfile
cat > product-service/Dockerfile << 'EOF'
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
EXPOSE 8003
CMD ["node", "server.js"]
EOF

# PostgreSQL init script
cat > init-postgres.sql << 'EOF'
CREATE DATABASE users;
CREATE DATABASE orders;
EOF

# Nginx config
cat > nginx/nginx.conf << 'EOF'
events {
    worker_connections 1024;
}

http {
    upstream api {
        server api-gateway:8080;
    }

    server {
        listen 80;

        location / {
            proxy_pass http://api;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        }
    }
}
EOF
```

2. Start all services:

```bash
docker-compose up -d
```

3. Check service health:

```bash
# View all services
docker-compose ps

# Check logs
docker-compose logs -f
```

4. Test the services:

```bash
# Through API Gateway
curl http://localhost:8080/api/users
curl http://localhost:8080/api/orders
curl http://localhost:8080/api/products

# Direct service access (for testing)
curl http://localhost:8001/health
curl http://localhost:8002/health
curl http://localhost:8003/health
```

5. Access RabbitMQ Management UI:
   - URL: http://localhost:15672
   - Username: guest
   - Password: guest

## Service Communication Patterns

### Synchronous Communication (HTTP)

```javascript
// API Gateway calling User Service
const response = await fetch('http://user-service:8001/users/123');
const user = await response.json();
```

### Asynchronous Communication (RabbitMQ)

```javascript
// Order Service publishing event
channel.publish('orders', 'order.created', Buffer.from(JSON.stringify(order)));

// Email Service consuming event
channel.consume('email_queue', (msg) => {
  const order = JSON.parse(msg.content.toString());
  sendOrderConfirmationEmail(order);
});
```

## Scaling Services

```bash
# Scale order service to 3 instances
docker-compose up -d --scale order-service=3

# Scale product service to 2 instances
docker-compose up -d --scale product-service=2
```

## Monitoring

```bash
# View logs from all services
docker-compose logs -f

# View logs from specific service
docker-compose logs -f user-service

# View resource usage
docker stats
```

## Development Workflow

1. Make changes to a service
2. Rebuild that service:

```bash
docker-compose build user-service
docker-compose up -d user-service
```

3. View updated logs:

```bash
docker-compose logs -f user-service
```

## Database Access

### PostgreSQL

```bash
# Access Users database
docker-compose exec postgres psql -U postgres -d users

# Access Orders database
docker-compose exec postgres psql -U postgres -d orders
```

### MongoDB

```bash
# Access MongoDB shell
docker-compose exec mongo mongosh

# List databases
use products
db.products.find()
```

## Troubleshooting

### Service can't connect to another service

```bash
# Check network connectivity
docker-compose exec user-service ping postgres
docker-compose exec api-gateway ping user-service

# Inspect network
docker network inspect microservices_backend
```

### RabbitMQ connection issues

```bash
# Check RabbitMQ logs
docker-compose logs rabbitmq

# Check if RabbitMQ is ready
docker-compose exec rabbitmq rabbitmq-diagnostics ping
```

## Cleanup

```bash
# Stop all services
docker-compose down

# Remove volumes
docker-compose down -v

# Remove images
docker-compose down --rmi all
```

## Next Steps

- Add authentication with JWT
- Implement service mesh (Istio)
- Add distributed tracing (Jaeger)
- Implement circuit breakers
- Add API documentation (Swagger)
- Set up CI/CD pipeline
