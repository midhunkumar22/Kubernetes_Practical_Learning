# Basic Web Application

A simple three-tier web application with Nginx, Node.js API, and PostgreSQL.

## Architecture

```
┌─────────┐      ┌─────────┐      ┌──────────────┐
│  Nginx  │─────▶│   API   │─────▶│  PostgreSQL  │
│  :8080  │      │  :3000  │      │    :5432     │
└─────────┘      └─────────┘      └──────────────┘
```

## Services

- **web**: Nginx web server serving static content
- **api**: Node.js API server
- **db**: PostgreSQL database

## Getting Started

1. Create the required files:

```bash
# Create API server file
mkdir -p api
cat > api/server.js << 'EOF'
const http = require('http');
const url = require('url');

const server = http.createServer((req, res) => {
  const parsedUrl = url.parse(req.url, true);
  
  if (parsedUrl.pathname === '/api/health') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ status: 'healthy', timestamp: new Date() }));
  } else if (parsedUrl.pathname === '/api/data') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ message: 'Hello from API!', data: [1, 2, 3] }));
  } else {
    res.writeHead(404, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ error: 'Not found' }));
  }
});

const PORT = process.env.PORT || 3000;
server.listen(PORT, '0.0.0.0', () => {
  console.log(`API server running on port ${PORT}`);
});
EOF

# Create HTML file
mkdir -p html
cat > html/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Docker Compose Demo</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        button { padding: 10px 20px; margin: 10px 0; }
        pre { background: #f4f4f4; padding: 10px; }
    </style>
</head>
<body>
    <h1>Docker Compose Web App</h1>
    <button onclick="fetchData()">Fetch Data from API</button>
    <pre id="output"></pre>
    <script>
        async function fetchData() {
            const response = await fetch('/api/data');
            const data = await response.json();
            document.getElementById('output').textContent = JSON.stringify(data, null, 2);
        }
    </script>
</body>
</html>
EOF

# Create nginx config
cat > nginx.conf << 'EOF'
events {
    worker_connections 1024;
}

http {
    upstream api {
        server api:3000;
    }

    server {
        listen 80;
        
        location / {
            root /usr/share/nginx/html;
            index index.html;
        }
        
        location /api/ {
            proxy_pass http://api/api/;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
        }
    }
}
EOF

# Create database init script
cat > init.sql << 'EOF'
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    email VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO users (name, email) VALUES 
    ('Alice', 'alice@example.com'),
    ('Bob', 'bob@example.com');
EOF
```

2. Start the application:

```bash
docker-compose up -d
```

3. Access the application:
   - Web: http://localhost:8080
   - API: http://localhost:8080/api/health

4. View logs:

```bash
docker-compose logs -f
```

5. Stop the application:

```bash
docker-compose down
```

## Useful Commands

```bash
# Check service status
docker-compose ps

# Access database
docker-compose exec db psql -U user -d myapp

# Access API container
docker-compose exec api sh

# Restart a service
docker-compose restart api
```
