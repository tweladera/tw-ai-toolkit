#!/usr/bin/env bash
# install-git-hooks.sh
# Installs tw-ai-toolkit git hooks into .git/hooks/
# Run once after cloning the toolkit repo.

set -euo pipefail

TOOLKIT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOOKS_SRC="$TOOLKIT_ROOT/scripts/git-hooks"
HOOKS_DST="$TOOLKIT_ROOT/.git/hooks"

if [ ! -d "$HOOKS_DST" ]; then
    echo "ERROR: .git/hooks directory not found. Are you inside the tw-ai-toolkit repo?" >&2
    exit 1
fi

for hook_file in "$HOOKS_SRC"/*; do
    hook_name="$(basename "$hook_file")"
    dst="$HOOKS_DST/$hook_name"

    if [ -f "$dst" ] && [ ! -L "$dst" ]; then
        echo "  SKIP: $hook_name already exists in .git/hooks (not a symlink — manual install present)"
        continue
    fi

    ln -sf "$hook_file" "$dst"
    chmod +x "$hook_file"
    echo "  Installed: $hook_name → $dst"
done

echo ""
echo "Git hooks installed. The pre-commit hook will now auto-sync context"
echo "whenever you commit changes to component files (skills/, agents/, etc.)."
