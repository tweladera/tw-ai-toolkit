---
name: tw-jira
description: Jira MCP server exposing issue, sprint, and project tools to AI assistants.
status: stable
version_added: v0.1.0
compatible_with:
  claude_code: full
  cursor: full
  codex: none
tags:
  - jira
  - project-management
  - issues
  - sprints
  - enterprise
---

# tw-jira

## Description

MCP server for Atlassian Jira. Exposes tools for reading and writing issues,
querying sprints, and navigating projects. Uses the Jira REST API v3 with
Basic authentication (email + API token).

Once configured, the AI assistant can autonomously read stories, log work,
transition issue states, and query board/sprint status without explicit invocation.

## Tools Exposed

| Tool | Description | Notes |
|---|---|---|
| `jira_get_issue` | Get full issue details by key (e.g. `PROJ-123`) | |
| `jira_search_issues` | Search issues using JQL | Full JQL support |
| `jira_create_issue` | Create a new issue in a project | |
| `jira_update_issue` | Update issue fields (summary, description, assignee, etc.) | |
| `jira_transition_issue` | Move issue to a new status (e.g. In Progress → Done) | |
| `jira_add_comment` | Add a comment to an issue | |
| `jira_list_comments` | List comments on an issue | |
| `jira_get_project` | Get project metadata and issue types | |
| `jira_list_projects` | List all accessible projects | |
| `jira_get_sprint` | Get sprint details and issues | Requires Jira Software |
| `jira_list_sprints` | List sprints for a board | Requires Jira Software |
| `jira_get_board` | Get board configuration | Requires Jira Software |
| `jira_log_work` | Log time worked on an issue | |
| `jira_get_current_user` | Get the authenticated user's profile | Useful for self-assignment |

## Authentication

| Credential | Env var | Required | Description |
|---|---|---|---|
| Jira instance URL | `TW_JIRA_HOST` | yes | e.g. `https://your-org.atlassian.net` |
| Account email | `TW_JIRA_EMAIL` | yes | Email of the Atlassian account |
| API token | `TW_JIRA_API_TOKEN` | yes | Generated at id.atlassian.com |

### Creating a Jira API Token

1. Go to: https://id.atlassian.com/manage-profile/security/api-tokens
2. Click "Create API token"
3. Label it (e.g. `tw-ai-toolkit`) and copy the token

Add to `.env` in consumer repo:
```bash
TW_JIRA_HOST=https://your-org.atlassian.net
TW_JIRA_EMAIL=you@company.com
TW_JIRA_API_TOKEN=ATATxxxxxxxxxxxxxxxx
```

## Configuration

Enable in `.ai/config.json`:
```json
{
  "mcp_servers": [
    {
      "name": "tw-jira",
      "config": {
        "default_project": "PROJ"
      }
    }
  ]
}
```

Full config schema: `mcp/tw-jira/config.json`

## Setup

### Prerequisites

- Node.js 18+ installed
- Jira Cloud or Jira Data Center (Server requires additional config)
- Valid API token in `.env`

### Claude Code (`.claude/settings.json`)

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

### Cursor (`.cursor/mcp.json`)

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

### Verify installation

Ask your assistant: *"What Jira tools do you have available?"*
Then: *"What's the status of issue PROJ-1?"*

## Examples

### Get sprint status
```
What's in the current sprint for the PLATFORM project?
```
The model calls `jira_list_sprints` then `jira_get_sprint` and summarizes the board.

### Create a story from a task
```
Create a Jira story in PROJ for the payment refactoring we discussed.
Use the acceptance criteria from our conversation.
```
The model calls `jira_create_issue` with a well-structured description.

### Transition an issue
```
Mark PROJ-123 as Done.
```
The model calls `jira_get_issue` (to find valid transitions), then `jira_transition_issue`.

### Log work
```
Log 2 hours on PROJ-456 with the comment "Implemented OAuth flow"
```
The model calls `jira_log_work` with the time and comment.

## Notes

- **Underlying package:** `@sooperset/mcp-atlassian` (community MCP server for Atlassian)
- **Jira Cloud vs Server:** API token auth works for Jira Cloud. Data Center requires OAuth setup.
- **JQL support:** `jira_search_issues` accepts full JQL — the model can build complex queries
- **Rate limits:** Jira REST API has rate limits; large board queries may be slow
- **Offline behavior:** All tool calls fail gracefully with a descriptive error when Jira is unreachable
