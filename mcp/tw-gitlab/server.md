---
name: tw-gitlab
description: GitLab MCP server exposing merge requests, CI/CD pipelines, issues, and repository tools to AI assistants. Essential for teams using GitLab as their primary VCS and CI platform.
status: stable
version_added: v0.5.0
compatible_with:
  claude_code: full
  cursor: full
  codex: none
tags:
  - gitlab
  - vcs
  - merge-requests
  - ci-cd
  - pipelines
  - issues
  - enterprise
---

# tw-gitlab

## Description

Wraps the GitLab REST API v4 with MCP conventions, exposing GitLab-specific workflows
to AI assistants: merge requests (not PRs), pipelines (not Actions), GitLab CI configuration,
and GitLab-specific project structure.

**Clients using GitLab** (common in European enterprises, financial services, and
government) need this server instead of `tw-github`. The tools are parallel but
adapted to GitLab terminology and API.

## Tools Exposed

| Tool | Description | Required scope |
|---|---|---|
| `gitlab_list_mrs` | List open merge requests for a project | `read_api` |
| `gitlab_get_mr` | Get full MR details including diff, comments, approvals | `read_api` |
| `gitlab_create_mr_comment` | Post a review comment on a merge request | `api` |
| `gitlab_get_pipeline` | Get pipeline status and job list for a ref | `read_api` |
| `gitlab_list_pipeline_jobs` | List jobs in a pipeline with status and logs URL | `read_api` |
| `gitlab_get_job_trace` | Get the console output of a CI job | `read_api` |
| `gitlab_trigger_pipeline` | Trigger a pipeline for a branch or tag | `api` |
| `gitlab_list_issues` | List project issues with filters (label, milestone, assignee) | `read_api` |
| `gitlab_get_issue` | Get full issue details | `read_api` |
| `gitlab_create_issue_comment` | Post a comment on an issue | `api` |
| `gitlab_get_file` | Read a file from the repository at a specific ref | `read_repository` |
| `gitlab_list_branches` | List repository branches | `read_repository` |
| `gitlab_get_commit` | Get commit details including changed files | `read_repository` |
| `gitlab_list_group_projects` | List all projects in a GitLab group | `read_api` |

## Configuration

### 1. Create a GitLab Personal Access Token (PAT)

1. In GitLab: User Settings → Access Tokens → Add new token
2. Required scopes: `read_api` (minimum), `api` (for write operations)
3. Set expiration: recommend 90 days for security

### 2. Configure the MCP Server

Add to your Claude Code MCP configuration (`.claude/settings.json` or global settings):

```json
{
  "mcpServers": {
    "tw-gitlab": {
      "command": "npx",
      "args": ["-y", "@tw-ai/mcp-gitlab"],
      "env": {
        "GITLAB_TOKEN": "glpat-xxxxxxxxxxxxxxxxxxxx",
        "GITLAB_BASE_URL": "https://gitlab.com",
        "GITLAB_DEFAULT_PROJECT": "group/project-name"
      }
    }
  }
}
```

For self-hosted GitLab instances:
```json
{
  "GITLAB_BASE_URL": "https://gitlab.yourcompany.com",
  "GITLAB_TOKEN": "glpat-xxxxxxxxxxxxxxxxxxxx"
}
```

### 3. Add to `.ai/config.json`

```json
{
  "mcp_servers": {
    "tw-gitlab": {
      "enabled": true,
      "default_project": "group/project-name",
      "self_hosted": false
    }
  }
}
```

### 4. Add token to `.env.toolkit` (never commit this file)

```bash
# .env.toolkit — gitignored
TW_GITLAB_TOKEN=glpat-xxxxxxxxxxxxxxxxxxxx
TW_GITLAB_BASE_URL=https://gitlab.com
TW_GITLAB_DEFAULT_PROJECT=group/project-name
```

## Example Interactions

Once configured, the AI assistant can use these tools autonomously:

```
User: "Summarize the open MRs and what CI failures they have"
→ AI calls gitlab_list_mrs, gitlab_get_pipeline per MR, gitlab_get_job_trace for failing jobs

User: "What did the last pipeline failure say?"
→ AI calls gitlab_get_pipeline, gitlab_list_pipeline_jobs, gitlab_get_job_trace

User: "Create a QA review comment on MR !42 about the missing test for the refund endpoint"
→ AI calls gitlab_create_mr_comment with the review content

User: "What tests failed in the last CI run on main?"
→ AI calls gitlab_get_pipeline for main, lists failed jobs, reads traces
```

## Security Notes

- Store `GITLAB_TOKEN` in `.env.toolkit` — this file must be gitignored
- Use the minimum required scope: `read_api` is sufficient for most read operations
- For CI operations, a Project Access Token (scoped to the project) is preferred over a PAT
- Rotate tokens every 90 days
- For self-hosted GitLab: ensure the MCP server can reach the GitLab instance (network access)

## Troubleshooting

**Tool returns 401 Unauthorized:**
- Verify token has not expired
- Verify `GITLAB_BASE_URL` matches your instance (no trailing slash)

**Tool returns 403 Forbidden:**
- Token scope is insufficient — add `api` scope for write operations

**Cannot reach self-hosted instance:**
- Check network connectivity and SSL certificates
- For self-signed certs: set `NODE_TLS_REJECT_UNAUTHORIZED=0` (not for production)

## Notes

- GitLab uses "merge requests" (MRs) not "pull requests" (PRs)
- GitLab CI uses `.gitlab-ci.yml` — the `pipeline-generator` skill supports GitLab CI output
- For groups with many projects, `gitlab_list_group_projects` is useful for multi-repo analysis
- Self-hosted GitLab instances may have API rate limits configured differently from gitlab.com
