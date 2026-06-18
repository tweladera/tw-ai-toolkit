---
name: ts-architecture-analyzer
description: Analyzes TypeScript/NestJS code with adaptive depth, auto-detects granularity level (L1-L4), identifies architectural risks, silent traps, and scalability issues, and produces a technical health scorecard with Gherkin feature file.
status: stable
version_added: v0.1.0
compatible_with:
  claude_code: full
  cursor: partial
  codex: none
parameters:
  - name: artifact
    type: string
    required: false
    default: ""
    description: Path or pasted code to analyze. If omitted, Claude analyzes the full repo at L1.
tags:
  - typescript
  - nestjs
  - architecture
  - code-review
  - qa
---

# ts-architecture-analyzer

## Description

Performs deep architectural analysis of TypeScript/NestJS code with automatic granularity detection.
Determines the analysis level (L1 System → L2 Module → L3 Component → L4 Unit) based on what is
provided, then produces: an architectural map (ASCII), an execution walkthrough, risk analysis with
gotchas and failure points, a technical health scorecard (7 dimensions, 1–10), and a Gherkin
feature file derived from identified risks. Always exports the full analysis to a Markdown file.

**Stack:** TypeScript / Node.js / NestJS / Jest / TypeORM / class-validator

## When to Use

Invoke this skill when you need to:

- Analyze TypeScript/NestJS code architecture before a code review or PR merge
- Identify silent risks, gotchas, and scalability failure points in a module or service
- Evaluate design decisions and get senior-level improvement suggestions
- Generate a structured technical report exportable as Markdown
- Produce Gherkin test scenarios derived from identified architectural risks

Triggers: user pastes code without instructions, asks "analyze", "review architecture",
"what risks does this have", "refactor", "scalability", or "what does this code do".

## Instructions

### Step 1 — Detect Scope Level (Automatic)

Before responding, determine the level of the artifact:

| Level | Scope | Analysis Focus |
|-------|-------|----------------|
| **L1 — System** | Full project / repository | Stack, infrastructure, global flow, bounded contexts |
| **L2 — Module** | Directory / NestJS module | Cohesion, coupling, responsibility |
| **L3 — Component** | File / class / interface | Data structures, patterns, states |
| **L4 — Unit** | Function / method / fragment | Pure logic, algorithms, error handling |

State the detected level at the start of the response. If ambiguous, analyze at the lowest
possible level and explain what additional context would broaden the analysis.

### Step 2 — Check for Missing Context

If the level is **L3 or L4**, evaluate whether these artifacts are present:

| Missing Artifact | Impact if Absent |
|-----------------|-----------------|
| Interfaces/ports the class implements | Cannot evaluate contract or actual coupling |
| Configuration (`app.module.ts`, `.env`, `config/`) | Timeouts, pools, feature flags remain black boxes |
| Existing tests (`*.spec.ts`) | Cannot measure coverage or original design intent |
| Referenced collaborating classes (injected deps) | Flow analysis remains incomplete |
| Data models (TypeORM entities, DTOs, interfaces) | Cannot detect N+1, mutability, or data contracts |

**Protocol:**
- 2+ critical artifacts missing → notify user, list exactly which files would add value and why, then proceed
- 1 or none missing → proceed and mention the gap at the end in the Scorecard

Never block the analysis. Move forward with what is available and be explicit about partial conclusions.

### Step 3 — Produce the Required Response Structure

#### Mission
One sentence: what problem does this artifact solve in the system?

#### Architectural Map
ASCII diagram calibrated to the detected level:
- **L1:** NestJS modules, external dependencies, data flow between bounded contexts
- **L2:** Classes within the module with dependency relationships and flow direction
- **L3:** Simplified class diagram: key attributes, public methods, injected dependencies
- **L4:** Logic flow: inputs → transformations → outputs

#### Execution Walkthrough
Narrate the intent behind the logic, not the syntax. Describe data transformation start to end.
Answer: what design decisions did the author make, and why did they probably make them that way?

#### Risk Analysis & Senior Insights

**Gotchas — Silent Traps**
Errors that do not raise an exception but corrupt state or behavior.
Format: `[Observable symptom] → [Root cause] → [Triggering condition]`

**Failure Points — Scalability and Fragility**
Where does the system break under load, concurrency, or data volume?
Format: `[Pressure scenario] → [Degraded behavior] → [Estimated threshold]`

**Pro-Tips — Architectural Implementation**
Concrete senior-level suggestions. Include solution pattern or technical reference.
Format: `[Detected problem] → [Recommended solution] → [Trade-off or consideration]`

Minimum 1 item per category. If one does not apply, state so explicitly with the reason.

#### Technical Health Scorecard

Rate each dimension 1–10 based on observed evidence, not assumptions:

| Dimension | Score | Status | Brief justification |
|-----------|-------|--------|---------------------|
| Maintainability | X/10 | ✅/⚠️/🔥 | |
| Scalability | X/10 | ✅/⚠️/🔥 | |
| Testability | X/10 | ✅/⚠️/🔥 | |
| Security | X/10 | ✅/⚠️/🔥 | |
| Observability | X/10 | ✅/⚠️/🔥 | |
| Monitoring | X/10 | ✅/⚠️/🔥 | |
| Analysis Context | X/10 | ✅/⚠️/🔥 | penalize if key artifacts missing |

Status scale: ✅ 8–10 Healthy · ⚠️ 5–7 Needs attention · 🔥 1–4 Critical risk

#### Automated Test Feature File

Generate a `.feature` in Gherkin oriented toward business value, derived from identified risks:
- Scenarios in `Given / When / Then` format
- Mandatory tags: `@smoke`, `@regression`, `@async`, `@contract`, `@happy` as applicable
- No technical implementation details (no class names, no queries, no tables)
- Minimum: 1 positive scenario (`@happy`) and 1 negative or edge-case scenario
- Feature name must reflect the business capability, not the class name
- Language: English

### Step 4 — Export Analysis (Automatic, No Confirmation Needed)

Always execute these steps after producing the analysis:

**File name:** `analisis-[level]-[artifact-name]-[YYYY-MM-DD].md`
Examples: `analisis-L3-InventoryService-2025-03-04.md`, `analisis-L1-run-service-api-2025-03-04.md`

**Directory:**
```bash
mkdir -p resultado-analisis
```

**File structure:**
```markdown
---
nivel: L3 — Component
artefacto: [artifact-name]
ruta: [path/to/file]
fecha_analisis: [YYYY-MM-DD]
score_general: X/10
estado_general: ✅/⚠️/🔥
tags: [typescript, nestjs, jest, typeorm]
---

# Analysis: [Artifact Name]
> Level: L3 — Component | Score: X/10 | Date: [YYYY-MM-DD]

## Executive Summary
[2–3 lines for stakeholders, critical risks, remediation effort]

## Mission / Architectural Map / Execution Walkthrough / Risk Analysis / Scorecard / Feature File
[full content]
```

**Update INDEX.md** in `resultado-analisis/` — append one row to the history table.

**Confirm to user:**
```
Analysis completed and exported
Main document: resultado-analisis/analisis-[level]-[artifact]-[date].md
Index updated: resultado-analisis/INDEX.md
Score: X/10 | Critical risks: X | Recommendations: X
```

### TypeScript/NestJS Patterns to Detect

**Common Traps:**
- Missing `await` on async calls — Promise silently dropped, state corrupted
- `any` type masking errors — type safety bypassed, runtime errors hidden
- NestJS circular dependencies — `forwardRef()` overuse or hidden circular module graph
- Unhandled promise rejections — `async` method without try/catch, crashes process silently
- TypeORM eager relations without explicit joins — N+1 queries on every find call
- `undefined` vs `null` confusion — optional chaining gaps
- Event emitter memory leaks — listeners added without `removeListener`
- Injectable singleton state — mutable properties in `@Injectable()` shared across requests
- Missing `onModuleDestroy` — DB connections, timers, streams not released

**NestJS Architecture Patterns:**
- Port/Adapter violations — domain layer importing infrastructure concerns directly
- Missing exception filter coverage — `HttpException` vs application exceptions not mapped
- Interceptors with side effects — global interceptors modifying request state silently
- Guard bypasses — route-level guards not applied to all routes in controller
- DTO validation gaps — `class-validator` decorators missing on nested DTOs
- Controller fat logic — business logic in controllers instead of use cases/services

See `references/analysis-example.md` for a complete example output.

## Examples

### Example 1 — Analyze a NestJS service class

Paste the service code or provide its path:
```
/tw-ts-architecture-analyzer artifact=src/orders/orders.service.ts
```

### Example 2 — Analyze full repository (L1)

```
/tw-ts-architecture-analyzer
```

Claude scans the project structure, detects the NestJS module graph, and produces an L1
system-level analysis with bounded context diagram and top architectural risks.

### Example 3 — Triggered automatically

Paste a TypeScript class or method in the chat without any instruction. Claude detects
the scope, picks the appropriate level, and runs the full analysis flow.

## Dependencies

- TypeScript/NestJS project in the working directory
- No external scripts required — analysis is performed by Claude Code reading source files
