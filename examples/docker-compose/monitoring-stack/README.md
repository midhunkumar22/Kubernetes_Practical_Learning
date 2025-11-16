# Monitoring Stack

Complete monitoring solution with Prometheus, Grafana, Loki, and exporters.

## Stack Components

- **Prometheus**: Time-series database for metrics
- **Grafana**: Visualization and dashboards
- **Node Exporter**: Host metrics
- **cAdvisor**: Container metrics
- **Loki**: Log aggregation
- **Promtail**: Log collection

## Architecture

```
┌─────────┐     ┌───────────┐     ┌──────────┐
│   App   │────▶│Prometheus │◀────│ Grafana  │
└─────────┘     └───────────┘     └──────────┘
                      ▲                  ▲
                      │                  │
         ┌────────────┼──────────┐       │
         │            │          │       │
    ┌────▼────┐  ┌───▼────┐ ┌───▼───┐   │
    │ Node    │  │cAdvisor│ │ Loki  │◀──┘
    │Exporter │  │        │ │       │
    └─────────┘  └────────┘ └───▲───┘
                                │
                          ┌─────▼────┐
                          │ Promtail │
                          └──────────┘
```

## Port Mappings

- 3000: Application
- 3001: Grafana UI
- 9090: Prometheus UI
- 9100: Node Exporter metrics
- 8081: cAdvisor UI
- 3100: Loki API

## Quick Start

1. Create configuration files:

```bash
# Prometheus config
mkdir -p prometheus
cat > prometheus/prometheus.yml << 'EOF'
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'node-exporter'
    static_configs:
      - targets: ['node-exporter:9100']

  - job_name: 'cadvisor'
    static_configs:
      - targets: ['cadvisor:8080']

  - job_name: 'app'
    static_configs:
      - targets: ['app:3000']
EOF

# Sample app
mkdir -p app
cat > app/server.js << 'EOF'
const http = require('http');

let requestCount = 0;

const server = http.createServer((req, res) => {
  requestCount++;
  
  if (req.url === '/metrics') {
    res.writeHead(200, { 'Content-Type': 'text/plain' });
    res.end(`# TYPE http_requests_total counter
http_requests_total ${requestCount}
`);
  } else {
    res.writeHead(200, { 'Content-Type': 'text/html' });
    res.end('<h1>Hello from monitored app!</h1>');
  }
});

server.listen(3000, '0.0.0.0', () => {
  console.log('Server running on port 3000');
});
EOF

# Promtail config
mkdir -p promtail
cat > promtail/promtail-config.yml << 'EOF'
server:
  http_listen_port: 9080
  grpc_listen_port: 0

positions:
  filename: /tmp/positions.yaml

clients:
  - url: http://loki:3100/loki/api/v1/push

scrape_configs:
  - job_name: system
    static_configs:
      - targets:
          - localhost
        labels:
          job: varlogs
          __path__: /var/log/*log
EOF
```

2. Start the stack:

```bash
docker-compose up -d
```

3. Access dashboards:
   - Grafana: http://localhost:3001 (admin/admin)
   - Prometheus: http://localhost:9090
   - cAdvisor: http://localhost:8081

4. Configure Grafana:
   - Add Prometheus data source: http://prometheus:9090
   - Add Loki data source: http://loki:3100
   - Import dashboards:
     - Node Exporter: Dashboard ID 1860
     - cAdvisor: Dashboard ID 14282

## Sample Queries

### Prometheus Queries

```promql
# Request rate
rate(http_requests_total[5m])

# CPU usage
100 - (avg by (instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# Memory usage
(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100

# Container memory
container_memory_usage_bytes{name!=""}
```

### Loki Queries

```logql
{job="varlogs"}
{job="varlogs"} |= "error"
{job="varlogs"} | json | level="error"
```

## Alerts

Add to `prometheus.yml`:

```yaml
rule_files:
  - /etc/prometheus/alerts.yml

alerting:
  alertmanagers:
    - static_configs:
        - targets:
            - alertmanager:9093
```

Create `alerts.yml`:

```yaml
groups:
  - name: example
    rules:
      - alert: HighMemoryUsage
        expr: (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100 > 80
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High memory usage detected"
```

## Cleanup

```bash
docker-compose down -v
```
