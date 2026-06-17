# Prompt Template

Use this template to create a new reusable prompt.

## Steps

1. Copy this directory:
   ```bash
   cp -r prompts/_template/ prompts/your-prompt-name/
   ```

2. Fill in `prompt.md`.

3. Validate:
   ```
   /tw-lint-component prompts/your-prompt-name
   ```

## Prompt vs Skill — When to use each

| Use a Prompt when... | Use a Skill when... |
|---|---|
| You want a reusable piece of model instructions | You want a complete, invocable action |
| The template is meant to be filled and sent | The model executes a defined workflow |
| Compatible with multiple models/contexts | Model-specific execution logic needed |

## Variable Conventions

- Variables: `{{variable_name}}` — snake_case, descriptive names
- Conditional blocks: `{{#if variable}}...{{/if}}`
- All variables must be documented in the Parameters table
