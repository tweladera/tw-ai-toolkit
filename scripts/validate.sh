#!/usr/bin/env bash
# validate.sh
# Runs all automated checks on toolkit components.
# Used by CI and locally before opening a PR.
#
# Usage: bash scripts/validate.sh [--strict]
#   --strict  Treat warnings as errors (exits 1 on any warning)

set -euo pipefail

TOOLKIT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STRICT=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --strict) STRICT=true; shift ;;
        *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
done

cd "$TOOLKIT_ROOT"

echo "[tw-ai-toolkit] Validating..."
echo ""

python3 - "$TOOLKIT_ROOT" "$STRICT" << 'PYTHON'
import sys, os, re, json, subprocess
from datetime import datetime

TOOLKIT_ROOT = sys.argv[1]
STRICT = sys.argv[2].lower() == "true"

COMPONENT_TYPES = {
    "skills":      "skill.md",
    "agents":      "agent.md",
    "prompts":     "prompt.md",
    "rules":       "rule.md",
    "hooks":       "hook.md",
    "mcp_servers": "server.md",  # folder is mcp/
}
TYPE_TO_FOLDER = {
    "skills": "skills", "agents": "agents", "prompts": "prompts",
    "rules": "rules", "hooks": "hooks", "mcp_servers": "mcp",
}

REQUIRED_SECTIONS = {
    "skill.md":  ["## Description", "## When to Use", "## Instructions", "## Examples"],
    "agent.md":  ["## Description", "## Trigger", "## Skills Used", "## Flow", "## Outputs"],
    "prompt.md": ["## Description", "## Parameters", "## Template", "## Example"],
    "rule.md":   ["## Description", "## Applies To", "## Rule Content"],
    "hook.md":   ["## Description", "## Event", "## Action", "## Configuration"],
    "server.md": ["## Description", "## Tools Exposed", "## Authentication", "## Setup"],
}

PLACEHOLDER_PATTERNS = [
    r"example-skill", r"example-agent", r"example-prompt",
    r"example-rule", r"example-hook", r"example-server",
    r"One sentence describing",
    r"\[REPLACE:",
    r"\[REQUIRED\]",
]

errors = []
warnings = []
checked = 0

def err(path, msg):
    errors.append(f"  ERROR   {path}: {msg}")

def warn(path, msg):
    warnings.append(f"  WARN    {path}: {msg}")

def parse_frontmatter(content):
    match = re.match(r'^---\s*\n(.*?)\n---', content, re.DOTALL)
    if not match:
        return {}
    return _parse_yaml(match.group(1))

def _parse_yaml(text):
    result = {}
    lines = text.split('\n')
    i = 0
    while i < len(lines):
        line = lines[i]
        if not line.strip():
            i += 1; continue
        m = re.match(r'^([a-z_]+):\s*(.*)', line)
        if not m:
            i += 1; continue
        key, val = m.group(1), m.group(2).strip()
        if val:
            result[key] = val
            i += 1; continue
        i += 1
        child_list, child_dict, is_list, cur = [], {}, False, None
        while i < len(lines):
            child = lines[i]
            if child.strip() and not child[0] in (' ', '\t'):
                break
            if not child.strip():
                i += 1; continue
            li = re.match(r'^  - (.*)', child)
            di = re.match(r'^  ([a-z_]+):\s*(.*)', child)
            si = re.match(r'^    ([a-z_]+):\s*(.*)', child)
            if li:
                is_list = True
                item = li.group(1).strip()
                cur = {item.split(':')[0].strip(): item.split(':',1)[1].strip()} if ':' in item else item
                child_list.append(cur)
            elif si and is_list and isinstance(cur, dict):
                cur[si.group(1)] = si.group(2).strip()
            elif di and not is_list:
                child_dict[di.group(1)] = di.group(2).strip()
            i += 1
        if is_list:
            result[key] = child_list
        elif child_dict:
            result[key] = child_dict
    return result

# ── Check 1: Registry sync ────────────────────────────────────────────────────

print("  Syncing registry...", end=" ", flush=True)
try:
    result = subprocess.run(
        ["bash", "scripts/sync-registry.sh"],
        cwd=TOOLKIT_ROOT, capture_output=True, text=True
    )
    if result.returncode != 0:
        errors.append("  ERROR   registry: sync-registry.sh failed\n" + result.stderr)
        print("FAIL")
    else:
        # Check for drift
        diff = subprocess.run(
            ["git", "diff", "--name-only", "registry.json"],
            cwd=TOOLKIT_ROOT, capture_output=True, text=True
        )
        if diff.stdout.strip():
            errors.append("  ERROR   registry: registry.json is out of sync with component files. "
                          "Commit the result of sync-registry.sh.")
            print("DRIFT")
        else:
            print("OK")
except Exception as e:
    errors.append(f"  ERROR   registry: {e}")
    print("FAIL")

# ── Load registry ─────────────────────────────────────────────────────────────

with open(os.path.join(TOOLKIT_ROOT, "registry.json")) as f:
    registry = json.load(f)

# Build set of all known skill/agent names for reference validation
known_names = set()
for type_key, items in registry.get("components", {}).items():
    for comp in items:
        known_names.add(comp["name"])

# ── Check 2: Schema and content per component ─────────────────────────────────

for type_key, deffile in COMPONENT_TYPES.items():
    folder = TYPE_TO_FOLDER[type_key]
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
        rel_path = f"{folder}/{entry}/{deffile}"

        if not os.path.exists(def_path):
            err(f"{folder}/{entry}", f"{deffile} not found")
            continue

        with open(def_path) as f:
            content = f.read()

        fm = parse_frontmatter(content)
        label = f"{folder}/{entry}"
        checked += 1
        had_error = False

        # Frontmatter presence
        if not fm:
            err(label, "no YAML frontmatter found (missing --- delimiters)")
            had_error = True

        if not had_error:
            # Required fields
            for field in ("name", "description", "status", "version_added"):
                if field not in fm or not fm[field]:
                    err(label, f"frontmatter.{field} is missing or empty")

            # name matches directory
            if fm.get("name") and fm["name"] != entry:
                err(label, f"frontmatter.name '{fm['name']}' does not match directory '{entry}'")

            # status values
            if fm.get("status") and fm["status"] not in ("stable", "experimental", "deprecated"):
                err(label, f"frontmatter.status must be stable|experimental|deprecated, got '{fm['status']}'")

            # version_added format
            if fm.get("version_added") and not re.match(r'^v\d+\.\d+\.\d+$', fm["version_added"]):
                err(label, f"frontmatter.version_added must be vMAJOR.MINOR.PATCH, got '{fm['version_added']}'")

            # Rules use `target` instead of `compatible_with`
            if deffile == "rule.md":
                if "target" not in fm:
                    err(label, "rule must have frontmatter.target field")
            else:
                compat = fm.get("compatible_with", {})
                if isinstance(compat, dict):
                    if "claude_code" not in compat:
                        err(label, "frontmatter.compatible_with.claude_code is required")
                    for assistant, val in compat.items():
                        if val not in ("full", "partial", "none"):
                            err(label, f"frontmatter.compatible_with.{assistant} must be full|partial|none")
                else:
                    err(label, "frontmatter.compatible_with must be a mapping")

            # deprecated fields
            if fm.get("status") == "deprecated":
                if "deprecated_since" not in fm:
                    err(label, "deprecated component must have frontmatter.deprecated_since")
                if "removed_in" not in fm:
                    err(label, "deprecated component must have frontmatter.removed_in")

        # Placeholder text (skip if component opts out via lint_skip)
        lint_skip = fm.get("lint_skip", [])
        if isinstance(lint_skip, str):
            lint_skip = [lint_skip]
        if "placeholder_check" not in lint_skip:
            for pattern in PLACEHOLDER_PATTERNS:
                if re.search(pattern, content, re.IGNORECASE):
                    err(label, f"contains placeholder text matching '{pattern}'")

        # Required sections
        sections = REQUIRED_SECTIONS.get(deffile, [])
        for section in sections:
            if section not in content:
                err(label, f"missing required section '{section}'")

        # Prompt must have at least one {{variable}}
        if deffile == "prompt.md" and "{{" not in content:
            err(label, "prompt template has no {{variable}} placeholders")

        # README.md check
        if not os.path.exists(os.path.join(comp_dir, "README.md")):
            warn(label, "README.md not found")

        status = "FAIL" if any(label in e for e in errors) else "PASS"
        print(f"  Schema: {label:<35} {status}")

# ── Check 3: Agent skill references ──────────────────────────────────────────

print("")
print("  Agent references...", end=" ", flush=True)

agents_dir = os.path.join(TOOLKIT_ROOT, "agents")
agent_ref_errors = []

if os.path.isdir(agents_dir):
    for entry in sorted(os.listdir(agents_dir)):
        if entry.startswith('_'):
            continue
        agent_file = os.path.join(agents_dir, entry, "agent.md")
        if not os.path.exists(agent_file):
            continue
        with open(agent_file) as f:
            content = f.read()

        # Find "## Skills Used" section and extract /tw-<name> references
        skills_match = re.search(r'## Skills Used\n(.*?)(?=\n##|\Z)', content, re.DOTALL)
        if not skills_match:
            continue

        skills_section = skills_match.group(1)
        referenced = re.findall(r'/tw-([\w-]+)', skills_section)

        for skill_name in referenced:
            if skill_name not in known_names:
                agent_ref_errors.append(
                    f"  ERROR   agents/{entry}: references /tw-{skill_name} which is not in registry.json"
                )

if agent_ref_errors:
    errors.extend(agent_ref_errors)
    print("FAIL")
else:
    print("OK")

# ── Check 4: Snapshot freshness ───────────────────────────────────────────────

print("  Snapshot freshness...", end=" ", flush=True)
checkpoint_path = os.path.join(TOOLKIT_ROOT, "context", "CHECKPOINT.md")

if not os.path.exists(checkpoint_path):
    warn("context/CHECKPOINT.md", "not found — run sync-snapshots.sh")
    print("WARN")
else:
    with open(checkpoint_path) as f:
        checkpoint_content = f.read()

    try:
        current_hash = subprocess.check_output(
            ["git", "rev-parse", "HEAD"], cwd=TOOLKIT_ROOT, stderr=subprocess.DEVNULL
        ).decode().strip()[:8]

        hash_match = re.search(r'`([0-9a-f]{6,8})`', checkpoint_content)
        if hash_match:
            snapshot_hash = hash_match.group(1)
            if snapshot_hash != current_hash:
                warn("context/CHECKPOINT.md",
                     f"snapshot hash '{snapshot_hash}' differs from HEAD '{current_hash}' — run /tw-sync-context")
                print("STALE")
            else:
                print("OK")
        else:
            warn("context/CHECKPOINT.md", "could not read git hash — run sync-snapshots.sh")
            print("WARN")
    except Exception:
        print("SKIP (git unavailable)")

# ── Summary ───────────────────────────────────────────────────────────────────

print("")
print("─" * 52)

total_issues = len(errors) + (len(warnings) if STRICT else 0)

for e in errors:
    print(e)
for w in warnings:
    print(w)

if errors or warnings:
    print("")

print(f"  {checked} components checked, {len(errors)} errors, {len(warnings)} warnings")

if total_issues > 0:
    print("  Status: FAIL")
    sys.exit(1)
else:
    print("  Status: PASS")
    sys.exit(0)
PYTHON
