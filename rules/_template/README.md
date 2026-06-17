# Rule Template

Use this template to create a new behavioral rule.

## Steps

1. Copy this directory:
   ```bash
   cp -r rules/_template/ rules/your-rule-name/
   ```

2. Fill in `rule.md`.

3. Generate model-specific format files from the rule content:
   ```bash
   # These files are consumed by consumer repos
   rules/your-rule-name/claude.md     # CLAUDE.md fragment
   rules/your-rule-name/cursor.md     # .cursorrules fragment
   ```

4. Validate:
   ```
   /tw-lint-component rules/your-rule-name
   ```

## Rule Writing Guidelines

- **Be specific.** "Always use descriptive variable names" is vague.
  "Variable names must describe their purpose, not their type (e.g. `userList` not `arr`)" is specific.
- **Give the reason.** Rules with explanations are followed more consistently.
- **Show examples.** Compliant vs non-compliant examples remove ambiguity.
- **Keep rules atomic.** One rule = one behavioral concern.
- **Test the rule.** Verify the model actually follows it before marking as stable.

## `target` Field Values

| Value | Description |
|---|---|
| `claude` | Rule is applicable to Claude Code |
| `cursor` | Rule is applicable to Cursor |
| `codex` | Rule is applicable to GitHub Copilot |
