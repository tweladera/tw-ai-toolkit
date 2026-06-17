---
name: example-hook
description: One sentence describing what this hook does when triggered.
status: stable
version_added: v0.1.0
compatible_with:
  claude_code: full
  cursor: partial
  codex: none
tags:
  - example
  - template
---

# example-hook

## Description

Expand on what this hook does, when it fires, and what effect it has.
Hooks are shell commands that the AI assistant executes automatically
in response to events — without the user having to ask.

## Event

Which assistant event triggers this hook.

| Event | Description |
|---|---|
| `PreToolUse` | Before the model calls any tool |
| `PostToolUse` | After a tool finishes executing |
| `Stop` | When the model finishes its response |
| `Notification` | When the assistant sends a notification |

**This hook uses:** `[EventName]`

## Condition (optional)

Additional filter to narrow when the hook fires.
Leave empty if the hook fires on every occurrence of the event.

```json
{
  "tool_name": "Bash"
}
```

Explanation: [What this condition means in plain English]

## Action

The shell command this hook executes when triggered.

```bash
[your-command-here]
```

Variables available from the assistant context:
- `$TOOL_NAME` — name of the tool that fired the event
- `$TOOL_INPUT` — JSON input to the tool
- `$TOOL_RESULT` — JSON output from the tool (PostToolUse only)

## Configuration

### Claude Code (`settings.json`)

Add this block to `.claude/settings.json` in the consumer repo:

```json
{
  "hooks": {
    "[EventName]": [
      {
        "matcher": "[optional condition]",
        "hooks": [
          {
            "type": "command",
            "command": "[your-command-here]"
          }
        ]
      }
    ]
  }
}
```

### Cursor

Cursor hook support is limited. Equivalent behavior via:
[Describe the Cursor alternative, or state "not supported"]

## Examples

### Scenario 1
**Trigger:** [Describe what action causes this hook to fire]
**What happens:** [Describe the effect]

### Scenario 2
**Trigger:** [Another scenario]
**What happens:** [Effect]

## Notes

- This hook runs [synchronously / asynchronously] with the assistant
- Failure behavior: [what happens if the command fails]
- Performance: [any latency considerations]
