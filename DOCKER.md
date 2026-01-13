# Docker Build & Run Instructions

## Quick Start

### Nur MCP-Server starten
```powershell
# MCP-Server bauen und starten
docker-compose up -d --build

# Logs ansehen
docker-compose logs -f mcp-servers

# Status prüfen
docker-compose ps
```

### Nur N8N starten
```powershell
# N8N separat starten
docker-compose -f docker-compose-n8n.yml up -d

# Logs ansehen
docker-compose -f docker-compose-n8n.yml logs -f n8n
```

### Beide zusammen starten (MCP + N8N)
```powershell
# Erst MCP-Server
docker-compose up -d --build

# Dann N8N (kann mit MCP kommunizieren über mcp-network)
docker-compose -f docker-compose-n8n.yml up -d
```

### Einzelner MCP Container

```powershell
# Container bauen
docker build -t mcp-servers .

# Container starten
docker run -d \
  --name mcp-servers \
  -p 8001:8001 \
  -p 8003:8003 \
  -p 8004:8004 \
  -v ${PWD}/mcp-ado/config.json:/app/mcp-ado/config.json:ro \
  -v ${PWD}/mcp-docupedia/config.json:/app/mcp-docupedia/config.json:ro \
  -v ${PWD}/mcp-gateway/gateway_config.json:/app/mcp-gateway/gateway_config.json:ro \
  -e HTTP_PROXY=http://rb-proxy-de.bosch.com:8080 \
  -e HTTPS_PROXY=http://rb-proxy-de.bosch.com:8080 \
  mcp-servers

# Logs ansehen
docker logs -f mcp-servers
```

## Services & Ports

### Vom Host (Windows) zugreifen:
- **Gateway UI**: http://localhost:8001
- **ADO Server**: http://localhost:8003
- **Docupedia Server**: http://localhost:8004
- **N8N**: http://localhost:5678

### Von N8N Container aus (Docker-Netzwerk):
- **Gateway UI**: http://mcp-servers:8001
- **ADO Server**: http://mcp-servers:8003
- **Docupedia Server**: http://mcp-servers:8004

## Health Checks

```powershell
# ADO Server
curl http://localhost:8003/healthcheck

# Docupedia Server
curl http://localhost:8004/healthcheck
```

## Stoppen & Cleanup

```powershell
# Nur MCP-Server stoppen
docker-compose down

# Nur N8N stoppen
docker-compose -f docker-compose-n8n.yml down

# Beide stoppen
docker-compose down
docker-compose -f docker-compose-n8n.yml down

# Mit Volumes löschen
docker-compose down -v
docker-compose -f docker-compose-n8n.yml down -v

# Einzelnen Container stoppen
docker stop mcp-servers
docker rm mcp-servers
```

## Troubleshooting

### Logs prüfen
```powershell
docker-compose logs mcp-servers
docker-compose logs n8n
```

### In Container einsteigen
```powershell
docker exec -it mcp-servers /bin/bash
```

### Config-Dateien prüfen
Stelle sicher, dass alle Config-Dateien existieren:
- `mcp-ado/config.json`
- `mcp-docupedia/config.json`
- `mcp-gateway/gateway_config.json`

### Proxy-Probleme
Falls Proxy-Probleme auftreten, passe die `HTTP_PROXY` Umgebungsvariablen in `docker-compose.yml` an.
