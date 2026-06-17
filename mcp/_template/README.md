# MCP Server Template

Use this template to create a new MCP server integration.

## Steps

1. Copy this directory:
   ```bash
   cp -r mcp/_template/ mcp/your-server-name/
   ```

2. Fill in `server.md`.

3. Implement the actual MCP server (see MCP SDK docs for implementation):
   ```
   mcp/your-server-name/
   ├── server.md       # Definition (this template)
   ├── index.js        # MCP server implementation
   ├── config.json     # Config schema for this server
   └── README.md       # Your documentation
   ```

4. Validate:
   ```
   /tw-lint-component mcp/your-server-name
   ```

## MCP Server Guidelines

- **One server per external service.** Don't bundle multiple unrelated services.
- **Minimal permissions.** Only request the API scopes the tools actually need.
- **Document all tools.** Every tool exposed must appear in the Tools Exposed table.
- **Handle auth errors gracefully.** The model should get a clear error when credentials are missing or invalid.
- **Never log credentials.** Sanitize all logs.
- **Declare rate limits.** The model needs to know if it should throttle requests.

## Naming Convention

- Folder: `tw-<service-name>` (e.g. `tw-jira`, `tw-github`, `tw-slack`)
- Tool names: `<service>_<action>` in snake_case (e.g. `jira_get_issue`, `github_create_pr`)
- Env vars: `TW_<SERVICE>_<CREDENTIAL>` (e.g. `TW_JIRA_API_TOKEN`)

## Resources

- [MCP Specification](https://modelcontextprotocol.io)
- [MCP TypeScript SDK](https://github.com/modelcontextprotocol/typescript-sdk)
- [MCP Python SDK](https://github.com/modelcontextprotocol/python-sdk)
