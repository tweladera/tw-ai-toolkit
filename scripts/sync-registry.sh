#!/usr/bin/env bash
# sync-registry.sh
# Scans all component directories and regenerates registry.json
# Run manually or triggered by the pre-commit git hook.

set -euo pipefail

TOOLKIT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$TOOLKIT_ROOT"

echo "[tw-ai-toolkit] Syncing registry..."

python3 - "$TOOLKIT_ROOT" << 'PYTHON'
import sys, os, re, json, subprocess
from datetime import date

TOOLKIT_ROOT = sys.argv[1]

COMPONENT_TYPES = {
    "skills":      ("skills",  "skill.md",  "/tw-{name}"),
    "agents":      ("agents",  "agent.md",  "/tw-{name}"),
    "prompts":     ("prompts", "prompt.md", None),
    "rules":       ("rules",   "rule.md",   None),
    "hooks":       ("hooks",   "hook.md",   None),
    "mcp_servers": ("mcp",     "server.md", None),
}

def parse_frontmatter(content):
    """Parse simple YAML frontmatter from a markdown file (no external deps)."""
    match = re.match(r'^---\s*\n(.*?)\n---', content, re.DOTALL)
    if not match:
        return {}
    return _parse_yaml_subset(match.group(1))

def _parse_yaml_subset(text):
    """Handle strings, flat dicts, and lists of dicts — our schema subset only."""
    result = {}
    lines = text.split('\n')
    i = 0

    while i < len(lines):
        line = lines[i]
        if not line.strip():
            i += 1
            continue

        m = re.match(r'^([a-z_]+):\s*(.*)', line)
        if not m:
            i += 1
            continue

        key, val = m.group(1), m.group(2).strip()

        if val:
            result[key] = val
            i += 1
            continue

        # No inline value — look ahead for nested content
        i += 1
        child_list = []
        child_dict = {}
        is_list = False
        current_item = None

        while i < len(lines):
            child = lines[i]
            stripped = child.strip()

            if stripped and not child[0] in (' ', '\t'):
                break  # back to top level

            if not stripped:
                i += 1
                continue

            li = re.match(r'^  - (.*)', child)   # 2-space list item
            di = re.match(r'^  ([a-z_]+):\s*(.*)', child)   # 2-space dict
            si = re.match(r'^    ([a-z_]+):\s*(.*)', child)  # 4-space (list item continuation)

            if li:
                is_list = True
                item_text = li.group(1).strip()
                if ':' in item_text:
                    sk, sv = item_text.split(':', 1)
                    current_item = {sk.strip(): sv.strip()}
                else:
                    current_item = item_text
                child_list.append(current_item)
                i += 1
            elif si and is_list and isinstance(current_item, dict):
                current_item[si.group(1)] = si.group(2).strip()
                i += 1
            elif di and not is_list:
                child_dict[di.group(1)] = di.group(2).strip()
                i += 1
            else:
                i += 1

        if is_list:
            result[key] = child_list
        elif child_dict:
            result[key] = child_dict

    return result

def scan_components():
    components = {k: [] for k in COMPONENT_TYPES}

    for comp_type, (folder, deffile, invocation_tpl) in COMPONENT_TYPES.items():
        folder_path = os.path.join(TOOLKIT_ROOT, folder)
        if not os.path.isdir(folder_path):
            continue

        for entry in sorted(os.listdir(folder_path)):
            if entry.startswith('_') or entry.startswith('.'):
                continue
            comp_dir = os.path.join(folder_path, entry)
            if not os.path.isdir(comp_dir):
                continue

            def_path = os.path.join(comp_dir, deffile)
            if not os.path.exists(def_path):
                print(f"  SKIP: {def_path} not found", file=sys.stderr)
                continue

            with open(def_path) as f:
                content = f.read()

            fm = parse_frontmatter(content)
            if not fm:
                print(f"  WARNING: No frontmatter in {def_path}", file=sys.stderr)
                continue

            name = fm.get('name', entry)
            comp = {
                "name": name,
                "description": fm.get('description', ''),
                "path": os.path.relpath(def_path, TOOLKIT_ROOT),
                "status": fm.get('status', 'stable'),
                "compatible_with": fm.get('compatible_with', {
                    "claude_code": "full",
                    "cursor": "none",
                    "codex": "none"
                }),
            }

            if invocation_tpl:
                comp["invocation"] = invocation_tpl.format(name=name)

            for opt_field in ('version_added', 'deprecated_since', 'removed_in', 'replacement'):
                if opt_field in fm:
                    comp[opt_field] = fm[opt_field]

            if 'parameters' in fm:
                comp['parameters'] = fm['parameters']

            if 'tags' in fm:
                comp['tags'] = fm['tags'] if isinstance(fm['tags'], list) else [fm['tags']]

            components[comp_type].append(comp)
            print(f"  + {comp_type}/{name}")

    return components

# Load existing registry to preserve non-scanned fields
registry_path = os.path.join(TOOLKIT_ROOT, 'registry.json')
with open(registry_path) as f:
    registry = json.load(f)

registry['components'] = scan_components()
registry['last_updated'] = str(date.today())

try:
    git_hash = subprocess.check_output(
        ['git', 'rev-parse', '--short', 'HEAD'],
        cwd=TOOLKIT_ROOT, stderr=subprocess.DEVNULL
    ).decode().strip()
    registry['git_hash'] = git_hash
except Exception:
    pass

with open(registry_path, 'w') as f:
    json.dump(registry, f, indent=2)
    f.write('\n')

total = sum(len(v) for v in registry['components'].values())
print(f"[tw-ai-toolkit] Registry updated: {total} components indexed.")
PYTHON
