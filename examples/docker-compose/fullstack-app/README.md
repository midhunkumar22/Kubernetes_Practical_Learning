# Full-Stack Application

A complete full-stack application with frontend, backend, database, cache, and reverse proxy.

## Architecture

```
                    ┌─────────────┐
                    │   Nginx     │
                    │   :8080     │
                    └──────┬──────┘
                           │
              ┌────────────┴────────────┐
              │                         │
         ┌────▼─────┐            ┌─────▼────┐
         │ Frontend │            │ Backend  │
         │  :3000   │            │  (API)   │
         └──────────┘            └─────┬────┘
                                       │
                            ┌──────────┼──────────┐
                            │          │          │
                       ┌────▼───┐ ┌───▼────┐ ┌──▼────┐
                       │Postgres│ │ Redis  │ │pgAdmin│
                       │ :5432  │ │ :6379  │ │ :5050 │
                       └────────┘ └────────┘ └───────┘
```

## Services

- **frontend**: React/Vue frontend application
- **backend**: Node.js/Express API server
- **postgres**: PostgreSQL database
- **redis**: Redis cache
- **nginx**: Reverse proxy and load balancer
- **pgadmin**: PostgreSQL admin interface

## Port Mappings

- 8080: Main application (Nginx)
- 3000: Frontend (direct access for development)
- 5432: PostgreSQL
- 6379: Redis
- 5050: pgAdmin

## Getting Started

1. Start all services:

```bash
docker-compose up -d
```

2. Access the application:
   - Main app: http://localhost:8080
   - Frontend dev: http://localhost:3000
   - pgAdmin: http://localhost:5050
     - Email: admin@admin.com
     - Password: admin

3. View logs:

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f backend
```

## Development

### Frontend Hot Reload

The frontend supports hot reload. Edit files in `./frontend` and see changes immediately.

### Backend Hot Reload

The backend uses nodemon for hot reload. Edit files in `./backend` to see changes.

### Database Migrations

```bash
# Run migrations
docker-compose exec backend npm run migrate

# Seed database
docker-compose exec backend npm run seed
```

### Redis CLI

```bash
docker-compose exec redis redis-cli
```

### PostgreSQL CLI

```bash
docker-compose exec postgres psql -U postgres -d appdb
```

## Production Deployment

For production, use:

```bash
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

## Cleanup

```bash
# Stop all services
docker-compose down

# Remove volumes
docker-compose down -v
```
