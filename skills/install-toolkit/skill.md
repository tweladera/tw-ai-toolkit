---
name: install-toolkit
description: Guides the user through installing tw-ai-toolkit into a consumer repository.
status: stable
version_added: v0.1.0
compatible_with:
  claude_code: full
  cursor: partial
  codex: none
parameters:
  - name: repo_path
    type: string
    required: false
    default: "."
    description: Absolute or relative path to the consumer repo root (defaults to current directory)
  - name: version
    type: string
    required: false
    default: "latest"
    description: Toolkit version tag to install (e.g. v1.0.0). Defaults to latest stable tag.
tags:
  - setup
  - installation
  - onboarding
---

# install-toolkit

## Description

Walks the user through installing tw-ai-toolkit as a git submodule in a consumer repo.
Creates the `.ai/` folder structure, sets up `config.json`, generates a `CLAUDE.md`
fragment, and optionally configures Dependabot. Validates the installation at the end.

## When to Use

- When a user wants to add the toolkit to a repo for the first time
- When setting up a new project that should use toolkit components

## Parameters

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `repo_path` | string | no | `.` | Path to the consumer repo root |
| `version` | string | no | `latest` | Toolkit version tag to install |

## Instructions

1. **Verify prerequisites.** Check that:
   - `git` is available in the terminal
   - The `repo_path` is a git repository (`.git/` directory exists)
   - The toolkit is not already installed (`.ai/toolkit/` does not exist)
   If any check fails, report the issue clearly and stop.

2. **Resolve the version.** If `version` is `latest`, run:
   ```bash
   git ls-remote --tags https://github.com/tw-qa/tw-ai-toolkit.git | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | sort -V | tail -1
   ```
   Show the resolved version to the user and ask for confirmation before proceeding.

3. **Add the submodule:**
   ```bash
   cd <repo_path>
   git submodule add https://github.com/tw-qa/tw-ai-toolkit.git .ai/toolkit
   cd .ai/toolkit && git checkout <version> && cd ../..
   git add .gitmodules .ai/toolkit
   ```

4. **Create `.ai/config.json`** with these defaults:
   ```json
   {
     "toolkit_version": "<version>",
     "enabled_components": ["skills", "agents", "prompts", "rules", "hooks", "mcp_servers"],
     "disabled_skills": [],
     "local_overrides": true,
     "mcp_servers": [],
     "env_file": ".env",
     "update_strategy": "manual"
   }
   ```

5. **Create `.ai/AGENTS.md`** with this content:
   ```markdown
   # AI Toolkit Context

   This repo uses tw-ai-toolkit <version>.

   Load toolkit context from:
   - Toolkit overview: `.ai/toolkit/AGENTS.md`
   - Available components: `.ai/toolkit/registry.json`
   - Local overrides: `.ai/skills/`, `.ai/agents/`
   - Local config: `.ai/config.json`

   All toolkit skills and agents use the `/tw-` prefix.
   ```

6. **Check if `CLAUDE.md` exists** in the repo root:
   - If it exists: append the following block to it (with a separator comment)
   - If it does not exist: create it with the following content

   ```markdown
   ## AI Toolkit (tw-ai-toolkit)

   This repo uses tw-ai-toolkit. On every session start:
   1. Read `.ai/AGENTS.md` for toolkit context
   2. Check `.ai/toolkit/context/CHECKPOINT.md` — if the git hash is stale, run `/tw-sync-context`
   3. Toolkit skills and agents use the `/tw-` prefix

   To see all available components: load `.ai/toolkit/registry.json`
   ```

7. **Copy the env example:**
   ```bash
   cp .ai/toolkit/config/.env.example .env.toolkit.example
   ```
   Tell the user: "Copy `.env.toolkit.example` to `.env` and fill in any credentials you need."

8. **Ask the user** if they want to configure Dependabot for automated update PRs.
   If yes, append to `.github/dependabot.yml` (create the file if needed):
   ```yaml
   - package-ecosystem: gitsubmodules
     directory: "/"
     schedule:
       interval: weekly
     labels:
       - dependencies
       - ai-toolkit
   ```

9. **Validate the installation** by checking these files exist:
   - `.ai/toolkit/AGENTS.md`
   - `.ai/toolkit/registry.json`
   - `.ai/config.json`
   - `.ai/AGENTS.md`

10. **Report success:**
    ```
    tw-ai-toolkit <version> installed successfully.

    Files created:
    - .ai/toolkit/          (submodule — pinned to <version>)
    - .ai/config.json
    - .ai/AGENTS.md
    - CLAUDE.md             (updated)
    - .env.toolkit.example  (copy to .env and fill credentials)

    Next steps:
    1. Fill in .env with any needed credentials
    2. Run: git commit -m "chore: add tw-ai-toolkit <version>"
    3. Ask me: "What toolkit components are available?"
    ```

## Examples

### Default install — latest version
```
/tw-install-toolkit
```

### Install specific version in another directory
```
/tw-install-toolkit repo_path="../my-other-repo" version="v1.2.0"
```

## Dependencies

- Requires `git` to be available
- Requires the consumer repo to already be a git repository

## Notes

- This skill does NOT commit for you — it stages the files and tells you the commit command.
- If the user already has a `CLAUDE.md`, the skill appends to it without overwriting.
- Running this skill twice on the same repo will detect the existing installation and stop.
