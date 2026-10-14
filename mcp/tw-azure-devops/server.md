---
name: tw-azure-devops
description: Azure DevOps MCP server exposing Boards (work items), Pipelines (builds and releases), Repos (PRs, commits), and Test Plans to AI assistants. Essential for Microsoft-stack clients using Azure DevOps as their primary platform.
status: stable
version_added: v0.5.0
compatible_with:
  claude_code: full
  cursor: full
  codex: none
tags:
  - azure-devops
  - ado
  - boards
  - pipelines
  - work-items
  - microsoft
  - enterprise
---

# tw-azure-devops

## Description

Azure DevOps is the dominant platform in Microsoft-stack enterprise environments —
.NET shops, companies heavily invested in Azure cloud, and large enterprises that
standardized on Microsoft tooling. A consultant without ADO integration is working
blind in these environments.

`tw-azure-devops` exposes the four core ADO services the AI needs for QA work:
Boards (user stories, bugs, test cases as work items), Pipelines (CI/CD status and logs),
Repos (code and pull requests), and Test Plans (manual and automated test management).

## Tools Exposed

### Boards

| Tool | Description |
|---|---|
| `ado_get_work_item` | Get full work item details (user story, bug, task, test case) |
| `ado_list_work_items` | Query work items (WIQL or saved query ID) |
| `ado_create_work_item` | Create a new work item (bug, test case, task) |
| `ado_update_work_item` | Update work item fields (state, assigned to, comments) |
| `ado_list_sprint_items` | List work items for the current or a named sprint |

### Pipelines

| Tool | Description |
|---|---|
| `ado_get_pipeline` | Get pipeline definition and last run status |
| `ado_list_pipeline_runs` | List recent pipeline runs with status |
| `ado_get_pipeline_run` | Get full run details including stage/job/step results |
| `ado_get_build_log` | Get the console log for a specific build task |
| `ado_trigger_pipeline` | Queue a new pipeline run for a branch |

### Repos

| Tool | Description |
|---|---|
| `ado_list_prs` | List pull requests with filters (status, reviewer, branch) |
| `ado_get_pr` | Get full PR details including diff, comments, votes |
| `ado_create_pr_comment` | Post a comment on a pull request |
| `ado_get_commit` | Get commit details and changed files |
| `ado_get_file` | Read a file from the repository at a specific commit |

### Test Plans

| Tool | Description |
|---|---|
| `ado_list_test_plans` | List test plans in the project |
| `ado_get_test_plan` | Get test plan details including test suites |
| `ado_list_test_cases` | List test cases in a suite |
| `ado_get_test_results` | Get test run results for a pipeline or manual run |

## Configuration

### 1. Create a Personal Access Token (PAT)

Azure DevOps → User Settings (top right) → Personal Access Tokens → New Token

Required scopes (minimum):
- `Work Items: Read & Write` (for Boards)
- `Build: Read` (for Pipelines read)
- `Build: Read & Execute` (for Pipelines trigger)
- `Code: Read` (for Repos read)
- `Code: Read & Write` (for PR comments)
- `Test Management: Read` (for Test Plans)

### 2. Configure the MCP Server

```json
{
  "mcpServers": {
    "tw-azure-devops": {
      "command": "npx",
      "args": ["-y", "@tw-ai/mcp-azure-devops"],
      "env": {
        "ADO_TOKEN": "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
        "ADO_ORGANIZATION": "https://dev.azure.com/your-org",
        "ADO_PROJECT": "YourProjectName",
        "ADO_DEFAULT_REPO": "YourRepoName"
      }
    }
  }
}
```

### 3. Add to `.env.toolkit` (never commit)

```bash
TW_ADO_TOKEN=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
TW_ADO_ORGANIZATION=https://dev.azure.com/your-org
TW_ADO_PROJECT=YourProjectName
```

## Example Interactions

```
User: "What user stories are in the current sprint?"
→ AI calls ado_list_sprint_items → current sprint backlog

User: "The pipeline for the payments service failed — what was the error?"
→ AI calls ado_get_pipeline_run → failed step → ado_get_build_log → error message

User: "Create a bug for the failing authentication test we just found"
→ AI calls ado_create_work_item(type=Bug, title=..., description=..., area=auth)

User: "What test cases exist for the order placement feature?"
→ AI calls ado_list_test_plans → ado_get_test_plan → ado_list_test_cases(suite=order-placement)

User: "Post a QA review comment on PR #247 about the missing error scenario"
→ AI calls ado_create_pr_comment with the review content

User: "How many tests failed in yesterday's nightly run?"
→ AI calls ado_get_test_results for the nightly pipeline run
```

## Integration with Toolkit Skills

| ADO capability | Toolkit skill |
|---|---|
| Test Plans — manual test cases | Convert to Gherkin with `/tw-exec-spec-generator` |
| Pipeline failures — test results | Analyze with `/tw-flakiness-analyzer` |
| Work items — user stories | Generate specs with `/tw-exec-spec-generator story=<work-item>` |
| Pipeline definition | Update with `/tw-pipeline-generator platform=azure-devops` |

## Notes

- ADO uses "pull requests" but from the Azure Repos product — same concept as GitHub PRs
- Work item types vary by process template (Agile, Scrum, CMMI) — query returns the correct type names
- `ado_list_work_items` accepts WIQL (Work Item Query Language) — the AI can construct WIQL queries from natural language
- Azure Pipelines YAML format is different from GitHub Actions and GitLab CI — the `pipeline-generator` skill supports Azure DevOps output
- Test Plans is a paid ADO feature (Basic + Test Plans license) — verify the client has it enabled
