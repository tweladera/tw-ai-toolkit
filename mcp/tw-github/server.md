---
name: tw-github
description: GitHub MCP server exposing PR, issue, and repository tools to AI assistants.
status: stable
version_added: v0.1.0
compatible_with:
  claude_code: full
  cursor: full
  codex: none
tags:
  - github
  - vcs
  - prs
  - issues
  - enterprise
---

# tw-github

## Description

Wraps the official `@modelcontextprotocol/server-github` with tw-ai-toolkit conventions:
standardized env var naming (`TW_GITHUB_*`), `.ai/config.json` integration, and
documentation for the specific token scopes required per tool.

Once configured, the AI assistant can autonomously read and write GitHub resources
(PRs, issues, branches, repos) without explicit invocation — the model decides when
to call each tool based on the user's intent.

## Tools Exposed

| Tool | Description | Required scope |
|---|---|---|
| `github_get_file_contents` | Read a file from a repo | `repo` (private) / `public_repo` (public) |
| `github_create_or_update_file` | Create or update a file in a repo | `repo` |
| `github_push_files` | Push multiple files in one commit | `repo` |
| `github_create_repository` | Create a new repository | `repo` |
| `github_search_repositories` | Search repos by query | `public_repo` |
| `github_get_file_contents` | Read file contents from a repo | `repo` |
| `github_create_issue` | Create a new issue | `repo` |
| `github_list_issues` | List issues with filters | `repo` |
| `github_update_issue` | Update issue title, body, labels | `repo` |
| `github_add_issue_comment` | Add a comment to an issue | `repo` |
| `github_create_pull_request` | Open a PR from branch to base | `repo` |
| `github_list_pull_requests` | List PRs with filters | `repo` |
| `github_get_pull_request` | Get PR details + diff | `repo` |
| `github_merge_pull_request` | Merge a PR | `repo` |
| `github_create_branch` | Create a new branch from ref | `repo` |
| `github_list_commits` | List commits on a branch | `repo` |
| `github_search_code` | Search code across repos | `repo` / `public_repo` |
| `github_search_issues` | Search issues and PRs | `repo` |

## Authentication

| Credential | Env var | Required | Description |
|---|---|---|---|
| Personal Access Token | `TW_GITHUB_TOKEN` | yes | PAT with required scopes |

### Creating a GitHub PAT

1. GitHub → Settings → Developer settings → Personal access tokens → Fine-grained tokens
2. Repository access: select repos or all repos
3. Permissions needed (minimum):
   - `Contents`: Read and write (for file operations)
   - `Issues`: Read and write
   - `Pull requests`: Read and write
   - `Metadata`: Read (automatic)

Add to `.env` in consumer repo:
```bash
TW_GITHUB_TOKEN=github_pat_xxxxxxxxxxxxxxxxxxxx
```

## Configuration

Enable in `.ai/config.json`:
```json
{
  "mcp_servers": [
    {
      "name": "tw-github",
      "config": {
        "default_owner": "your-org",
        "default_repo": "your-default-repo"
      }
    }
  ]
}
```

Full config schema: `mcp/tw-github/config.json`

## Setup

### Prerequisites

- Node.js 18+ installed (`node --version`)
- Valid GitHub PAT in `.env`

### Claude Code (`.claude/settings.json`)

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

Restart Claude Code after adding this configuration.

### Cursor (`.cursor/mcp.json`)

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

### Verify installation

Ask your assistant: *"What GitHub tools do you have available?"*
Expected: a list of `github_*` tools.

## Examples

### Create a PR autonomously
```
Create a PR from my feature branch to main with a descriptive title based on my commits.
```
The model will call `github_list_commits`, then `github_create_pull_request` automatically.

### Review an issue
```
What's the status of issue #42 in this repo?
```
The model will call `github_get_file_contents` or `github_list_issues` and summarize.

### Search across repos
```
Find all open PRs in the org that mention "database migration"
```
The model will call `github_search_issues` with appropriate filters.

## Notes

- **Underlying package:** `@modelcontextprotocol/server-github` (official MCP server from Anthropic/GitHub)
- **Rate limits:** GitHub API has rate limits — 5000 requests/hour for authenticated users
- **Private repos:** require `repo` scope. Public repos only need `public_repo`
- **Offline behavior:** All tool calls fail gracefully with a clear error when GitHub is unreachable
