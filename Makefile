# Makefile — tw-ai-toolkit
#
# Useful commands for toolkit contributors.
# Run from the repo root: make <target>
#
# Prerequisites:
#   pip install pyyaml   (for sync and validate)

.PHONY: help sync validate test check-env new-skill link-claude link-cursor link-all verify

# ─────────────────────────────────────────────
# Default: show help
# ─────────────────────────────────────────────

help:
	@echo ""
	@echo "tw-ai-toolkit — available commands"
	@echo "────────────────────────────────────"
	@echo "  make sync         Regenerate registry.json and context snapshots"
	@echo "  make validate     Validate the catalog (--strict)"
	@echo "  make test         Run the test suite"
	@echo "  make check-env    Check system dependencies"
	@echo ""
	@echo "  make link-claude  Create symlinks in .claude/skills/ (local dev)"
	@echo "  make link-cursor  Create symlinks in .cursor/skills/ (local dev)"
	@echo "  make link-all     Create symlinks for all tools"
	@echo "  make verify       Verify installation and symlinks"
	@echo ""
	@echo "  make new-skill    Print step-by-step guide to create a skill"
	@echo ""

# ─────────────────────────────────────────────
# Catalog sync
# ─────────────────────────────────────────────

sync:
	@echo "-> Syncing registry.json..."
	python3 scripts/sync_registry.py
	@echo "-> Generating context snapshots..."
	bash scripts/sync-snapshots.sh
	@echo "Sync complete"

validate:
	@echo "-> Validating catalog with --strict..."
	python3 scripts/validate.py --strict

# Shortcut: sync + validate in a single command
ci: sync validate

# ─────────────────────────────────────────────
# Tests
# ─────────────────────────────────────────────

test:
	@echo "-> Running test suite..."
	python3 -m pytest tests/

# ─────────────────────────────────────────────
# Installation / linking (local development in this repo)
# ─────────────────────────────────────────────

link-claude:
	python3 scripts/install.py --local . --target .ai/toolkit 2>/dev/null || true
	python3 .ai/toolkit/scripts/install.py --link-claude

link-cursor:
	python3 scripts/install.py --local . --target .ai/toolkit 2>/dev/null || true
	python3 .ai/toolkit/scripts/install.py --link-cursor

link-all:
	python3 scripts/install.py --local . --target .ai/toolkit 2>/dev/null || true
	python3 .ai/toolkit/scripts/install.py --link-all

verify:
	python3 scripts/install.py --verify 2>/dev/null || python3 .ai/toolkit/scripts/install.py --verify

# ─────────────────────────────────────────────
# Help for creating a new component
# ─────────────────────────────────────────────

new-skill:
	@echo ""
	@echo "Steps to create a new skill:"
	@echo "────────────────────────────────────────────────────────────────────"
	@echo "  1. mkdir skills/<skill-name>"
	@echo "  2. Create skills/<skill-name>/skill.md  (see docs/contributing.md)"
	@echo "  3. Create skills/<skill-name>/README.md (1-screen summary)"
	@echo "  4. make sync"
	@echo "  5. make validate"
	@echo "  6. git add skills/<skill-name>/ registry.json context/"
	@echo "  7. git commit -m 'feat: add <skill-name> skill'"
	@echo ""
	@echo "  Or: invoke /tw-scaffold-component in Claude Code for guided creation."
	@echo ""

# ─────────────────────────────────────────────
# Check system dependencies
# ─────────────────────────────────────────────

check-env:
	@echo "-> Checking dependencies..."
	@python3 --version 2>/dev/null && echo "  python3" || echo "  python3 not found"
	@python3 -c "import yaml" 2>/dev/null && echo "  pyyaml" || echo "  pyyaml not installed (pip install pyyaml)"
	@python3 -m pytest --version 2>/dev/null && echo "  pytest" || echo "  pytest not installed (pip install pytest)"
	@command -v gitleaks >/dev/null 2>&1 && echo "  gitleaks" || echo "  gitleaks not installed (brew install gitleaks) — only required for security scanning"
	@echo "Check complete"
