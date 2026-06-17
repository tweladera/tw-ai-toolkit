# Versioning Strategy

tw-ai-toolkit follows **Semantic Versioning** (`MAJOR.MINOR.PATCH`).

---

## Version Format

```
v1.2.3
│ │ └── PATCH — bug fix, safe to update always
│ └──── MINOR — new feature, backwards compatible, safe to update
└────── MAJOR — breaking change, requires migration steps
```

---

## When Each Number Bumps

### PATCH — `v1.0.0 → v1.0.1`

- Bug fix in an existing component
- Documentation correction
- Snapshot or registry regeneration
- No behavior change

**Consumer repos:** Safe to update without review.

### MINOR — `v1.0.0 → v1.1.0`

- New skill, agent, prompt, rule, hook, or MCP server added
- New optional parameter added to an existing component
- Existing component marked as `deprecated` (still works, just warns)
- New field added to `registry.json` (backwards compatible)

**Consumer repos:** Safe to update. Read the CHANGELOG for new components you may want to use.

### MAJOR — `v1.0.0 → v2.0.0`

- Component removed (was previously deprecated for at least 2 minor versions)
- Breaking parameter change in an existing component
- Schema change in `registry.json` or `config.json` that requires migration
- Rename of a component that was previously deprecated

**Consumer repos:** Review `CHANGELOG.md` before updating. Follow migration notes.

---

## Component Lifecycle

```
[Added]          Status: experimental
                    ↓ (after validation)
[Stable]         Status: stable
                    ↓ (replacement exists or component is obsolete)
[Deprecated]     Status: deprecated (min. 2 MINOR versions in this state)
  - Still works
  - Warns user on invocation
  - CHANGELOG documents the replacement
                    ↓ (next MAJOR release)
[Removed]        Component deleted from the repo
```

### In `registry.json`

```json
{
  "name": "old-skill",
  "status": "deprecated",
  "deprecated_since": "v1.3.0",
  "removed_in": "v2.0.0",
  "replacement": "new-skill"
}
```

---

## Tagging Releases

All releases are tagged in the toolkit repo:

```bash
git tag -a v1.2.0 -m "Release v1.2.0"
git push origin v1.2.0
```

Consumer repos pin to a specific tag via git submodule. See `docs/integration-guide.md`.

---

## Branching Model

| Branch | Purpose |
|---|---|
| `main` | Always stable, always tagged on release |
| `feat/<name>` | Feature development — merged to main with PR |
| `fix/<name>` | Bug fixes — merged to main with PR |

No long-lived release branches. All releases are tagged commits on `main`.

---

## Changelog

Every release has a corresponding entry in `CHANGELOG.md` following the
[Keep a Changelog](https://keepachangelog.com) format.

Types of changes: `Added`, `Changed`, `Deprecated`, `Removed`, `Fixed`, `Security`.
