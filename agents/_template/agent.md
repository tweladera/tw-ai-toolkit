---
name: example-agent
description: One sentence describing the autonomous task this agent accomplishes.
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

# example-agent

## Description

Expanded description. An agent is an autonomous orchestrator — it takes a high-level
goal and breaks it down into steps, invoking skills and making decisions along the way.
Explain what task this agent completes end-to-end and what the final output looks like.

## Trigger

When should this agent be invoked? Be specific so the model can decide autonomously.

Examples:
- When the user asks to [high-level task] from scratch
- At the start of a new [workflow type]
- When [condition] is true and multiple steps need to be coordinated

## Skills Used

List every skill this agent orchestrates, in approximate execution order.

- `/tw-skill-one` — [why it's used in this context]
- `/tw-skill-two` — [why it's used in this context]
- `/tw-skill-three` — [why it's used in this context]

> If a skill is used conditionally, note the condition: "only if X is true"

## Inputs

What the agent needs before it can start.

| Input | Required | Description |
|---|---|---|
| `input_name` | yes | Description of what this input is |
| `option_name` | no | Optional configuration |

## Flow

Step-by-step description of what the agent does. This is the core of the agent definition.
The model uses this to orchestrate its execution.

```
Step 1 — [Name]
  Action: [What the agent does]
  Skill:  /tw-skill-one
  Output: [What this step produces]

Step 2 — [Name]
  Condition: Only if [step 1 produced X]
  Action: [What the agent does]
  Skill:  /tw-skill-two
  Output: [What this step produces]

Step 3 — [Name]
  Action: [What the agent does]
  Skill:  /tw-skill-three
  Output: [Final output]
```

## Outputs

What the agent produces when it completes successfully.

- [Output item 1 — description]
- [Output item 2 — description]

**On failure:** If the agent cannot complete a step, it must [stop and report / ask user / attempt recovery] with a clear explanation of what failed and why.

## Examples

### Example 1 — Standard usage
```
/tw-example-agent input="path/to/something"
```
What happens:
1. Agent runs step 1 (skill: /tw-skill-one)
2. Agent runs step 2 (skill: /tw-skill-two)
3. Agent produces [output]

## Notes

- This agent does NOT [common misconception]
- Maximum autonomy level: [fully autonomous / asks for confirmation at step X]
- Estimated steps: [N-M steps depending on input]
