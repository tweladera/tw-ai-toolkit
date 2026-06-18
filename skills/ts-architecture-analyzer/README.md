# ts-architecture-analyzer

**Invocation:** `/tw-ts-architecture-analyzer`

Performs deep architectural analysis of TypeScript/NestJS code with automatic granularity detection.
Determines the analysis level (L1–L4), produces an architectural map, execution walkthrough, risk
analysis, a technical health scorecard (7 dimensions, 1–10), and a Gherkin feature file derived
from identified risks. Exports the full analysis to a Markdown file.

## When to Use

- Architecture review before a code review or PR merge
- Identifying silent risks, gotchas, and scalability failure points
- Evaluating design decisions with senior-level improvement suggestions
- Generating a structured technical report exportable as Markdown
- Producing Gherkin test scenarios from identified architectural risks

## Analysis Levels

| Level | Scope | Focus |
|-------|-------|-------|
| L1 — System | Full repository | Stack, infrastructure, bounded contexts |
| L2 — Module | Directory / NestJS module | Cohesion, coupling, responsibility |
| L3 — Component | File / class / interface | Data structures, patterns, states |
| L4 — Unit | Function / method | Pure logic, algorithms, error handling |

## Output

- `resultado-analisis/analisis-[level]-[artifact]-[date].md` — full analysis
- `resultado-analisis/INDEX.md` — updated history table

## Supporting files

| File | Purpose |
|------|---------|
| `references/analysis-example.md` | Complete example output |

## Full flow

```bash
# Analyze a specific service
/tw-ts-architecture-analyzer artifact=src/orders/orders.service.ts

# Analyze full repository (L1)
/tw-ts-architecture-analyzer
```
