# tw-jira

Jira MCP server — gives AI assistants autonomous access to issues, sprints, and projects.

**Underlying server:** `@sooperset/mcp-atlassian` (community)
**Tools:** 14 tools covering issues, transitions, sprints, boards, comments, work logs

## Quick Setup

1. Add credentials to `.env`:
   ```bash
   TW_JIRA_HOST=https://your-org.atlassian.net
   TW_JIRA_EMAIL=you@company.com
   TW_JIRA_API_TOKEN=ATATxxxxxxxxxxxxxxxx
   ```

2. Add to `.claude/settings.json`:
   ```json
   {
     "mcpServers": {
       "tw-jira": {
         "command": "npx",
         "args": ["-y", "@sooperset/mcp-atlassian"],
         "env": {
           "JIRA_URL": "${TW_JIRA_HOST}",
           "JIRA_USERNAME": "${TW_JIRA_EMAIL}",
           "JIRA_API_TOKEN": "${TW_JIRA_API_TOKEN}"
         }
       }
     }
   }
   ```

3. Restart Claude Code and ask: *"What Jira tools do you have available?"*

See `server.md` for full documentation, including tool list and Cursor setup.
See `docs/mcp-guide.md` for general MCP guidance.
