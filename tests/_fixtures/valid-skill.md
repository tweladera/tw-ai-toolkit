---
name: fixture-valid-skill
description: Validates a given file against a set of rules and reports issues.
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
    description: Path to the file to validate
  - name: strict
    type: boolean
    required: false
    default: "false"
    description: Treat warnings as errors
tags:
  - validation
  - fixture
---

# fixture-valid-skill

## Description

This is a fixture file used by `tests/core/lint-component/test.md` to verify
that `lint-component` correctly passes a well-formed skill definition.
It is not a real toolkit skill — do not invoke it.

## When to Use

Do not use. This is a test fixture only.

## Parameters

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `target` | string | yes | — | Path to the file to validate |
| `strict` | boolean | no | false | Treat warnings as errors |

## Instructions

1. Read the file at `{{target}}`.
2. Validate it against the rules.
3. Report findings.

## Examples

### Basic usage
```
/tw-fixture-valid-skill target="path/to/file"
```

## Dependencies

None.

## Notes

This is a fixture for testing `lint-component`. Not a real skill.
