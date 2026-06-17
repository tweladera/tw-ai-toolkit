---
name: onboard-repo
description: Analyzes a repository and sets up tw-ai-toolkit with configuration tailored to the project.
status: stable
version_added: v0.1.0
compatible_with:
  claude_code: full
  cursor: partial
  codex: none
tags:
  - onboarding
  - setup
  - initialization
---

# onboard-repo

## Description

A full-setup agent that analyzes an existing repository, installs the toolkit,
and configures it based on what it finds. It reads the repo's tech stack, structure,
and existing tooling to generate a `config.json` that enables only the relevant
toolkit components and recommends which MCP servers to activate.

Use this when adding the toolkit to an existing project for the first time,
or when you want a guided, opinionated setup rather than the manual install flow.

## Trigger

When the user says:
- "Set up the AI toolkit in this repo"
- "Onboard this repo to tw-ai-toolkit"
- "Configure the toolkit for this project"
- `/tw-onboard-repo`

## Skills Used

- `/tw-install-toolkit` — performs the actual submodule installation

## Inputs

| Input | Required | Description |
|---|---|---|
| `repo_path` | no | Path to the repo root (defaults to current directory) |

## Flow

```
Step 1 — Analyze repository
  Action: Read and summarize the repository structure:
          - Programming languages used (check file extensions, package.json, pyproject.toml, etc.)
          - Framework / platform (Next.js, Django, Spring, etc.)
          - CI/CD system present (.github/workflows/, .gitlab-ci.yml, Jenkinsfile, etc.)
          - Existing AI tooling (CLAUDE.md, .cursorrules, .github/copilot-instructions.md)
          - Team size indicator (number of contributors from git log --oneline -20)
          - Enterprise tools in use (Jira references in commits, Slack webhooks, etc.)
  Output: Summary of findings to show the user for confirmation.

Step 2 — Confirm findings with user
  Action: Present the analysis summary and ask:
          "Does this look correct? Should I proceed with installation?"
  Output: User confirmation (or corrections to apply).

Step 3 — Install toolkit
  Action: Invoke /tw-install-toolkit with repo_path and default version.
  Output: Toolkit submodule installed, .ai/ structure created.

Step 4 — Generate tailored config
  Action: Based on Step 1 findings, write `.ai/config.json`:
          - Enable only component types relevant to the stack
          - Suggest MCP servers based on detected enterprise tools:
              * Jira references detected → suggest tw-jira MCP server (commented out)
              * GitHub Actions detected → suggest tw-github MCP server (commented out)
              * Slack detected → suggest tw-slack MCP server (commented out)
          - Set update_strategy based on CI presence:
              * CI detected → suggest "dependabot" in config comments
              * No CI → default "manual"
  Output: `.ai/config.json` written with tailored values and comments.

Step 5 — Generate CLAUDE.md or update existing
  Action: If CLAUDE.md exists, read it first to understand the existing structure.
          Add the toolkit fragment in the most appropriate location (end of file if unsure).
          If it doesn't exist, create it with the toolkit fragment + a brief project context header.
  Output: CLAUDE.md created or updated.

Step 6 — Summary report
  Action: Show the user what was created and the recommended next steps specific
          to their stack.
  Output: See Outputs section.
```

## Outputs

```
Onboarding complete for: <repo_name>

What was set up:
- .ai/toolkit/          tw-ai-toolkit v<version> (submodule)
- .ai/config.json       Configured for <detected_stack>
- .ai/AGENTS.md         Toolkit context pointer
- CLAUDE.md             Updated with toolkit fragment

Detected stack: <language> / <framework>

Recommended next steps:
1. Fill in .env with any needed credentials (see .env.toolkit.example)
2. [If enterprise tools detected]: Activate MCP servers in .ai/config.json
3. Run: git add .ai/ CLAUDE.md && git commit -m "chore: add tw-ai-toolkit v<version>"
4. Try your first skill: /tw-sync-context

Components available for your stack:
- [List of most relevant skills/agents for the detected tech stack]
```

## Notes

- This agent asks for confirmation after Step 1 before making any changes.
- It does NOT modify source code — only configuration and AI tooling files.
- If the toolkit is already installed, it skips Step 3 and goes straight to config optimization.
- Maximum autonomy: the agent stops and asks before any write operation if it is uncertain.
