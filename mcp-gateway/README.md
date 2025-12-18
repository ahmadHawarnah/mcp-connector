# MCP Gateway Server

A flexible gateway server for aggregating multiple Model Context Protocol (MCP) servers into a single unified interface. The gateway supports loading MCP servers as Python modules for optimal performance or proxying to external HTTP servers.

![MCP Gateway Architecture](gateway.png)

## Features

- **Multiple Server Types**: Support for module-based and HTTP proxy servers
- **Unified Interface**: Single endpoint to access all connected MCP servers
- **Tool Namespacing**: Automatic prefixing prevents tool name conflicts
- **Health Monitoring**: Built-in health checks and metrics for all servers
- **CORS Support**: Configurable CORS for browser-based clients
- **Interactive UI**: Terminal-based UI for monitoring server status
- **Hot Configuration**: JSON-based configuration for easy setup

## Installation

```bash
# Install dependencies using uv (recommended)
uv sync

# Or using pip
pip install -e .
```

## Configuration

Edit `gateway_config.json` to configure your MCP servers:

```json
{
  "gateway": {
    "name": "MCP Gateway Server",
    "cors": {
      "origins": ["*"],
      "credentials": true
    }
  },
  "child_servers": [
    {
      "name": "Demo Server",
      "type": "module",
      "module_path": "mcp-demo-server",
      "prefix": "demo",
      "description": "Example demo server"
    },
    {
      "name": "External Server",
      "type": "proxy",
      "url": "http://localhost:8003/mcp",
      "prefix": "external",
      "health_endpoint": "/health"
    }
  ]
}
```

### Server Types

#### Module Servers
Load MCP servers directly as Python modules for best performance:
```json
{
  "type": "module",
  "module_path": "path-to-module",
  "module_name": "module_name",  // Optional, defaults to module_path
  "init_function": "initialize",  // Optional, defaults to "initialize"
  "prefix": "unique-prefix"
}
```

#### Proxy Servers
Connect to external MCP servers via HTTP:
```json
{
  "type": "proxy",
  "url": "http://server-url/mcp",
  "prefix": "unique-prefix",
  "health_endpoint": "/health"  // Optional health check endpoint
}
```

## Usage

### Start the Gateway

```bash
# With interactive UI (recommended)
uv run ui.py

# Or run the server directly (starts on port 8001)
uv run gateway_server.py

# With custom port
uv run gateway_server.py 8080
```

### API Endpoints

- `GET /` - Gateway status
- `GET /health` - Health check with server metrics
- `POST /mcp` - MCP protocol endpoint
- `GET /metrics` - Detailed metrics for all servers

### Using with MCP Clients

The gateway exposes all tools from connected servers with automatic prefixing:

```python
# Original tool: "search_emails"
# Via gateway: "outlook_search_emails" (with prefix "outlook")
```

### Example Client Usage

```python
import httpx

async with httpx.AsyncClient() as client:
    # List available tools
    response = await client.post("http://localhost:8002/mcp", json={
        "jsonrpc": "2.0",
        "method": "tools/list",
        "params": {},
        "id": 1
    })
    
    # Call a tool (automatically routed to correct server)
    response = await client.post("http://localhost:8002/mcp", json={
        "jsonrpc": "2.0",
        "method": "tools/call",
        "params": {
            "name": "demo_get_weather",  # Prefixed tool name
            "arguments": {"location": "London"}
        },
        "id": 2
    })
```

### Using the Gateway Server with Github Copilot in VSCode

Add the following `mcp.json` file to the `.vscode` folder in the workspace you want to use the MCP gateway server in:
```json
{
    "servers": {
        "bre_tools_server": {
            "command": "cmd",
            "args": [
                "python \\path\\to\\your\\GIT\\mcp-gateway\\gateway_server.py --no_http"
            ]
        }
    }
}
```

## Interactive UI

The gateway includes a terminal-based UI for monitoring:

```bash
uv run ui.py
```

Features:
- Real-time server status monitoring
- Request/error metrics
- Connection health indicators
- Automatic refresh every 5 seconds

## Architecture

The gateway acts as a central hub, routing MCP requests to appropriate backend servers:

1. **Request Reception**: Receives MCP protocol requests on `/mcp`
2. **Tool Resolution**: Maps prefixed tool names to target servers
3. **Request Routing**: Forwards requests to the appropriate server
4. **Response Aggregation**: Combines responses from multiple servers
5. **Metrics Collection**: Tracks performance and health metrics

## Monitoring

### Health Check
```bash
curl http://localhost:8002/health
```

Response:
```json
{
  "status": "healthy",
  "servers": {
    "demo": {
      "status": "connected",
      "type": "module"
    },
    "outlook": {
      "status": "connected",
      "type": "proxy"
    }
  }
}
```

### Metrics
```bash
curl http://localhost:8002/metrics
```

## Troubleshooting

### Common Issues

1. **Port Already in Use**
   - Change the port using `--port` flag
   - Check for other services on port 8002

2. **Module Import Errors**
   - Ensure module is in Python path
   - Check module has proper `initialize()` function

3. **Proxy Connection Failed**
   - Verify external server is running
   - Check network connectivity
   - Validate health endpoint configuration

4. **Event Loop Errors**
   - The gateway handles async operations automatically
   - Ensure you're using the latest version

## Development

### Adding New Server Types

Extend the gateway by adding new server types in `gateway_server.py`:

1. Add handler in `initialize_servers()`
2. Implement connection logic
3. Add routing in request handlers

### Running Tests

```bash
# Run gateway with test configuration
uv run gateway_server.py --config test_config.json

# Test health endpoint
curl http://localhost:8002/health

# Test MCP protocol
uv run test_client.py
```

## License

MIT

## Contributing

Contributions are welcome! Please ensure:
- Code follows existing patterns
- Configuration examples are updated
- Health checks are implemented for new server types