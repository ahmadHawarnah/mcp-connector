# MCP Azure DevOps Server

A Model Context Protocol (MCP) server for Azure DevOps integration using FastMCP v2 with HTTP transport.

## Features

- ✅ Full Azure DevOps REST API integration
- ✅ Work Items management (list, get, create, update)
- ✅ Repository operations (list repos, get commits)
- ✅ Build pipeline queries
- ✅ Pull Request management
- ✅ Code search across repositories
- ✅ WIQL query support for advanced work item filtering
- ✅ HTTP transport with Server-Sent Events (SSE)
- ✅ CORS enabled for browser access
- ✅ Session management

## Requirements

- Python 3.10+
- Azure DevOps Personal Access Token (PAT)
- uv package manager

## Installation

```bash
# Navigate to the mcp-ado directory
cd mcp-ado

# Install dependencies using uv
uv pip install -e .
```

## Configuration

1. Copy the example configuration file:
```bash
cp config.example.json config.json
```

2. Edit `config.json` and add your Azure DevOps credentials:
```json
{
  "azure_devops": {
    "organization": "your-organization-name",
    "default_project": "your-default-project",
    "pat": "your-personal-access-token",
    "api_version": "7.1"
  }
}
```

### Getting Your Azure DevOps PAT

1. Go to Azure DevOps: `https://dev.azure.com/{your-organization}`
2. Click on User Settings (top right) → Personal Access Tokens
3. Click "New Token"
4. Configure the token:
   - Name: `MCP Server`
   - Organization: Select your organization
   - Expiration: Choose appropriate duration
   - Scopes: Select the following:
     - **Code**: Read & Write (for repositories and PRs)
     - **Work Items**: Read & Write
     - **Build**: Read
     - **Project and Team**: Read
5. Click "Create" and copy the generated token
6. Paste it into your `config.json` file

### Alternative: Environment Variable

Instead of storing the PAT in `config.json`, you can use an environment variable:

```bash
$env:AZURE_DEVOPS_PAT = "your-pat-here"
```

## Running the Server

```bash
# Start the server on default port 8003
uv run mcp_server.py

# Or specify a custom port
$env:MCP_ADO_PORT = "8005"
uv run mcp_server.py
```

The server will be available at: `http://localhost:8003/mcp`

## Testing the Server

### Health Check

```bash
curl http://localhost:8003/healthcheck
```

### Using curl

```bash
# 1. Initialize session
$SESSION_ID = (curl -s -X POST http://localhost:8003/mcp `
  -H "Content-Type: application/json" `
  -H "Accept: application/json, text/event-stream" `
  -d '{"jsonrpc":"2.0","method":"initialize","params":{"protocolVersion":"2025-06-18","capabilities":{"tools":{}},"clientInfo":{"name":"test-client","version":"1.0.0"}},"id":1}' `
  -i | Select-String "mcp-session-id" | ForEach-Object { $_.Line.Split(':')[1].Trim() })

# 2. Send initialized notification (REQUIRED!)
curl -s -X POST http://localhost:8003/mcp `
  -H "Content-Type: application/json" `
  -H "Accept: application/json, text/event-stream" `
  -H "mcp-session-id: $SESSION_ID" `
  -d '{"method":"notifications/initialized","jsonrpc":"2.0"}'

# 3. List available tools
curl -s -X POST http://localhost:8003/mcp `
  -H "Content-Type: application/json" `
  -H "Accept: application/json, text/event-stream" `
  -H "mcp-session-id: $SESSION_ID" `
  -d '{"jsonrpc":"2.0","method":"tools/list","id":2}'
```

## Available Tools

### Work Items

- `list_work_items` - List work items using WIQL queries
- `get_work_item` - Get details of a specific work item by ID
- `create_work_item` - Create a new work item (Task, Bug, User Story, etc.)

### Repositories

- `list_repositories` - List all Git repositories in a project
- `get_repository_commits` - Get recent commits from a repository
- `list_pull_requests` - List pull requests (active, completed, or all)

### Builds & Pipelines

- `list_builds` - List recent builds with optional status filter
- `get_build_details` - Get detailed information about a specific build

### Code Search

- `search_code` - Search for code across all repositories in a project

## Available Resources

- `ado://config` - Get server configuration
- `ado://projects/{organization}` - List all projects in an organization

## Available Prompts

- `work_item_analysis` - Generate analysis prompts for work items
- `pr_review_prompt` - Generate code review templates for PRs

## Example Tool Calls

### List Recent Work Items

```json
{
  "jsonrpc": "2.0",
  "method": "tools/call",
  "params": {
    "name": "list_work_items",
    "arguments": {
      "organization": "your-org",
      "project": "your-project",
      "max_results": 10
    }
  },
  "id": 3
}
```

### Create a Bug

```json
{
  "jsonrpc": "2.0",
  "method": "tools/call",
  "params": {
    "name": "create_work_item",
    "arguments": {
      "organization": "your-org",
      "project": "your-project",
      "work_item_type": "Bug",
      "title": "Login page not responsive",
      "description": "The login page doesn't display correctly on mobile devices",
      "tags": "UI, Mobile, High-Priority"
    }
  },
  "id": 4
}
```

### Search Code

```json
{
  "jsonrpc": "2.0",
  "method": "tools/call",
  "params": {
    "name": "search_code",
    "arguments": {
      "organization": "your-org",
      "project": "your-project",
      "search_text": "authentication",
      "max_results": 20
    }
  },
  "id": 5
}
```

## Integration with MCP Gateway

To use this server with the MCP Gateway, add it to the gateway's configuration:

```json
{
  "servers": {
    "ado": {
      "module": "mcp-ado.mcp_server",
      "port": 8003,
      "base_path": "/ado"
    }
  }
}
```

## Common WIQL Queries

```sql
-- My active work items
SELECT [System.Id], [System.Title], [System.State] 
FROM WorkItems 
WHERE [System.AssignedTo] = @Me 
  AND [System.State] <> 'Closed'

-- Recent bugs
SELECT [System.Id], [System.Title], [System.State] 
FROM WorkItems 
WHERE [System.WorkItemType] = 'Bug' 
  AND [System.State] = 'Active'
ORDER BY [System.CreatedDate] DESC

-- High priority items
SELECT [System.Id], [System.Title], [System.State], [Microsoft.VSTS.Common.Priority]
FROM WorkItems 
WHERE [Microsoft.VSTS.Common.Priority] = 1
  AND [System.State] <> 'Closed'
```

## Troubleshooting

### Authentication Errors

- Verify your PAT is valid and not expired
- Ensure your PAT has the required scopes (Code, Work Items, Build, Project and Team)
- Check that the organization name is correct

### Connection Issues

- Verify you can access Azure DevOps in your browser
- Check if you're behind a corporate proxy (configure proxy in requests if needed)
- Ensure the server port is not blocked by firewall

### API Errors

- Check the Azure DevOps API version compatibility (currently using 7.1)
- Verify project names and IDs are correct
- Review logs for detailed error messages

## API Documentation

- [Azure DevOps REST API Reference](https://learn.microsoft.com/en-us/rest/api/azure/devops/)
- [Work Items API](https://learn.microsoft.com/en-us/rest/api/azure/devops/wit/)
- [Git API](https://learn.microsoft.com/en-us/rest/api/azure/devops/git/)
- [Build API](https://learn.microsoft.com/en-us/rest/api/azure/devops/build/)

## License

MIT
