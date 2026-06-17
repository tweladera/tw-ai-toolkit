# tw-github

GitHub MCP server — gives AI assistants autonomous access to GitHub PRs, issues, and repositories.

**Underlying server:** `@modelcontextprotocol/server-github` (official)
**Tools:** 17 tools covering files, issues, PRs, branches, search

## Quick Setup

1. Add token to `.env`:
   ```bash
   TW_GITHUB_TOKEN=github_pat_xxxxxxxxxxxxxxxxxxxx
   ```

2. Add to `.claude/settings.json`:
   ```json
   {
     "mcpServers": {
       "tw-github": {
         "command": "npx",
         "args": ["-y", "@modelcontextprotocol/server-github"],
         "env": {
           "GITHUB_PERSONAL_ACCESS_TOKEN": "${TW_GITHUB_TOKEN}"
         }
       }
     }
   }
   ```

3. Restart Claude Code and ask: *"What GitHub tools do you have available?"*

See `server.md` for full documentation including tool list, scopes, and Cursor setup.
See `docs/mcp-guide.md` for general MCP guidance.
