#!/usr/bin/env bash
# install.sh
# Installs tw-ai-toolkit as a git submodule in a consumer repository.
#
# Usage:
#   bash install.sh [OPTIONS]
#
# Options:
#   --version  <tag>   Toolkit version to install (default: latest stable tag)
#   --repo-path <dir>  Consumer repo root (default: current directory)
#   --no-claude-md     Skip CLAUDE.md update
#   --dependabot       Configure Dependabot for automated update PRs
#   --yes              Non-interactive: accept all defaults without prompting

set -euo pipefail

# ── Config ────────────────────────────────────────────────────────────────────

TOOLKIT_REPO="https://github.com/tw-qa/tw-ai-toolkit.git"
AI_DIR=".ai"
SUBMODULE_PATH="$AI_DIR/toolkit"

# ── Defaults ──────────────────────────────────────────────────────────────────

ARG_VERSION="latest"
ARG_REPO_PATH="."
ARG_NO_CLAUDE_MD=false
ARG_DEPENDABOT=false
ARG_YES=false

# ── Argument parsing ──────────────────────────────────────────────────────────

while [[ $# -gt 0 ]]; do
    case $1 in
        --version)      ARG_VERSION="$2";    shift 2 ;;
        --repo-path)    ARG_REPO_PATH="$2";  shift 2 ;;
        --no-claude-md) ARG_NO_CLAUDE_MD=true; shift ;;
        --dependabot)   ARG_DEPENDABOT=true; shift ;;
        --yes)          ARG_YES=true;        shift ;;
        *) echo "Unknown option: $1" >&2; echo "Run with --help for usage." >&2; exit 1 ;;
    esac
done

# ── Helpers ───────────────────────────────────────────────────────────────────

info()    { echo "  $*"; }
success() { echo "  [OK] $*"; }
warn()    { echo "  [!]  $*"; }
error()   { echo "  [ERR] $*" >&2; }
abort()   { error "$*"; exit 1; }

ask() {
    # ask <prompt> <default y|n>
    local prompt="$1" default="${2:-y}"
    if $ARG_YES; then
        [[ "$default" == "y" ]] && return 0 || return 1
    fi
    local answer
    read -r -p "  $prompt [${default^^}/$([ "$default" == "y" ] && echo n || echo Y)] " answer
    answer="${answer:-$default}"
    [[ "${answer,,}" == "y" ]]
}

# ── Prerequisites ─────────────────────────────────────────────────────────────

echo ""
echo "tw-ai-toolkit installer"
echo "────────────────────────"

command -v git >/dev/null 2>&1 || abort "git is not installed or not in PATH."

REPO_PATH="$(cd "$ARG_REPO_PATH" 2>/dev/null && pwd)" || abort "repo-path '$ARG_REPO_PATH' does not exist."

[[ -d "$REPO_PATH/.git" ]] || abort "'$REPO_PATH' is not a git repository."

# Check not already installed
if [[ -d "$REPO_PATH/$SUBMODULE_PATH" ]]; then
    CURRENT=$(cd "$REPO_PATH/$SUBMODULE_PATH" && git describe --tags 2>/dev/null || echo "unknown")
    warn "tw-ai-toolkit is already installed at '$SUBMODULE_PATH' (version: $CURRENT)."
    warn "To update, run: bash $SUBMODULE_PATH/scripts/update.sh"
    exit 0
fi

# ── Resolve version ───────────────────────────────────────────────────────────

if [[ "$ARG_VERSION" == "latest" ]]; then
    info "Resolving latest stable version..."
    RESOLVED_VERSION=$(git ls-remote --tags "$TOOLKIT_REPO" 2>/dev/null \
        | grep -oE 'refs/tags/v[0-9]+\.[0-9]+\.[0-9]+$' \
        | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' \
        | sort -V | tail -1)

    if [[ -z "$RESOLVED_VERSION" ]]; then
        abort "Could not resolve latest version. Check network access or use --version."
    fi
    info "Latest stable version: $RESOLVED_VERSION"
else
    RESOLVED_VERSION="$ARG_VERSION"
fi

echo ""
echo "  Repository: $TOOLKIT_REPO"
echo "  Version:    $RESOLVED_VERSION"
echo "  Target:     $REPO_PATH/$SUBMODULE_PATH"
echo ""

ask "Proceed with installation?" "y" || { info "Installation cancelled."; exit 0; }
echo ""

# ── Install submodule ─────────────────────────────────────────────────────────

info "Adding git submodule..."
cd "$REPO_PATH"

git submodule add "$TOOLKIT_REPO" "$SUBMODULE_PATH" 2>/dev/null \
    || abort "Failed to add submodule. Check git output above."

(cd "$SUBMODULE_PATH" && git checkout "$RESOLVED_VERSION" --quiet) \
    || abort "Version '$RESOLVED_VERSION' not found in toolkit repo."

git add ".gitmodules" "$SUBMODULE_PATH"
success "Submodule added and pinned to $RESOLVED_VERSION"

# ── Create .ai/ structure ─────────────────────────────────────────────────────

mkdir -p "$AI_DIR"

# config.json
cat > "$AI_DIR/config.json" << EOF
{
  "toolkit_version": "$RESOLVED_VERSION",
  "enabled_components": ["skills", "agents", "prompts", "rules", "hooks", "mcp_servers"],
  "disabled_skills": [],
  "local_overrides": true,
  "mcp_servers": [],
  "env_file": ".env",
  "update_strategy": "manual",
  "context_layer": {
    "auto_load_l2": false,
    "snapshot_ttl_hours": 24
  }
}
EOF
success "Created $AI_DIR/config.json"

# AGENTS.md pointer
REPO_NAME="$(basename "$REPO_PATH")"
cat > "$AI_DIR/AGENTS.md" << EOF
# AI Toolkit Context — $REPO_NAME

This repo uses tw-ai-toolkit $RESOLVED_VERSION.

## Load Toolkit Context

- Toolkit overview:       \`.ai/toolkit/AGENTS.md\`
- Available components:   \`.ai/toolkit/registry.json\`
- Context snapshot:       \`.ai/toolkit/context/snapshot.md\`
- Snapshot freshness:     \`.ai/toolkit/context/CHECKPOINT.md\`
- Local overrides:        \`.ai/skills/\`, \`.ai/agents/\`
- Local config:           \`.ai/config.json\`

## Conventions

All toolkit skills and agents use the \`/tw-\` prefix.
Local skills in this repo do not use a prefix.

## Quick Start

Run \`/tw-sync-context\` if snapshots seem stale.
Run \`/tw-onboard-repo\` for a guided setup tailored to this repo's stack.
EOF
success "Created $AI_DIR/AGENTS.md"

# ── Update CLAUDE.md ──────────────────────────────────────────────────────────

if ! $ARG_NO_CLAUDE_MD; then
    echo ""
    CLAUDE_FRAGMENT="## AI Toolkit (tw-ai-toolkit)

This repo uses tw-ai-toolkit $RESOLVED_VERSION. On every session:

**Context loading:**
1. Read \`.ai/AGENTS.md\` at session start
2. Check \`.ai/toolkit/context/CHECKPOINT.md\` — if git hash is stale, run \`/tw-sync-context\`
3. Load \`.ai/toolkit/registry.json\` for the component list (not directory scanning)

**Invocation:** Toolkit components use \`/tw-\` prefix. Local skills have no prefix.

**After editing components:** Run \`/tw-lint-component <path>\` then \`/tw-sync-context\`.

**Never edit manually:** \`registry.json\`, \`context/snapshot.md\`, \`context/snapshots/\`, \`context/CHECKPOINT.md\`"

    if [[ -f "CLAUDE.md" ]]; then
        if ask "CLAUDE.md exists — append toolkit fragment to it?" "y"; then
            printf "\n\n---\n\n%s\n" "$CLAUDE_FRAGMENT" >> "CLAUDE.md"
            success "Appended toolkit fragment to CLAUDE.md"
        fi
    else
        if ask "Create CLAUDE.md with toolkit fragment?" "y"; then
            printf "%s\n" "$CLAUDE_FRAGMENT" > "CLAUDE.md"
            success "Created CLAUDE.md"
        fi
    fi
fi

# ── Copy .env example ─────────────────────────────────────────────────────────

if [[ ! -f ".env.toolkit.example" ]]; then
    cp "$SUBMODULE_PATH/config/.env.example" ".env.toolkit.example"
    success "Created .env.toolkit.example (copy to .env and fill credentials)"
fi

# ── Dependabot (optional) ──────────────────────────────────────────────────────

if $ARG_DEPENDABOT || ask "Configure Dependabot for automated update PRs? (optional)" "n"; then
    mkdir -p ".github"
    DEPENDABOT_FILE=".github/dependabot.yml"

    if [[ -f "$DEPENDABOT_FILE" ]]; then
        # Append submodule entry
        cat >> "$DEPENDABOT_FILE" << 'EOF'
  - package-ecosystem: gitsubmodules
    directory: "/"
    schedule:
      interval: weekly
    labels:
      - dependencies
      - ai-toolkit
EOF
        success "Added submodule entry to $DEPENDABOT_FILE"
    else
        cat > "$DEPENDABOT_FILE" << 'EOF'
version: 2
updates:
  - package-ecosystem: gitsubmodules
    directory: "/"
    schedule:
      interval: weekly
    labels:
      - dependencies
      - ai-toolkit
EOF
        success "Created $DEPENDABOT_FILE"
    fi
fi

# ── Validate ──────────────────────────────────────────────────────────────────

echo ""
info "Validating installation..."

MISSING=()
[[ -f "$SUBMODULE_PATH/AGENTS.md" ]]   || MISSING+=("$SUBMODULE_PATH/AGENTS.md")
[[ -f "$SUBMODULE_PATH/registry.json" ]] || MISSING+=("$SUBMODULE_PATH/registry.json")
[[ -f "$AI_DIR/config.json" ]]          || MISSING+=("$AI_DIR/config.json")
[[ -f "$AI_DIR/AGENTS.md" ]]            || MISSING+=("$AI_DIR/AGENTS.md")

if [[ ${#MISSING[@]} -gt 0 ]]; then
    warn "Validation found missing files:"
    for f in "${MISSING[@]}"; do warn "  - $f"; done
else
    success "Installation validated — all expected files present"
fi

# ── Done ──────────────────────────────────────────────────────────────────────

echo ""
echo "────────────────────────"
echo "  tw-ai-toolkit $RESOLVED_VERSION installed."
echo ""
echo "  Files created:"
echo "    $SUBMODULE_PATH/    (submodule, pinned to $RESOLVED_VERSION)"
echo "    $AI_DIR/config.json"
echo "    $AI_DIR/AGENTS.md"
[[ -f ".env.toolkit.example" ]] && echo "    .env.toolkit.example"
echo ""
echo "  Next steps:"
echo "    1. Fill in .env with any needed credentials (see .env.toolkit.example)"
echo "    2. git add .ai/ CLAUDE.md && git commit -m \"chore: add tw-ai-toolkit $RESOLVED_VERSION\""
echo "    3. Open Claude Code and ask: \"What toolkit components are available?\""
echo ""
