# scaffold-component

Creates a new toolkit component from the appropriate template given a type and name.

**Invocation:** `/tw-scaffold-component type=skill name=my-skill`

Copies the template, pre-fills `name` and `version_added`, then runs lint-component
to show what the user still needs to fill. Supported types: skill, agent, prompt, rule, hook, mcp.

See `agent.md` for full documentation and `tests/core/scaffold-component/test.md` for test cases.
