#!/usr/bin/env python3
"""
sync_registry.py — Scan tw-ai-toolkit components and regenerate registry.json.

Usage:
    python3 scripts/sync_registry.py [--root PATH]

Reads frontmatter from component definition files and writes registry.json at the
toolkit root. Run after adding or modifying any component. The pre-commit hook runs
this automatically when component files are staged.
"""
from __future__ import annotations

import argparse
import json
from datetime import datetime, timezone
from pathlib import Path

try:
    import yaml
except ImportError:
    import sys
    print("ERROR: pyyaml required. Install with: pip install pyyaml", file=sys.stderr)
    sys.exit(1)


TOOLKIT_REPO = "https://github.com/tw-qa/tw-ai-toolkit.git"

# Maps directory name → (definition filename, registry key)
COMPONENT_TYPES: dict[str, tuple[str, str]] = {
    "skills":  ("skill.md",  "skills"),
    "agents":  ("agent.md",  "agents"),
    "prompts": ("prompt.md", "prompts"),
    "rules":   ("rule.md",   "rules"),
    "hooks":   ("hook.md",   "hooks"),
    "mcp":     ("server.md", "mcp_servers"),
}


def parse_frontmatter(path: Path) -> dict:
    content = path.read_text(encoding="utf-8")
    if not content.startswith("---"):
        return {}
    parts = content.split("---", 2)
    if len(parts) < 3:
        return {}
    try:
        return yaml.safe_load(parts[1]) or {}
    except yaml.YAMLError as exc:
        print(f"  WARN: invalid YAML in {path} — {exc}")
        return {}


def rule_target_to_compat(target) -> dict:
    """Translate rule `target` list to a compatible_with dict."""
    if isinstance(target, str):
        target = [target]
    compat: dict[str, str] = {}
    for t in (target or []):
        t = str(t).lower().replace("-", "_")
        if t in ("claude", "claude_code"):
            compat["claude_code"] = "full"
        elif t == "cursor":
            compat["cursor"] = "full"
        elif t == "codex":
            compat["codex"] = "full"
    return compat


def scan_components(root: Path) -> dict[str, list]:
    components: dict[str, list] = {
        "skills": [],
        "agents": [],
        "prompts": [],
        "rules": [],
        "hooks": [],
        "mcp_servers": [],
    }

    for dir_name, (def_file, registry_key) in COMPONENT_TYPES.items():
        comp_dir = root / dir_name
        if not comp_dir.exists():
            continue

        for item_dir in sorted(comp_dir.iterdir()):
            if not item_dir.is_dir() or item_dir.name.startswith("_"):
                continue

            def_path = item_dir / def_file
            if not def_path.exists():
                continue

            meta = parse_frontmatter(def_path)
            if not meta:
                print(f"  WARN: skipping {def_path.relative_to(root)} — no frontmatter")
                continue

            name = meta.get("name") or item_dir.name
            rel_path = str(def_path.relative_to(root))

            entry: dict = {
                "name": name,
                "description": str(meta.get("description", "")).strip(),
                "path": rel_path,
                "status": meta.get("status", "stable"),
            }

            # Invocation — explicit in frontmatter, or derived
            if "invocation" in meta:
                entry["invocation"] = meta["invocation"]
            elif dir_name in ("skills", "agents"):
                entry["invocation"] = f"/tw-{name}"

            # Compatibility — rules use `target`, others use `compatible_with`
            if dir_name == "rules":
                compat = rule_target_to_compat(meta.get("target", []))
                if compat:
                    entry["compatible_with"] = compat
            elif "compatible_with" in meta:
                entry["compatible_with"] = meta["compatible_with"]

            # Optional metadata
            for field in ("version_added", "parameters", "tags",
                          "deprecated_since", "removed_in", "replacement"):
                if field in meta:
                    entry[field] = meta[field]

            components[registry_key].append(entry)
            print(f"  indexed: {dir_name}/{name}")

    return components


def main() -> None:
    parser = argparse.ArgumentParser(description="Regenerate tw-ai-toolkit registry.json")
    parser.add_argument("--root", default=".", help="Toolkit root directory (default: .)")
    args = parser.parse_args()

    root = Path(args.root).resolve()
    registry_path = root / "registry.json"

    # Preserve current version field if registry already exists
    existing_version = "0.1.0"
    if registry_path.exists():
        try:
            existing = json.loads(registry_path.read_text(encoding="utf-8"))
            existing_version = existing.get("version", existing_version)
        except json.JSONDecodeError:
            pass

    print(f"Scanning {root} ...")
    components = scan_components(root)

    total = sum(len(v) for v in components.values())
    now = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

    registry = {
        "version": existing_version,
        "last_updated": now,
        "toolkit_repo": TOOLKIT_REPO,
        "components": components,
    }

    registry_path.write_text(
        json.dumps(registry, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )

    print(f"\nregistry.json updated — {total} component(s) indexed")
    for key, items in components.items():
        if items:
            print(f"  {key}: {len(items)}")


if __name__ == "__main__":
    main()
