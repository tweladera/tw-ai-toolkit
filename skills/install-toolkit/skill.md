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
invocation: tw-install-toolkit
---

# install-toolkit

## Description

Walks the user through installing tw-ai-toolkit locally in a consumer repo.
The toolkit is installed via `--local` symlink — nothing is committed or pushed to the
consumer repo's remote. Creates the `.ai/` folder structure, sets up `AGENTS.md` and
`CLAUDE.md`, links all skills, and validates the installation at the end.

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
   - The toolkit is cloned somewhere on the machine (ask the user for the path, default `~/tw-ai-toolkit`)
   If any check fails, report the issue clearly and stop.

2. **Clone the toolkit if not present.** If the toolkit path does not exist:
   ```bash
   git clone https://github.com/tweladera/tw-ai-toolkit.git ~/tw-ai-toolkit
   ```

3. **Install the toolkit locally** (nothing committed to the consumer repo):
   ```bash
   cd <repo_path>
   python3 ~/tw-ai-toolkit/scripts/install.py --local ~/tw-ai-toolkit
   ```
   This creates `.ai/toolkit/` as a symlink, generates `.ai/AGENTS.md`, `.ai/config.json`,
   and `CLAUDE.md`, and adds all of them to `.gitignore`.

4. **Link all skills:**
   ```bash
   python3 .ai/toolkit/scripts/install.py --link-all
   ```
   This creates symlinks in `.claude/skills/`, `.cursor/skills/`, `.claude/rules/`, and
   `.cursor/rules/`. All added to `.gitignore` automatically.

5. **Copy the env example:**
   ```bash
   cp .ai/toolkit/.env.example .env
   ```
   Tell the user: "Edit `.env` and fill in the credentials for the MCP integrations you need.
   Never commit `.env` — it is already in `.gitignore`."

6. **Validate the installation:**
   ```bash
   python3 .ai/toolkit/scripts/install.py --verify
   ```

7. **Validate the installation** by checking these files exist:
   - `.ai/toolkit/AGENTS.md`
   - `.ai/toolkit/registry.json`
   - `.ai/AGENTS.md`
   - `CLAUDE.md`

8. **Report success:**
    ```
    tw-ai-toolkit installed successfully (local-only — nothing pushed to remote).

    Files created (all gitignored):
    - .ai/toolkit/          (symlink to ~/tw-ai-toolkit)
    - .ai/AGENTS.md
    - CLAUDE.md             (updated)
    - .env                  (fill in your MCP credentials)

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
