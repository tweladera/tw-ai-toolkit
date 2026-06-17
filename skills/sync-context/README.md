# sync-context

Regenerates the toolkit registry and context snapshots from current component files.

**Invocation:** `/tw-sync-context`

Run this after adding or modifying any component, or when snapshots seem stale.
The pre-commit git hook runs this automatically on commits that touch component files.

See `skill.md` for full documentation and `tests/core/sync-context/test.md` for test cases.
