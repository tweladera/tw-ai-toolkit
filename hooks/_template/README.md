# Hook Template

Use this template to create a new assistant hook.

## Steps

1. Copy this directory:
   ```bash
   cp -r hooks/_template/ hooks/your-hook-name/
   ```

2. Fill in `hook.md`.

3. Validate:
   ```
   /tw-lint-component hooks/your-hook-name
   ```

## Claude Code Events Reference

| Event | When it fires |
|---|---|
| `PreToolUse` | Before the model calls a tool (Bash, Edit, Write, etc.) |
| `PostToolUse` | After a tool call completes |
| `Stop` | When the model finishes its final response |
| `Notification` | When the assistant sends a desktop notification |

## Hook Guidelines

- **Keep commands fast.** Hooks run synchronously — slow hooks block the assistant.
- **Handle failures gracefully.** A failing hook should not crash the assistant.
- **Be idempotent.** The same hook may fire multiple times per session.
- **Log to a file, not stdout.** Hook stdout goes to the assistant, which can be confusing.
- **Test in isolation** before adding to settings.json.

## Security Note

Hooks execute shell commands with the same permissions as the assistant process.
Never include credentials or secrets in hook commands — use environment variables.
