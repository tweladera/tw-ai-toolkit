---
name: example-rule
description: One sentence describing what behavior this rule enforces or prevents.
status: stable
version_added: v0.1.0
target:
  - claude
  - cursor
tags:
  - example
  - template
---

# example-rule

## Description

Explain what behavioral constraint or guidance this rule establishes.
Rules define how the AI model should behave in a specific context —
what it should always do, never do, or how to handle a specific situation.

## Applies To

| Assistant | Format | Location |
|---|---|---|
| Claude Code | `CLAUDE.md` fragment | Consumer repo root |
| Cursor | `.cursorrules` fragment | Consumer repo root |
| Codex | `.github/copilot-instructions.md` | Consumer repo |

## Rule Content

> The actual rule text that gets injected into the model's context.
> Write in second person ("You should...", "Never...").
> Be specific — vague rules produce inconsistent behavior.

---

### [Rule Section Name]

You should always [specific behavior].

When [condition], you must [specific action].

Never [prohibited behavior] because [reason].

If you are unsure whether [scenario applies], [decision rule].

#### Examples

**Compliant:**
```
[Example of behavior that follows the rule]
```

**Non-compliant:**
```
[Example of behavior that violates the rule — and why]
```

---

## Model-Specific Formats

### Claude Code (`CLAUDE.md` fragment)

Add this block to the consumer repo's `CLAUDE.md`:

```markdown
## [Rule Category]

[Paste the rule content here, formatted for CLAUDE.md]
```

### Cursor (`.cursorrules` fragment)

Add this block to the consumer repo's `.cursorrules`:

```
[Paste the rule content here, formatted for .cursorrules]
```

## Notes

- This rule is [always active / only active in specific contexts]
- Conflicts with: [other rules this might conflict with, if any]
- Priority: [high / medium / low — relative to other rules]
