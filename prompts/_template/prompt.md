---
name: example-prompt
description: One sentence describing what situation this prompt template addresses.
status: stable
version_added: v0.1.0
compatible_with:
  claude_code: full
  cursor: full
  codex: full
tags:
  - example
  - template
---

# example-prompt

## Description

Explain what this prompt is for, when to use it, and what kind of output it produces.
Prompts are reusable templates that a user (or a skill/agent) fills with parameters
and passes to the model.

## Parameters

Variables use `{{double_braces}}` notation in the template.

| Name | Required | Description | Example value |
|---|---|---|---|
| `variable_one` | yes | Description of what to put here | `"example value"` |
| `variable_two` | no | Description of what to put here | `"optional value"` |

## Template

---

You are a [role] with expertise in [domain].

Context:
{{variable_one}}

Task:
[Clear description of what the model should do with the context above]

Requirements:
- [Requirement 1]
- [Requirement 2]
- [Requirement 3]

Output format:
[Define the exact format of the expected output]

{{#if variable_two}}
Additional instructions when variable_two is provided:
{{variable_two}}
{{/if}}

---

## Example

### Input
```
variable_one = "We need to improve the performance of our checkout flow.
                Currently it takes 4 seconds to process a payment."

variable_two = "Focus on database query optimization."
```

### Filled template
```
You are a senior software engineer with expertise in web performance.

Context:
We need to improve the performance of our checkout flow.
Currently it takes 4 seconds to process a payment.

Task:
[Task description]

Requirements:
- [Requirement 1]
- [Requirement 2]
- [Requirement 3]

Output format:
[Output format]

Additional instructions when variable_two is provided:
Focus on database query optimization.
```

### Expected output
```
[Show what a good model response looks like given the filled template]
```

## Usage

### From a skill or agent
```python
# Load and fill the template
prompt = load_prompt("example-prompt", {
    "variable_one": "...",
    "variable_two": "..."  # optional
})
```

### Manually in Claude Code
```
Load prompts/example-prompt/prompt.md, fill {{variable_one}} with [your value],
and then execute it.
```

## Notes

- [Any important behavior, edge cases, or model-specific considerations]
