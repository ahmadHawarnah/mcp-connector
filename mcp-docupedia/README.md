# MCP Confluence/Docupedia Server

A Model Context Protocol (MCP) server for Confluence/Docupedia integration using FastMCP v2 with HTTP transport.

## Features

- ✅ Full Confluence REST API integration
- ✅ Content search with CQL (Confluence Query Language)
- ✅ Page management (create, read, update)
- ✅ Space listing and details
- ✅ Comments and attachments
- ✅ Labels/tags management
- ✅ Corporate proxy support
- ✅ SSL verification bypass for internal CAs
- ✅ HTTP transport with Server-Sent Events (SSE)
- ✅ CORS enabled for browser access
- ✅ Session management

## Requirements

- Python 3.10+
- Confluence/Docupedia access credentials (PAT or username/password)
- uv package manager
- (Optional) Corporate proxy configuration

## Installation

```bash
# Navigate to the mcp-docupedia directory
cd mcp-docupedia

# Install dependencies using uv
uv pip install -e .
```

## Configuration

1. Copy the example configuration file:
```bash
cp config.example.json config.json
```

2. Edit `config.json` and add your Confluence credentials:

### Option A: Using Personal Access Token (Recommended)

```json
{
  "confluence": {
    "host": "inside-docupedia.bosch.com/confluence",
    "api_token": "your-personal-access-token",
    "username": "",
    "password": ""
  },
  "proxy": {
    "enabled": true,
    "url": "http://localhost:3128",
    "disable_ssl_verification": true
  }
}
```

### Option B: Using Username/Password

```json
{
  "confluence": {
    "host": "inside-docupedia.bosch.com/confluence",
    "api_token": "",
    "username": "your-username",
    "password": "your-password"
  },
  "proxy": {
    "enabled": true,
    "url": "http://localhost:3128",
    "disable_ssl_verification": true
  }
}
```

### Getting Your Confluence PAT

1. Log in to Confluence/Docupedia
2. Go to Profile → Settings → Personal Access Tokens
3. Click "Create token"
4. Give it a name (e.g., "MCP Server") and set expiration
5. Copy the generated token
6. Paste it into your `config.json` file

### Proxy Configuration

If you're behind a corporate proxy (like at Bosch):

```json
{
  "proxy": {
    "enabled": true,
    "url": "http://localhost:3128",
    "disable_ssl_verification": true
  }
}
```

Set `disable_ssl_verification: true` if your corporate proxy uses custom SSL certificates.

### Alternative: Environment Variables

Instead of storing credentials in `config.json`, you can use environment variables:

```bash
# Confluence credentials
$env:CONFLUENCE_API_TOKEN = "your-pat-here"
# OR
$env:CONFLUENCE_USERNAME = "your-username"
$env:CONFLUENCE_PASSWORD = "your-password"

# Proxy settings
$env:HTTP_PROXY = "http://localhost:3128"
$env:HTTPS_PROXY = "http://localhost:3128"
```

## Running the Server

```bash
# Start the server on default port 8004
uv run mcp_server.py

# Or specify a custom port
$env:MCP_CONFLUENCE_PORT = "8005"
uv run mcp_server.py
```

The server will be available at: `http://localhost:8004/mcp`

## Testing the Server

### Health Check

```bash
curl http://localhost:8004/healthcheck
```

### Using curl (PowerShell)

```powershell
# 1. Initialize session
$response = curl -X POST http://localhost:8004/mcp `
  -H "Content-Type: application/json" `
  -H "Accept: application/json, text/event-stream" `
  -d '{"jsonrpc":"2.0","method":"initialize","params":{"protocolVersion":"2025-06-18","capabilities":{"tools":{}},"clientInfo":{"name":"test-client","version":"1.0.0"}},"id":1}' `
  -i

$SESSION_ID = ($response | Select-String "mcp-session-id").Line.Split(':')[1].Trim()

# 2. Send initialized notification (REQUIRED!)
curl -X POST http://localhost:8004/mcp `
  -H "Content-Type: application/json" `
  -H "Accept: application/json, text/event-stream" `
  -H "mcp-session-id: $SESSION_ID" `
  -d '{"method":"notifications/initialized","jsonrpc":"2.0"}'

# 3. List available tools
curl -X POST http://localhost:8004/mcp `
  -H "Content-Type: application/json" `
  -H "Accept: application/json, text/event-stream" `
  -H "mcp-session-id: $SESSION_ID" `
  -d '{"jsonrpc":"2.0","method":"tools/list","id":2}'
```

## Available Tools

### Search & Discovery

- `search_content` - Search for content using CQL (Confluence Query Language)
- `list_spaces` - List all accessible Confluence spaces
- `get_space` - Get details of a specific space
- `list_pages_in_space` - List all pages in a space

### Page Operations

- `get_page` - Get a page by ID or title
- `create_page` - Create a new page
- `update_page` - Update an existing page
- `get_page_children` - Get child pages of a page

### Collaboration

- `get_page_comments` - Get comments on a page
- `add_comment` - Add a comment to a page
- `get_page_attachments` - Get attachments for a page
- `get_page_labels` - Get labels/tags for a page
- `add_label` - Add a label/tag to a page

## Available Resources

- `confluence://config` - Get server configuration
- `confluence://spaces` - List all accessible spaces

## Available Prompts

- `page_summary_prompt` - Generate prompts for summarizing pages
- `documentation_prompt` - Generate prompts for finding documentation

## Example Tool Calls

### Search for Content

```json
{
  "jsonrpc": "2.0",
  "method": "tools/call",
  "params": {
    "name": "search_content",
    "arguments": {
      "query": "authentication",
      "space_key": "DOCS",
      "max_results": 10
    }
  },
  "id": 3
}
```

### Get a Page

```json
{
  "jsonrpc": "2.0",
  "method": "tools/call",
  "params": {
    "name": "get_page",
    "arguments": {
      "page_title": "API Documentation",
      "space_key": "DOCS"
    }
  },
  "id": 4
}
```

### Create a New Page

```json
{
  "jsonrpc": "2.0",
  "method": "tools/call",
  "params": {
    "name": "create_page",
    "arguments": {
      "space_key": "DOCS",
      "title": "New Feature Documentation",
      "content": "<p>This is the content of the new page.</p><h2>Features</h2><ul><li>Feature 1</li><li>Feature 2</li></ul>"
    }
  },
  "id": 5
}
```

### Add a Comment

```json
{
  "jsonrpc": "2.0",
  "method": "tools/call",
  "params": {
    "name": "add_comment",
    "arguments": {
      "page_id": "123456789",
      "comment_text": "<p>Great documentation! Very helpful.</p>"
    }
  },
  "id": 6
}
```

## Integration with MCP Gateway

To use this server with the MCP Gateway, add it to the gateway's configuration:

```json
{
  "servers": {
    "docupedia": {
      "module": "mcp-docupedia.mcp_server",
      "port": 8004,
      "base_path": "/docupedia"
    }
  }
}
```

## CQL Query Examples

CQL (Confluence Query Language) is used for advanced content searches:

```sql
-- Search for pages with specific text
text ~ "authentication" AND type = page

-- Search in a specific space
space = "DOCS" AND text ~ "API"

-- Search by label
label = "important" AND type = page

-- Search by creator
creator = "john.doe" AND type = page

-- Search recent pages
type = page AND created >= now("-7d")

-- Combine multiple criteria
space = "DOCS" AND type = page AND label = "API" AND text ~ "REST"
```

## Troubleshooting

### Authentication Errors

- Verify your PAT or username/password is correct
- Check token hasn't expired
- Ensure you have access to the Confluence instance
- Try accessing Confluence in a browser first

### Proxy Issues

- Verify proxy URL is correct (`http://localhost:3128`)
- Check proxy is running (e.g., Px proxy for corporate networks)
- Try setting `disable_ssl_verification: true` if SSL errors occur
- Test proxy with curl: `curl -x http://localhost:3128 https://www.google.com`

### Connection Timeouts

- Check network connectivity to Confluence host
- Verify firewall rules allow connections
- Try increasing timeout in requests (modify `_make_confluence_request`)

### SSL Certificate Errors

- Set `disable_ssl_verification: true` in proxy config
- Install corporate CA certificate in Python's certificate store
- Use `requests.packages.urllib3.disable_warnings()` (already included)

### Page Not Found Errors

- Verify space key is correct (case-sensitive)
- Check you have permission to access the space/page
- Use `list_spaces` to see available spaces
- Use `list_pages_in_space` to browse available pages

## API Documentation

- [Confluence REST API Reference](https://developer.atlassian.com/cloud/confluence/rest/v1/intro/)
- [Confluence Query Language (CQL)](https://developer.atlassian.com/cloud/confluence/advanced-searching-using-cql/)
- [Confluence Storage Format](https://confluence.atlassian.com/doc/confluence-storage-format-790796544.html)

## Corporate Network Setup (Bosch Example)

For Bosch Docupedia access behind corporate proxy:

1. Install and configure Px proxy:
```bash
pip install px-proxy
px --proxy=rb-proxy-de.bosch.com:8080 --listen=127.0.0.1:3128
```

2. Set environment variables:
```powershell
$env:HTTP_PROXY = "http://localhost:3128"
$env:HTTPS_PROXY = "http://localhost:3128"
$env:NODE_TLS_REJECT_UNAUTHORIZED = "0"
```

3. Use configuration with proxy enabled and SSL verification disabled

## License

MIT
