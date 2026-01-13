# Multi-stage Dockerfile für alle MCP Server
FROM python:3.12-slim as base

# Build-Argumente für Proxy
ARG HTTP_PROXY
ARG HTTPS_PROXY
ARG NO_PROXY

# Setze Proxy-Umgebungsvariablen für Build
ENV HTTP_PROXY=${HTTP_PROXY}
ENV HTTPS_PROXY=${HTTPS_PROXY}
ENV NO_PROXY=${NO_PROXY}

# Setze Arbeitsverzeichnis
WORKDIR /app

# Kopiere alle Projektdateien
COPY . .

# Installiere alle Abhängigkeiten direkt mit pip
RUN pip install --no-cache-dir \
    fastapi>=0.116.1 \
    fastmcp>=2.11.3 \
    requests>=2.31.0 \
    python-dotenv>=1.0.0 \
    uvicorn>=0.38.0 \
    starlette>=0.50.0 \
    azure-devops>=7.1.0b4 \
    urllib3>=2.0.0 \
    rich>=14.1.0

# Erstelle Startup-Script
RUN echo '#!/bin/bash\n\
set -e\n\
\n\
echo "=== Starting MCP Servers ==="\n\
\n\
# Start MCP ADO Server im Hintergrund\n\
echo "[1/3] Starting MCP ADO Server on port 8003..."\n\
cd /app/mcp-ado && python mcp_server.py &\n\
ADO_PID=$!\n\
sleep 2\n\
\n\
# Start MCP Docupedia Server im Hintergrund\n\
echo "[2/3] Starting MCP Docupedia Server on port 8004..."\n\
cd /app/mcp-docupedia && python mcp_server.py &\n\
DOCUPEDIA_PID=$!\n\
sleep 2\n\
\n\
# Start MCP Gateway im Vordergrund\n\
echo "[3/3] Starting MCP Gateway on port 8001..."\n\
cd /app/mcp-gateway && python ui.py\n\
\n\
# Falls Gateway beendet wird, stoppe auch die anderen Server\n\
kill $ADO_PID $DOCUPEDIA_PID 2>/dev/null || true\n\
' > /app/start-all.sh && chmod +x /app/start-all.sh

# Exponiere Ports
EXPOSE 8001 8003 8004

# Healthcheck
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:8003/healthcheck && \
        curl -f http://localhost:8004/healthcheck || exit 1

# Starte alle Server
CMD ["/app/start-all.sh"]
