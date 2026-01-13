# Open WebUI mit MCP Gateway Integration

## Schnellstart

### Alle Services starten (Open WebUI + MCP-Server)

```powershell
# MCP-Server bauen (falls noch nicht gebaut)
docker-compose up -d --build

# Open WebUI mit MCP-Servern starten
docker-compose -f docker-compose-openwebui.yml up -d
```

## Zugriff

- **Open WebUI**: http://localhost:3000
- **MCP Gateway**: http://localhost:8001
- **ADO Server**: http://localhost:8003
- **Docupedia Server**: http://localhost:8004

## Open WebUI Konfiguration für MCP

### In Open WebUI:

1. Öffne **Settings** → **Connections** → **MCP Servers**
2. Füge einen neuen MCP Server hinzu:
   - **Name**: MCP Gateway
   - **URL**: `http://mcp-servers:8001/mcp`
   - **Type**: HTTP/SSE

### Verfügbare Tools über Gateway:

Nach der Verbindung hast du Zugriff auf:

**Docupedia Tools** (Prefix: `docupedia_`):
- `docupedia_search_content` - Suche in Confluence
- `docupedia_get_page` - Seite abrufen
- `docupedia_create_page` - Seite erstellen
- `docupedia_update_page` - Seite aktualisieren
- und weitere...

**Azure DevOps Tools** (Prefix: `ado_`):
- `ado_list_work_items` - Work Items auflisten
- `ado_get_work_item` - Work Item abrufen
- `ado_create_work_item` - Work Item erstellen
- `ado_update_work_item` - Work Item aktualisieren
- und weitere...

## Architektur

```
Open WebUI (Port 3000)
    ↓
MCP Gateway (Port 8001)
    ↓
    ├─→ Docupedia Server (Port 8004)
    └─→ ADO Server (Port 8003)
```

## Troubleshooting

### Open WebUI kann Gateway nicht erreichen

```powershell
# Prüfe, ob alle Container im gleichen Netzwerk sind
docker network inspect mcp-network

# Logs prüfen
docker-compose -f docker-compose-openwebui.yml logs open-webui
docker logs mcp-servers
```

### MCP Tools werden nicht angezeigt

1. Prüfe Gateway-Status: http://localhost:8001/healthcheck
2. Prüfe Server-Logs: `docker logs mcp-servers`
3. Stelle sicher, dass config.json Dateien korrekt gemountet sind

## Services stoppen

```powershell
# Open WebUI stoppen
docker-compose -f docker-compose-openwebui.yml down

# MCP-Server stoppen
docker-compose down

# Alles stoppen
docker-compose -f docker-compose-openwebui.yml down
docker-compose down
```
