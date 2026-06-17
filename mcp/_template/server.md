---
name: example-server
description: One sentence describing which enterprise tool this MCP server integrates.
status: stable
version_added: v0.1.0
compatible_with:
  claude_code: full
  cursor: full
  codex: none
tags:
  - example
  - template
  - mcp
---

# example-server

## Description

Expand on what enterprise tool this server integrates, what operations it exposes,
and what use cases it enables. MCP servers make external tools available to AI
models as callable functions, without the model needing direct API access.

## Tools Exposed

List every MCP tool this server makes available to the model.

| Tool name | Description | Key inputs |
|---|---|---|
| `tool_name_one` | What this tool does | `param_a`, `param_b` |
| `tool_name_two` | What this tool does | `param_c` |

## Authentication

How the server authenticates with the external service.

| Credential | Source | Description |
|---|---|---|
| `API_KEY` | `.env` → `TW_EXAMPLE_API_KEY` | API key for the external service |
| `HOST_URL` | `.env` → `TW_EXAMPLE_HOST` | Base URL of the service |

Add to consumer repo's `.env`:
```bash
TW_EXAMPLE_API_KEY=your_api_key_here
TW_EXAMPLE_HOST=https://your-instance.example.com
```

## Configuration

### `config.json` (this server's config schema)

```json
{
  "server_name": "example-server",
  "env_prefix": "TW_EXAMPLE",
  "options": {
    "timeout_ms": 5000,
    "max_results": 50
  }
}
```

Enable in consumer repo's `.ai/config.json`:
```json
{
  "mcp_servers": [
    {
      "name": "example-server",
      "config": {
        "options": {
          "timeout_ms": 10000
        }
      }
    }
  ]
}
```

## Setup

### Claude Code

Add to `.claude/settings.json` in the consumer repo:

```json
{
  "mcpServers": {
    "example-server": {
      "command": "node",
      "args": [".ai/toolkit/mcp/example-server/index.js"],
      "env": {
        "TW_EXAMPLE_API_KEY": "${TW_EXAMPLE_API_KEY}",
        "TW_EXAMPLE_HOST": "${TW_EXAMPLE_HOST}"
      }
    }
  }
}
```

### Cursor

Add to Cursor MCP config (`.cursor/mcp.json`):

```json
{
  "mcpServers": {
    "example-server": {
      "command": "node",
      "args": [".ai/toolkit/mcp/example-server/index.js"],
      "env": {
        "TW_EXAMPLE_API_KEY": "${TW_EXAMPLE_API_KEY}",
        "TW_EXAMPLE_HOST": "${TW_EXAMPLE_HOST}"
      }
    }
  }
}
```

## Examples

### Example 1 — Basic tool usage
The model can now use `tool_name_one` directly:
```
Use example-server to [task]. The project is [context].
```
The model will call `tool_name_one` with the appropriate parameters automatically.

### Example 2 — Combined with a skill
```
/tw-skill-that-uses-example-server project="my-project"
```

## Notes

- Rate limits: [describe any rate limiting from the external service]
- Data sensitivity: [what kind of data flows through this server]
- Offline behavior: [what happens when the external service is unreachable]
