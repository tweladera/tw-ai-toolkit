---
name: tw-sonarqube
description: SonarQube/SonarCloud MCP server exposing code quality metrics, security hotspots, code smells, coverage data, and quality gate status to AI assistants. Enables AI-assisted triage of SonarQube findings.
status: stable
version_added: v0.5.0
compatible_with:
  claude_code: full
  cursor: full
  codex: none
tags:
  - sonarqube
  - sonarcloud
  - code-quality
  - security-hotspots
  - quality-gate
  - sast
  - enterprise
---

# tw-sonarqube

## Description

SonarQube is the enterprise standard for continuous code quality and security analysis.
Most large enterprise clients already have SonarQube or SonarCloud running — but the
findings often pile up unactioned because triaging them is time-consuming.

`tw-sonarqube` brings SonarQube data into the AI conversation: the assistant can read
quality gate status, explain specific findings, suggest fixes, and help prioritize the
backlog of code smells and security hotspots.

**The AI use case:** Instead of a developer manually opening SonarQube, finding an issue,
reading the documentation, and figuring out how to fix it — they ask the AI:
"What are the blocking SonarQube findings and how do I fix them?"

## Tools Exposed

| Tool | Description | Auth |
|---|---|---|
| `sonar_get_quality_gate` | Get quality gate status for a project (PASSED/FAILED) | Token |
| `sonar_list_issues` | List issues filtered by severity, type, status, or file | Token |
| `sonar_get_issue` | Get full issue details including rule description and fix suggestion | Token |
| `sonar_list_hotspots` | List security hotspots requiring manual review | Token |
| `sonar_get_hotspot` | Get full security hotspot details with vulnerability description | Token |
| `sonar_get_metrics` | Get quality metrics: coverage, duplications, complexity, debt | Token |
| `sonar_get_coverage` | Get line and branch coverage per file or module | Token |
| `sonar_list_projects` | List all analyzed projects (admin) | Token |
| `sonar_get_project_status` | Get project analysis status and last run timestamp | Token |

## Configuration

### SonarQube (self-hosted)

```json
{
  "mcpServers": {
    "tw-sonarqube": {
      "command": "npx",
      "args": ["-y", "@tw-ai/mcp-sonarqube"],
      "env": {
        "SONAR_TOKEN": "squ_xxxxxxxxxxxxxxxxxxxx",
        "SONAR_BASE_URL": "https://sonarqube.yourcompany.com",
        "SONAR_DEFAULT_PROJECT": "com.company:project-key"
      }
    }
  }
}
```

### SonarCloud

```json
{
  "mcpServers": {
    "tw-sonarqube": {
      "command": "npx",
      "args": ["-y", "@tw-ai/mcp-sonarqube"],
      "env": {
        "SONAR_TOKEN": "squ_xxxxxxxxxxxxxxxxxxxx",
        "SONAR_BASE_URL": "https://sonarcloud.io",
        "SONAR_ORGANIZATION": "your-org-key",
        "SONAR_DEFAULT_PROJECT": "your-org_project-key"
      }
    }
  }
}
```

### Generate a SonarQube Token

SonarQube: Account → Security → Generate Token (type: User Token or Project Analysis Token)
SonarCloud: Account → Security → Generate Token

Minimum permissions required: `Browse` on the target project(s).

## Example Interactions

```
User: "Is our SonarQube quality gate passing?"
→ AI calls sonar_get_quality_gate → "FAILED — 3 blocking issues"

User: "What are the BLOCKER issues in the orders service?"
→ AI calls sonar_list_issues(severity=BLOCKER, component=orders-service)
→ Returns list with descriptions, files, and line numbers

User: "Explain the SQL injection hotspot in OrderRepository.java and show me how to fix it"
→ AI calls sonar_get_hotspot(hotspotKey=...) → full vulnerability description
→ AI reads the file context and generates the fix

User: "How much technical debt do we have and what's the breakdown?"
→ AI calls sonar_get_metrics → debt in minutes, issues by category

User: "Which files have the lowest test coverage?"
→ AI calls sonar_get_coverage(sort=coverage_asc) → worst covered files
```

## Integration with Toolkit Skills

| SonarQube finding type | Toolkit skill to use |
|---|---|
| Security hotspot / vulnerability | `/tw-security-audit` for context + remediation |
| Low coverage | `/tw-ts-test-governor` or `/tw-java-test-governor` |
| Code smell (testability) | `/tw-qa-coach source=<file>` |
| Duplications | Manual refactoring — no specific skill |
| Quality gate failure | `/tw-release-readiness` for full picture |

## Security Notes

- Use Project Analysis Tokens (scoped to one project) when possible over User Tokens
- Store `SONAR_TOKEN` in `.env.toolkit` — never commit to git
- SonarQube tokens do not expire by default — set an expiration date if your instance supports it
- The MCP server has read-only access — it cannot modify SonarQube findings or configurations

## Notes

- SonarQube "quality gate" FAILED does not always mean the same as the toolkit's NO-GO — configure your gate to align with the toolkit's thresholds
- Security hotspots require manual review — the AI can explain them but cannot definitively classify them as vulnerabilities without context
- Coverage data from SonarQube and from Istanbul/Jacoco may differ slightly due to instrumentation differences
- For large projects, use `sonar_list_issues(componentKeys=specific-module)` to scope queries
