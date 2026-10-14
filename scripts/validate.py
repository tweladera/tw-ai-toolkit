#!/usr/bin/env python3
"""
validate.py — Validate the tw-ai-toolkit catalog structure and component frontmatter.

Usage:
    python3 scripts/validate.py [--root PATH] [--strict]

Exit codes:
    0  All checks passed
    1  Errors found (always blocking)
    2  Warnings found and --strict mode active

Integrated in .github/workflows/ci.yml and the pre-commit git hook.
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

try:
    import yaml
except ImportError:
    print("ERROR: pyyaml is required. Install with: pip install pyyaml", file=sys.stderr)
    sys.exit(1)


REQUIRED_SKILL_FIELDS = [
    "name", "description", "status", "version_added",
    "compatible_with", "tags", "invocation",
]
VALID_STATUSES = {"stable", "beta", "experimental", "deprecated"}
VALID_COMPAT_LEVELS = {"full", "partial", "none"}


# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------

class Report:
    def __init__(self) -> None:
        self.errors: list[str] = []
        self.warnings: list[str] = []

    def err(self, msg: str) -> None:
        self.errors.append(f"  ERROR  {msg}")

    def warn(self, msg: str) -> None:
        self.warnings.append(f"  WARN   {msg}")

    def ok(self) -> bool:
        return len(self.errors) == 0


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def parse_frontmatter(path: Path, report: Report) -> dict:
    content = path.read_text(encoding="utf-8")
    if not content.startswith("---"):
        report.err(f"{path}: no YAML frontmatter block found")
        return {}
    parts = content.split("---", 2)
    if len(parts) < 3:
        report.err(f"{path}: malformed frontmatter (missing closing ---)")
        return {}
    try:
        return yaml.safe_load(parts[1]) or {}
    except yaml.YAMLError as exc:
        report.err(f"{path}: invalid YAML — {exc}")
        return {}


# ---------------------------------------------------------------------------
# Validators
# ---------------------------------------------------------------------------

def validate_skill(skill_dir: Path, root: Path, report: Report) -> None:
    rel = skill_dir.relative_to(root)
    skill_file = skill_dir / "skill.md"
    readme = skill_dir / "README.md"

    if not skill_file.exists():
        report.err(f"{rel}/: missing skill.md")
        return

    if not readme.exists():
        report.warn(f"{rel}/: missing README.md")

    meta = parse_frontmatter(skill_file, report)
    if not meta:
        return

    rel_file = skill_file.relative_to(root)

    # Required fields
    for field in REQUIRED_SKILL_FIELDS:
        if field not in meta:
            report.err(f"{rel_file}: missing required field '{field}'")

    # Status
    status = meta.get("status")
    if status and status not in VALID_STATUSES:
        report.err(
            f"{rel_file}: status='{status}' is not valid"
            f" — use one of {sorted(VALID_STATUSES)}"
        )

    # compatible_with
    compat = meta.get("compatible_with")
    if compat is not None:
        if not isinstance(compat, dict):
            report.err(
                f"{rel_file}: 'compatible_with' must be a mapping"
                f" (got {type(compat).__name__})"
            )
        else:
            for tool, level in compat.items():
                if level not in VALID_COMPAT_LEVELS:
                    report.err(
                        f"{rel_file}: compatible_with.{tool}='{level}' is not valid"
                        f" — use one of {sorted(VALID_COMPAT_LEVELS)}"
                    )

    # name matches directory
    declared_name = meta.get("name")
    if declared_name and declared_name != skill_dir.name:
        report.warn(
            f"{rel_file}: name='{declared_name}' does not match"
            f" directory '{skill_dir.name}'"
        )

    # invocation format: must start with tw-
    invocation = meta.get("invocation", "")
    if invocation and not invocation.startswith("tw-"):
        report.warn(
            f"{rel_file}: invocation='{invocation}' should start with 'tw-'"
        )


def validate_registry_sync(root: Path, report: Report) -> None:
    registry_path = root / "registry.json"
    if not registry_path.exists():
        report.warn(
            "registry.json not found"
            " — run python3 scripts/sync_registry.py"
        )
        return

    try:
        registry = json.loads(registry_path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        report.err(f"registry.json: invalid JSON — {exc}")
        return

    registered = {
        s["name"]
        for s in registry.get("components", {}).get("skills", [])
    }

    skills_dir = root / "skills"
    if not skills_dir.exists():
        return

    actual = {
        d.name
        for d in skills_dir.iterdir()
        if d.is_dir()
        and not d.name.startswith("_")
        and (d / "skill.md").exists()
    }

    for name in actual - registered:
        report.err(
            f"skill '{name}' exists in skills/ but not in registry.json"
            " — run sync_registry.py"
        )

    for name in registered - actual:
        report.err(
            f"skill '{name}' is in registry.json but skills/{name}/ not found"
        )


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main() -> None:
    parser = argparse.ArgumentParser(description="Validate tw-ai-toolkit catalog")
    parser.add_argument("--root", default=".", help="Toolkit root directory (default: .)")
    parser.add_argument(
        "--strict", action="store_true",
        help="Treat warnings as errors (for CI)"
    )
    args = parser.parse_args()

    root = Path(args.root).resolve()
    report = Report()

    print(f"Validating {root} ...")

    skills_dir = root / "skills"
    if skills_dir.exists():
        for skill_dir in sorted(skills_dir.iterdir()):
            if skill_dir.is_dir() and not skill_dir.name.startswith("_"):
                validate_skill(skill_dir, root, report)
    else:
        report.warn("skills/ directory does not exist yet")

    validate_registry_sync(root, report)

    # Output
    if report.errors:
        print(f"\nErrors ({len(report.errors)}):")
        for line in report.errors:
            print(line)

    if report.warnings:
        print(f"\nWarnings ({len(report.warnings)}):")
        for line in report.warnings:
            print(line)

    if not report.errors and not report.warnings:
        print("  All checks passed.")
    elif not report.errors:
        print(f"\n  No errors. {len(report.warnings)} warning(s).")

    if report.errors:
        sys.exit(1)
    if args.strict and report.warnings:
        sys.exit(2)


if __name__ == "__main__":
    main()
