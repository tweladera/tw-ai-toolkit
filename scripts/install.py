#!/usr/bin/env python3
"""
install.py — Install tw-ai-toolkit into a consumer repository.

Usage:
    # Step 1 — install the toolkit (choose one)
    python3 install.py                          # clone from GitHub (default)
    python3 install.py --local /path/to/toolkit # symlink to local copy (dev/test)
    python3 install.py --update                 # pull latest from GitHub

    # Step 2 — link skills and rules to AI tools (run after Step 1)
    python3 install.py --link-claude   # .claude/skills + .claude/rules + command stubs
    python3 install.py --link-cursor   # .cursor/skills + .cursor/rules
    python3 install.py --link-all      # both Claude Code + Cursor

    # Step 3 — verify the installation
    python3 install.py --verify

Recommended flow — local install (nothing pushed to remote):
    git clone https://github.com/tweladera/tw-ai-toolkit.git ~/tw-ai-toolkit
    cd /path/to/your-repo
    python3 ~/tw-ai-toolkit/scripts/install.py --local ~/tw-ai-toolkit
    python3 .ai/toolkit/scripts/install.py --link-all
    python3 .ai/toolkit/scripts/install.py --verify

Git submodule (only when team wants toolkit pinned in the repo):
    cd /path/to/your-repo
    git submodule add https://github.com/tweladera/tw-ai-toolkit.git .ai/toolkit
    python3 .ai/toolkit/scripts/install.py
    python3 .ai/toolkit/scripts/install.py --link-all
"""
from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
from pathlib import Path

TOOLKIT_REPO_HTTPS = "https://github.com/tweladera/tw-ai-toolkit.git"
DEFAULT_TARGET = ".ai/toolkit"
GITIGNORE_COMMENT = "# tw-ai-toolkit (managed by install.py — do not commit)"


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def run(cmd: list[str]) -> None:
    print(f"    $ {' '.join(cmd)}")
    result = subprocess.run(cmd, check=False)
    if result.returncode != 0:
        print(
            f"\n  ERROR: command failed with exit code {result.returncode}",
            file=sys.stderr,
        )
        sys.exit(result.returncode)


def ensure_gitignore(entry: str) -> None:
    gitignore = Path(".gitignore")
    if gitignore.exists():
        if entry in gitignore.read_text(encoding="utf-8"):
            return
        with gitignore.open("a", encoding="utf-8") as f:
            f.write(f"\n{GITIGNORE_COMMENT}\n{entry}\n")
        print(f"    added '{entry}' to .gitignore")
    else:
        gitignore.write_text(
            f"{GITIGNORE_COMMENT}\n{entry}\n", encoding="utf-8"
        )
        print(f"    created .gitignore with '{entry}'")


def load_registry(target: Path) -> dict:
    registry_path = target / "registry.json"
    if not registry_path.exists():
        print(
            f"  ERROR: {registry_path} not found."
            " Run sync_registry.py first.",
            file=sys.stderr,
        )
        sys.exit(1)
    return json.loads(registry_path.read_text(encoding="utf-8"))


def _skills(registry: dict) -> list[dict]:
    return registry.get("components", {}).get("skills", [])


def _rules(registry: dict) -> list[dict]:
    return registry.get("components", {}).get("rules", [])


def compatible_skill_names(registry: dict, tool_key: str) -> list[str]:
    return [
        s["name"]
        for s in _skills(registry)
        if s.get("compatible_with", {}).get(tool_key) in ("full", "partial")
    ]


def compatible_rule_names(registry: dict, tool_key: str) -> list[str]:
    """Return rule names whose compatible_with includes tool_key."""
    names = []
    for rule in _rules(registry):
        compat = rule.get("compatible_with", {})
        if compat.get(tool_key) in ("full", "partial"):
            names.append(rule["name"])
    return names


def command_stub_names(registry: dict) -> list[str]:
    """Return expected .md stub filenames for .claude/commands/."""
    names = []
    for skill in _skills(registry):
        if skill.get("compatible_with", {}).get("claude_code") not in ("full", "partial"):
            continue
        invocation = skill.get("invocation", f"/tw-{skill['name']}")
        # invocation may be "/tw-name" or "tw-name" — strip leading slash
        stub_name = invocation.lstrip("/") + ".md"
        names.append(stub_name)
    return names


def cursor_rule_link_name(filename: str) -> str:
    """Cursor only loads `.mdc` project rules; rename .md → .mdc."""
    if filename.endswith(".mdc"):
        return filename
    if filename.endswith(".md"):
        return filename[:-3] + ".mdc"
    return filename


def ensure_relative_symlink(link: Path, source: Path, dest_dir: Path) -> str:
    """Create or repair a relative symlink. Returns 'linked', 'replaced', or 'skipped'."""
    rel_source = os.path.relpath(source, dest_dir)
    if link.is_symlink():
        try:
            current = link.resolve()
        except OSError:
            current = None
        if current is not None and link.exists() and current == source.resolve():
            return "skipped"
        link.unlink()
        link.symlink_to(rel_source)
        return "replaced"
    if link.exists():
        return "skipped"
    link.symlink_to(rel_source)
    return "linked"


def create_skill_symlinks(target: Path, dest_dir: Path, tool_key: str) -> int:
    registry = load_registry(target)
    dest_dir.mkdir(parents=True, exist_ok=True)
    linked = 0

    for skill_name in compatible_skill_names(registry, tool_key):
        skill_source = (target / "skills" / skill_name).resolve()
        link = dest_dir / skill_name

        if not skill_source.exists():
            print(f"    skip (missing source): {skill_source}")
            continue

        action = ensure_relative_symlink(link, skill_source, dest_dir)
        rel_source = os.path.relpath(skill_source, dest_dir)
        if action == "skipped":
            print(f"    skip (exists): {link}")
            continue
        print(f"    {action}: {link} -> {rel_source}")
        linked += 1

    return linked


def create_rule_symlinks(target: Path, dest_dir: Path, tool_key: str) -> int:
    registry = load_registry(target)
    dest_dir.mkdir(parents=True, exist_ok=True)
    linked = skipped = 0

    for rule_name in compatible_rule_names(registry, tool_key):
        # Find the rule's path from registry
        rule_entry = next(
            (r for r in _rules(registry) if r["name"] == rule_name), None
        )
        if rule_entry is None:
            continue

        rule_source = (target / rule_entry["path"]).resolve()
        if not rule_source.exists():
            print(f"    skip (missing): {rule_source}")
            skipped += 1
            continue

        link_name = (
            cursor_rule_link_name(rule_source.name)
            if tool_key == "cursor"
            else rule_source.name
        )
        link = dest_dir / link_name
        action = ensure_relative_symlink(link, rule_source, dest_dir)
        rel_source = os.path.relpath(rule_source, dest_dir)
        if action == "skipped":
            print(f"    skip (exists): {link}")
            skipped += 1
            continue
        print(f"    {action}: {link} -> {rel_source}")
        linked += 1

    return linked


def create_claude_commands(target: Path) -> int:
    """Create stub .md files in .claude/commands/ for slash command autocomplete."""
    registry = load_registry(target)
    commands_dir = Path(".claude/commands")
    commands_dir.mkdir(parents=True, exist_ok=True)
    created = skipped = 0

    for skill in _skills(registry):
        compat = skill.get("compatible_with", {})
        if compat.get("claude_code") not in ("full", "partial"):
            continue

        skill_name = skill["name"]
        invocation = skill.get("invocation", f"/tw-{skill_name}").lstrip("/")
        stub_path = commands_dir / f"{invocation}.md"

        if stub_path.exists():
            print(f"    skip (exists): {stub_path}")
            skipped += 1
            continue

        stub_content = (
            "$ARGUMENTS\n\n"
            f"Read and follow the instructions in `.claude/skills/{skill_name}/skill.md`"
            " to complete the task.\n"
        )
        stub_path.write_text(stub_content, encoding="utf-8")
        print(f"    created: {stub_path}")
        created += 1

    return created


# ---------------------------------------------------------------------------
# Consumer file generation
# ---------------------------------------------------------------------------

def create_consumer_files(target: Path) -> None:
    """Create .ai/AGENTS.md and CLAUDE.md in the consumer repo."""
    # .ai/AGENTS.md
    ai_dir = Path(".ai")
    ai_dir.mkdir(exist_ok=True)
    agents_md = ai_dir / "AGENTS.md"
    if not agents_md.exists():
        agents_md.write_text(
            "# AI Toolkit Context\n\n"
            "This repo uses tw-ai-toolkit.\n\n"
            "Load toolkit context from:\n"
            f"- Toolkit overview: `{target}/AGENTS.md`\n"
            f"- Available components: `{target}/registry.json`\n"
            f"- Context snapshot: `{target}/context/snapshot.md`\n\n"
            "All toolkit skills and agents use the `/tw-` prefix.\n",
            encoding="utf-8",
        )
        print("  created: .ai/AGENTS.md")
    else:
        print("  skip (exists): .ai/AGENTS.md")
    ensure_gitignore(".ai/")

    # CLAUDE.md
    claude_md = Path("CLAUDE.md")
    toolkit_block = (
        "## AI Toolkit (tw-ai-toolkit)\n\n"
        "This repo uses tw-ai-toolkit. On every session start:\n"
        f"1. Read `.ai/AGENTS.md` for toolkit context\n"
        f"2. Check `{target}/context/CHECKPOINT.md` — if the git hash is stale, run `/tw-sync-context`\n"
        "3. Toolkit skills and agents use the `/tw-` prefix\n\n"
        f"To see all available components: load `{target}/registry.json`\n"
    )
    if claude_md.exists():
        if "tw-ai-toolkit" not in claude_md.read_text(encoding="utf-8"):
            with claude_md.open("a", encoding="utf-8") as f:
                f.write(f"\n{toolkit_block}")
            print("  updated: CLAUDE.md (appended toolkit block)")
        else:
            print("  skip (exists): CLAUDE.md already has toolkit block")
    else:
        claude_md.write_text(toolkit_block, encoding="utf-8")
        print("  created: CLAUDE.md")
    ensure_gitignore("CLAUDE.md")


# ---------------------------------------------------------------------------
# Install modes
# ---------------------------------------------------------------------------

def relink_if_present(target: Path) -> None:
    """Re-link skills/rules when the consumer already ran --link-* once."""
    if (
        Path(".claude/skills").exists()
        or Path(".claude/rules").exists()
        or Path(".claude/commands").exists()
    ):
        link_claude(target)
    if Path(".cursor/skills").exists() or Path(".cursor/rules").exists():
        link_cursor(target)


def install_clone(target: Path, update: bool) -> None:
    if target.exists():
        if not update:
            print(
                f"  '{target}' already exists."
                " Use --update to pull latest changes."
            )
            return
        print(f"  Updating {target} ...")
        run(["git", "-C", str(target), "pull", "--ff-only"])
    else:
        print(f"  Cloning tw-ai-toolkit into {target} ...")
        target.parent.mkdir(parents=True, exist_ok=True)
        run(["git", "clone", "--depth=1", TOOLKIT_REPO_HTTPS, str(target)])

    ensure_gitignore(str(target) + "/")
    create_consumer_files(target)
    if update:
        relink_if_present(target)


def install_local_link(source: Path, target: Path) -> None:
    """Symlink target to a local toolkit directory (dev/test mode)."""
    source = source.resolve()
    if not source.exists():
        print(f"  ERROR: local toolkit not found at {source}", file=sys.stderr)
        sys.exit(1)
    if target.exists() or target.is_symlink():
        print(f"  '{target}' already exists — remove it first to re-link.")
    else:
        target.parent.mkdir(parents=True, exist_ok=True)
        target.symlink_to(source)
        print(f"  linked: {target}/ -> {source}")
        ensure_gitignore(str(target) + "/")
    create_consumer_files(target)


# ---------------------------------------------------------------------------
# Linking modes
# ---------------------------------------------------------------------------

def link_claude(target: Path) -> None:
    print("  Linking skills to .claude/skills/ ...")
    n = create_skill_symlinks(target, Path(".claude/skills"), "claude_code")
    ensure_gitignore(".claude/skills/")
    print(f"  {n} skill(s) linked for Claude Code.")

    print("  Linking rules to .claude/rules/ ...")
    r = create_rule_symlinks(target, Path(".claude/rules"), "claude_code")
    ensure_gitignore(".claude/rules/")
    print(f"  {r} rule(s) linked for Claude Code.")

    print("  Creating slash command stubs in .claude/commands/ ...")
    m = create_claude_commands(target)
    ensure_gitignore(".claude/commands/")
    print(f"  {m} command stub(s) created for Claude Code autocomplete.")


def link_cursor(target: Path) -> None:
    print("  Linking skills to .cursor/skills/ ...")
    n = create_skill_symlinks(target, Path(".cursor/skills"), "cursor")
    ensure_gitignore(".cursor/skills/")
    print(f"  {n} skill(s) linked for Cursor.")

    print("  Linking rules to .cursor/rules/ ...")
    r = create_rule_symlinks(target, Path(".cursor/rules"), "cursor")
    ensure_gitignore(".cursor/rules/")
    print(f"  {r} rule(s) linked for Cursor.")


# ---------------------------------------------------------------------------
# Verify
# ---------------------------------------------------------------------------

def check_dest_coverage(
    label: str, expected: list[str], dest: Path, hint: str
) -> bool:
    if not dest.exists():
        print(f"  {label}: not found ({hint})")
        return True

    expected_set = set(expected)
    working = set()
    broken = []
    for p in dest.iterdir():
        if p.is_symlink() and not p.exists():
            broken.append(p.name)
        elif p.name in expected_set:
            working.add(p.name)

    missing = sorted(expected_set - working - set(broken))
    print(f"  {label}: {len(working)}/{len(expected)} catalog items")
    ok = True
    for name in missing:
        print(f"    MISSING: {name}")
        ok = False
    for name in broken:
        print(f"    BROKEN: {name}")
        ok = False
    return ok


def verify(target: Path) -> None:
    print(f"  Verifying tw-ai-toolkit installation at {target} ...")

    if not target.exists():
        print(f"  ERROR: {target}/ not found. Run install first.")
        sys.exit(1)

    registry_path = target / "registry.json"
    if not registry_path.exists():
        print("  ERROR: registry.json missing in toolkit.")
        sys.exit(1)

    registry = json.loads(registry_path.read_text(encoding="utf-8"))
    n_skills = len(_skills(registry))
    print(f"  registry.json: {n_skills} skill(s) registered")

    ok = True
    ok &= check_dest_coverage(
        ".claude/skills/",
        compatible_skill_names(registry, "claude_code"),
        Path(".claude/skills"),
        "run --link-claude",
    )
    ok &= check_dest_coverage(
        ".claude/commands/",
        command_stub_names(registry),
        Path(".claude/commands"),
        "run --link-claude",
    )
    ok &= check_dest_coverage(
        ".cursor/skills/",
        compatible_skill_names(registry, "cursor"),
        Path(".cursor/skills"),
        "run --link-cursor",
    )

    if ok:
        print("\n  Installation looks good.")
        return

    print("\n  Installation is incomplete. Re-run:")
    print("    python3 scripts/install.py --link-all")
    sys.exit(1)


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main() -> None:
    parser = argparse.ArgumentParser(
        description="Install and configure tw-ai-toolkit in a consumer repository.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    parser.add_argument(
        "--target", default=DEFAULT_TARGET,
        help=f"Toolkit install directory (default: {DEFAULT_TARGET})",
    )
    parser.add_argument(
        "--local", metavar="PATH",
        help="Symlink to a local toolkit directory instead of cloning (dev/test mode)",
    )
    parser.add_argument(
        "--update", action="store_true",
        help="Pull latest toolkit changes and re-link any newly added skills/rules",
    )
    parser.add_argument(
        "--link-claude", action="store_true",
        help="Create .claude/skills/ symlinks and command stubs for Claude Code",
    )
    parser.add_argument(
        "--link-cursor", action="store_true",
        help="Create .cursor/skills/ symlinks for Cursor",
    )
    parser.add_argument(
        "--link-all", action="store_true",
        help="Link skills for all tools (Claude Code + Cursor)",
    )
    parser.add_argument(
        "--verify", action="store_true",
        help="Verify the installation",
    )
    args = parser.parse_args()

    target = Path(args.target)

    # If default target not found, check if we are inside the toolkit root
    if args.target == DEFAULT_TARGET and not (target / "registry.json").exists():
        if Path("registry.json").exists():
            print(
                "  NOTE: .ai/toolkit/ not found;"
                " using current directory as the toolkit root."
            )
            target = Path(".")

    # Linking and verify modes (can be run standalone after install)
    if args.link_claude or args.link_all:
        link_claude(target)
    if args.link_cursor or args.link_all:
        link_cursor(target)
    if args.verify:
        verify(target)

    # If only linking/verifying, stop here
    if args.link_claude or args.link_cursor or args.link_all or args.verify:
        return

    # Install mode
    print("tw-ai-toolkit installer")
    print(f"  Target: {target}")

    if args.local:
        print(f"  Mode:   local-link -> {args.local}\n")
        install_local_link(Path(args.local), target)
    else:
        print(f"  Repo:   {TOOLKIT_REPO_HTTPS}")
        print("  Mode:   clone\n")
        install_clone(target, args.update)

    print(f"\n  tw-ai-toolkit ready at {target}/")
    print(f"  Next step: python3 {target}/scripts/install.py --link-all")


if __name__ == "__main__":
    main()
