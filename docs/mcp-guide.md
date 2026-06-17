# MCP Servers Guide

Model Context Protocol (MCP) lets AI assistants call external tools as if they were
built-in functions. tw-ai-toolkit provides pre-configured MCP server definitions for
common enterprise tools so you don't have to figure out the wiring yourself.

---

## What is MCP?

MCP is an open protocol that standardizes how AI models communicate with external tools.
A running MCP server exposes a set of **tools** (functions) that the model can call:

```
User: "Create a PR for my feature branch"
Model → calls github_create_pr(title="...", branch="feature/x", base="main")
MCP Server → GitHub REST API → returns PR URL
Model: "PR created: https://github.com/org/repo/pull/123"
```

The model decides when to call which tool based on context — no explicit invocation needed.

---

## MCP vs Skills — When to Use Each

| Use a Skill when... | Use an MCP server when... |
|---|---|
| You want explicit invocation (`/tw-name`) | You want the model to call tools autonomously |
| The action is purely AI-orchestrated | The action requires a real API call to an external service |
| No external API is involved | You need to read/write real data (GitHub, Jira, Slack) |
| Works without credentials | Requires authentication |

---

## Available MCP Servers

| Server | Enterprise Tool | Status |
|---|---|---|
| `tw-github` | GitHub — PRs, issues, repos | stable |
| `tw-jira` | Jira — stories, sprints, projects | stable |

---

## Adding an MCP Server to a Consumer Repo

### Step 1 — Enable in `.ai/config.json`

```json
{
  "mcp_servers": [
    {
      "name": "tw-github",
      "config": {}
    }
  ]
}
```

### Step 2 — Add credentials to `.env`

```bash
# GitHub
TW_GITHUB_TOKEN=ghp_xxxxxxxxxxxxxxxxxxxx

# Jira
TW_JIRA_HOST=https://your-org.atlassian.net
TW_JIRA_EMAIL=you@company.com
TW_JIRA_API_TOKEN=xxxxxxxxxxxxxxxxxxxx
```

### Step 3 — Configure the AI assistant

#### Claude Code (`.claude/settings.json`)

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

#### Cursor (`.cursor/mcp.json`)

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

### Step 4 — Verify

Ask your AI assistant: *"What GitHub tools do you have access to?"*
It should list the tools exposed by the server.

---

## MCP Server Naming Convention

| Part | Convention | Example |
|---|---|---|
| Folder name | `tw-<service>` | `tw-github`, `tw-jira` |
| Tool names | `<service>_<action>` (snake_case) | `github_create_pr`, `jira_get_issue` |
| Env vars | `TW_<SERVICE>_<CREDENTIAL>` | `TW_GITHUB_TOKEN` |

---

## Security Considerations

- **Never commit credentials.** All secrets go in `.env` (gitignored).
- **Minimal permissions.** Only grant the API scopes the tools actually need:
  - GitHub: `repo` scope for private repos, `public_repo` for public only
  - Jira: read-only token if you only need to read issues
- **Audit tool calls.** Claude Code logs every tool invocation — review periodically.
- **Consumer repo isolation.** Each repo has its own `.env` — no shared credentials.

---

## Troubleshooting

**Model says "I don't have access to GitHub tools"**
→ Check `.claude/settings.json` has the `mcpServers` block and Claude Code was restarted.

**MCP server fails to start**
→ Run the command manually: `npx -y @modelcontextprotocol/server-github`
   Look for missing credentials or Node.js not installed.

**Tool calls succeed but return errors**
→ Check that the token has the required scopes.
   GitHub tokens: Settings → Developer settings → Personal access tokens.

**Jira "401 Unauthorized"**
→ Verify `TW_JIRA_EMAIL` matches the account that generated the token.
   Jira API tokens are tied to the account email.
