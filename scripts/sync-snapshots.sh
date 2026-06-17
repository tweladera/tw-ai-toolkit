#!/usr/bin/env bash
# sync-snapshots.sh
# Reads registry.json and regenerates L2/L3 context snapshots + CHECKPOINT.md
# Run after sync-registry.sh, or triggered by the pre-commit git hook.

set -euo pipefail

TOOLKIT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$TOOLKIT_ROOT"

echo "[tw-ai-toolkit] Syncing snapshots..."

python3 - "$TOOLKIT_ROOT" << 'PYTHON'
import sys, os, json, subprocess
from datetime import datetime, timezone

TOOLKIT_ROOT = sys.argv[1]

TYPE_META = {
    "skills":      "Skills",
    "agents":      "Agents",
    "prompts":     "Prompts",
    "rules":       "Rules",
    "hooks":       "Hooks",
    "mcp_servers": "MCP Servers",
}

L3_FILENAMES = {
    "skills":      "skills.snapshot.md",
    "agents":      "agents.snapshot.md",
    "prompts":     "prompts.snapshot.md",
    "rules":       "rules.snapshot.md",
    "hooks":       "hooks.snapshot.md",
    "mcp_servers": "mcp.snapshot.md",
}

# Load registry
with open(os.path.join(TOOLKIT_ROOT, 'registry.json')) as f:
    registry = json.load(f)

components = registry.get('components', {})
now = datetime.now(timezone.utc).strftime('%Y-%m-%d %H:%M UTC')
version = registry.get('version', '—')

try:
    git_hash = subprocess.check_output(
        ['git', 'rev-parse', 'HEAD'], cwd=TOOLKIT_ROOT, stderr=subprocess.DEVNULL
    ).decode().strip()
    git_hash_short = git_hash[:8]
except Exception:
    git_hash = git_hash_short = 'unknown'

def status_counts(items):
    counts = {'stable': 0, 'deprecated': 0, 'experimental': 0}
    for item in items:
        counts[item.get('status', 'stable')] = counts.get(item.get('status', 'stable'), 0) + 1
    return counts

def compat(comp, assistant):
    level = comp.get('compatible_with', {}).get(assistant, 'none')
    return {'full': 'yes', 'partial': 'partial', 'none': 'no'}.get(level, '—')

# ── L2: context/snapshot.md ──────────────────────────────────────────────────

total_all = sum(len(components.get(k, [])) for k in TYPE_META)

lines = [
    "# Toolkit Snapshot (L2)",
    "",
    f"> Auto-generated on {now}. Do not edit manually.",
    "> Check `context/CHECKPOINT.md` for freshness info before relying on this data.",
    "",
    "---",
    "",
    "## Summary",
    "",
    "| Type | Total | Stable | Deprecated | Experimental |",
    "|---|---|---|---|---|",
]

for type_key, label in TYPE_META.items():
    items = components.get(type_key, [])
    counts = status_counts(items)
    lines.append(
        f"| {label} | {len(items)} "
        f"| {counts.get('stable', 0)} "
        f"| {counts.get('deprecated', 0)} "
        f"| {counts.get('experimental', 0)} |"
    )

lines += ["", "---", ""]

for type_key, label in TYPE_META.items():
    items = components.get(type_key, [])
    lines.append(f"## {label}")
    lines.append("")

    if not items:
        lines.append("*(none yet)*")
    else:
        lines.append("| Name | Invocation | Description | Status | Claude Code | Cursor | Codex |")
        lines.append("|---|---|---|---|---|---|---|")
        for comp in items:
            inv = f"`{comp['invocation']}`" if comp.get('invocation') else "—"
            lines.append(
                f"| {comp['name']} | {inv} | {comp.get('description', '—')} "
                f"| {comp.get('status', 'stable')} "
                f"| {compat(comp, 'claude_code')} "
                f"| {compat(comp, 'cursor')} "
                f"| {compat(comp, 'codex')} |"
            )
    lines.append("")

lines += [
    "---",
    "",
    "For full metadata (parameters, tags), load `registry.json`.",
    "For per-category detail, load `context/snapshots/<type>.snapshot.md`.",
]

with open(os.path.join(TOOLKIT_ROOT, 'context', 'snapshot.md'), 'w') as f:
    f.write('\n'.join(lines) + '\n')

print(f"  L2: context/snapshot.md written")

# ── L3: context/snapshots/<type>.snapshot.md ─────────────────────────────────

snapshots_dir = os.path.join(TOOLKIT_ROOT, 'context', 'snapshots')
os.makedirs(snapshots_dir, exist_ok=True)

for type_key, label in TYPE_META.items():
    items = components.get(type_key, [])
    fname = L3_FILENAMES[type_key]

    slines = [
        f"# {label} Snapshot (L3)",
        "",
        f"> Auto-generated on {now}. Do not edit manually.",
        f"> For a quick overview of all types, load `context/snapshot.md` (L2).",
        "",
        "---",
        "",
    ]

    if not items:
        slines.append(f"No {label.lower()} defined yet. See `docs/contributing.md` to add one.")
    else:
        for comp in items:
            slines.append(f"## {comp['name']}")
            slines.append("")

            status = comp.get('status', 'stable')
            if status != 'stable':
                slines.append(f"> **Status:** {status.upper()}")
                if comp.get('replacement'):
                    slines.append(f"> **Replacement:** `{comp['replacement']}`")
                if comp.get('removed_in'):
                    slines.append(f"> **Removed in:** {comp['removed_in']}")
                if comp.get('deprecated_since'):
                    slines.append(f"> **Deprecated since:** {comp['deprecated_since']}")
                slines.append("")

            slines.append(f"**Description:** {comp.get('description', '—')}")
            slines.append("")

            if comp.get('invocation'):
                slines.append(f"**Invocation:** `{comp['invocation']}`")
                slines.append("")

            compat_map = comp.get('compatible_with', {})
            slines.append(
                f"**Compatibility:** "
                f"Claude Code: `{compat_map.get('claude_code', '—')}` | "
                f"Cursor: `{compat_map.get('cursor', '—')}` | "
                f"Codex: `{compat_map.get('codex', '—')}`"
            )
            slines.append("")

            params = comp.get('parameters', [])
            if params:
                slines.append("**Parameters:**")
                slines.append("")
                slines.append("| Name | Type | Required | Default | Description |")
                slines.append("|---|---|---|---|---|")
                for p in params:
                    if isinstance(p, dict):
                        slines.append(
                            f"| `{p.get('name','—')}` "
                            f"| {p.get('type','—')} "
                            f"| {p.get('required','—')} "
                            f"| {p.get('default','—')} "
                            f"| {p.get('description','—')} |"
                        )
                slines.append("")

            tags = comp.get('tags', [])
            if tags:
                slines.append(f"**Tags:** {', '.join(f'`{t}`' for t in tags)}")
                slines.append("")

            if comp.get('version_added'):
                slines.append(f"**Added in:** {comp['version_added']}")
                slines.append("")

            slines.append(f"**Definition file:** `{comp.get('path', '—')}`")
            slines.append("")
            slines.append("---")
            slines.append("")

    with open(os.path.join(snapshots_dir, fname), 'w') as f:
        f.write('\n'.join(slines) + '\n')

    print(f"  L3: context/snapshots/{fname} written ({len(items)} items)")

# ── Per-assistant snapshots (L3+) ─────────────────────────────────────────────

ASSISTANTS = {
    "cursor": ("Cursor", "partial"),   # include full + partial
    "codex":  ("Codex",  "full"),      # include full only
}

all_components = []
for type_key, label in TYPE_META.items():
    for comp in components.get(type_key, []):
        comp["_type"] = label
        all_components.append(comp)

for assistant_key, (assistant_label, min_level) in ASSISTANTS.items():
    levels = {"full"} if min_level == "full" else {"full", "partial"}

    def is_compat(comp):
        compat = comp.get("compatible_with", {})
        if isinstance(compat, dict):
            return compat.get(assistant_key, "none") in levels
        # Rules use 'target' field instead of compatible_with
        target = comp.get("target", [])
        if isinstance(target, str):
            target = [target]
        return assistant_key in target

    compat_comps = [c for c in all_components if is_compat(c)]
    fname = f"{assistant_key}.snapshot.md"

    alines = [
        f"# {assistant_label} Compatibility Snapshot (L3+)",
        "",
        f"> Auto-generated on {now}. Do not edit manually.",
        f"> Shows only components with `compatible_with.{assistant_key}: full` or `partial`.",
        f"> For full compatibility details see `docs/compatibility-matrix.md`.",
        "",
        "---",
        "",
    ]

    if not compat_comps:
        alines.append(f"No components currently support {assistant_label}.")
    else:
        alines.append(f"## Available for {assistant_label} ({len(compat_comps)} components)")
        alines.append("")
        alines.append(f"| Name | Type | Invocation | Compatibility | Description |")
        alines.append("|---|---|---|---|---|")
        for comp in compat_comps:
            compat_map = comp.get("compatible_with", {})
            level = compat_map.get(assistant_key, "—") if isinstance(compat_map, dict) else "—"
            inv = f"`{comp['invocation']}`" if comp.get("invocation") else "—"
            alines.append(
                f"| {comp['name']} | {comp.get('_type','—')} | {inv} | {level} | {comp.get('description','—')} |"
            )
        alines.append("")

        if assistant_key == "cursor":
            alines += [
                "## Cursor Quick Start",
                "",
                "1. Copy `rules/cursor-base/fragment.md` into your `.cursorrules`",
                "2. Configure MCP servers in `.cursor/mcp.json` (see `docs/mcp-guide.md`)",
                "3. Use Cursor Composer for skills and agents",
                "4. For component details, read `context/snapshots/<type>.snapshot.md`",
            ]
        elif assistant_key == "codex":
            alines += [
                "## Codex Quick Start",
                "",
                "Codex supports prompts and rules only. For each skill you want to use:",
                "1. Open the `skill.md` for that component",
                "2. Copy the `## Instructions` section",
                "3. Paste it as a prompt in Copilot Chat with your context",
                "",
                "For rules, copy the relevant rule content into `.github/copilot-instructions.md`.",
            ]

    with open(os.path.join(snapshots_dir, fname), 'w') as f:
        f.write('\n'.join(alines) + '\n')

    print(f"  L3+: context/snapshots/{fname} written ({len(compat_comps)} compatible items)")

# ── CHECKPOINT.md ─────────────────────────────────────────────────────────────

checkpoint = [
    "# Context Checkpoint",
    "",
    "This file tracks the freshness of the Context Layer System snapshots.",
    "AI models should check this file before relying on L2/L3 snapshots.",
    "",
    "## Current Snapshot State",
    "",
    "| Field | Value |",
    "|---|---|",
    f"| **Last sync** | {now} |",
    f"| **Git hash at sync** | `{git_hash_short}` |",
    f"| **Toolkit version** | {version} |",
    f"| **Components indexed** | {total_all} |",
    "| **Snapshot files** | `context/snapshot.md`, `context/snapshots/` |",
    "",
    "## How to Check Freshness",
    "",
    "Run in the toolkit repo root:",
    "```bash",
    "git rev-parse --short HEAD",
    "```",
    "",
    f"If the result does not match `{git_hash_short}`, snapshots are stale. Regenerate:",
    "```bash",
    "bash scripts/sync-registry.sh && bash scripts/sync-snapshots.sh",
    "```",
    "",
    "Or use the skill once available:",
    "```",
    "/tw-sync-context",
    "```",
    "",
    "## Auto-sync",
    "",
    "The pre-commit git hook in this repo regenerates snapshots automatically",
    "whenever component files are staged. Install it once with:",
    "```bash",
    "bash scripts/install-git-hooks.sh",
    "```",
]

with open(os.path.join(TOOLKIT_ROOT, 'context', 'CHECKPOINT.md'), 'w') as f:
    f.write('\n'.join(checkpoint) + '\n')

print(f"  CHECKPOINT.md updated (hash: {git_hash_short}, {total_all} components)")
PYTHON
