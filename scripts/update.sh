#!/usr/bin/env bash
# update.sh
# Updates tw-ai-toolkit to a specified version in a consumer repository.
#
# Usage (run from the consumer repo root):
#   bash .ai/toolkit/scripts/update.sh [OPTIONS]
#
# Options:
#   --version <tag>   Target version (e.g. v1.2.0). Defaults to interactive selection.
#   --yes             Non-interactive: accept defaults without prompting

set -euo pipefail

# ── Helpers ───────────────────────────────────────────────────────────────────

info()    { echo "  $*"; }
success() { echo "  [OK] $*"; }
warn()    { echo "  [!]  $*"; }
error()   { echo "  [ERR] $*" >&2; }
abort()   { error "$*"; exit 1; }

ask() {
    local prompt="$1" default="${2:-y}"
    if $ARG_YES; then [[ "$default" == "y" ]] && return 0 || return 1; fi
    local answer
    read -r -p "  $prompt [${default^^}/$([ "$default" == "y" ] && echo n || echo Y)] " answer
    answer="${answer:-$default}"
    [[ "${answer,,}" == "y" ]]
}

semver_major() { echo "$1" | grep -oE '^v?[0-9]+' | tr -d 'v'; }

# ── Argument parsing ──────────────────────────────────────────────────────────

ARG_VERSION=""
ARG_YES=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --version) ARG_VERSION="$2"; shift 2 ;;
        --yes)     ARG_YES=true;     shift ;;
        *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
done

# ── Locate submodule ──────────────────────────────────────────────────────────

echo ""
echo "tw-ai-toolkit updater"
echo "──────────────────────"

# Detect consumer repo root (script is inside .ai/toolkit/scripts/)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLKIT_ROOT="$SCRIPT_DIR/.."
CONSUMER_ROOT="$SCRIPT_DIR/../../.."

# Validate this is a submodule context
[[ -f "$TOOLKIT_ROOT/registry.json" ]] || abort "Cannot find toolkit root. Run this script from the consumer repo."
[[ -d "$CONSUMER_ROOT/.git" ]]         || abort "Consumer repo root not found. Are you inside a git repository?"

cd "$CONSUMER_ROOT"

# ── Current version ───────────────────────────────────────────────────────────

CURRENT_VERSION=$(cd "$TOOLKIT_ROOT" && git describe --tags --exact-match 2>/dev/null || echo "untagged")
CURRENT_HASH=$(cd "$TOOLKIT_ROOT" && git rev-parse --short HEAD)
TOOLKIT_REPO=$(cd "$TOOLKIT_ROOT" && git remote get-url origin 2>/dev/null || echo "unknown")

info "Submodule path: .ai/toolkit"
info "Current version: $CURRENT_VERSION ($CURRENT_HASH)"
info "Remote: $TOOLKIT_REPO"
echo ""

# ── Resolve available versions ────────────────────────────────────────────────

info "Fetching available versions..."
AVAILABLE=$(git ls-remote --tags "$TOOLKIT_REPO" 2>/dev/null \
    | grep -oE 'refs/tags/v[0-9]+\.[0-9]+\.[0-9]+$' \
    | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' \
    | sort -V) || abort "Could not fetch versions. Check network access."

LATEST=$(echo "$AVAILABLE" | tail -1)

if [[ -z "$ARG_VERSION" ]]; then
    echo "  Available versions (newest last):"
    echo "$AVAILABLE" | tail -10 | while read -r v; do
        if [[ "$v" == "$CURRENT_VERSION" ]]; then
            echo "    $v  ← current"
        elif [[ "$v" == "$LATEST" ]]; then
            echo "    $v  ← latest"
        else
            echo "    $v"
        fi
    done
    echo ""
    read -r -p "  Target version (default: $LATEST): " USER_VERSION
    TARGET_VERSION="${USER_VERSION:-$LATEST}"
else
    TARGET_VERSION="$ARG_VERSION"
fi

# Validate target exists
echo "$AVAILABLE" | grep -qx "$TARGET_VERSION" \
    || abort "Version '$TARGET_VERSION' not found. Run without --version to see available versions."

# ── Already up to date? ───────────────────────────────────────────────────────

if [[ "$TARGET_VERSION" == "$CURRENT_VERSION" ]]; then
    info "Already on $TARGET_VERSION — nothing to do."
    exit 0
fi

# ── Breaking change warning ───────────────────────────────────────────────────

CURRENT_MAJOR=$(semver_major "$CURRENT_VERSION")
TARGET_MAJOR=$(semver_major "$TARGET_VERSION")

echo ""
if [[ "$TARGET_MAJOR" -gt "$CURRENT_MAJOR" ]]; then
    warn "MAJOR VERSION BUMP: $CURRENT_VERSION → $TARGET_VERSION"
    warn "This may include breaking changes. Review the changelog before proceeding:"
    warn "$TOOLKIT_REPO/blob/main/CHANGELOG.md"
    echo ""
    ask "Proceed with major version update?" "n" || { info "Update cancelled."; exit 0; }
else
    info "Updating: $CURRENT_VERSION → $TARGET_VERSION"
    ask "Proceed?" "y" || { info "Update cancelled."; exit 0; }
fi

echo ""

# ── Perform update ────────────────────────────────────────────────────────────

info "Fetching toolkit..."
(cd ".ai/toolkit" && git fetch --tags --quiet)

info "Checking out $TARGET_VERSION..."
(cd ".ai/toolkit" && git checkout "$TARGET_VERSION" --quiet) \
    || abort "Failed to checkout $TARGET_VERSION"

git add ".ai/toolkit"
success "Submodule updated to $TARGET_VERSION"

# Update version in .ai/config.json if it exists
if [[ -f ".ai/config.json" ]] && command -v python3 >/dev/null 2>&1; then
    python3 - "$TARGET_VERSION" << 'PYTHON'
import sys, json

version = sys.argv[1]
config_path = ".ai/config.json"

with open(config_path) as f:
    config = json.load(f)

config["toolkit_version"] = version

with open(config_path, "w") as f:
    json.dump(config, f, indent=2)
    f.write("\n")
PYTHON
    success "Updated toolkit_version in .ai/config.json"
fi

# ── Regenerate snapshots ──────────────────────────────────────────────────────

info "Regenerating context snapshots..."
bash ".ai/toolkit/scripts/sync-registry.sh" \
    && bash ".ai/toolkit/scripts/sync-snapshots.sh" \
    && success "Context snapshots updated"

# ── Done ─────────────────────────────────────────────────────────────────────

echo ""
echo "──────────────────────"
echo "  Updated: $CURRENT_VERSION → $TARGET_VERSION"
echo ""
echo "  Next steps:"
echo "    1. Review CHANGELOG for $CURRENT_VERSION → $TARGET_VERSION migrations (if any)"
echo "    2. git add .ai/ && git commit -m \"chore: update tw-ai-toolkit to $TARGET_VERSION\""
echo ""
