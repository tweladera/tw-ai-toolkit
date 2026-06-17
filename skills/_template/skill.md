---
name: example-skill
description: One sentence describing what this skill does — be specific and actionable.
status: stable
version_added: v0.1.0
compatible_with:
  claude_code: full
  cursor: partial
  codex: none
parameters:
  - name: target
    type: string
    required: true
    default: ""
    description: The main input this skill operates on (e.g. file path, PR number, text)
  - name: verbose
    type: boolean
    required: false
    default: "false"
    description: Whether to include detailed output
tags:
  - example
  - template
---

# example-skill

## Description

Expanded description. Explain what this skill does, what problem it solves,
and what the output looks like. One to three paragraphs max.

## When to Use

Describe the trigger condition or scenario where this skill is useful.
Be specific so the AI model can decide on its own when to invoke it.

Example:
- When the user asks to review X
- After Y action is completed
- When working with files matching Z pattern

## Parameters

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `target` | string | yes | — | The main input this skill operates on |
| `verbose` | boolean | no | false | Whether to include detailed output |

## Instructions

> This section contains the actual prompt instructions the AI model will follow.
> Write as if speaking directly to the model. Be specific and unambiguous.
> The model will execute exactly what is written here.

1. Read the `{{target}}` provided by the user.
2. Analyze it for [specific criteria].
3. Produce output in the following format:
   - [Output item 1]
   - [Output item 2]
4. If `{{verbose}}` is true, include [additional detail].
5. If you cannot complete the task because [reason], tell the user clearly.

**Output format:**
```
[Define the exact output structure here]
```

## Examples

### Example 1 — Basic usage
```
/tw-example-skill path/to/file.ts
```
Expected output:
```
[Show what a correct output looks like]
```

### Example 2 — With verbose flag
```
/tw-example-skill path/to/file.ts verbose=true
```
Expected output:
```
[Show verbose output]
```

## Dependencies

List any other skills, tools, or external resources this skill requires.
- `/tw-other-skill` — used for [reason] *(or "none")*

## Notes

Any edge cases, limitations, or important behavior to document.
- This skill does NOT [common misconception]
- When [edge case], the skill will [behavior]
